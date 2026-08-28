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

// Dial string parsing, ported from the legacy Enyo phone app
// (com.palm.app.phone source/telephonydialhandler/TelephonyDialHandler.js).
//
// parse() is pure: it turns a dial string into an action descriptor and never
// touches a service. DialHandler.qml executes the descriptor. Keeping the two
// apart is what makes the GSM rules testable without a modem.

.pragma library

.import "MmiCodes.js" as MmiCodes

// Launch codes that hand off to another application, dialled as "#*<code>#".
// The legacy table pointed at Palm diagnostic apps (com.palm.app.phonediag,
// com.palm.app.ftp, ...) that no longer exist; the table is empty until
// LuneOS has an app worth a launch code. A code that matches nothing here is
// sent out as USSD, like any other "#..." string.
var LaunchCodesExternalApps = {};

// Prefixes that introduce a launch code on GSM.
var LaunchCodePrefixes = ["#*"];

// A normal number: all numeric (optionally with '+'), at least 3 digits.
var REGEX_NORMAL_NUMBER = /^[0-9\+]{3,}$/;

// Matches *|#|**|##|*# into group 1, and the rest of the dial string
// (minus the trailing '#') into group 2.
var REGEX_GSM_LAUNCH_CODE = /^(\*|#|\*\*|##|\*#)([\+0-9]+[\+0-9\*]*)#$/;

// (star or hash) then a digit, or '0', or '00' -- North American short codes.
var REGEX_GSM_NA = /^([\*#][0-9]|0|00)$/;

// Service code (the first number, terminated by either '*' or '#').
var REGEX_GSM_SERVICE_CODE = /^([0-9]*)[\*#]?([\+0-9\*]*)$/;

// *31#<number> to suppress CLIR, #31#<number> to invoke CLIR.
var REGEX_CLIR = /^([\*#]31#)([\+0-9]+)$/;

// SI1..SI4 separated by '*'. '+' is allowed in the first slot for call forwarding.
var REGEX_GSM_MULTI_MMI = /^([0-9\+]*)[\*]?([0-9]*)[\*]?([0-9]*)[\*]?([0-9]*)[\*]?/;

// Characters that pause (',' / 'p') or wait (';' / 'w') before sending the
// remainder of the dial string as DTMF once the call is up.
var REGEX_POST_DIAL = /[,p;w]/i;

// Default emergency numbers, used until oFono reports the network's own list.
var DefaultEmergencyNumbers = ["911", "112", "000", "08", "110", "999", "118", "119", "#911", "*911"];

/// Strips everything that cannot be part of a dial string.
function normalize(address) {
    return address ? String(address).replace(/[^\+01234567890\*#,;pwt]/gi, '') : '';
}

/// Just the digits, for handing to the modem.
function digitsOnly(address) {
    return address ? String(address).replace(/[^\+0-9]/g, '') : '';
}

function isDtmfKey(character) {
    return "0123456789*#".indexOf(character) >= 0;
}

function isEmergencyNumber(address, emergencyNumbers) {
    var numbers = (emergencyNumbers && emergencyNumbers.length > 0) ? emergencyNumbers
                                                                    : DefaultEmergencyNumbers;
    return numbers.indexOf(address) >= 0;
}

/// Splits "555123,,1234" into { number: "555123", postDial: ",,1234" }.
function splitPostDial(address) {
    var index = address.search(REGEX_POST_DIAL);
    if (index < 0)
        return { number: address, postDial: "" };

    return { number: address.slice(0, index), postDial: address.slice(index) };
}

function _launchCodeFor(address) {
    for (var i = 0; i < LaunchCodePrefixes.length; i++) {
        if (address.indexOf(LaunchCodePrefixes[i]) === 0)
            return address.slice(LaunchCodePrefixes[i].length).replace(/#$/, '');
    }
    return undefined;
}

/// Substitutes #{si.1}, #{ic.2}, #{bs.1} ... in an MMI command template.
function interpolate(template, values) {
    return JSON.stringify(template).replace(/#\{([a-z]+)\.([0-9]+)\}/g, function(match, group, index) {
        var table = values[group];
        var value = table ? table[parseInt(index, 10)] : undefined;
        if (value === undefined || value === null)
            return "";
        // The template is already JSON, so escape whatever we splice into it.
        return JSON.stringify(String(value)).slice(1, -1);
    });
}

function _parseMmi(address) {
    var parsed = address.match(REGEX_GSM_LAUNCH_CODE);
    if (!parsed)
        return undefined;

    var mmi = {};
    switch (parsed[1]) {
    case "*":  mmi.action = 'activate'; break;
    case "#":  mmi.action = 'deactivate'; break;
    case "**": mmi.action = 'register'; break;
    case "##": mmi.action = 'unregister'; break;
    case "*#": mmi.action = 'interrogate'; break;
    }

    var matches = parsed[2].match(REGEX_GSM_SERVICE_CODE);
    if (matches && matches.length >= 2) {
        mmi.serviceCode = matches[1];
        mmi.si = matches[2];
    }

    // Not a service code we know: the whole string goes out as USSD.
    if (!mmi.serviceCode || !MmiCodes.MmiServiceCodes[mmi.serviceCode])
        return { action: "ussd", command: address };

    mmi.si = mmi.si.match(REGEX_GSM_MULTI_MMI);

    var template = MmiCodes.MmiServiceCodes[mmi.serviceCode][mmi.action];
    if (!template)
        return { action: "none", reason: "unsupportedMmiAction" };

    // Call forwarding special case: "activate" with a number really means "register".
    if (mmi.action === 'activate' && mmi.si[1].length > 0 && template.cmd.indexOf("forward") >= 0 &&
        MmiCodes.MmiServiceCodes[mmi.serviceCode]["register"]) {
        template = MmiCodes.MmiServiceCodes[mmi.serviceCode]["register"];
        mmi.action = "register";
    }

    // Bearer / info class for each supplementary information slot.
    mmi.ic = [];
    for (var i = 1; i <= 4; i++)
        mmi.ic[i] = MmiCodes.MmiInfoClass[mmi.si[i]] || MmiCodes.MmiInfoClassDefault;

    // Call barring type, used when changing the barring password (*03 / **03).
    mmi.bs = [];
    mmi.bs[1] = MmiCodes.MmiCallBarringType[mmi.si[1]] || MmiCodes.MmiCallBarringTypeDefault;

    var args = JSON.parse(interpolate(template, mmi));
    var cmd = args.cmd;
    delete args.cmd;

    return { action: "mmi", cmd: cmd, args: args, serviceCode: mmi.serviceCode, mmiAction: mmi.action };
}

// In-call MMI (3GPP 22.030 6.5.5): single digits control the calls in progress.
function _parseInCall(address) {
    if (address.length > 2)
        return undefined;

    if (address.length === 1) {
        switch (address) {
        case "0": return { action: "callControl", op: "releaseHeldOrReject" };
        case "1": return { action: "callControl", op: "releaseActiveAndAnswer" };
        case "2": return { action: "callControl", op: "swap" };
        case "3": return { action: "callControl", op: "merge" };
        default:  return { action: "ussd", command: address };
        }
    }

    var index = parseInt(address.charAt(1), 10);
    switch (address.charAt(0)) {
    case '1': return { action: "callControl", op: "releaseCall", index: index };
    case '2': return { action: "callControl", op: "privateChat", index: index };
    default:  return { action: "ussd", command: address };
    }
}

/**
 * Turns a dial string into an action descriptor.
 *
 * context:
 *   emergencyNumbers  numbers oFono reports for the current network
 *   hasCall           true when a call is already in progress
 *   northAmerican     honour *NN / 0 / 00 short codes instead of sending USSD
 *   radioOn           false when the modem is offline (airplane mode)
 *
 * Returns one of:
 *   { action: "none", reason }
 *   { action: "emergency", number, radioOff }
 *   { action: "launchApp", appId, launchCode }
 *   { action: "callControl", op, index }
 *   { action: "clir", number, hideCallerId }
 *   { action: "mmi", cmd, args }
 *   { action: "ussd", command }
 *   { action: "dial", number, postDial }
 */
function parse(rawAddress, context) {
    var ctx = context || {};
    var address = normalize(rawAddress);

    // 'w'/'p' on their own have nothing to dial.
    if (!address || address[0] === 'w' || address[0] === 'p')
        return { action: "none", reason: "empty" };

    // Emergency numbers always go out, even with the radio off -- the caller is
    // expected to power the modem up first and redial.
    if (isEmergencyNumber(address, ctx.emergencyNumbers))
        return { action: "emergency", number: address, radioOff: (ctx.radioOn === false) };

    var launchCode = _launchCodeFor(address);
    if (launchCode && LaunchCodesExternalApps[launchCode]) {
        return { action: "launchApp", appId: LaunchCodesExternalApps[launchCode],
                 launchCode: launchCode };
    }

    // Plain number: dial it now, before any of the GSM special-casing below.
    if (REGEX_NORMAL_NUMBER.test(address))
        return { action: "dial", number: address, postDial: "" };

    if (ctx.hasCall) {
        var inCall = _parseInCall(address);
        if (inCall)
            return inCall;
    }

    var clir = address.match(REGEX_CLIR);
    if (clir)
        return { action: "clir", number: clir[2], hideCallerId: (clir[1] === "#31#") };

    var mmi = _parseMmi(address);
    if (mmi)
        return mmi;

    if (!ctx.hasCall && address.length <= 2) {
        // Short string with no call up: USSD unless it starts with 1, p or w.
        if ('1pw'.indexOf(address.charAt(0)) === -1) {
            if (ctx.northAmerican && REGEX_GSM_NA.test(address))
                return { action: "dial", number: address, postDial: "" };
            return { action: "ussd", command: address };
        }
        if ('pw'.indexOf(address.charAt(0)) === -1)
            return { action: "dial", number: address, postDial: "" };

        return { action: "none", reason: "notDialable" };
    }

    var split = splitPostDial(address);
    if (split.postDial.length > 0)
        return { action: "dial", number: split.number, postDial: split.postDial };

    // Anything else ending in '#' is USSD (3GPP 22.030 6.5.3.2, figure 3.5.3.2).
    if (address.charAt(address.length - 1) === '#')
        return { action: "ussd", command: address };

    return { action: "dial", number: address, postDial: "" };
}
