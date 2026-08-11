/*
 * Copyright (C) 2026 WebOS Ports
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0

import LuneOS.Service 1.0

import "ServiceLabels.js" as ServiceLabels

/**
 * The Synergy call transport registry.
 *
 * Ports the transport half of the legacy CallSynergizer: every account with a
 * PHONE capability is a transport the user can place a call over -- the
 * cellular modem, and any messaging connector that declares PHONE (WhatsApp,
 * Telegram, Signal, Teams, ...). Each transport is described by the account's
 * PHONE capabilityProvider, merged with whatever the connector publishes into
 * com.palm.callcapabilities:1 at runtime.
 *
 * SERVICE-AGNOSTIC: nothing here names a particular service. Adding a connector
 * means installing its account template, not editing this file.
 */
Item {
    id: callTransports

    readonly property string cellularTransport: ServiceLabels.TIL
    readonly property string palmProfile: ServiceLabels.PALM_PROFILE

    /**
     * Every known transport, keyed by account templateId. Each entry carries:
     *   templateId      "com.palm.telegram"
     *   accountId       db8 id of the account it came from
     *   serviceName     "type_telegram", the IM contact-point type it calls
     *   implementation  luna service to send call control to
     *   videoFormat     "none" / "both" / ...
     *   networkStatus   published by the connector, e.g. "service"
     *   networkName     the connector's own display name, if it has one
     *   alias           the signed-in account's own name
     */
    property var transports: ({})

    /**
     * Bumped whenever the registry changes. The map is mutated in place so its
     * own change signal never fires; bindings depend on this instead.
     * `transports` is a property, so transportsChanged() already exists.
     */
    property int revision: 0

    readonly property bool ready: revision > 0

    /**
     * Queries
     **/

    function transportIds() {
        revision;
        return Object.keys(transports);
    }

    /// Every transport except cellular and the palm profile: the Synergy ones.
    function voipTransportIds() {
        return transportIds().filter(function(id) {
            return id !== cellularTransport && id !== palmProfile;
        });
    }

    /// Transports the user can actually place a call over right now.
    function callableTransportIds() {
        return transportIds().filter(function(id) {
            return id !== palmProfile;
        });
    }

    readonly property bool hasCellular: !!transports[cellularTransport]
    readonly property bool hasVoipAccount: {
        revision;
        return voipTransportIds().length > 0;
    }

    /**
     * The IM contact-point types that map to a call transport
     * ("type_whatsapp", "type_telegram", ...). Drives which of a contact's IM
     * addresses are offered as call options.
     */
    function callableImTypes() {
        var types = [];
        voipTransportIds().forEach(function(id) {
            var name = transports[id].serviceName;
            if (name && types.indexOf(name) < 0)
                types.push(name);
        });
        return types;
    }

    /**
     * The subset of those whose account declares a video format. Video
     * capability is a per-service fact from the account template, not a
     * per-buddy runtime flag, so it comes straight off the capabilityProvider.
     */
    function videoCallableImTypes() {
        var types = [];
        voipTransportIds().forEach(function(id) {
            var transport = transports[id];
            if (transport.serviceName && transport.videoFormat &&
                transport.videoFormat !== "none" && types.indexOf(transport.serviceName) < 0)
                types.push(transport.serviceName);
        });
        return types;
    }

    /**
     * Resolves whatever a caller has -- a templateId, or the serviceName of an
     * IM contact point -- to a known transport id.
     *
     * The direct "type_X" -> "com.palm.X" mapping is tried first and is not
     * allowed to be overridden by a serviceName search: the legacy code hit a
     * case where one transport's stale serviceName hijacked another service's
     * calls. The search only runs for ids that do not follow the convention.
     */
    function resolveTransport(idOrServiceName) {
        if (!idOrServiceName)
            return "";

        if (transports[idOrServiceName])
            return idOrServiceName;

        var direct = ServiceLabels.serviceNameToTemplateId(idOrServiceName);
        if (direct && transports[direct])
            return direct;

        var ids = transportIds();
        for (var i = 0; i < ids.length; ++i) {
            if (transports[ids[i]].serviceName === idOrServiceName)
                return ids[i];
        }

        return "";
    }

    function transportFor(id) {
        return transports[resolveTransport(id)] || null;
    }

    function labelFor(id) {
        var resolved = resolveTransport(id) || id;
        return ServiceLabels.transportLabel(resolved, transports[resolved]);
    }

    function implementationFor(id) {
        var transport = transportFor(id);
        return transport ? transport.implementation : "";
    }

    function supportsVideo(id) {
        var transport = transportFor(id);
        return !!transport && !!transport.videoFormat && transport.videoFormat !== "none";
    }

    /// A transport is usable when its connector says it has service. Cellular
    /// reports this through oFono instead, so it is assumed available here and
    /// checked by the dial handler.
    function isAvailable(id) {
        var transport = transportFor(id);
        if (!transport) return false;
        if (id === cellularTransport) return true;
        if (!transport.networkStatus) return true;

        return transport.networkStatus === "service" || transport.networkStatus === "roaming";
    }

    /**
     * Discovery
     **/

    // A nested array on a db8 record arrives as a list model, not a JS array,
    // so it has no forEach. Normalise before walking it.
    function _asArray(list) {
        if (!list) return [];
        if (Array.isArray(list)) return list;

        var count = (list.length !== undefined) ? list.length : list.count;
        var result = [];
        for (var i = 0; i < count; ++i)
            result.push(list.get ? list.get(i) : list[i]);

        return result;
    }

    function _mergeTransport(templateId, values) {
        var merged = transports[templateId] || { templateId: templateId };
        for (var key in values)
            merged[key] = values[key];

        // Keep an explicit serviceName where the template did not give one, so
        // callableImTypes() works for connectors that only set templateId.
        if (!merged.serviceName)
            merged.serviceName = ServiceLabels.templateIdToServiceName(templateId);

        transports[templateId] = merged;
    }

    function _publish() {
        revision = revision + 1;
        transportsChanged();
    }

    // Accounts and their capability providers. The templates carry the static
    // description (implementation, videoFormat, name); the account carries which
    // of them the user actually signed in to.
    function _onAccounts(accounts, templates) {
        var seen = {};

        accounts.forEach(function(account) {
            if (!account.capabilityProviders || account.beingDeleted)
                return;

            var template = templates[account.templateId] || {};

            _asArray(account.capabilityProviders).forEach(function(capability) {
                if (capability.capability !== "PHONE")
                    return;

                var templateCapability = _templateCapability(template, capability.id) || {};

                seen[account.templateId] = true;
                _mergeTransport(account.templateId, {
                    accountId: account._id,
                    alias: account.alias || account.username || "",
                    implementation: capability.implementation || templateCapability.implementation || "",
                    serviceName: capability.serviceName || templateCapability.serviceName ||
                                 ServiceLabels.templateIdToServiceName(account.templateId),
                    videoFormat: capability.videoFormat || templateCapability.videoFormat || "none",
                    networkName: template.name || "",
                    icon: (template.icon && template.icon.loc_32x32) || ""
                });
            });
        });

        // Drop transports whose account went away, so removing an account stops
        // offering calls over it.
        transportIds().forEach(function(id) {
            if (!seen[id] && id !== cellularTransport)
                delete transports[id];
        });

        _publish();
    }

    function _templateCapability(template, capabilityId) {
        var providers = _asArray(template.capabilityProviders);
        for (var i = 0; i < providers.length; ++i) {
            if (providers[i].id === capabilityId)
                return providers[i];
        }
        return null;
    }

    // Runtime capabilities the connectors publish: network status, whether the
    // transport supports swapping and merging, its emergency numbers.
    function _onCapabilities(capabilities) {
        capabilities.forEach(function(capability) {
            if (!capability.transport)
                return;

            _mergeTransport(capability.transport, capability);
        });

        _publish();
    }

    property var _accountTemplates: ({})

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    // Runtime call capabilities, watched so a connector coming online updates
    // what the dialer offers without a restart.
    Db8Model {
        id: capabilitiesModel

        kind: "com.palm.callcapabilities:1"
        watch: true
        query: ({})

        Component.onCompleted: {
            if(capabilitiesModel.setTestDataFile) {
                capabilitiesModel.setTestDataFile(Qt.resolvedUrl("../test/callcapabilities.json"));
            }
        }

        onCountChanged: {
            var capabilities = [];
            for (var i = 0; i < capabilitiesModel.count; ++i)
                capabilities.push(capabilitiesModel.get(i));

            callTransports._onCapabilities(capabilities);
        }
    }

    // Accounts, watched the same way.
    Db8Model {
        id: accountsModel

        kind: "com.palm.account:1"
        watch: true
        query: ({
            "where": [ { "prop": "capabilityProviders.capability", "op": "=", "val": "PHONE" } ]
        })

        Component.onCompleted: {
            if(accountsModel.setTestDataFile) {
                accountsModel.setTestDataFile(Qt.resolvedUrl("../test/accounts.json"));
            }
        }

        onCountChanged: callTransports._refreshAccounts()
    }

    function _refreshAccounts() {
        var accounts = [];
        for (var i = 0; i < accountsModel.count; ++i)
            accounts.push(accountsModel.get(i));

        _onAccounts(accounts, _accountTemplates);
    }

    function _loadTemplates() {
        lunaService.call("luna://com.palm.service.accounts/listAccountTemplates",
                         JSON.stringify({}),
                         function(message) {
                             var response = JSON.parse(message.payload);
                             var templates = {};
                             (response.results || []).forEach(function(template) {
                                 templates[template.templateId] = template;
                             });
                             callTransports._accountTemplates = templates;
                             callTransports._refreshAccounts();
                         },
                         function(error) {
                             console.log("Could not list account templates: " + error);
                             callTransports._refreshAccounts();
                         });
    }

    Component.onCompleted: {
        // The cellular transport always exists on a device with a modem; it is
        // registered up front so dialling works before the accounts service has
        // answered, and before any Synergy connector is installed.
        _mergeTransport(cellularTransport, {
            accountId: "",
            serviceName: "",
            implementation: "luna://com.palm.telephony",
            videoFormat: "none",
            networkName: ""
        });
        _publish();

        _loadTemplates();
    }
}
