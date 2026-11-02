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

import org.nemomobile.voicecall 1.0

/// One call as voicecall-manager's oFono handler presents it; see
/// FakeCallNetwork for what it stands in for.
QtObject {
    property var network
    property int index: 0
    property string handlerId: ""
    property string providerId: "ofono/ril_0"
    property string lineId: ""
    property int status: VoiceCall.STATUS_NULL
    property string statusText: ""
    property bool isIncoming: false
    property bool isEmergency: false
    property bool isMultiparty: false
    property bool isForwarded: false
    property bool isRemoteHeld: false
    property date startedAt: new Date()
    property int duration: 0

    // OfonoVoiceCallHandler::answer
    function answer() {
        if (status === VoiceCall.STATUS_WAITING)
            network.holdAndAnswer();
        else
            network.answer(this);
    }

    function hangup() { network.hangup(this); }

    // OfonoVoiceCallHandler::hold: already in that state is nothing to do.
    function hold(on) {
        var isHeld = status === VoiceCall.STATUS_HELD;
        if (isHeld === on)
            return;
        network.swapCalls();
    }

    function sendDtmf(tones) { network._send("AT+VTS=" + tones); }
    // OfonoVoiceCallHandler::merge: oFono's CreateMultiparty.
    function merge(otherHandlerId) { network.createMultiparty(this, otherHandlerId); }
    // OfonoVoiceCallHandler::split: oFono's PrivateChat.
    function split() { network.privateChat(this); }
    function deflect(target) {}
}
