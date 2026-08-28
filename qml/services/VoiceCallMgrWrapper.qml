/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtQml 2.2

import LuneOS.Service 1.0
import org.nemomobile.voicecall 1.0

import "../model"
import "DialStringParser.js" as DialStringParser
import "IncomingCallsService.js" as IncomingCallsService

/**
 * Owns every call in progress and the call-control operations that act on more
 * than one of them at a time.
 *
 * The legacy Enyo app called this the CallSynergizer: it kept a list of "lines",
 * each of which could hold a single call or a conference, and knew which
 * operations were legal for a given combination. That model is reproduced here
 * over the nemo voicecall manager.
 */
Item {
    id: root

    LunaService {
        id: __lunaNextLS2Service
        name: "org.webosports.app.phone"
    }

    property VoiceCallManager manager: VoiceCallManager {
        id: voiceCallManagerId
    }

    property alias calls: voiceCallManagerId.voiceCalls
    property alias activeVoiceCall: voiceCallManagerId.activeVoiceCall

    property string countryCode: 'US'

    /// The Synergy transport registry. Calls placed over a messaging connector
    /// go through the matching SynergyTransport instead of the modem.
    property CallTransports callTransports

    /// One driver per non-cellular transport, keyed by templateId.
    property var synergyTransports: ({})

    property var heldCall: null
    property string _dialNumberAfterHold: ""

    // Post-dial string ("555,,1234") waiting for its call to connect, keyed by
    // the handlerId of the call it belongs to.
    property var _postDialStrings: ({})

    signal activeCall(var voiceCall);
    signal outgoingCall(var voiceCall);
    signal incomingCall(var voiceCall);
    signal endingCall(var voiceCall);
    signal resetCall(var voiceCall);

    /// A call could not be placed. `reason` keys into CallMessages.dialFailure.
    signal dialFailed(string number, string reason);
    /// A connected call went away without either side hanging up.
    signal callDropped(var voiceCall, string reason);

    /**
     * Call inventory
     **/

    readonly property int callCount: {
        callsRevision;
        return allCallsList.length;
    }
    readonly property bool hasCall: callCount > 0

    // Bumped whenever a call is added, removed or changes state. Bindings that
    // have to be recomputed by walking the call list depend on this, since the
    // list itself is a C++ model whose contents are not individually bindable.
    property int callsRevision: 0

    function callAt(index) {
        return allCallsList[index] || null;
    }

    /**
     * Every call in progress, whichever transport it is on, as a plain array so
     * views can use it as a model.
     *
     * Cellular calls come from the nemo manager and Synergy calls from the
     * connectors, but both are voice call handlers by the time they get here,
     * so nothing downstream has to tell them apart.
     */
    property var allCallsList: {
        callsRevision; // establish the dependency
        var result = [];
        for (var i = 0; i < (calls ? calls.count : 0); ++i) {
            var call = calls.instance(i);
            if (call) result.push(call);
        }

        for (var transportId in synergyTransports)
            result = result.concat(synergyTransports[transportId].calls);

        return result;
    }

    function allCalls() {
        return allCallsList;
    }

    function callsWithStatus(status) {
        return allCalls().filter(function(call) { return call.status === status; });
    }

    function incomingVoiceCall() {
        var incoming = callsWithStatus(VoiceCall.STATUS_INCOMING);
        if (incoming.length > 0) return incoming[0];

        var waiting = callsWithStatus(VoiceCall.STATUS_WAITING);
        return waiting.length > 0 ? waiting[0] : null;
    }

    function heldVoiceCall() {
        var held = callsWithStatus(VoiceCall.STATUS_HELD);
        return held.length > 0 ? held[0] : null;
    }

    /**
     * The call the user is talking on. Prefers what the manager reports, but
     * falls back to the first connected call: during a conference, or briefly
     * while calls are being swapped, activeVoiceCall can be unset even though
     * there is plainly a call to act on.
     */
    function currentCall() {
        if (activeVoiceCall)
            return activeVoiceCall;

        var active = callsWithStatus(VoiceCall.STATUS_ACTIVE);
        return active.length > 0 ? active[0] : null;
    }

    function conferenceCall() {
        var conference = allCalls().filter(function(call) { return call.isMultiparty; });
        return conference.length > 0 ? conference[0] : null;
    }

    /**
     * Which controls the active call UI should offer. Mirrors the legacy
     * AbstractCallButtons rules: with one call you can only hang up, with two
     * you can swap and merge, and once merged you can split again.
     */
    readonly property bool hasConference: {
        callsRevision;
        return allCallsList.some(function(call) { return call.isMultiparty; });
    }
    readonly property bool hasHeldCall: {
        callsRevision;
        return allCallsList.some(function(call) { return call.status === VoiceCall.STATUS_HELD; });
    }

    readonly property bool hasActiveCall: {
        callsRevision;
        return !!activeVoiceCall ||
               allCallsList.some(function(call) { return call.status === VoiceCall.STATUS_ACTIVE; });
    }

    readonly property bool canSwap: hasActiveCall && hasHeldCall
    readonly property bool canMerge: canSwap && !hasConference
    readonly property bool canSplit: hasConference
    readonly property bool canAddCall: callCount > 0 && callCount < 2 && hasActiveCall
    readonly property bool canHangupAll: callCount > 1

    /**
     * Dialling
     **/

    function dial(number) {
        _dialWithPostDial(number, "", undefined, "");
    }

    /**
     * Places a call over a specific Synergy transport. `transport` is an
     * account templateId; an empty one means the modem.
     */
    function dialOver(number, transport, video) {
        _pendingTransport = transport || "";
        _pendingVideo = video === true;
        _dialWithPostDial(number, "", undefined, _pendingTransport);
    }

    /**
     * Dials `number`, then sends `postDial` as DTMF once the call connects.
     * `hideCallerId` maps onto the CLIR prefixes the modem understands.
     */
    function dialFull(number, postDial, hideCallerId, transport, video) {
        var target = number;
        // CLIR prefixes only mean anything to the modem.
        if (!transport || transport === _cellularTransport()) {
            if (hideCallerId === true)
                target = "#31#" + number;
            else if (hideCallerId === false)
                target = "*31#" + number;
        }

        _pendingTransport = transport || "";
        _pendingVideo = video === true;
        _dialWithPostDial(target, postDial, number, _pendingTransport);
    }

    function _dialWithPostDial(number, postDial, displayNumber, transport) {
        // With a call already up, hold it first and dial once it is on hold.
        var ongoing = currentCall();
        if (ongoing && ongoing.status === VoiceCall.STATUS_ACTIVE && !heldCall) {
            _dialNumberAfterHold = number;
            _dialTransportAfterHold = transport || "";
            _pendingPostDial = postDial || "";
            ongoing.hold(true);
            return;
        }

        _pendingPostDial = postDial || "";
        _pendingDialNumber = displayNumber || number;
        _dialAttemptedAt = Date.now();
        _dial(number, transport);
    }

    property string _pendingPostDial: ""
    property string _pendingDialNumber: ""

    /*
     * When that dial was asked for. A dial is only in flight for a moment --
     * either a call appears or the attempt has failed -- and after that the
     * errors the call manager reports are nothing to do with it. Without this
     * a dial that never became a call leaves the next unrelated error, and on
     * a phone whose radio keeps changing technology there are plenty, showing
     * "No service" to someone who is not dialling.
     */
    property double _dialAttemptedAt: 0
    readonly property int _dialInFlightMs: 15000

    property string _pendingTransport: ""
    property bool _pendingVideo: false
    property string _dialTransportAfterHold: ""

    function hangupAll() {
        // Take a copy first: hanging a call up removes it from the list.
        allCallsList.slice().forEach(function(voiceCall) { voiceCall.hangup(); });
    }

    function _cellularTransport() {
        return callTransports ? callTransports.cellularTransport : "com.palm.telephony";
    }

    function _dial(number, transport) {
        var target = transport || "";

        if (target.length > 0 && target !== _cellularTransport()) {
            var synergy = synergyTransports[target];
            if (synergy) {
                synergy.dial(number, _pendingVideo, true);
                _pendingVideo = false;
                return;
            }

            console.log("No driver for transport " + target + ", falling back to the modem");
        }

        manager.dial(manager.defaultProviderId, number);
    }

    /**
     * Call control
     **/

    /// Puts the active call on hold and takes the held one, or answers a waiting
    /// call while holding the current one.
    function swap() {
        var waiting = incomingVoiceCall();
        if (waiting) {
            IncomingCallsService.setActionForCall(waiting.handlerId, IncomingCallsService.Accepted);
            waiting.answer();
            return;
        }

        var call = currentCall();
        if (call)
            call.hold(true);
        else {
            var held = heldVoiceCall();
            if (held) held.hold(false);
        }
    }

    /// Joins the active and held calls into a conference.
    function merge() {
        var call = currentCall();
        var held = heldVoiceCall();
        if (!call || !held) {
            console.log("Cannot merge: need one active and one held call");
            return;
        }
        call.merge(held.handlerId);
    }

    /// Takes one participant back out of the conference into a private chat.
    function split(voiceCall) {
        var target = voiceCall || conferenceCall();
        if (target) target.split();
    }

    /// Releases every held call; if a call is waiting, rejects it instead
    /// (3GPP 22.030 "0" in-call code).
    function releaseHeldOrReject() {
        var waiting = incomingVoiceCall();
        if (waiting) {
            IncomingCallsService.setActionForCall(waiting.handlerId, IncomingCallsService.Ignored);
            waiting.hangup();
            return;
        }

        callsWithStatus(VoiceCall.STATUS_HELD).forEach(function(call) { call.hangup(); });
    }

    /// Releases every active call and takes the held or waiting one
    /// (3GPP 22.030 "1").
    function releaseActiveAndAnswer() {
        callsWithStatus(VoiceCall.STATUS_ACTIVE).forEach(function(call) { call.hangup(); });

        var waiting = incomingVoiceCall();
        if (waiting) {
            IncomingCallsService.setActionForCall(waiting.handlerId, IncomingCallsService.Accepted);
            waiting.answer();
            return;
        }

        var held = heldVoiceCall();
        if (held) held.hold(false);
    }

    /// Releases the Nth call (3GPP 22.030 "1X"). The index is 1-based.
    function releaseCall(index) {
        var call = callAt(index - 1);
        if (call) call.hangup();
    }

    /// Splits the Nth call out of the conference (3GPP 22.030 "2X").
    function privateChat(index) {
        var call = callAt(index - 1);
        if (call) call.split();
    }

    function answer() {
        var incoming = incomingVoiceCall();
        if (!incoming) return;

        IncomingCallsService.setActionForCall(incoming.handlerId, IncomingCallsService.Accepted);
        incoming.answer();
    }

    /// Rejects a ringing call, or hangs up the active one if nothing is ringing.
    function reject() {
        var incoming = incomingVoiceCall();
        if (incoming) {
            IncomingCallsService.setActionForCall(incoming.handlerId, IncomingCallsService.Ignored);
            incoming.hangup();
            return;
        }

        var call = currentCall();
        if (call) call.hangup();
    }

    function sendDtmf(tones) {
        var call = currentCall();
        if (call) call.sendDtmf(tones);
    }

    /// Transfers the active call to `target` without answering it.
    function deflect(target) {
        var incoming = incomingVoiceCall();
        if (incoming) incoming.deflect(target);
    }

    function silenceRingtone() {
        manager.silenceRingtone();
    }

    /**
     * Audio passthroughs, so callers work against this wrapper rather than
     * reaching into the nemo manager behind it.
     */
    property alias audioMode: voiceCallManagerId.audioMode
    property alias isMicrophoneMuted: voiceCallManagerId.isMicrophoneMuted
    property alias isSpeakerMuted: voiceCallManagerId.isSpeakerMuted

    function setAudioMode(mode) {
        return manager.setAudioMode(mode);
    }

    function setMuteMicrophone(on) {
        return manager.setMuteMicrophone(on);
    }

    /**
     * Audio
     **/

    function __setCallModeError(message) {
        console.log("Problem when calling luna://org.webosports.service.audio/setCallMode : " + message);
    }

    onActiveVoiceCallChanged: {
        console.log("Active VoiceCall changed -> setting audio to " + !!activeVoiceCall);
        __lunaNextLS2Service.call("luna://org.webosports.service.audio/setCallMode", JSON.stringify({ inCall: (!!activeVoiceCall) }),
                                  undefined, root.__setCallModeError);

        // A queued post-dial string is sent as soon as its call goes active.
        if (activeVoiceCall)
            _flushPostDial(activeVoiceCall);
    }

    onHeldCallChanged: {
        if (!root.heldCall || root._dialNumberAfterHold.length === 0)
            return;

        var number = _dialNumberAfterHold;
        var transport = _dialTransportAfterHold;
        _dialNumberAfterHold = "";
        _dialTransportAfterHold = "";
        _pendingDialNumber = number;
        _dialAttemptedAt = Date.now();
        _dial(number, transport);
    }

    /**
     * Post-dial strings
     **/

    // A ',' pauses for a moment and keeps going; a ';' (or 'w') waits for the
    // user to confirm before sending the rest. Only the pause form is automatic.
    function _flushPostDial(voiceCall) {
        var pending = _postDialStrings[voiceCall.handlerId];
        if (!pending || pending.length === 0)
            return;

        var waitIndex = pending.search(/[;w]/i);
        var toSend = (waitIndex < 0) ? pending : pending.slice(0, waitIndex);
        var remainder = (waitIndex < 0) ? "" : pending.slice(waitIndex + 1);

        var tones = toSend.replace(/[,p]/gi, "");
        if (tones.length > 0) {
            console.log("Sending post-dial DTMF: " + tones);
            voiceCall.sendDtmf(tones);
        }

        _postDialStrings[voiceCall.handlerId] = remainder;
        if (remainder.length > 0)
            postDialWaiting(voiceCall, remainder);
    }

    /// The rest of a post-dial string needs the user to confirm before it is sent.
    signal postDialWaiting(var voiceCall, string remainder);

    /// Sends whatever is left of the post-dial string for `voiceCall`.
    function sendPendingPostDial(voiceCall) {
        _flushPostDial(voiceCall);
    }

    function _updateState(voiceCall, isIncoming) {
        console.log("Currently we have " + manager.voiceCalls.count + " calls");

        // Let the derived call-list properties know something moved.
        callsRevision = callsRevision + 1;

        console.log("Looking at call " + voiceCall.lineId + " with state " + voiceCall.statusText + " "
                    + voiceCall.status);

        switch (voiceCall.status) {
        case VoiceCall.STATUS_ACTIVE:
            if (root.heldCall && root.heldCall.handlerId === voiceCall.handlerId)
                root.heldCall = null;
            root.activeCall(voiceCall);
            _flushPostDial(voiceCall);
            break;
        case VoiceCall.STATUS_DIALING:
        case VoiceCall.STATUS_ALERTING:
            IncomingCallsService.setIncomingForCall(voiceCall.handlerId, false);
            root.outgoingCall(voiceCall);
            break;
        case VoiceCall.STATUS_INCOMING:
        case VoiceCall.STATUS_WAITING:
            IncomingCallsService.setIncomingForCall(voiceCall.handlerId, true);
            root.incomingCall(voiceCall);
            break;
        case VoiceCall.STATUS_HELD:
            root.heldCall = voiceCall;
            break;
        case VoiceCall.STATUS_DISCONNECTED:
            /*
             * Which way the call went, from the states it actually passed
             * through rather than from what it said about itself when the row
             * first appeared. isIncoming is read the instant the handler is
             * inserted, before the call has settled, and a call we placed that
             * reads as incoming there is filed as one the user missed.
             */
            isIncoming = IncomingCallsService.wasIncoming(voiceCall.handlerId, isIncoming);

            // the voicecall object is soon to be destroyed, so save its state before sending the signal
            var endedVoiceCall = {
                handlerId: voiceCall.handlerId,
                providerId: voiceCall.providerId,
                status: voiceCall.status,
                statusText: voiceCall.statusText,
                lineId:voiceCall.lineId,
                startedAt: voiceCall.startedAt,
                duration: voiceCall.duration,
                isIncoming: isIncoming,
                isEmergency: voiceCall.isEmergency,
                isMultiparty: voiceCall.isMultiparty,
                isForwarded: voiceCall.isForwarded,
                isRemoteHeld: voiceCall.isRemoteHeld
            };

            if (root.heldCall && root.heldCall.handlerId === voiceCall.handlerId)
                root.heldCall = null;
            delete _postDialStrings[voiceCall.handlerId];

            // A call that never connected and was not rejected by the user did
            // not "end", it failed to be placed.
            if (!isIncoming && endedVoiceCall.duration === 0 &&
                IncomingCallsService.getActionForCall(voiceCall.handlerId) === IncomingCallsService.Missed) {
                root.dialFailed(endedVoiceCall.lineId, "callfailed");
            }

            root.endingCall(endedVoiceCall);
            break;
        case VoiceCall.STATUS_NULL:
            root.resetCall(voiceCall);
            break;
        }
    }

    Connections {
        target: calls
        function onRowsRemoved(parent, first, last) {
            root.callsRevision = root.callsRevision + 1;
        }
        function onRowsInserted(parent, first, last) {
            root.callsRevision = root.callsRevision + 1;
            for(var i=first;i<=last;++i) {
                var object = calls.instance(i);
                addStatusObserver(object);

                // Attach the post-dial string queued by the dial() that created
                // this call, now that we know which handler it landed on.
                if (!object.isIncoming && root._pendingPostDial.length > 0) {
                    root._postDialStrings[object.handlerId] = root._pendingPostDial;
                    root._pendingPostDial = "";
                }
                if (!object.isIncoming)
                    root._pendingDialNumber = "";

                _updateState(object, object.isIncoming); // initialize the state
            }
        }
        function addStatusObserver(object) {
            console.log("Adding status observer for " + object);
            var isIncoming=object.isIncoming; // memorize the incoming status asap
            object.statusChanged.connect( function() { _updateState(object, isIncoming) } );
        }
    }

    /**
     * Synergy transports
     *
     * One driver per non-cellular calling account, rebuilt whenever the account
     * list changes so installing or removing a connector takes effect without a
     * restart. Their calls are observed exactly like the modem's.
     */
    Instantiator {
        model: callTransports ? callTransports.voipTransportIds() : []

        delegate: SynergyTransport {
            required property var modelData

            transportId: modelData
            implementation: root.callTransports.implementationFor(modelData)

            onCallAdded: (call) => {
                console.log("Synergy call added on " + transportId + ": " + call.lineId);
                call.statusChanged.connect(function() { root._updateState(call, call.isIncoming); });

                if (!call.isIncoming && root._pendingPostDial.length > 0) {
                    root._postDialStrings[call.handlerId] = root._pendingPostDial;
                    root._pendingPostDial = "";
                }
                if (!call.isIncoming)
                    root._pendingDialNumber = "";

                root.callsRevision = root.callsRevision + 1;
                root._updateState(call, call.isIncoming);
            }

            onCallRemoved: (call) => {
                root.callsRevision = root.callsRevision + 1;
            }

            onCallsChanged: root.callsRevision = root.callsRevision + 1

            onDialFailed: (address, reason) => root.dialFailed(address, reason)

            Component.onCompleted: {
                var registry = root.synergyTransports;
                registry[transportId] = this;
                root.synergyTransports = registry;
                root.callsRevision = root.callsRevision + 1;
            }
            Component.onDestruction: {
                var registry = root.synergyTransports;
                delete registry[transportId];
                root.synergyTransports = registry;
                root.callsRevision = root.callsRevision + 1;
            }
        }
    }

    Connections {
        target: manager

        /*
         * The call manager reports every error it meets, most of them nothing
         * to do with us -- the modem losing service, a provider complaining
         * while the phone sits idle. Only an error arriving while we are
         * actually placing a call means that call failed; announcing the rest
         * puts "No service" in front of someone who is not even dialling.
         */
        function onError(message) {
            console.log("VoiceCallManager error: " + message);

            if (root._pendingDialNumber.length === 0 ||
                Date.now() - root._dialAttemptedAt > root._dialInFlightMs) {
                console.log("  ... not ours: pending='" + root._pendingDialNumber +
                            "' age=" + (Date.now() - root._dialAttemptedAt) + "ms");
                return;
            }

            console.log("DIALFAIL from the call manager while dialling " + root._pendingDialNumber);

            root.dialFailed(root._pendingDialNumber, _reasonFromError(message));
            root._pendingDialNumber = "";
            root._pendingPostDial = "";
        }
    }

    // The manager reports errors as free text; map the ones we recognise onto
    // the reason keys CallMessages.dialFailure uses.
    function _reasonFromError(message) {
        var text = String(message).toLowerCase();
        if (text.indexOf("no service") >= 0 || text.indexOf("not registered") >= 0) return "noservice";
        if (text.indexOf("airplane") >= 0 || text.indexOf("offline") >= 0) return "airplanemodeon";
        if (text.indexOf("emergency") >= 0) return "emergencyonly";
        if (text.indexOf("fdn") >= 0 || text.indexOf("fixed dialing") >= 0) return "invalidnumber";
        if (text.indexOf("pin") >= 0) return "pinrequired";
        if (text.indexOf("puk") >= 0) return "pukrequired";
        if (text.indexOf("busy") >= 0 || text.indexOf("no free") >= 0) return "nofreelines";
        return "callfailed";
    }

    Component.onCompleted: {
        __lunaNextLS2Service.call("luna://com.webos.service.systemservice/getPreferences", JSON.stringify({ keys: ["region"], subscribe: false }), _getPreferencesSuccess, _getPreferencesFailure)
    }
    function _getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
        if (response.region && response.region.countryCode) {
            countryCode = response.region.countryCode;
            console.log("phone: set current country code to: " + response.region.countryCode);
        }
    }
    function _getPreferencesFailure(message) {
        console.log("No region found, default to US: " + message);
        countryCode = 'US'
        console.log("phone: set current country code to: " + countryCode);
    }
}
