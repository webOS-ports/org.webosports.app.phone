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

import "DialStringParser.js" as DialStringParser

/**
 * Decides which transport a call goes over.
 *
 * Ports the legacy DialProxy. With one calling account the answer is obvious;
 * with several it comes from the user's preferred service for domestic and for
 * international calls, and when that preference is unset the user is asked at
 * dial time.
 *
 * SERVICE-AGNOSTIC: the preference holds an account templateId, so any current
 * or future connector can be the preferred service without code changes.
 */
Item {
    id: dialProxy

    property CallTransports callTransports
    property TelephonyManager telephonyManager

    /// The user has to pick a transport before this call can be placed.
    /// `callData` is { address, video, audio, personId, isInternational }.
    signal transportChoiceRequired(var callData);

    /// No account can place calls at all.
    signal noCallingAccount();

    readonly property string preferenceDomestic: "phonePreferredDomesticPhoneService"
    readonly property string preferenceInternational: "phonePreferredIntlPhoneService"

    property string preferredDomesticService: "none"
    property string preferredInternationalService: "none"

    /**
     * Returns the transport to dial `address` over, or "" when the caller must
     * ask the user first (in which case transportChoiceRequired has fired).
     */
    function chooseTransport(address, callData) {
        var transports = callTransports.callableTransportIds();

        if (transports.length === 0) {
            console.log("No calling account is available");
            noCallingAccount();
            return "";
        }

        // MMI and USSD strings only mean anything to the modem. Sending them to
        // a messaging connector would place a call to a nonsense address.
        if (_isCellularOnly(address))
            return callTransports.hasCellular ? callTransports.cellularTransport : "";

        if (transports.length === 1)
            return transports[0];

        var international = _isInternational(address);
        var preferred = international ? preferredInternationalService : preferredDomesticService;

        if (preferred && preferred !== "none") {
            var resolved = callTransports.resolveTransport(preferred);
            if (resolved.length > 0)
                return resolved;

            // The preferred account was removed since it was chosen.
            console.log("Preferred service " + preferred + " is no longer available");
        }

        var data = callData || {};
        data.address = address;
        data.isInternational = international;
        transportChoiceRequired(data);
        return "";
    }

    /// Remembers the user's choice so they are not asked again.
    function setPreferredService(transportId, international) {
        var payload = {};
        payload[international ? preferenceInternational : preferenceDomestic] = transportId;

        lunaService.call("luna://com.webos.service.systemservice/setPreferences",
                         JSON.stringify(payload), undefined,
                         function(error) { console.log("Could not store the preferred service: " + error); });
    }

    /**
     * private
     **/

    // Anything the modem has to interpret itself: MMI codes, USSD, in-call
    // control digits, and emergency numbers.
    function _isCellularOnly(address) {
        if (/[*#]/.test(address))
            return true;

        if (DialStringParser.isEmergencyNumber(address,
                telephonyManager ? telephonyManager.emergencyNumbers : []))
            return true;

        return false;
    }

    // "International" means a country code the SIM's own country does not match.
    // Without a SIM to compare against, a leading + or 00 is the best we can do.
    function _isInternational(address) {
        var normalized = String(address).replace(/[\s()\-.]/g, "");
        if (normalized.indexOf("+") !== 0 && normalized.indexOf("00") !== 0)
            return false;

        var homeCode = _homeCountryCode();
        if (homeCode.length === 0)
            return true;

        var prefix = normalized.indexOf("+") === 0 ? normalized.slice(1) : normalized.slice(2);
        return prefix.indexOf(homeCode) !== 0;
    }

    function _homeCountryCode() {
        // The MCC identifies the SIM's country; the dialling code cannot be
        // derived from it here, so only an explicit country code is compared.
        return "";
    }

    function _onPreferences(preferences) {
        if (typeof preferences[preferenceDomestic] === 'string')
            preferredDomesticService = preferences[preferenceDomestic];
        if (typeof preferences[preferenceInternational] === 'string')
            preferredInternationalService = preferences[preferenceInternational];
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
    }

    Component.onCompleted: {
        lunaService.subscribe("luna://com.webos.service.systemservice/getPreferences",
                              JSON.stringify({ keys: [preferenceDomestic, preferenceInternational],
                                               subscribe: true }),
                              function(message) { _onPreferences(JSON.parse(message.payload)); },
                              function(error) { console.log("No preferred phone service set: " + error); });
    }
}
