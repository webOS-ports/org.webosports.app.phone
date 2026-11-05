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
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "../qml/services"
import "../qml/services/IncomingCallsService.js" as IncomingCallsService

/**
 * A messaging call answered on another of the user's devices ends here with
 * disconnectDetails.cause "answeredElsewhere": it was answered, so the missed
 * call alert (NotificationManager) and the call log (CallHistory), which both
 * go by IncomingCallsService.getActionForCall(), must not count it as missed.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "AnsweredElsewhere"
        when: windowShown

        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.teams" } }

        property var transport: null
        property int serial: 0
        property string callId: ""

        function init() {
            transport = createTemporaryObject(transportComponent, root);
            // A call id of its own per test: the actions register is shared.
            callId = "elsewhere-" + (++serial);
        }

        function push(state, extra) {
            var l = { state: state, calls: [{ id: callId, address: "8:peer" }] };
            for (var k in (extra || {})) l[k] = extra[k];
            transport._onLines([l], { returnValue: true, lines: [l] });
            return transport._findCall(callId);
        }

        // The status the call had when its end was seen, and what was recorded then.
        function endWith(extra) {
            var call = push("incoming");
            verify(call !== null);
            var handlerId = call.handlerId;
            var seen = null;
            call.statusChanged.connect(function() {
                if (call.status === VoiceCall.STATUS_DISCONNECTED)
                    seen = IncomingCallsService.getActionForCall(handlerId);
            });
            push("disconnected", extra);
            return { seen: seen, after: IncomingCallsService.getActionForCall(handlerId) };
        }

        function test_answeredElsewhereIsNotMissed() {
            var r = endWith({ disconnectDetails: { cause: "answeredElsewhere" } });
            compare(r.seen, IncomingCallsService.Accepted, "already answered when the end is seen");
            compare(r.after, IncomingCallsService.Accepted);
        }

        function test_aCallThatRangOutIsStillMissed() {
            var r = endWith({ disconnectDetails: { cause: "missed" } });
            compare(r.after, IncomingCallsService.Missed);
        }

        function test_anEndWithoutDetailsIsStillMissed() {
            var r = endWith({});
            compare(r.after, IncomingCallsService.Missed);
        }

        function test_anOtherCauseIsStillMissed() {
            var r = endWith({ disconnectDetails: { cause: "error" } });
            compare(r.after, IncomingCallsService.Missed);
        }

        function test_aRejectedCallStaysIgnored() {
            var call = push("incoming");
            IncomingCallsService.setActionForCall(call.handlerId, IncomingCallsService.Ignored);
            push("disconnected", { disconnectDetails: { cause: "rejected" } });
            compare(IncomingCallsService.getActionForCall(call.handlerId), IncomingCallsService.Ignored);
        }

        function test_anOutgoingCallIsLeftAlone() {
            var call = push("dialing");
            verify(!call.isIncoming);
            push("disconnected", { disconnectDetails: { cause: "answeredElsewhere" } });
            // Never registered: the register's answer for an id it has not heard of.
            compare(IncomingCallsService.getActionForCall(call.handlerId), IncomingCallsService.Missed);
        }
    }
}
