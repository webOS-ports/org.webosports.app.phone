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

// Display names for Synergy contact points and call transports.
// Ported from com.palm.app.phone source/utils/Utils.js.
//
// SERVICE-AGNOSTIC by design: a new messaging connector must need no code here.
// Anything whose label is just its own name Title-cased is derived; the table
// below only covers names plain Title-casing cannot produce -- acronyms,
// internal capitals, punctuation, or a name that differs from the type.

.pragma library

var TIL = "com.palm.telephony";
var PALM_PROFILE = "com.palm.palmprofile";

var imServiceLabels = {
    "type_aim": qsTr("AIM"),
    "type_yahoo": qsTr("Yahoo!"),
    "type_gtalk": qsTr("GTalk"),
    "type_msn": qsTr("Messenger"),
    "type_icq": qsTr("ICQ"),
    "type_irc": qsTr("IRC"),
    "type_qq": qsTr("QQ"),
    "type_whatsapp": qsTr("WhatsApp"),
    "type_yjp": qsTr("Y! Japan"),
    "type_lcs": qsTr("LCS"),
    "type_dotmac": qsTr(".Mac"),
    "type_myspace": qsTr("MySpace"),
    "type_gadugadu": qsTr("GaduGadu"),
    "type_googlechat": qsTr("Google Chat"),
    "type_default": qsTr("IM")
};

var phoneNumberTypeLabels = {
    "type_mobile": qsTr("Mobile"),
    "type_home": qsTr("Home"),
    "type_home2": qsTr("Home 2"),
    "type_work": qsTr("Work"),
    "type_work2": qsTr("Work 2"),
    "type_main": qsTr("Main"),
    "type_personal_fax": qsTr("Fax"),
    "type_work_fax": qsTr("Fax"),
    "type_pager": qsTr("Pager"),
    "type_personal": qsTr("Personal"),
    "type_sim": qsTr("SIM"),
    "type_assistant": qsTr("Assistant"),
    "type_car": qsTr("Car"),
    "type_radio": qsTr("Radio"),
    "type_company": qsTr("Company"),
    "type_other": qsTr("Other")
};

/// "type_teams" -> "Teams". Derived when the table has no entry.
function imServiceLabel(type) {
    if (!type || String(type).indexOf("type_") !== 0)
        return "";

    if (imServiceLabels[type])
        return imServiceLabels[type];

    var name = String(type).slice("type_".length);
    return name.charAt(0).toUpperCase() + name.slice(1);
}

function phoneNumberTypeLabel(type) {
    return phoneNumberTypeLabels[type] || qsTr("Other");
}

/**
 * Display name for the transport a call went over. Prefers the account's own
 * network name, then its serviceName, then the last segment of the templateId
 * ("com.palm.telegram" -> "Telegram").
 */
function transportLabel(transportId, transport) {
    if (!transportId)
        return "";

    if (transportId === TIL)
        return qsTr("Cellular");

    if (transport) {
        if (transport.networkName && transport.networkName.length > 0)
            return transport.networkName;
        if (transport.serviceName)
            return imServiceLabel(transport.serviceName);
    }

    var segment = String(transportId).split(".").pop();
    return segment ? (segment.charAt(0).toUpperCase() + segment.slice(1)) : String(transportId);
}

/**
 * The account templateId for a serviceName, and vice versa.
 *
 * Every connector's templateId is "com.palm.<X>" for serviceName "type_<X>",
 * so the mapping is direct. The legacy code learned the hard way not to search
 * by serviceName first: one stale entry elsewhere in the registry could hijack
 * the match. Callers use this and only fall back to a search if the direct id
 * is not a known transport.
 */
function serviceNameToTemplateId(serviceName) {
    if (!serviceName || String(serviceName).indexOf("type_") !== 0)
        return "";

    return "com.palm." + String(serviceName).slice("type_".length);
}

function templateIdToServiceName(templateId) {
    if (!templateId || String(templateId).indexOf("com.palm.") !== 0)
        return "";

    return "type_" + String(templateId).slice("com.palm.".length);
}

/// An IM address that is an E.164 number is formatted like a phone number;
/// username-style ids are shown unchanged.
function looksLikePhoneNumber(value) {
    return /^\+?[0-9][0-9 ().\-]{5,}$/.test(String(value || "").trim());
}
