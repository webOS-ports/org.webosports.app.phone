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

// The ways a contact can be reached: their phone numbers over the modem, and
// their IM addresses over whichever Synergy connectors can place calls.
//
// Ports the legacy Utils.getDefaultCallableIms / Favorites call-option list.
// SERVICE-AGNOSTIC: which IM types count as callable comes from the transport
// registry at runtime, so a newly installed connector's addresses show up here
// with no code change.

.pragma library

.import "ServiceLabels.js" as ServiceLabels

function _asArray(list) {
    if (!list) return [];
    if (Array.isArray(list)) return list;

    var count = (list.length !== undefined) ? list.length : list.count;
    var result = [];
    for (var i = 0; i < count; ++i)
        result.push(list.get ? list.get(i) : list[i]);

    return result;
}

/// A person's IM addresses, as a plain array.
function imAddressesOf(person) {
    return _asArray(person ? person.ims : null);
}

/// A person's phone numbers, as a plain array.
function phoneNumbersOf(person) {
    return _asArray(person ? person.phoneNumbers : null);
}

/**
 * Every way this contact can be called, most-preferred first.
 *
 * Each option is:
 *   kind            "phone" or "im"
 *   value           the address to dial
 *   type            contact point type, e.g. "type_mobile" / "type_telegram"
 *   typeLabel       "Mobile" / "Telegram"
 *   transport       account templateId to place the call over, "" for cellular
 *   transportLabel  "Cellular" / "Telegram"
 *   supportsVideo   whether that transport can carry video
 *   isPrimary       the number flagged primary in Contacts
 */
function callOptionsFor(person, callTransports) {
    if (!person)
        return [];

    var options = [];
    var cellular = callTransports ? callTransports.cellularTransport : ServiceLabels.TIL;
    var hasCellular = !callTransports || callTransports.hasCellular;

    // Phone numbers go over the modem. Without a modem they are still listed if
    // some connector can dial a phone number -- that is what the dial proxy is
    // for -- but they are not attached to a specific transport here.
    phoneNumbersOf(person).forEach(function(number) {
        if (!number || !number.value)
            return;

        options.push({
            kind: "phone",
            value: number.value,
            type: number.type || "type_other",
            typeLabel: ServiceLabels.phoneNumberTypeLabel(number.type),
            transport: hasCellular ? cellular : "",
            transportLabel: hasCellular ? ServiceLabels.transportLabel(cellular, null) : "",
            supportsVideo: false,
            isPrimary: number.primary === true
        });
    });

    if (!callTransports)
        return options;

    // IM addresses go over the connector that owns their type, and only if that
    // connector is actually installed and signed in.
    var callableTypes = callTransports.callableImTypes();

    imAddressesOf(person).forEach(function(im) {
        if (!im || !im.value || callableTypes.indexOf(im.type) < 0)
            return;

        var transportId = callTransports.resolveTransport(im.type);
        if (transportId.length === 0)
            return;

        options.push({
            kind: "im",
            value: im.value,
            type: im.type,
            typeLabel: ServiceLabels.imServiceLabel(im.type),
            transport: transportId,
            transportLabel: callTransports.labelFor(transportId),
            supportsVideo: callTransports.supportsVideo(transportId),
            isPrimary: false
        });
    });

    return options;
}

/// The single option to use when the user just taps a contact.
function defaultCallOption(person, callTransports) {
    var options = callOptionsFor(person, callTransports);
    if (options.length === 0)
        return null;

    for (var i = 0; i < options.length; ++i) {
        if (options[i].isPrimary)
            return options[i];
    }

    return options[0];
}

/// Options that can carry a video call.
function videoCallOptionsFor(person, callTransports) {
    return callOptionsFor(person, callTransports).filter(function(option) {
        return option.supportsVideo;
    });
}

/// How an IM address should be shown: E.164 ids read as phone numbers, and
/// username-style ids are left alone.
function formatImAddress(value) {
    return String(value === undefined || value === null ? "" : value).trim();
}
