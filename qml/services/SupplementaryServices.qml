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

import QOfono 0.2

import "PinTypes.js" as PinTypes
import "CallMessages.js" as CallMessages

/**
 * Executes the supplementary-service commands that DialStringParser decodes out
 * of an MMI dial string, and exposes the same operations to the preferences UI.
 *
 * The legacy Enyo app sent these as `cmd` payloads to com.palm.telephony
 * (source/telephonydialhandler/MmiService.js); here each one maps onto the
 * matching oFono interface.
 */
Item {
    id: supplementaryServices

    property string modemPath: ""

    /// Emitted when a command finished, with a message ready to show the user.
    signal completed(bool success, string message);
    /// Emitted for interrogations, with the current setting.
    signal queried(string what, string status, string details);

    readonly property bool busy: _pendingCommand.length > 0
    property string _pendingCommand: ""

    // Call barring conditions, as named by the MMI tables, mapped onto the
    // barring strings oFono understands.
    readonly property var _barringOutgoing: ({
        "baralloutgoing": "always",
        "baroutgoingint": "international",
        "baroutgoingintextohome": "internationalnothome",
        "baroutgoing": "always"
    })
    readonly property var _barringIncoming: ({
        "barallincoming": "always",
        "barincomingroaming": "whenroaming",
        "barincoming": "always"
    })

    /**
     * Runs an MMI command produced by DialStringParser.parse().
     * Returns false when the command is not something we can carry out.
     */
    function execute(cmd, args) {
        console.log("Supplementary service: " + cmd + " " + JSON.stringify(args));
        _pendingCommand = cmd;

        switch (cmd) {
        case "forwardActivate":  return _forwardActivate(args);
        case "forwardRegister":  return _forwardRegister(args);
        case "forwardQuery":     return _forwardQuery(args);
        case "callWaitingSet":   return _callWaitingSet(args);
        case "callWaitingQuery": return _callWaitingQuery(args);
        case "barringSet":       return _barringSet(args);
        case "barringQuery":     return _barringQuery(args);
        case "barringPasswordChange": return _barringPasswordChange(args);
        case "clirSet":          return _clirSet(args);
        case "clirQuery":        return _clirQuery(args);
        case "clipQuery":        return _clipQuery(args);
        case "cnapQuery":        return _cnapQuery(args);
        case "imeiQuery":        return _imeiQuery(args);
        case "pin1Change":       return _pinChange(PinTypes.SimPin, args.oldPin, args.newPin, args.newPinConfirm);
        case "pin2Change":       return _pinChange(PinTypes.SimPin2, args.oldPin, args.newPin, args.newPinConfirm);
        case "pin1Unblock":      return _pinUnblock(PinTypes.SimPuk, args.puk, args.newPin, args.newPinConfirm);
        case "pin2Unblock":      return _pinUnblock(PinTypes.SimPuk2, args.puk2, args.newPin2, args.newPinConfirm);
        }

        _fail(CallMessages.mmiFailed);
        return false;
    }

    /**
     * Preferences-facing API. These are the same operations the MMI codes reach,
     * exposed under readable names for PhonePrefsPage.
     */
    property alias callForwardingUnconditional: callForwarding.voiceUnconditional
    property alias callForwardingBusy: callForwarding.voiceBusy
    property alias callForwardingNoReply: callForwarding.voiceNoReply
    property alias callForwardingNoReplyTimeout: callForwarding.voiceNoReplyTimeout
    property alias callForwardingNotReachable: callForwarding.voiceNotReachable
    property alias callWaiting: callSettings.voiceCallWaiting
    property alias hideCallerId: callSettings.hideCallerId
    property alias barringIncoming: callBarring.voiceIncoming
    property alias barringOutgoing: callBarring.voiceOutgoing

    function disableAllForwarding() {
        _pendingCommand = "forwardActivate";
        callForwarding.disableAll("all");
    }

    function disableAllBarring(password) {
        _pendingCommand = "barringSet";
        callBarring.disableAll(password || "");
    }

    function changeBarringPassword(oldPassword, newPassword) {
        _pendingCommand = "barringPasswordChange";
        callBarring.changePassword(oldPassword, newPassword);
    }

    function changeSimPin(oldPin, newPin) {
        return _pinChange(PinTypes.SimPin, oldPin, newPin, newPin);
    }

    function unblockSimPin(puk, newPin) {
        return _pinUnblock(PinTypes.SimPuk, puk, newPin, newPin);
    }

    function lockSimPin(pin) {
        _pendingCommand = "pinLock";
        simManager.lockPin(PinTypes.SimPin, pin);
        return true;
    }

    function unlockSimPin(pin) {
        _pendingCommand = "pinUnlock";
        simManager.unlockPin(PinTypes.SimPin, pin);
        return true;
    }

    /**
     * private
     **/

    function _done(success, message) {
        _pendingCommand = "";
        completed(success, message);
    }

    function _fail(message) {
        _done(false, message || CallMessages.mmiFailed);
    }

    // Call forwarding. The MMI tables use 'condition' names that do not line up
    // one-to-one with oFono's per-condition properties, so translate here.
    function _forwardSetter(condition, value) {
        switch (condition) {
        case "unconditional":  callForwarding.voiceUnconditional = value; return true;
        case "mobilebusy":     callForwarding.voiceBusy = value; return true;
        case "noreply":        callForwarding.voiceNoReply = value; return true;
        case "unreachable":    callForwarding.voiceNotReachable = value; return true;
        case "allconditional":
            callForwarding.voiceBusy = value;
            callForwarding.voiceNoReply = value;
            callForwarding.voiceNotReachable = value;
            return true;
        case "allforwarding":
            callForwarding.voiceUnconditional = value;
            callForwarding.voiceBusy = value;
            callForwarding.voiceNoReply = value;
            callForwarding.voiceNotReachable = value;
            return true;
        }
        return false;
    }

    function _forwardActivate(args) {
        // oFono has no separate activate/deactivate: an empty number is "off",
        // and there is no stored number to re-activate, so activation without a
        // number can only be expressed by clearing the condition.
        if (args.activate) {
            _fail(qsTr("Enter the forwarding number to turn call forwarding on."));
            return false;
        }

        if (args.condition === "allforwarding" || args.condition === "allconditional") {
            callForwarding.disableAll(args.condition === "allforwarding" ? "all" : "conditional");
            return true;
        }

        if (!_forwardSetter(args.condition, "")) {
            _fail();
            return false;
        }
        return true;
    }

    function _forwardRegister(args) {
        if (args.time && args.time.length > 0)
            callForwarding.voiceNoReplyTimeout = parseInt(args.time, 10);

        if (!_forwardSetter(args.condition, args.number || "")) {
            _fail();
            return false;
        }
        return true;
    }

    function _forwardQuery(args) {
        var value = "";
        switch (args.condition) {
        case "unconditional": value = callForwarding.voiceUnconditional; break;
        case "mobilebusy":    value = callForwarding.voiceBusy; break;
        case "noreply":       value = callForwarding.voiceNoReply; break;
        case "unreachable":   value = callForwarding.voiceNotReachable; break;
        default:
            value = [callForwarding.voiceUnconditional, callForwarding.voiceBusy,
                     callForwarding.voiceNoReply, callForwarding.voiceNotReachable]
                        .filter(function(n) { return n && n.length > 0; }).join(", ");
            break;
        }

        var active = value && value.length > 0;
        queried("callforwarding", active ? CallMessages.forwardingActivated
                                         : CallMessages.forwardingNotActivated, value);
        _done(true, (active ? qsTr("Calls are forwarded to %1").arg(value)
                            : qsTr("Call forwarding is off")));
        return true;
    }

    function _callWaitingSet(args) {
        callSettings.voiceCallWaiting = args.enable ? "enabled" : "disabled";
        return true;
    }

    function _callWaitingQuery(args) {
        var enabled = callSettings.voiceCallWaiting === "enabled";
        queried("callwaiting", enabled ? "enabled" : "disabled", "");
        _done(true, enabled ? qsTr("Call waiting is on") : qsTr("Call waiting is off"));
        return true;
    }

    function _barringSet(args) {
        var outgoing = _barringOutgoing[args.condition];
        var incoming = _barringIncoming[args.condition];

        if (args.condition === "barallbarring" || args.condition === "barallservices") {
            if (!args.enable) {
                callBarring.disableAll(args.password || "");
                return true;
            }
            _fail(qsTr("Choose which calls to bar."));
            return false;
        }

        if (outgoing !== undefined) {
            callBarring.setVoiceOutgoing(args.enable ? outgoing : "disabled", args.password || "");
            return true;
        }
        if (incoming !== undefined) {
            callBarring.setVoiceIncoming(args.enable ? incoming : "disabled", args.password || "");
            return true;
        }

        _fail();
        return false;
    }

    function _barringQuery(args) {
        var isIncoming = _barringIncoming[args.condition] !== undefined;
        var value = isIncoming ? callBarring.voiceIncoming : callBarring.voiceOutgoing;
        var active = value && value !== "disabled";

        queried(isIncoming ? "barringincoming" : "barringoutgoing", value, "");
        _done(true, active ? qsTr("Call barring is on (%1)").arg(value)
                           : qsTr("Call barring is off"));
        return true;
    }

    function _barringPasswordChange(args) {
        if (args.newpassword !== args.newpasswordconfirm) {
            _fail(qsTr("The new passwords don't match."));
            return false;
        }
        callBarring.changePassword(args.oldpassword, args.newpassword);
        return true;
    }

    function _clirSet(args) {
        callSettings.hideCallerId = args.restrict ? "enabled" : "disabled";
        return true;
    }

    function _clirQuery(args) {
        queried("clir", callSettings.callingLineRestriction, callSettings.hideCallerId);
        _done(true, qsTr("Caller ID restriction: %1").arg(callSettings.callingLineRestriction));
        return true;
    }

    function _clipQuery(args) {
        queried("clip", callSettings.callingLinePresentation, "");
        _done(true, qsTr("Caller ID: %1").arg(callSettings.callingLinePresentation));
        return true;
    }

    function _cnapQuery(args) {
        queried("cnap", callSettings.callingNamePresentation, "");
        _done(true, qsTr("Caller name: %1").arg(callSettings.callingNamePresentation));
        return true;
    }

    function _imeiQuery(args) {
        queried("imei", modem.serial, "");
        _done(true, modem.serial);
        return true;
    }

    function _pinChange(pinType, oldPin, newPin, confirmPin) {
        if (newPin !== confirmPin) {
            _fail(CallMessages.pinFailure["mismatch"]);
            return false;
        }
        simManager.changePin(pinType, oldPin, newPin);
        return true;
    }

    function _pinUnblock(pukType, puk, newPin, confirmPin) {
        if (newPin !== confirmPin) {
            _fail(CallMessages.pukFailure["mismatch"]);
            return false;
        }
        simManager.resetPin(pukType, puk, newPin);
        return true;
    }

    function _onSetComplete(success) {
        _done(success, success ? CallMessages.mmiSucceeded : CallMessages.mmiFailed);
    }

    function _onPinComplete(error, errorString) {
        if (error === OfonoSimManager.NoError) {
            _done(true, qsTr("PIN changed."));
            return;
        }
        console.log("PIN operation failed: " + errorString);
        _done(false, (_pendingCommand.indexOf("Unblock") >= 0) ? CallMessages.pukFailureDefault
                                                               : CallMessages.pinFailureDefault);
    }

    OfonoCallForwarding {
        id: callForwarding
        modemPath: supplementaryServices.modemPath

        onVoiceUnconditionalComplete: (success) => _onSetComplete(success)
        onVoiceBusyComplete: (success) => _onSetComplete(success)
        onVoiceNoReplyComplete: (success) => _onSetComplete(success)
        onVoiceNotReachableComplete: (success) => _onSetComplete(success)
        onGetPropertiesFailed: _fail(CallMessages.noServiceError)
    }

    OfonoCallSettings {
        id: callSettings
        modemPath: supplementaryServices.modemPath

        onVoiceCallWaitingComplete: (success) => _onSetComplete(success)
        onHideCallerIdComplete: (success) => _onSetComplete(success)
        onGetPropertiesFailed: _fail(CallMessages.noServiceError)
    }

    OfonoCallBarring {
        id: callBarring
        modemPath: supplementaryServices.modemPath

        onVoiceIncomingComplete: (success) => _onSetComplete(success)
        onVoiceOutgoingComplete: (success) => _onSetComplete(success)
        onChangePasswordComplete: (success) =>
            _done(success, success ? qsTr("Call barring password changed.")
                                   : qsTr("Could not change the call barring password."))
        onDisableAllComplete: (success) => _onSetComplete(success)
        onGetPropertiesFailed: _fail(CallMessages.noServiceError)
    }

    OfonoSimManager {
        id: simManager
        modemPath: supplementaryServices.modemPath

        onChangePinComplete: (error, errorString) => _onPinComplete(error, errorString)
        onResetPinComplete: (error, errorString) => _onPinComplete(error, errorString)
        onLockPinComplete: (error, errorString) => _onPinComplete(error, errorString)
        onUnlockPinComplete: (error, errorString) => _onPinComplete(error, errorString)
    }

    OfonoModem {
        id: modem
        modemPath: supplementaryServices.modemPath
    }
}
