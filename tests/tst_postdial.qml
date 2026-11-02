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
import "fakes"

/**
 * Post-dial strings, "0800123456,1234" and the like. A ',' is a pause: the
 * menu at the other end needs a moment before it listens, so the digits must
 * wait for it rather than go out the instant the call connects. oFono's
 * SendTones knows the pause as 'p' and refuses ',' with InvalidFormat.
 */
Item {
    id: root

    TestCase {
        name: "PostDial"

        Component {
            id: networkComponent
            FakeCallNetwork {}
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }

        SignalSpy { id: waitingSpy; signalName: "postDialWaiting" }

        property var network: null
        property var wrapper: null
        property var call: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            call = network._add("0800123456", VoiceCall.STATUS_ACTIVE);
            waitingSpy.clear();
            waitingSpy.target = wrapper;
        }

        function flush(postDial) {
            wrapper._postDialStrings[call.handlerId] = postDial;
            wrapper.sendPendingPostDial(call);
            return network.commands.join(" ");
        }

        function test_aCommaPausesBeforeTheDigits() {
            compare(flush(",1234"), "AT+VTS=p1234");
        }

        function test_everyCommaIsAPause() {
            compare(flush(",,12,34"), "AT+VTS=pp12p34");
        }

        function test_pIsKeptAsItIs() {
            compare(flush("p12P3"), "AT+VTS=p12P3");
        }

        function test_onlyCharactersOfonoTakesAreSent() {
            var sent = flush(",12*#,A");
            compare(sent, "AT+VTS=p12*#pA");
            verify(/^AT\+VTS=[0-9*#A-DpP]+$/.test(sent), "oFono would refuse " + sent);
        }

        function test_aPauseAloneSendsNothing() {
            compare(flush(",,"), "");
        }

        function test_aWaitStopsTheAutomaticPart() {
            compare(flush(",12;34"), "AT+VTS=p12");
            compare(waitingSpy.count, 1);
            compare(waitingSpy.signalArguments[0][1], "34");
            network.commands = [];
            compare(flush(wrapper._postDialStrings[call.handlerId]), "AT+VTS=34");
        }
    }
}
