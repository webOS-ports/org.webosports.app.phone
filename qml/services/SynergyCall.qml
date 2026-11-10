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
    /// Why the connector says the call ended (its line's
    /// disconnectDetails.cause): "rejected", "busy", "missed", "normal", ...
    /// Set before the status turns disconnected. Empty while the call is up.
    property string disconnectCause: ""

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

    /**
     * Video, as the connector's line reports it (legacy CallSynergizer names).
     **/

    /// We are receiving the far side's picture.
    property bool incomingVideo: false
    /// We are sending ours.
    property bool outgoingVideo: false
    /// "unavailable", "available" (offered) or "streaming" (arriving).
    property string incomingVideoState: "unavailable"
    /// The connector may turn video down for a call altogether.
    property bool allowVideoCalls: true
    /// The connector says video needs no question to the user.
    property bool autoAcceptVideoCalls: false
    /// Where the connector publishes the decoded far-side picture (a gst-shm
    /// socket of luneos-rtc-engine), and its frame size. Empty while nothing
    /// is being decoded.
    property string videoURI: ""
    property int videoWidth: 0
    property int videoHeight: 0
    /// How far the far side's phone is turned, in quarter turns (0..3); the
    /// picture is turned back by as much to stand upright.
    property int incomingVideoOrientation: 0
    /// Our own camera's picture while we send it (a gst-shm socket of the
    /// engine), its size, how far to turn it, and whether to mirror it.
    property string videoPreviewURI: ""
    property int videoPreviewWidth: 0
    property int videoPreviewHeight: 0
    property int videoPreviewOrientation: 0
    property bool videoPreviewMirrored: false

    /**
     * Whether the user lets video on this call: "" not asked yet, "granted"
     * or "refused". As in 2.2.4's ActiveCall.updateWithCallState, asking
     * happens once, and video we send ourselves counts as granted.
     */
    property string videoAuthorization: ""

    /// The call screen shows the far side's picture.
    readonly property bool showsVideo: allowVideoCalls && videoAuthorization === "granted"
                                       && videoURI.length > 0

    /// Asks the user whether to switch to video: the far side started sending.
    signal videoRequested();

    property bool _videoAsked: false
    property bool _incomingVideoAsked: false

    /// Applies the legacy authorisation rules to the latest line update.
    function _evaluateVideo() {
        if (!allowVideoCalls)
            return;
        var streaming = incomingVideoState === "streaming" || incomingVideo;
        if (videoAuthorization === "" && (outgoingVideo || autoAcceptVideoCalls))
            videoAuthorization = "granted";
        if (videoAuthorization === "" && streaming && !_videoAsked) {
            _videoAsked = true;
            videoRequested();
        }
        // Granted: make sure the connector decodes what arrives. Once per
        // stream, so a "no" sent from elsewhere is not overridden in a loop.
        if (videoAuthorization === "granted" && streaming && !_incomingVideoAsked) {
            _incomingVideoAsked = true;
            changeMedia(true, undefined);
        }
        if (!streaming)
            _incomingVideoAsked = false;
    }

    /// The user's answer to videoRequested(). `sendOwn`: also send our camera.
    function acceptVideo(sendOwn) {
        videoAuthorization = "granted";
        _incomingVideoAsked = true;
        changeMedia(true, sendOwn === true ? true : undefined);
    }
    function refuseVideo() {
        videoAuthorization = "refused";
        changeMedia(false, false);
    }

    /// The user asked to turn this voice call into a video call.
    property bool videoSwitchRequested: false

    /**
     * Turns a voice call into a video call, as 2.2.4's AbstractCall
     * changeToVideoCall: both directions on in one changeMedia, and the far
     * side's picture authorised up front, so it shows without asking. Once
     * per call; the header button stays disabled after it, as legacy's did.
     */
    function switchToVideo() {
        if (videoSwitchRequested)
            return;
        videoSwitchRequested = true;
        videoAuthorization = "granted";
        _incomingVideoAsked = true;
        changeMedia(true, true);
    }

    // Once our camera has been on and goes off again, the call is back to voice
    // and the switch is offered again; until the connector first reports it on,
    // the button stays disabled so a second tap cannot ask twice.
    onOutgoingVideoChanged: {
        if (!outgoingVideo)
            videoSwitchRequested = false;
    }

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

    // The method names are the call services' - webOS 2.x's CallSynergizer
    // and every LuneOS connector call ending a call "disconnect".
    function answer()          { callControlRequested("answer", { id: callId }); }
    function hangup()          { callControlRequested("disconnect", { id: callId }); }
    function hold(on)          { callControlRequested(on ? "hold" : "resume", { id: callId }); }
    function deflect(target)   { callControlRequested("deflect", { id: callId, address: target }); }
    function sendDtmf(tones)   { callControlRequested("dtmf", { id: callId, tone: tones }); }
    function merge(handle)     { callControlRequested("merge", { id: callId, otherId: handle }); }
    function split()           { callControlRequested("extract", { id: callId }); }

    /// Video on or off per direction; undefined leaves that direction as it
    /// is, as the connectors read it (legacy VideoRequest.changeMedia).
    function changeMedia(incoming, outgoing) {
        var params = { id: callId };
        if (incoming !== undefined)
            params.incomingVideo = incoming;
        if (outgoing !== undefined)
            params.outgoingVideo = outgoing;
        callControlRequested("changeMedia", params);
    }

    /// Which way the phone is held (the shell's quarter turns, 0 top up), so
    /// the connector can turn the picture it sends with it. Sent alone: no
    /// video direction changes.
    function setDeviceOrientation(turns) {
        callControlRequested("changeMedia", { id: callId, deviceOrientation: turns & 3 });
    }
}
