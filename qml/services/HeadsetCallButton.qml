/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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
import org.nemomobile.voicecall 1.0

import "HeadsetCallKeys.js" as HeadsetCallKeys

/**
 * The wired headset's button for the calls: a press answers a ringing
 * call or ends the one in progress, a long press rejects a ringing call.
 *
 * mediacontroller sends the button here instead of to the music while
 * registerCallKeys is held, which it is from the moment a call rings
 * until the last call ends, as Android's Telecom holds its media session
 * only while there are calls. A Bluetooth headset's buttons do not come
 * here: its call keys are HFP's, and its AVRCP keys mediacontroller drops
 * during a call.
 */
Item {
    id: headsetCallButton

    property var voiceCallManager

    readonly property bool wanted: !!voiceCallManager && voiceCallManager.hasCall

    /// What subscribe() handed back; cancel() lives on that.
    property var _subscription: null
    /// The bus: replaced by the tests.
    property var _bus: lunaService

    onWantedChanged: wanted ? _take() : _letGo()

    function _take() {
        if (_subscription)
            return;
        _subscription = _bus.subscribe(JSON.stringify({ subscribe: true }));
    }

    function _letGo() {
        if (!_subscription)
            return;
        _subscription.cancel();
        _subscription = null;
    }

    function _ringingCall() {
        return voiceCallManager.incomingVoiceCall();
    }

    function _callToEnd() {
        var call = voiceCallManager.currentCall();
        if (call)
            return call;
        var statuses = [VoiceCall.STATUS_DIALING, VoiceCall.STATUS_ALERTING, VoiceCall.STATUS_HELD];
        for (var i = 0; i < statuses.length; ++i) {
            var calls = voiceCallManager.callsWithStatus(statuses[i]);
            if (calls.length > 0)
                return calls[0];
        }
        return null;
    }

    /// Acts on keyEvent; what it did ("" for nothing).
    function handleKey(keyEvent) {
        if (!voiceCallManager)
            return "";
        var callToEnd = _callToEnd();
        var action = HeadsetCallKeys.actionFor(keyEvent, !!_ringingCall(), !!callToEnd);
        console.log("Headset button: " + keyEvent + (action ? " - " + action : ", nothing to do"));
        switch (action) {
        case "answer": voiceCallManager.answer(); break;
        case "reject": voiceCallManager.reject(); break;
        case "hangup": callToEnd.hangup(); break;
        }
        return action;
    }

    /// The first reply, and any other without a key, is let be: no log
    /// line for each.
    function _onResponse(message) {
        var response;
        try {
            response = JSON.parse(message.payload);
        } catch (e) {
            return;
        }
        if (response && typeof response.keyEvent === "string")
            handleKey(response.keyEvent);
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        service: "luna://com.webos.service.mediacontroller"
        method: "registerCallKeys"

        onResponse: function (message) { headsetCallButton._onResponse(message); }
        onError: function (message) {
            console.warn("Headset button: no call keys from mediacontroller: " + message);
        }
    }

    Component.onDestruction: _letGo()
}
