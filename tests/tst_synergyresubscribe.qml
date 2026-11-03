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

import "../qml/services"

/**
 * Hearing about calls again after the connector's service restarts.
 *
 * The hub ends a subscription whose service went away with a
 * {"returnValue":false} reply, which LunaService passes to the reply
 * callback. Taken for an empty update, it left the app deaf to every later
 * call on the transport (sargo, 2026-11-03).
 */
Item {
    id: root

    TestCase {
        name: "SynergyResubscribe"

        // No implementation: nothing is subscribed for real, so the test
        // drives the replies itself.
        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.whatsapp" } }

        property var transport: null
        property var timer: null

        function findByName(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            var kids = item.data || [];
            for (var i = 0; i < kids.length; ++i) {
                var found = findByName(kids[i], name);
                if (found)
                    return found;
            }
            return null;
        }

        function init() {
            transport = createTemporaryObject(transportComponent, root);
            timer = findByName(transport, "resubscribeTimer");
            verify(timer !== null, "no resubscribe timer");
            // As if subscribed and the first reply had come in.
            transport._subscribed = true;
        }

        function test_serviceGoingAwayResubscribes() {
            transport._onCallState({ returnValue: false, errorCode: -1,
                                     errorText: "Service is down" });
            verify(!transport._subscribed, "still thinks it is subscribed");
            verify(timer.running, "no resubscribe scheduled");
        }

        function test_firstReplyIsNotALoss() {
            transport._onCallState({ returnValue: true });
            verify(transport._subscribed);
            verify(!timer.running);
        }

        function test_callStateStillReachesTheCalls() {
            transport._onCallState({ returnValue: true, lines: [
                { state: "incoming", calls: [{ id: "c1", address: "+10000000000" }] }] });
            verify(transport._subscribed);
            verify(!timer.running);
            compare(transport.calls.length, 1);
        }

        function test_anEmptyReplyIsALoss() {
            transport._onCallState(null);
            verify(!transport._subscribed);
            verify(timer.running);
        }
    }
}
