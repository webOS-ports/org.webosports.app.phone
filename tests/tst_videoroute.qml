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

/**
 * A call with video, as Android's Telecom and InCallUI treat one:
 *
 * - it goes to the speaker once it is placed or answered, or once a voice
 *   call turns into video - unless a wired headset or Bluetooth is there;
 * - once per call: a route the user picks afterwards stays;
 * - the proximity sensor stays off for it, even on the earpiece, while a
 *   voice call on the earpiece still blanks the screen.
 */
Item {
    id: root

    TestCase {
        name: "VideoRoute"

        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: routesComponent
            AudioRouteManager {}
        }
        Component {
            id: proximityComponent
            ProximityManager {}
        }
        Component {
            id: callComponent
            QtObject {
                property string handlerId: ""
                property string providerId: "com.palm.teams"
                property string lineId: "8:someone"
                property int status: VoiceCall.STATUS_NULL
                property bool isIncoming: false
                property bool isMultiparty: false
                property bool isVideo: false
            }
        }

        function status(wrapper, fields) {
            var s = { returnValue: true, speakerMode: false, micMute: false,
                      headset: false, bluetoothAudio: false,
                      bluetoothCall: false, bluetoothCallActive: false };
            for (var k in fields)
                s[k] = fields[k];
            wrapper.__audioStatus({ payload: JSON.stringify(s) });
        }

        function make(audio) {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            status(wrapper, audio || {});
            var routes = createTemporaryObject(routesComponent, root, { voiceCallManager: wrapper });
            verify(routes !== null, "the route manager did not load");
            var o = { wrapper: wrapper, routes: routes, asked: [] };
            routes.routeRequested.connect(function(route) { o.asked.push(route); });
            return o;
        }

        function call(handlerId, callStatus, video) {
            var c = createTemporaryObject(callComponent, root,
                                          { handlerId: handlerId, status: callStatus, isVideo: video });
            verify(c !== null, "the call did not load");
            return c;
        }

        // Stands in for a transport listing its calls.
        function listCalls(wrapper, calls) {
            wrapper.synergyTransports = { "test": { calls: calls } };
            wrapper.callsRevision = wrapper.callsRevision + 1;
        }

        // What PhoneWindow does as a call goes live.
        function goLive(o, c) {
            c.status = VoiceCall.STATUS_ACTIVE;
            o.routes.applyDefaultRoute();
        }

        function test_aPlacedVideoCallGoesToTheSpeaker() {
            var o = make();
            var c = call("v-1", VoiceCall.STATUS_DIALING, true);
            listCalls(o.wrapper, [c]);
            verify(o.routes.videoCallActive);
            compare(o.asked, ["ihf"]);
            goLive(o, c);
            // Going live does not ask again, or put it back on the earpiece.
            compare(o.asked, ["ihf"]);
        }

        function test_aRingingVideoCallWaitsToBeAnswered() {
            var o = make();
            var c = call("v-2", VoiceCall.STATUS_INCOMING, true);
            c.isIncoming = true;
            listCalls(o.wrapper, [c]);
            compare(o.asked, []);
            goLive(o, c);
            compare(o.asked, ["ihf"]);
        }

        function test_aVoiceCallKeepsTheDefaultRoute() {
            var o = make();
            var c = call("a-1", VoiceCall.STATUS_INCOMING, false);
            listCalls(o.wrapper, [c]);
            goLive(o, c);
            verify(!o.routes.videoCallActive);
            compare(o.asked, ["default"]);
        }

        function test_aVoiceCallTurnedIntoVideoGoesToTheSpeaker() {
            var o = make();
            var c = call("u-1", VoiceCall.STATUS_INCOMING, false);
            listCalls(o.wrapper, [c]);
            goLive(o, c);
            c.isVideo = true;
            compare(o.asked, ["default", "ihf"]);
        }

        function test_aHeadsetOrBluetoothKeepsTheAudio_data() {
            return [
                { tag: "wired headset", audio: { headset: true } },
                { tag: "bluetooth",     audio: { bluetoothCall: true } }
            ];
        }
        function test_aHeadsetOrBluetoothKeepsTheAudio(data) {
            var o = make(data.audio);
            var c = call("h-1", VoiceCall.STATUS_INCOMING, true);
            listCalls(o.wrapper, [c]);
            goLive(o, c);
            compare(o.asked, ["default"]);
        }

        function test_theUsersPickStaysForTheCall() {
            var o = make();
            var c = call("p-1", VoiceCall.STATUS_INCOMING, true);
            listCalls(o.wrapper, [c]);
            goLive(o, c);
            status(o.wrapper, { speakerMode: true });
            o.routes.toggleSpeaker();                       // back to the earpiece
            status(o.wrapper, {});
            // The call going voice and video again, or live again, leaves it.
            c.isVideo = false;
            c.isVideo = true;
            o.routes.applyDefaultRoute();
            compare(o.asked, ["ihf", "default"]);
        }

        function test_theNextVideoCallGoesToTheSpeakerAgain() {
            var o = make();
            var c = call("n-1", VoiceCall.STATUS_INCOMING, true);
            listCalls(o.wrapper, [c]);
            goLive(o, c);
            listCalls(o.wrapper, []);
            var d = call("n-2", VoiceCall.STATUS_INCOMING, true);
            listCalls(o.wrapper, [d]);
            goLive(o, d);
            compare(o.asked, ["ihf", "ihf"]);
        }

        function test_proximity_data() {
            return [
                { tag: "voice on the earpiece", video: false, audio: {},                  on: true },
                { tag: "voice on the speaker",  video: false, audio: { speakerMode: true }, on: false },
                { tag: "video on the earpiece", video: true,  audio: {},                  on: false },
                { tag: "video on the speaker",  video: true,  audio: { speakerMode: true }, on: false }
            ];
        }
        function test_proximity(data) {
            // A headset, so nothing moves the audio by itself here.
            var o = make({ headset: true });
            var prox = createTemporaryObject(proximityComponent, root,
                                             { voiceCallManager: o.wrapper, audioRouteManager: o.routes });
            verify(prox !== null, "the proximity manager did not load");
            var c = call("x-1", VoiceCall.STATUS_ACTIVE, data.video);
            listCalls(o.wrapper, [c]);
            var audio = { headset: false };
            for (var k in data.audio)
                audio[k] = data.audio[k];
            status(o.wrapper, audio);
            compare(prox.shouldEnable, data.on);
            listCalls(o.wrapper, []);
            compare(prox.shouldEnable, false);
        }
    }
}
