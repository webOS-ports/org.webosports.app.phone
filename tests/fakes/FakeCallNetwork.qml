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

/**
 * A stand-in for voicecall-manager over oFono, for VoiceCallMgrWrapper's
 * `manager`. Unlike the mock in luneos-components it behaves the way the
 * real stack does where the call-waiting code depends on it:
 *
 * - activeVoiceCall is the first call added and stays that call until it is
 *   removed, held or not (voicecall src/voicecallmanager.cpp,
 *   onVoiceCallAdded / onVoiceCallRemoved);
 * - hold(on) on a call does nothing if it is already in that state, and is
 *   SwapCalls otherwise; answer() on a waiting call is HoldAndAnswer
 *   (plugins/providers/ofono/src/ofonovoicecallhandler.cpp);
 * - SwapCalls and HoldAndAnswer are AT+CHLD=2, releasing one call of
 *   several is AT+CHLD=1<n>, rejecting a waiting call AT+CHLD=0, as the
 *   Mindphone's radio log shows them.
 *
 * `commands` records what the modem would have been sent.
 */
Item {
    id: network

    property var activeVoiceCall: null
    property string defaultProviderId: "ofono/ril_0"
    property var commands: []

    /// Calls report "disconnected" before their row goes; with this off the
    /// row goes first, as for a call that vanished without saying so.
    property bool disconnectBeforeRemoval: true

    property FakeCallModel voiceCalls: FakeCallModel {}

    signal error(string message)

    property int _nextIndex: 1

    Component {
        id: callComponent
        FakeOfonoCall {}
    }

    function _send(command) {
        var sent = commands.slice();
        sent.push(command);
        commands = sent;
    }

    function _add(lineId, status) {
        var call = callComponent.createObject(network, {
            network: network,
            index: _nextIndex,
            handlerId: "/ril_0/voicecall0" + _nextIndex,
            lineId: lineId,
            isIncoming: true,
            status: status
        });
        _nextIndex = _nextIndex + 1;
        var list = voiceCalls.list.slice();
        list.push(call);
        voiceCalls.list = list;
        voiceCalls.count = list.length;
        voiceCalls.rowsInserted(null, list.length - 1, list.length - 1);
        if (!activeVoiceCall)
            activeVoiceCall = call;
        return call;
    }

    function _remove(call) {
        var list = voiceCalls.list.slice();
        var i = list.indexOf(call);
        if (i < 0)
            return;
        list.splice(i, 1);
        voiceCalls.list = list;
        voiceCalls.count = list.length;
        voiceCalls.rowsRemoved(null, i, i);
        if (activeVoiceCall === call)
            activeVoiceCall = null;
    }

    function _withStatus(status) {
        return voiceCalls.list.filter(function(call) { return call.status === status; });
    }

    /// A call rings with nothing else up.
    function ring(lineId) { return _add(lineId, VoiceCall.STATUS_INCOMING); }
    /// A call comes in on top of another one.
    function wait(lineId) { return _add(lineId, VoiceCall.STATUS_WAITING); }

    /// The call is over, at whichever end: disconnected, then gone.
    function end(call) {
        if (disconnectBeforeRemoval) {
            call.status = VoiceCall.STATUS_DISCONNECTED;
            _remove(call);
        } else {
            _remove(call);
            call.status = VoiceCall.STATUS_DISCONNECTED;
        }
    }

    // --- what the handlers ask of oFono ---

    function answer(call) {
        _send("ATA");
        call.status = VoiceCall.STATUS_ACTIVE;
    }

    /// 3GPP 22.030 "2": active calls to hold, and the waiting call - or
    /// failing that the held ones - to active.
    function swapCalls() {
        _send("AT+CHLD=2");
        var active = _withStatus(VoiceCall.STATUS_ACTIVE);
        var waiting = _withStatus(VoiceCall.STATUS_WAITING);
        var held = _withStatus(VoiceCall.STATUS_HELD);
        active.forEach(function(call) { call.status = VoiceCall.STATUS_HELD; });
        if (waiting.length > 0)
            waiting[0].status = VoiceCall.STATUS_ACTIVE;
        else
            held.forEach(function(call) { call.status = VoiceCall.STATUS_ACTIVE; });
    }

    function holdAndAnswer() { swapCalls(); }

    function hangup(call) {
        if (call.status === VoiceCall.STATUS_WAITING)
            _send("AT+CHLD=0");
        else if (voiceCalls.count > 1)
            _send("AT+CHLD=1" + call.index);
        else
            _send("ATH");
        end(call);
    }

    function dial(providerId, number) { console.log("FakeCallNetwork: dial " + number); }
    function silenceRingtone() {}
}
