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

// User-visible telephony strings, ported from the legacy Enyo phone app
// (com.palm.app.phone source/Messages.js and phonePopups/sources/DialFail.js).

.pragma library

// Number placeholders. unknownNumber deliberately has no trailing period.
var unknownNumber = qsTr("Unknown number");
var blockedNumber = qsTr("Blocked number");
var conferenceCall = qsTr("Conference call");
var voicemailContact = qsTr("Voicemail");
var emergencyCallContact = qsTr("Emergency call");

// Call states.
var callStateDialing = qsTr("Dialing");
var callStateEnding = qsTr("Ending");
var callStateEnded = qsTr("Ended");
var callStateHold = qsTr("On hold");
var callStateIncoming = qsTr("Incoming");
var callStateWaiting = qsTr("Call waiting");
var callStateActive = qsTr("Active");

// Call log.
var logIncoming = qsTr("Incoming call");
var logMissed = qsTr("Missed call");
var logOutgoing = qsTr("Placed call");
var logIgnored = qsTr("Ignored call");

// Notifications.
var missedCallTitle = qsTr("Missed call");
var voicemailTitle = qsTr("Voicemail");
var networkMessageTitle = qsTr("Network message");

// Dialpad / dialing.
var voicemailNumberNotFound = qsTr("Unable to find voicemail number.");
var dialOnPowerPending = qsTr("Connecting to network to dial...");
var dialOnPowerFail = qsTr("Unable to complete call.");
var emergencyModeDialFailure = qsTr("Emergency call failed.");

// Supplementary services.
var mmiPending = qsTr("Sending your request...");
var mmiTimeout = qsTr("Request failed to complete before timeout.");
var mmiFailed = qsTr("Your request could not be completed.");
var mmiSucceeded = qsTr("Request completed.");
var noServiceError = qsTr("No service.");
var forwardingActivated = qsTr("(activated)");
var forwardingNotActivated = qsTr("(not activated)");

// Audio routes.
var audioRouteEarpiece = qsTr("Handset");
var audioRouteBluetooth = qsTr("Bluetooth");
var audioRouteSpeaker = qsTr("Speaker");
var audioRouteWiredHeadset = qsTr("Wired headset");

// Reason strings reported by the modem/telephony stack when a call cannot be
// placed. Keyed the same way the legacy DialFail popup keyed them.
var dialFailureTitle = qsTr("Unable to connect");
var dialFailureDefault = qsTr("Call failed.");
var dialFailure = {
    "callfailed": qsTr("Call failed."),
    "airplanemodeon": qsTr("Airplane mode is on."),
    "locked": qsTr("Phone is locked."),
    "noservice": qsTr("No service."),
    "invalidnumber": qsTr("Number not on fixed dialing list."),
    "emergencyonly": qsTr("Emergency calls only."),
    "nofreelines": qsTr("No free lines."),
    "pinrequired": qsTr("PIN required."),
    "pukrequired": qsTr("Call service provider for PUK code."),
    "simblocked": qsTr("SIM permanently blocked."),
    "rebootdevice": qsTr("The number you are trying to call cannot be tried again until you restart your phone."),
    "networkunavailable": qsTr("The network is unavailable."),
    "notloggedin": qsTr("Not logged in."),
    "contactnotfound": qsTr("Contact not found."),
    "invalidaddress": qsTr("Invalid address."),
    "insufficientfunds": qsTr("Insufficient funds.")
};

// Reasons a call in progress went away by itself.
var droppedCallTitle = qsTr("Call dropped");
var droppedCallDefault = qsTr("Call dropped.");
var droppedCall = {
    "signalfaded": qsTr("Call dropped: signal faded."),
    "outofrange": qsTr("Call dropped: out of range."),
    "networkfailure": qsTr("Call dropped: network failure."),
    "localhangup": qsTr("Call ended."),
    "remotehangup": qsTr("The other party hung up.")
};

// SIM PIN / PUK.
var pinFailureDefault = qsTr("Unable to change PIN.");
var pinFailure = {
    "incorrect": qsTr("Unable to change PIN: PIN not correct."),
    "puklocked": qsTr("Unable to change PIN: PUK locked."),
    "simlocked": qsTr("Unable to change PIN: SIM locked."),
    "notenabled": qsTr("Unable to change PIN: enable PIN first."),
    "mismatch": qsTr("Unable to change PIN: PINs don't match."),
    "badformat": qsTr("Unable to change PIN: bad format.")
};

var pukFailureDefault = qsTr("Unable to unlock PUK.");
var pukFailure = {
    "incorrect": qsTr("Unable to unlock PUK: bad or incorrect PUK."),
    "invalidpin": qsTr("Unable to unlock PUK: new PIN not valid."),
    "simlocked": qsTr("Unable to unlock PUK: SIM locked."),
    "mismatch": qsTr("Unable to unlock PUK: PINs don't match.")
};

/// Looks up a message in one of the maps above, falling back to its default.
function lookup(table, key, fallback) {
    if (key && table[key])
        return table[key];
    return fallback;
}
