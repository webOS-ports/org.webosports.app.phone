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

                call.isMultiparty = conference || (line.calls.length > 1);
                call.isVideo = call.isVideo || video;

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
    }

    function _onCallControlRequested(method, params) {
        _call(method, params);
    }

    function _call(method, params, onSuccess, onFailure) {
        if (implementation.length === 0)
            return;

        var uri = implementation;
        if (uri.indexOf("luna://") !== 0)
            uri = "luna://" + uri;
        if (uri.charAt(uri.length - 1) !== "/")
            uri += "/";

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
        name: "org.webosports.app.phone"
    }

    // Subscribe as soon as we know which service to talk to. The connector may
    // restart, so this resubscribes rather than giving up.
    onImplementationChanged: _subscribe()
    Component.onCompleted: _subscribe()

    property bool _subscribed: false

    function _subscribe() {
        if (_subscribed || implementation.length === 0)
            return;

        var uri = implementation;
        if (uri.indexOf("luna://") !== 0)
            uri = "luna://" + uri;
        if (uri.charAt(uri.length - 1) !== "/")
            uri += "/";

        console.log("Watching call state on " + transportId + " (" + uri + ")");
        _subscribed = true;

        lunaService.subscribe(uri + "callStateQuery", JSON.stringify({ subscribe: true }),
                              function(message) {
                                  var payload = JSON.parse(message.payload);
                                  // The first response is just {returnValue:true}.
                                  if (!payload.lines)
                                      return;

                                  synergyTransport._onLines(payload.lines, payload);
                              },
                              function(error) {
                                  console.log("Lost call state for " + transportId + ": " + error);
                                  synergyTransport._subscribed = false;
                                  resubscribeTimer.restart();
                              });
    }

    Timer {
        id: resubscribeTimer
        interval: 5000
        onTriggered: synergyTransport._subscribe()
    }
}
