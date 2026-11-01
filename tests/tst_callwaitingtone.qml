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
import QtMultimedia 6.3

import org.nemomobile.voicecall 1.0

import "../qml/services"
import "fakes"

/**
 * The tone of a second call arriving during a call.
 *
 * The old default named a file of the legacy app that is not on any LuneOS
 * device, so the second call was silent.
 *
 * - the default is a file shipped with the app, found wherever the app runs
 *   from, and a media player opens it;
 * - it has the shape loops = 2 counts on: 1.7 s with silence at its end, and
 *   it starts and ends on silence, so looping does not click;
 * - a second call plays it, twice, on pfeedback, a first call rings on
 *   pringtones;
 * - the preference overrides it, and a preference naming a file that does not
 *   exist falls back to it.
 */
Item {
    id: root
    width: 480
    height: 800

    MediaPlayer { id: probe }

    TestCase {
        name: "CallWaitingTone"
        when: windowShown

        Component {
            id: networkComponent
            FakeCallNetwork {}
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: ringComponent
            RingManager {
                property var asked: []
                // Every sink looked for, none found: this desktop's default.
                function _audioOutputNamed(name) {
                    asked.push(name);
                    return null;
                }
            }
        }

        property var network: null
        property var wrapper: null
        property var ring: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            ring = createTemporaryObject(ringComponent, root, { voiceCallManager: wrapper });
            verify(ring !== null, "the ring manager did not load");
            ring.asked = [];
            ring.ringtonePath = "file:///nonexistent/tst_callwaitingtone-ring.mp3";
        }

        function cleanup() {
            if (ring)
                ring.state = "default";
            probe.source = "";
        }

        function playerOf(item) {
            for (var i = 0; i < item.resources.length; i++) {
                var o = item.resources[i];
                if (o && o.hasOwnProperty("playbackState") && o.hasOwnProperty("audioOutput"))
                    return o;
            }
            return null;
        }

        function read(url) {
            var request = new XMLHttpRequest();
            request.open("GET", url, false);
            request.responseType = "arraybuffer";
            request.send();
            return request.response;
        }

        function test_theDefaultIsAFileOfTheApp() {
            var url = ring.defaultOnCallSound;
            verify(url.indexOf("file:///") === 0, url);
            verify(url.indexOf("/qml/assets/") > 0, "not in the app's assets: " + url);
            verify(url.indexOf("com.palm.app.phone") < 0, "still the legacy app's file: " + url);
            compare(ring.onCallSoundPath, url);
            var bytes = read(url);
            verify(bytes !== null && bytes.byteLength > 44, "no such file: " + url);
        }

        function test_aPlayerOpensTheDefault() {
            probe.source = ring.defaultOnCallSound;
            tryVerify(function() { return probe.duration > 0; }, 5000, "the tone did not load");
            verify(probe.error === MediaPlayer.NoError, probe.errorString);
            verify(Math.abs(probe.duration - 1702) < 50, "duration " + probe.duration);
        }

        function test_theToneIsShapedForLooping() {
            var bytes = read(ring.defaultOnCallSound);
            var header = new DataView(bytes, 0, 44);
            compare(header.getUint16(20, true), 1, "not PCM");
            compare(header.getUint16(22, true), 2, "channels");
            compare(header.getUint32(24, true), 44100, "rate");
            compare(header.getUint16(34, true), 16, "bits");

            var samples = new Int16Array(bytes, 44);
            var seconds = samples.length / 2 / 44100;
            verify(Math.abs(seconds - 1.7) < 0.02, seconds + " s");

            // Silent for its last half: the pause between the two chimes.
            for (var i = samples.length / 2; i < samples.length; i++)
                compare(samples[i], 0, "sound in the tail at sample " + i);

            // Starts from nothing and has room over a live call: no clipping.
            compare(samples[0], 0);
            var peak = 0;
            for (var j = 0; j < samples.length; j++)
                peak = Math.max(peak, Math.abs(samples[j]));
            verify(peak > 3000, "next to silent, peak " + peak);
            verify(peak < 16384, "too loud to play over a call, peak " + peak);
        }

        function test_aSecondCallPlaysTheToneTwiceOnTheFeedbackSink() {
            var player = playerOf(ring);
            network.ring("0600000001");
            compare(ring.state, "ringing");
            compare(player.loops, MediaPlayer.Infinite);
            compare(ring.asked[ring.asked.length - 1], "pringtones");

            wrapper.answer();
            compare(ring.state, "default");

            network.wait("0600000002");
            compare(ring.state, "callWaiting");
            compare(player.source.toString(), ring.defaultOnCallSound);
            compare(player.loops, 2);
            compare(ring.asked[ring.asked.length - 1], "pfeedback");
        }

        function test_thePreferenceOverridesTheDefault() {
            var player = playerOf(ring);
            var other = Qt.resolvedUrl("../qml/assets/ringtone_buzz.wav");
            ring._getPreferencesSuccess({ phoneIncomingCallOnCallSound: other });
            compare(ring.onCallSoundPath, other.toString());

            ring.state = "callWaiting";
            compare(player.source.toString(), other.toString());
            wait(300);
            compare(player.source.toString(), other.toString(), "fell back from a good file");
        }

        function test_aPreferenceNamingNoFileFallsBack() {
            var player = playerOf(ring);
            ignoreWarning(/using the default call-waiting tone/);
            ring._getPreferencesSuccess({
                phoneIncomingCallOnCallSound: "/nonexistent/tst_callwaitingtone-wait.wav"
            });
            ring.state = "callWaiting";
            tryCompare(player, "source", Qt.resolvedUrl(ring.defaultOnCallSound), 5000);
            compare(player.loops, 2);
            compare(ring.asked[ring.asked.length - 1], "pfeedback");
            tryVerify(function() { return player.playbackState === MediaPlayer.PlayingState; }, 5000,
                      "the fallback does not play");
        }

        function test_noFallbackOnceTheCallIsAnswered() {
            var player = playerOf(ring);
            ring.onCallSoundPath = "/nonexistent/tst_callwaitingtone-wait.wav";
            ring.state = "callWaiting";
            ring.state = "default";
            wait(300);
            verify(player.source.toString() !== ring.defaultOnCallSound, "played after the ring ended");
            verify(player.playbackState !== MediaPlayer.PlayingState);
        }

        function test_aRingThatFailsDoesNotPlayTheTone() {
            var player = playerOf(ring);
            ring.state = "ringing";
            wait(300);
            verify(player.source.toString() !== ring.defaultOnCallSound);
        }
    }
}
