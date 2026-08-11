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
import "CallMessages.js" as CallMessages

/**
 * Single entry point for "the user wants to dial this string".
 *
 * Replaces the legacy DialHandler.Telephony + DialProxy pair: DialStringParser
 * decides what the string means, and this component carries the decision out
 * against the call manager, the supplementary services and the app manager.
 * Everything that dials -- the dialpad, favourites, call log, launch
 * parameters, the bluetooth handset -- goes through here so the GSM rules only
 * exist in one place.
 */
Item {
    id: dialHandler

    property var voiceCallMgrWrapper
    property var telephonyManager
    property var supplementaryServices
    property var dialingShortcuts
    property var dialProxy
    property var callTransports

    /// Set from the North American dialling tweak; makes *NN / 0 / 00 dial
    /// instead of going out as USSD.
    property bool northAmericanSettings: false

    /// A dial attempt was refused before it reached the modem.
    signal dialFailed(string number, string reason);
    /// Something to show the user, e.g. the result of an MMI interrogation.
    signal message(string text);
    /// The user asked for voicemail but no mailbox number is known.
    signal voicemailNumberMissing();
    /// An MMI code asked for the SIM PIN dialog.
    signal pinRequested(string kind);

    /// Last number actually dialled, for redial.
    property string lastDialedNumber: ""
    /// Transport the last call went over, so a redial repeats it.
    property string lastDialedTransport: ""

    /// The user has to choose which calling account to use for this call.
    signal transportChoiceRequired(var callData);

    /**
     * Dials whatever the user typed. `rawAddress` may be a phone number, an MMI
     * code, a USSD string, an in-call control digit or a launch code.
     */
    function dial(rawAddress, transport, video) {
        // An IM address is not a dial string: it may be a username, and it must
        // not be run through the GSM rules or the speed-dial prefixes.
        if (transport && callTransports &&
            transport !== callTransports.cellularTransport &&
            !DialStringParser.REGEX_NORMAL_NUMBER.test(String(rawAddress).replace(/[\s()\-.]/g, ""))) {
            _dialOver(rawAddress, transport, video);
            return;
        }

        var address = _applyShortcuts(DialStringParser.normalize(rawAddress));
        if (address.length === 0) {
            console.log("Nothing to dial");
            return;
        }

        _requestedTransport = transport || "";
        _requestedVideo = video === true;

        var action = DialStringParser.parse(address, {
            emergencyNumbers: telephonyManager ? telephonyManager.emergencyNumbers : [],
            hasCall: voiceCallMgrWrapper ? voiceCallMgrWrapper.hasCall : false,
            northAmerican: northAmericanSettings,
            radioOn: telephonyManager ? telephonyManager.radioOnline : true
        });

        console.log("Dial '" + address + "' -> " + JSON.stringify(action));
        _execute(action);
    }

    /// Places a call over a transport the caller has already chosen, skipping
    /// the dial-string rules entirely. Used for IM addresses and for the answer
    /// to the "which account?" question.
    function _dialOver(address, transport, video) {
        lastDialedNumber = address;
        lastDialedTransport = transport || "";
        voiceCallMgrWrapper.dialOver(address, transport, video === true);
    }

    /// Completes a call that was waiting on the user to pick an account.
    function dialWithTransport(address, transport, video) {
        _dialOver(address, transport, video);
    }

    property string _requestedTransport: ""
    property bool _requestedVideo: false

    /// Dials the voicemail mailbox, or reports that we don't know its number.
    function dialVoicemail() {
        var number = telephonyManager ? telephonyManager.voicemailNumber : "";
        if (!number || number.length === 0) {
            console.log("No voicemail number configured");
            voicemailNumberMissing();
            message(CallMessages.voicemailNumberNotFound);
            return;
        }

        voiceCallMgrWrapper.dial(number);
    }

    /**
     * private
     **/

    // Emergency call placed while the radio was off; redialled once oFono
    // reports the modem back online.
    property string _emergencyRedialNumber: ""

    function _execute(action) {
        switch (action.action) {
        case "none":
            console.log("Dial string produced no action: " + action.reason);
            break;

        case "emergency":
            _dialEmergency(action.number, action.radioOff);
            break;

        case "launchApp":
            _launchApp(action.appId, action.launchCode);
            break;

        case "callControl":
            _callControl(action);
            break;

        case "clir":
            lastDialedNumber = action.number;
            lastDialedTransport = "";
            voiceCallMgrWrapper.dialFull(action.number, "", action.hideCallerId, "", false);
            break;

        case "mmi":
            _runMmi(action);
            break;

        case "ussd":
            if (!telephonyManager || !telephonyManager.radioOnline) {
                dialFailed(action.command, "noservice");
                return;
            }
            telephonyManager.initiateUssd(action.command);
            break;

        case "dial":
            _dialNormal(action);
            break;
        }
    }

    // A plain number can go over any calling account, so this is where Synergy
    // asks which one -- unless the caller already said, or there is only one.
    function _dialNormal(action) {
        var transport = _requestedTransport;

        if (transport.length === 0 && dialProxy) {
            transport = dialProxy.chooseTransport(action.number, {
                video: _requestedVideo,
                postDial: action.postDial
            });

            // The proxy is asking the user; the call resumes in
            // dialWithTransport() once they answer.
            if (transport.length === 0)
                return;
        }

        var cellular = callTransports ? callTransports.cellularTransport : "com.palm.telephony";

        // Only the modem is subject to airplane mode; a connector call goes
        // over whatever data connection the device has.
        if ((transport.length === 0 || transport === cellular) &&
            telephonyManager && !telephonyManager.radioOnline) {
            dialFailed(action.number, "airplanemodeon");
            return;
        }

        lastDialedNumber = action.number + action.postDial;
        lastDialedTransport = transport;
        voiceCallMgrWrapper.dialFull(action.number, action.postDial, undefined,
                                     transport, _requestedVideo);
        _requestedVideo = false;
    }

    function _dialEmergency(number, radioOff) {
        if (!radioOff) {
            voiceCallMgrWrapper.dial(number);
            return;
        }

        // Airplane mode: power the radio up and redial as soon as it registers.
        console.log("Emergency call with the radio off, powering up");
        message(CallMessages.dialOnPowerPending);

        if (!telephonyManager || !telephonyManager.setRadioOnline(true)) {
            dialFailed(number, "noservice");
            return;
        }

        _emergencyRedialNumber = number;
        emergencyRedialTimeout.restart();
    }

    function _callControl(action) {
        switch (action.op) {
        case "releaseHeldOrReject":   voiceCallMgrWrapper.releaseHeldOrReject(); break;
        case "releaseActiveAndAnswer": voiceCallMgrWrapper.releaseActiveAndAnswer(); break;
        case "swap":                  voiceCallMgrWrapper.swap(); break;
        case "merge":                 voiceCallMgrWrapper.merge(); break;
        case "releaseCall":           voiceCallMgrWrapper.releaseCall(action.index); break;
        case "privateChat":           voiceCallMgrWrapper.privateChat(action.index); break;
        }
    }

    function _runMmi(action) {
        // The PIN-related MMI codes are carried out by the SIM manager rather
        // than the network, so they still work with the radio off.
        var isPinCommand = action.cmd.indexOf("pin") === 0;

        if (!isPinCommand && telephonyManager && !telephonyManager.radioOnline) {
            dialFailed("", "airplanemodeon");
            return;
        }

        if (!supplementaryServices) {
            console.log("No supplementary services available for " + action.cmd);
            dialFailed("", "callfailed");
            return;
        }

        message(CallMessages.mmiPending);
        supplementaryServices.execute(action.cmd, action.args);
    }

    function _launchApp(appId, launchCode) {
        console.log("Launch code " + launchCode + " -> " + appId);
        lunaService.call("luna://com.webos.applicationManager/launch",
                         JSON.stringify({ id: appId, params: { launchCode: launchCode } }),
                         undefined,
                         function(error) { console.log("Could not launch " + appId + ": " + error); });
    }

    // Speed dial: a 4-, 5-, 6- or 7-digit string can be expanded with a stored
    // prefix, unless it is an emergency number or contains MMI characters.
    function _applyShortcuts(address) {
        if (!dialingShortcuts || address.length === 0)
            return address;

        if (/[\*#,;pw]/i.test(address))
            return address;

        if (DialStringParser.isEmergencyNumber(address,
                telephonyManager ? telephonyManager.emergencyNumbers : []))
            return address;

        var prefix = dialingShortcuts.prefixFor(address.length);
        return prefix ? (prefix + address) : address;
    }

    Timer {
        id: emergencyRedialTimeout
        interval: 30000
        onTriggered: {
            if (_emergencyRedialNumber.length === 0)
                return;

            console.log("Radio did not come up in time for the emergency call");
            dialFailed(_emergencyRedialNumber, "noservice");
            message(CallMessages.dialOnPowerFail);
            _emergencyRedialNumber = "";
        }
    }

    Connections {
        target: dialHandler.telephonyManager
        function onRegisteredChanged() {
            if (_emergencyRedialNumber.length === 0 || !telephonyManager.registered)
                return;

            var number = _emergencyRedialNumber;
            _emergencyRedialNumber = "";
            emergencyRedialTimeout.stop();
            voiceCallMgrWrapper.dial(number);
        }
    }

    Connections {
        target: dialHandler.supplementaryServices
        function onCompleted(success, text) {
            dialHandler.message(text);
        }
    }

    // With more than one calling account and no stored preference, the proxy
    // cannot decide on its own -- pass the question up to the UI.
    Connections {
        target: dialHandler.dialProxy

        function onTransportChoiceRequired(callData) {
            dialHandler.transportChoiceRequired(callData);
        }

        function onNoCallingAccount() {
            dialHandler.dialFailed("", "callfailed");
        }
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
}
