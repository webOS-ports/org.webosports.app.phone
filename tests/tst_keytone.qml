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

import "../qml/views"
import "../qml/services"
import "fakes"

/**
 * A key of a dialpad during a call: its tone goes to the network, and this
 * end hears a beep. The beep is audiod's, on the local feedback sink, and the
 * network must get the tone however that goes.
 *
 * - the call pad and the dialer behind it ask for the same thing, with
 *   feedbackOnly so that audiod does not send the tone a second time;
 * - Dialpad Feedback decides, not the call;
 * - a key without a tone, or a call on hold, stays silent;
 * - the network comes first and does not wait for the beep.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "KeyTone"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component {
            id: networkComponent
            FakeCallNetwork {}
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: pageComponent
            ActiveCallPage { width: 480; height: 800 }
        }
        Component {
            id: dialerComponent
            DialerPage { appTheme: theme; width: 480; height: 800 }
        }
        Component {
            id: playerComponent
            KeyTonePlayer {}
        }
        /// audiod, as far as the Phone app can tell. refuse answers every
        /// request with an error, as luna-service does when audiod is away.
        Component {
            id: audiodComponent
            QtObject {
                id: fakeAudiod
                property var network: null
                property var requests: []
                property bool refuse: false
                property int refused: 0
                function call(uri, payload, onResponse, onError) {
                    requests.push({ uri: uri, payload: JSON.parse(payload) });
                    network._send("beep");
                    if (refuse) {
                        onError("com.palm.audio is not running");
                        ++fakeAudiod.refused;
                    }
                }
            }
        }

        property var network: null
        property var wrapper: null
        property var audiod: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            verify(network !== null, "the fake network did not load");
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            verify(wrapper !== null, "the wrapper did not load");
            audiod = createTemporaryObject(audiodComponent, root, { network: network });
            verify(audiod !== null, "the fake audiod did not load");
        }

        function sent() { return network.commands.join(" "); }

        /// The call screen of an answered call, Dialpad Feedback as given.
        function callPage(feedback) {
            network.ring("0600000001");
            wrapper.answer();
            network.commands = [];
            var page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: wrapper.currentCall()
            });
            verify(page !== null, "the call screen did not load");
            page.keyTone.service = audiod;
            page.keyTone.feedback = feedback;
            return page;
        }

        function press(page, key) {
            var pad = findChild(page, "dtmfPad");
            verify(pad !== null, "no dialpad on the call screen");
            pad.sendKey(key);
        }

        function player(feedback) {
            var p = createTemporaryObject(playerComponent, root);
            p.service = audiod;
            p.feedback = feedback;
            return p;
        }

        function test_aKeyGoesToTheNetworkAndBeepsHere_data() {
            return [
                { tag: "1", key: Qt.Key_1, tone: "1" },
                { tag: "0", key: Qt.Key_0, tone: "0" },
                { tag: "9", key: Qt.Key_9, tone: "9" },
                { tag: "star", key: Qt.Key_Asterisk, tone: "*" },
                { tag: "hash", key: Qt.Key_NumberSign, tone: "#" }
            ];
        }

        function test_aKeyGoesToTheNetworkAndBeepsHere(data) {
            var page = callPage("vibrateSound");

            press(page, data.key);

            compare(sent(), "AT+VTS=" + data.tone + " beep");
            compare(audiod.requests.length, 1);
            compare(audiod.requests[0].uri, "luna://com.palm.audio/dtmf/playDTMF");
            compare(JSON.stringify(audiod.requests[0].payload),
                    JSON.stringify({ name: data.tone, feedbackOnly: true }));
        }

        function test_soundOnlyBeepsToo() {
            press(callPage("soundOnly"), Qt.Key_5);
            compare(sent(), "AT+VTS=5 beep");
        }

        function test_feedbackOffStillSendsTheTone_data() {
            return [
                { tag: "vibrate only", feedback: "vibrateOnly" },
                { tag: "none", feedback: "noFeedback" }
            ];
        }

        function test_feedbackOffStillSendsTheTone(data) {
            press(callPage(data.feedback), Qt.Key_5);

            compare(sent(), "AT+VTS=5");
            compare(audiod.requests.length, 0);
        }

        function test_anUnansweredBeepDoesNotStopTheNextKey() {
            var page = callPage("vibrateSound");
            audiod.refuse = true;

            press(page, Qt.Key_1);
            press(page, Qt.Key_2);

            compare(sent(), "AT+VTS=1 beep AT+VTS=2 beep");
            compare(audiod.refused, 2, "the error has to be dealt with, not thrown");
        }

        function test_aCallOnHoldDoesNotBeep() {
            var page = callPage("vibrateSound");
            wrapper.currentCall().hold(true);
            network.commands = [];

            press(page, Qt.Key_5);

            verify(sent().indexOf("beep") < 0, sent());
            compare(audiod.requests.length, 0);
        }

        function test_noCallNoBeep() {
            var page = callPage("vibrateSound");
            page.selectedCall = null;

            press(page, Qt.Key_5);

            compare(sent(), "");
        }

        function test_theDialerBehindACallAsksTheSame() {
            network.ring("0600000001");
            wrapper.answer();
            network.commands = [];
            var dialer = createTemporaryObject(dialerComponent, root, { voiceCallMgrWrapper: wrapper });
            verify(dialer !== null, "the dialer did not load");
            dialer.keyTone.service = audiod;
            dialer.keyTone.feedback = "vibrateSound";

            dialer.handleDialCharacter("5");

            compare(sent(), "AT+VTS=5 beep");
            compare(JSON.stringify(audiod.requests[0].payload),
                    JSON.stringify({ name: "5", feedbackOnly: true }));
            compare(dialer.number, "", "a key in a call is not a digit to dial");
        }

        function test_theDialerWithNoCallPlaysAnOrdinaryBeep() {
            var dialer = createTemporaryObject(dialerComponent, root, { voiceCallMgrWrapper: wrapper });
            verify(dialer !== null, "the dialer did not load");
            dialer.keyTone.service = audiod;
            dialer.keyTone.feedback = "soundOnly";

            dialer.handleDialCharacter("5");

            compare(JSON.stringify(audiod.requests[0].payload), JSON.stringify({ name: "5" }));
            compare(dialer.number, "5");
        }

        function test_onlyTheTwelveKeysHaveTones_data() {
            return [
                { tag: "plus", key: "+" },
                { tag: "letter", key: "a" },
                { tag: "nothing", key: "" },
                { tag: "two keys", key: "12" },
                { tag: "long press of 1", key: String.fromCharCode(Qt.Key_LaunchMail) }
            ];
        }

        function test_onlyTheTwelveKeysHaveTones(data) {
            player("vibrateSound").play(data.key, true);
            compare(audiod.requests.length, 0);
        }
    }
}
