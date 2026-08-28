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

import org.nemomobile.voicecall 1.0

/**
 * One call on a Synergy transport, presented with exactly the API a nemo
 * VoiceCallHandler has.
 *
 * That is the whole point of this type: the active call screen, the call log,
 * the ring manager and the launch actions all work against voice call handlers,
 * and none of them should have to know whether a call is going over the modem
 * or over a messaging connector. The legacy app achieved the same thing by
 * making every transport speak the "line" protocol; here the adapter sits on
 * this side instead.
 */
QtObject {
    id: synergyCall

    /// The transport (account templateId) this call belongs to.
    property string transport: ""
    /// The luna service to send call control to.
    property string implementation: ""
    /// The connector's own id for this call, used in call control requests.
    property string callId: ""

    /**
     * VoiceCallHandler API
     **/

    readonly property string handlerId: transport + ":" + callId
    /// Named to match the nemo handler, which the rest of the app reads.
    readonly property string providerId: transport

    property int status: VoiceCall.STATUS_NULL
    property string lineId: ""
    property var startedAt: new Date()
    property bool isIncoming: false
    property bool isEmergency: false
    property bool isMultiparty: false
    property bool isForwarded: false
    property bool isRemoteHeld: false

    /// Milliseconds, as the nemo handler reports it.
    property int duration: 0

    property string statusText: {
        switch (status) {
        case VoiceCall.STATUS_ACTIVE: return "active";
        case VoiceCall.STATUS_HELD: return "held";
        case VoiceCall.STATUS_DIALING: return "dialing";
        case VoiceCall.STATUS_ALERTING: return "alerting";
        case VoiceCall.STATUS_INCOMING: return "incoming";
        case VoiceCall.STATUS_WAITING: return "waiting";
        case VoiceCall.STATUS_DISCONNECTED: return "disconnected";
        default: return "null";
        }
    }

    /**
     * Synergy extras the cellular handler has no equivalent for.
     **/

    /// Set when the connector reports video on this call.
    property bool isVideo: false
    /// Name the connector supplied for the remote party, when it has one.
    property string displayName: ""

    // `status` is a property, so QML already gives us statusChanged() -- the
    // call manager connects to that. Declaring it again would collide with the
    // generated one.
    signal callControlRequested(string method, var params);

    onStatusChanged: {
        // A call only starts counting once it is connected.
        if (status === VoiceCall.STATUS_ACTIVE && !_connectedAt)
            _connectedAt = Date.now();
    }

    property var _connectedAt: 0

    /// Recomputed by the transport's tick timer, since the connector reports a
    /// start time rather than a running duration.
    function updateDuration() {
        duration = _connectedAt ? (Date.now() - _connectedAt) : 0;
    }

    function answer()          { callControlRequested("answer", { id: callId }); }
    function hangup()          { callControlRequested("hangup", { id: callId }); }
    function hold(on)          { callControlRequested(on ? "hold" : "resume", { id: callId }); }
    function deflect(target)   { callControlRequested("deflect", { id: callId, address: target }); }
    function sendDtmf(tones)   { callControlRequested("dtmf", { id: callId, tone: tones }); }
    function merge(handle)     { callControlRequested("merge", { id: callId, otherId: handle }); }
    function split()           { callControlRequested("extract", { id: callId }); }
}
