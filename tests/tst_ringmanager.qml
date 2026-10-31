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

/**
 * Where the ringtone plays.
 *
 * - every ring gets an audio output of its own, and the one of the ring
 *   before goes: Qt's GStreamer backend plays a source after a stop() on
 *   the default sink whatever the old output names, and the audio policy
 *   only knows a ringtone by the "pringtones" sink it plays on;
 * - the sink is found by its name: a device's id is a QByteArray, an
 *   ArrayBuffer in QML, whose text has to be compared;
 * - with no such sink (this desktop) the output is the default one;
 * - an incoming call rings, a waiting one plays the call-waiting tone, and
 *   answering or ending it stops the ring.
 *
 * Nothing is heard: the sound files do not exist.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "RingManager"
        when: windowShown

        Component {
            id: callComponent
            QtObject {
                property string handlerId: "ring-1"
                property int status: VoiceCall.STATUS_INCOMING
            }
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: ringComponent
            RingManager {}
        }

        property var wrapper: null

        function makeRing() {
            wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            var ring = createTemporaryObject(ringComponent, root, { voiceCallManager: wrapper });
            verify(ring !== null, "the ring manager did not load");
            // Silent whatever the preferences say.
            ring.ringtonePath = "file:///nonexistent/tst_ringmanager-ring.mp3";
            ring.onCallSoundPath = "file:///nonexistent/tst_ringmanager-wait.wav";
            return ring;
        }

        function playerOf(ring) {
            for (var i = 0; i < ring.resources.length; i++) {
                var o = ring.resources[i];
                if (o && o.hasOwnProperty("playbackState") && o.hasOwnProperty("audioOutput"))
                    return o;
            }
            return null;
        }

        function devicesOf(ring) {
            for (var i = 0; i < ring.resources.length; i++) {
                var o = ring.resources[i];
                if (o && o.hasOwnProperty("audioOutputs") && o.hasOwnProperty("defaultAudioOutput"))
                    return o;
            }
            return null;
        }

        function test_everyRingHasAnOutputOfItsOwn() {
            var ring = makeRing();
            var player = playerOf(ring);
            verify(player !== null, "no MediaPlayer in the RingManager");

            ring.state = "ringing";
            var first = player.audioOutput;
            verify(first !== null, "the first ring has no output");

            ring.state = "default";
            ring.state = "ringing";
            var second = player.audioOutput;
            verify(second !== null, "the second ring has no output");
            verify(second !== first, "the second ring kept the first ring's output");

            ring.state = "default";
            ring.state = "callWaiting";
            verify(player.audioOutput !== second, "call waiting kept the ring's output");
        }

        function test_theOutputOfTheRingBeforeGoes() {
            var ring = makeRing();
            var player = playerOf(ring);
            ring.state = "ringing";
            var first = player.audioOutput;
            var gone = false;
            first.Component.destruction.connect(function () { gone = true; });
            ring.state = "default";
            ring.state = "ringing";
            tryVerify(function () { return gone; }, 1000, "the first ring's output was left behind");
        }

        function test_onlyTheLastRingsOutputIsLeft() {
            var ring = makeRing();
            var player = playerOf(ring);
            var outputs = [];
            var gone = [];
            for (var r = 0; r < 5; r++) {
                ring.state = "default";
                ring.state = r % 2 ? "callWaiting" : "ringing";
                var out = player.audioOutput;
                verify(out !== null, "ring " + (r + 1) + " has no output");
                outputs.push(out);
                gone.push(false);
                (function (i) {
                    out.Component.destruction.connect(function () { gone[i] = true; });
                })(r);
            }
            // The outputs of the rings before go, and going does not take
            // the last ring's away.
            tryVerify(function () { return gone[0] && gone[1] && gone[2] && gone[3]; }, 1000,
                      "an output of an earlier ring was left behind: " + JSON.stringify(gone));
            wait(50);
            verify(!gone[4], "the last ring's output went");
            verify(player.audioOutput === outputs[4], "an old output took the last ring's away");
        }

        function test_closingAfterManyRings() {
            // A ring manager that rang a few times closes cleanly: no output
            // left with a callback into a player already gone.
            var ring = makeRing();
            for (var r = 0; r < 4; r++) {
                ring.state = "default";
                ring.state = "ringing";
            }
            ring.destroy();
            wait(50);
            verify(true);
        }

        function test_theRingtoneSinkIsPringtones() {
            // module-palm-policy's ringtone class, which audiod rings on the
            // loudspeaker
            compare(makeRing().ringtoneSinkName, "pringtones");
        }

        function test_aSinkIsFoundByItsName() {
            // A real device's id is a QByteArray (an ArrayBuffer in QML): the
            // lookup has to match its text, or no ring ever finds pringtones.
            var ring = makeRing();
            var devices = devicesOf(ring);
            var outputs = devices.audioOutputs;
            if (outputs.length === 0)
                skip("this machine has no audio outputs");
            for (var i = 0; i < outputs.length; i++) {
                var name = outputs[i].id.toString();
                var found = ring._audioOutputNamed(name);
                verify(found !== null, "no output found for " + name);
                compare(found.id.toString(), name);
            }
            compare(ring._audioOutputNamed("tst_ringmanager-no-such-sink"), null);
        }

        function test_aRingPlaysOnTheSinkItFinds() {
            // With the ringtone sink named after a real output of this
            // machine, the ring's output is that device, not the default.
            var ring = makeRing();
            var devices = devicesOf(ring);
            var outputs = devices.audioOutputs;
            var other = null;
            for (var i = 0; i < outputs.length; i++) {
                if (!outputs[i].isDefault) {
                    other = outputs[i];
                    break;
                }
            }
            if (other === null)
                skip("this machine has no audio output besides the default one");
            ring.ringtoneSinkName = other.id.toString();
            ring.state = "ringing";
            compare(playerOf(ring).audioOutput.device.id.toString(), other.id.toString());
        }

        function test_noRingtoneSinkMeansTheDefaultOutput() {
            var ring = makeRing();
            var devices = devicesOf(ring);
            var outputs = devices.audioOutputs;
            for (var i = 0; i < outputs.length; i++) {
                if (outputs[i].id.toString() === "pringtones")
                    skip("this machine has a pringtones sink");
            }
            compare(ring._ringtoneSink(), null);
            ring.state = "ringing";
            compare(playerOf(ring).audioOutput.device.id, devices.defaultAudioOutput.id);
        }

        function test_anIncomingCallRingsAndAnsweringStopsIt() {
            var ring = makeRing();
            var call = createTemporaryObject(callComponent, root);
            wrapper.incomingCall(call);
            compare(ring.state, "ringing");
            compare(playerOf(ring).loops, MediaPlayer.Infinite);
            compare(playerOf(ring).source.toString(), ring.ringtonePath);

            call.status = VoiceCall.STATUS_ACTIVE;
            wrapper.activeCall(call);
            compare(ring.state, "default");
        }

        function test_aWaitingCallGetsTheCallWaitingTone() {
            var ring = makeRing();
            var call = createTemporaryObject(callComponent, root,
                                             { status: VoiceCall.STATUS_WAITING });
            wrapper.incomingCall(call);
            compare(ring.state, "callWaiting");
            compare(playerOf(ring).loops, 2);
            compare(playerOf(ring).source.toString(), ring.onCallSoundPath);
        }

        function test_aCallThatEndsStopsTheRing() {
            var ring = makeRing();
            var call = createTemporaryObject(callComponent, root);
            wrapper.incomingCall(call);
            compare(ring.state, "ringing");
            wrapper.endingCall(call);
            compare(ring.state, "default");
            compare(playerOf(ring).playbackState, MediaPlayer.StoppedState);

            wrapper.incomingCall(call);
            compare(ring.state, "ringing");
            wrapper.resetCall(call);
            compare(ring.state, "default");
        }
    }
}
