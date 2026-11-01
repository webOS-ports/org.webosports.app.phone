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

pragma ComponentBehavior: Bound

import QtQuick 2.0
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "../qml/services"
import "../qml/services/HeadsetCallKeys.js" as HeadsetCallKeys

/**
 * The wired headset's button and the calls, as on Android: a press answers
 * a ringing call or ends the one in progress, a long press rejects a
 * ringing call; mediacontroller's registerCallKeys held while there is a
 * call and only then.
 */
Item {
    id: root

    TestCase {
        name: "HeadsetCallButton"

        function test_whatTheButtonDoes_data() {
            return [
                { tag: "press, ringing", key: "playPause", ringing: true, inProgress: false, action: "answer" },
                { tag: "press, waiting behind a call", key: "playPause", ringing: true, inProgress: true, action: "answer" },
                { tag: "press, in a call", key: "playPause", ringing: false, inProgress: true, action: "hangup" },
                { tag: "press, no call", key: "playPause", ringing: false, inProgress: false, action: "" },
                { tag: "long press, ringing", key: "hold", ringing: true, inProgress: false, action: "reject" },
                { tag: "long press, waiting behind a call", key: "hold", ringing: true, inProgress: true, action: "reject" },
                { tag: "long press, in a call", key: "hold", ringing: false, inProgress: true, action: "" },
                { tag: "long press, no call", key: "hold", ringing: false, inProgress: false, action: "" },
                { tag: "play", key: "play", ringing: true, inProgress: true, action: "" },
                { tag: "pause", key: "pause", ringing: true, inProgress: true, action: "" },
                { tag: "next", key: "next", ringing: true, inProgress: true, action: "" },
                { tag: "nothing", key: "", ringing: true, inProgress: true, action: "" }
            ];
        }

        function test_whatTheButtonDoes(data) {
            compare(HeadsetCallKeys.actionFor(data.key, data.ringing, data.inProgress), data.action);
        }

        Component {
            id: callComponent
            QtObject {
                property int status: VoiceCall.STATUS_ACTIVE
                property int hungUp: 0
                function hangup() { hungUp++; status = VoiceCall.STATUS_DISCONNECTED; }
            }
        }

        Component {
            id: managerComponent
            QtObject {
                property bool hasCall: false
                property var ringing: null
                property var current: null
                property var byStatus: ({})
                property int answered: 0
                property int rejected: 0
                function incomingVoiceCall() { return ringing; }
                function currentCall() { return current; }
                function callsWithStatus(status) { return byStatus[status] || []; }
                function answer() { answered++; }
                function reject() { rejected++; }
            }
        }

        Component {
            id: busComponent
            QtObject {
                id: bus
                property int subscribed: 0
                property int cancelled: 0
                property string payload: ""
                function subscribe(p) {
                    subscribed++;
                    payload = p;
                    // the bus may go before the button when a test ends
                    return { cancel: function () { if (bus) bus.cancelled++; } };
                }
            }
        }

        Component {
            id: buttonComponent
            HeadsetCallButton {}
        }

        QtObject { id: managerWithACall; property bool hasCall: true }
        Component {
            id: busComponentDeclared
            QtObject {
                property int subscribed: 0
                function subscribe(p) { subscribed++; return { cancel: function () {} }; }
            }
        }
        // as main.qml has it: bound to a manager that already has a call
        Component {
            id: declaredButton
            HeadsetCallButton { voiceCallManager: managerWithACall }
        }

        function make(hasCall) {
            const manager = createTemporaryObject(managerComponent, root, { hasCall: hasCall });
            const bus = createTemporaryObject(busComponent, root);
            const button = createTemporaryObject(buttonComponent, root, { _bus: bus, voiceCallManager: manager });
            return { manager: manager, bus: bus, button: button };
        }

        function reply(button, payload) {
            button._onResponse({ payload: JSON.stringify(payload) });
        }

        function test_heldWhileThereIsACallAndOnlyThen() {
            const t = make(false);
            compare(t.bus.subscribed, 0, "taken with no call");
            t.manager.hasCall = true;   // a call rings
            compare(t.bus.subscribed, 1);
            compare(JSON.parse(t.bus.payload), { subscribe: true });
            t.manager.hasCall = false;  // the last call ended
            compare(t.bus.cancelled, 1);
            t.manager.hasCall = true;
            compare(t.bus.subscribed, 2, "not taken again for the next call");
        }

        function test_heldFromTheStartWhenACallIsAlreadyThere() {
            const t = make(true);
            compare(t.bus.subscribed, 1);
            t.button.destroy();
            wait(0);
            compare(t.bus.cancelled, 1, "let go when it goes");
        }

        function test_heldWhenBoundToAManagerWithACall() {
            const bus = createTemporaryObject(busComponentDeclared, root);
            const button = createTemporaryObject(declaredButton, root, { _bus: bus });
            verify(button.wanted);
            compare(bus.subscribed, 1);
        }

        function test_aPressAnswersARingingCall() {
            const t = make(true);
            t.manager.ringing = createTemporaryObject(callComponent, root, { status: VoiceCall.STATUS_INCOMING });
            reply(t.button, { returnValue: true, subscribed: true, keyEvent: "playPause" });
            compare(t.manager.answered, 1);
            compare(t.manager.rejected, 0);
        }

        function test_aPressEndsTheCallInProgress() {
            const t = make(true);
            const call = createTemporaryObject(callComponent, root);
            t.manager.current = call;
            reply(t.button, { returnValue: true, subscribed: true, keyEvent: "playPause" });
            compare(call.hungUp, 1);
            compare(t.manager.answered, 0);
            compare(t.manager.rejected, 0);
        }

        function test_aPressEndsACallBeingDialled() {
            const t = make(true);
            const dialling = createTemporaryObject(callComponent, root, { status: VoiceCall.STATUS_ALERTING });
            var byStatus = {};
            byStatus[VoiceCall.STATUS_ALERTING] = [dialling];
            t.manager.byStatus = byStatus;
            compare(t.button.handleKey("playPause"), "hangup");
            compare(dialling.hungUp, 1);
        }

        function test_aLongPressRejectsARingingCallOnly() {
            const t = make(true);
            const call = createTemporaryObject(callComponent, root);
            t.manager.current = call;
            reply(t.button, { returnValue: true, subscribed: true, keyEvent: "hold" });
            compare(t.manager.rejected, 0, "a long press in a call ended it");
            compare(call.hungUp, 0);
            t.manager.ringing = createTemporaryObject(callComponent, root, { status: VoiceCall.STATUS_WAITING });
            reply(t.button, { returnValue: true, subscribed: true, keyEvent: "hold" });
            compare(t.manager.rejected, 1);
            compare(call.hungUp, 0, "the call in progress was ended with the waiting one");
        }

        function test_repliesWithoutAKeyDoNothing() {
            const t = make(true);
            t.manager.ringing = createTemporaryObject(callComponent, root, { status: VoiceCall.STATUS_INCOMING });
            reply(t.button, { returnValue: true, subscribed: true });
            reply(t.button, { returnValue: true, keyEvent: 5 });
            t.button._onResponse({ payload: "not json" });
            t.button._onResponse({ payload: "[]" });
            compare(t.manager.answered, 0);
            compare(t.manager.rejected, 0);
        }
    }
}
