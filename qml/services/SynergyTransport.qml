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
import org.nemomobile.voicecall 1.0

import "IncomingCallsService.js" as IncomingCallsService

/**
 * Drives calls on one Synergy transport.
 *
 * Ports the per-transport half of the legacy CallSynergizer: subscribe to the
 * connector's callStateQuery, turn the "lines" it pushes into call objects, and
 * send call control back to the same service. Everything the connector reports
 * is normalised into SynergyCall, so the rest of the app never learns that this
 * is not the modem.
 */
Item {
    id: synergyTransport

    /// Account templateId, e.g. "com.palm.telegram".
    property string transportId: ""
    /// Luna service the connector implements, from its PHONE capability.
    property string implementation: ""

    /// Calls currently in progress on this transport.
    property var calls: []

    // `calls` is a property, so callsChanged() already exists; redeclaring it
    // would collide with the generated one.
    signal callAdded(var call);
    signal callRemoved(var call);
    signal dialFailed(string address, string reason);

    /**
     * Call control
     **/

    function dial(address, video, audio) {
        if (implementation.length === 0) {
            console.log("Transport " + transportId + " has no implementation to dial through");
            dialFailed(address, "callfailed");
            return;
        }

        _pendingDialAddress = address;

        // Connectors want a clean address. A dial string typed on the dialpad
        // carries display grouping ("+31 6 2148 9831"); strip it when it looks
        // like a phone number, and leave usernames alone.
        var target = /^[\s()+\-.0-9]+$/.test(String(address))
                         ? String(address).replace(/[\s()\-.]/g, "")
                         : address;

        _call("dial", { address: target, video: video === true, audio: audio !== false },
              undefined,
              function(error) {
                  console.log("Dial over " + transportId + " failed: " + error);
                  synergyTransport.dialFailed(address, _reasonFromError(error));
              });
    }

    function hangupAll() {
        _call("hangupAll", {});
    }

    property string _pendingDialAddress: ""

    /**
     * State
     **/

    // The connector describes its calls as "lines", each holding one call or a
    // conference. The states it uses predate the nemo ones, so map them.
    function _statusFromLineState(state) {
        switch (state) {
        case "incoming":            return VoiceCall.STATUS_INCOMING;
        case "dialing":
        case "dialpending":         return VoiceCall.STATUS_DIALING;
        case "alerting":            return VoiceCall.STATUS_ALERTING;
        case "active":
        case "conference_active":   return VoiceCall.STATUS_ACTIVE;
        case "hold":
        case "onHold":
        case "conference_hold":     return VoiceCall.STATUS_HELD;
        case "disconnected":
        case "disconnectpending":   return VoiceCall.STATUS_DISCONNECTED;
        default:                    return VoiceCall.STATUS_NULL;
        }
    }

    function _isConferenceState(state) {
        return state === "conference_active" || state === "conference_hold";
    }

    // A disconnected line carries the connector's reason in
    // disconnectDetails.cause; "answeredElsewhere" means another of the user's
    // devices took the call.
    function _answeredElsewhere(line) {
        return !!line.disconnectDetails
                && line.disconnectDetails.cause === "answeredElsewhere";
    }

    function _findCall(callId) {
        for (var i = 0; i < calls.length; ++i) {
            if (calls[i].callId === callId)
                return calls[i];
        }
        return null;
    }

    function _onLines(lines, payload) {
        var seen = {};
        var current = calls.slice();
        var added = [];

        lines.forEach(function(line) {
            var status = _statusFromLineState(line.state);
            var conference = _isConferenceState(line.state);
            var video = !!(line.outgoingVideo || line.incomingVideo);

            (line.calls || []).forEach(function(entry) {
                seen[entry.id] = true;

                var call = _findCall(entry.id);
                if (!call) {
                    call = callComponent.createObject(synergyTransport, {
                        transport: synergyTransport.transportId,
                        implementation: synergyTransport.implementation,
                        callId: entry.id,
                        lineId: entry.address || "",
                        isIncoming: line.state === "incoming" || entry.direction === "incoming",
                        startedAt: entry.startTime ? new Date(entry.startTime) : new Date()
                    });
                    call.callControlRequested.connect(_onCallControlRequested);
                    current.push(call);
                    added.push(call);
                }

                // A display name that arrives in a later push has to be applied:
                // on an outgoing call the connector often sends the address
                // first and the real name only once the call is up.
                if (entry.displayName && entry.displayName.length > 0)
                    call.displayName = entry.displayName;
                if (entry.address && entry.address.length > 0)
                    call.lineId = entry.address;

                // Answered on another device: say so before the call is seen to
                // end, which is when it would be counted as missed.
                if (status === VoiceCall.STATUS_DISCONNECTED && call.isIncoming
                        && _answeredElsewhere(line))
                    IncomingCallsService.callAnsweredElsewhere(call.handlerId);

                call.isMultiparty = conference || (line.calls.length > 1);
                call.isVideo = call.isVideo || video
                               || line.incomingVideoState === "available"
                               || line.incomingVideoState === "streaming";
                _applyVideo(call, line, payload);

                call.status = status;
            });
        });

        // Anything the connector stopped reporting has gone away. Mark it
        // disconnected first so listeners see the transition rather than the
        // call simply vanishing.
        var removed = current.filter(function(call) { return !seen[call.callId]; });
        removed.forEach(function(call) {
            call.status = VoiceCall.STATUS_DISCONNECTED;
        });

        calls = current.filter(function(call) { return !!seen[call.callId]; });

        added.forEach(function(call) { callAdded(call); });
        removed.forEach(function(call) {
            callRemoved(call);
            call.destroy();
        });

        // After callAdded, so a call that turns up already streaming video has
        // its listeners connected before it asks the user.
        calls.forEach(function(call) {
            if (call.status !== VoiceCall.STATUS_DISCONNECTED)
                call._evaluateVideo();
        });
    }

    // The line's video fields onto the call. The decoded picture's location is
    // on the payload, not the line: a connector decodes one call at a time.
    function _applyVideo(call, line, payload) {
        call.incomingVideo = line.incomingVideo === true;
        call.outgoingVideo = line.outgoingVideo === true;
        call.incomingVideoState = line.incomingVideoState || "unavailable";
        call.incomingVideoOrientation = (line.incomingVideoOrientation | 0) & 3;
        var allow = line.allowVideoCalls !== undefined ? line.allowVideoCalls
                  : (payload && payload.allowVideoCalls !== undefined ? payload.allowVideoCalls : true);
        call.allowVideoCalls = allow !== false;
        call.autoAcceptVideoCalls = line.autoAcceptVideoCalls === true;
        var uri = payload && typeof payload.videoURI === "string" ? payload.videoURI : "";
        call.videoWidth = uri.length > 0 ? (payload.videoWidth || 0) : 0;
        call.videoHeight = uri.length > 0 ? (payload.videoHeight || 0) : 0;
        call.videoURI = uri;
        // Our own camera is read on its own: a call we place sends from the
        // start, and the far side may turn its camera on much later or never.
        var preview = payload && typeof payload.videoPreviewURI === "string" ? payload.videoPreviewURI : "";
        call.videoPreviewWidth = preview.length > 0 ? (payload.videoPreviewWidth || 0) : 0;
        call.videoPreviewHeight = preview.length > 0 ? (payload.videoPreviewHeight || 0) : 0;
        call.videoPreviewOrientation = preview.length > 0 ? ((payload.videoPreviewOrientation | 0) & 3) : 0;
        call.videoPreviewMirrored = preview.length > 0 && payload.videoPreviewMirrored === true;
        call.videoPreviewURI = preview;
    }

    function _onCallControlRequested(method, params) {
        _call(method, params);
    }

    /**
     * The connector's service URI, normalised and ending in "/".
     *
     * A template may declare its call service with either scheme - com.palm.whatsapp says
     * `palm://com.palm.whatsapp.call` - and the two are the same bus. Prefixing "luna://"
     * whenever the string did not already start with it turned that into
     * `luna://palm://com.palm.whatsapp.call`, which ls-hubd rejects outright:
     *
     *     LS_INV_URI_SNAME ... Not a valid service name in uri luna://palm://com.palm.whatsapp.call
     *
     * Every call failed, every subscribe failed, and the failure handler restarts
     * resubscribeTimer - so the app retried every five seconds for as long as the account
     * existed, which is what it was doing on a MindPhone after a WhatsApp account was added.
     */
    function _serviceUri() {
        var uri = implementation;
        if (uri.indexOf("palm://") === 0)
            uri = "luna://" + uri.substring(7);
        else if (uri.indexOf("luna://") !== 0)
            uri = "luna://" + uri;
        if (uri.charAt(uri.length - 1) !== "/")
            uri += "/";
        return uri;
    }

    function _call(method, params, onSuccess, onFailure) {
        if (implementation.length === 0)
            return;

        var uri = _serviceUri();

        lunaService.call(uri + method, JSON.stringify(params || {}), onSuccess,
                         onFailure || function(error) {
                             console.log(transportId + " " + method + " failed: " + error);
                         });
    }

    function _reasonFromError(message) {
        var text = String(message).toLowerCase();
        if (text.indexOf("notloggedin") >= 0 || text.indexOf("not logged in") >= 0) return "notloggedin";
        if (text.indexOf("insufficientfunds") >= 0 || text.indexOf("credit") >= 0) return "insufficientfunds";
        if (text.indexOf("invalidaddress") >= 0) return "invalidaddress";
        if (text.indexOf("contactnotfound") >= 0) return "contactnotfound";
        if (text.indexOf("noservice") >= 0 || text.indexOf("no service") >= 0) return "noservice";
        if (text.indexOf("disabled") >= 0) return "disabled";
        return "callfailed";
    }

    // The connector reports a start time, not a running duration, so the
    // duration has to be recomputed while calls are up.
    Timer {
        running: synergyTransport.calls.length > 0
        interval: 1000
        repeat: true
        onTriggered: synergyTransport.calls.forEach(function(call) { call.updateDuration(); })
    }

    Component {
        id: callComponent
        SynergyCall {}
    }

    LunaService {
        id: lunaService
        objectName: "lunaService"
        name: "org.webosports.app.phone"
        onInitialized: {
            synergyTransport._registered = true;
            synergyTransport._subscribe();
        }
    }

    // Subscribe as soon as we know which service to talk to and lunaService
    // has its name on the bus. implementation is set while the transport is
    // being created, before lunaService is registered; a call then fails with
    // "LunaService is not registered" and the first five seconds of call
    // state were lost to resubscribeTimer. The connector may restart, so this
    // resubscribes rather than giving up.
    onImplementationChanged: _subscribe()

    property bool _registered: false
    property bool _subscribed: false

    function _subscribe() {
        if (_subscribed || !_registered || implementation.length === 0)
            return;

        var uri = _serviceUri();

        console.log("Watching call state on " + transportId + " (" + uri + ")");
        _subscribed = true;

        lunaService.subscribe(uri + "callStateQuery", JSON.stringify({ subscribe: true }),
                              function(message) {
                                  synergyTransport._onCallState(JSON.parse(message.payload));
                              },
                              function(error) {
                                  synergyTransport._lostCallState(error);
                              });
    }

    /**
     * One reply on the callStateQuery subscription.
     *
     * When the connector's service goes away (imlibpurpleservice restarted,
     * say) the hub ends the subscription with a {"returnValue":false} reply in
     * its error category. LunaService hands that to the reply callback, not to
     * the error callback, and cancels the call - so it has to be caught here,
     * or the app stops hearing about calls on this transport for good. On
     * sargo on 2026-11-03 every WhatsApp call after a restart of the service
     * rang the far side and nothing on the phone.
     */
    function _onCallState(payload) {
        if (!payload || payload.returnValue === false) {
            _lostCallState(payload ? (payload.errorText || payload.errorCode) : "no payload");
            return;
        }
        // The first response is just {returnValue:true}.
        if (!payload.lines)
            return;

        _onLines(payload.lines, payload);
    }

    function _lostCallState(error) {
        console.warn("Lost call state for " + transportId + ": " + error);
        _subscribed = false;
        resubscribeTimer.restart();
    }

    Timer {
        id: resubscribeTimer
        objectName: "resubscribeTimer"
        interval: 5000
        onTriggered: synergyTransport._subscribe()
    }
}
