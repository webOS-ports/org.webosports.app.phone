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
 *   answering or ending it stops the ring;
 * - a stopped ring stays stopped, also when the player is asked to play
 *   again behind the stop, as Qt's GStreamer backend does for a looping
 *   player whose end-of-stream message was still waiting when the call was
 *   answered.
 *
 * Nothing is heard: the sound files do not exist, and the one file that is
 * played, to have a player that really plays, is half a second of silence.
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

        /*
         * A ring that is stopped stays stopped.
         *
         * The calls below go through the wrapper's call list, as the nemo
         * manager's do, and the player plays a real (silent) file. What the
         * device did on 31 October at 12:53:07: the call was answered on the
         * screen 13.5 s into a 13.1 s ringtone. The end-of-stream message of
         * the first loop was waiting when stop() ran, Qt 6.12's GStreamer
         * backend answered it with gst_play_play() - it only asks whether a
         * loop is left (QPlatformMediaPlayer::doLoop: seekable and loops left)
         * - and the ringtone played on, on the default sink, through the call
         * and after it. lateEndOfStream() does what that message does.
         */

        readonly property url silence: Qt.resolvedUrl("assets/tst_ringmanager-silence.wav")

        Component {
            id: listedCallComponent
            Item {
                property string handlerId: "/calls/0"
                property string providerId: "ril_0"
                property int status: VoiceCall.STATUS_INCOMING
                property string statusText: ""
                property string lineId: "+31600000000"
                property date startedAt: new Date()
                property int duration: 0
                property bool isIncoming: true
                property bool isEmergency: false
                property bool isMultiparty: false
                property bool isForwarded: false
                property bool isRemoteHeld: false
                function answer() { status = VoiceCall.STATUS_ACTIVE; }
                function hangup() { status = VoiceCall.STATUS_DISCONNECTED; }
            }
        }

        Component {
            id: headsetButtonComponent
            HeadsetCallButton {
                _bus: QtObject {
                    function subscribe(p) { return { cancel: function () {} }; }
                }
            }
        }

        function makePlayingRing() {
            var ring = makeRing();
            ring.ringtonePath = silence;
            ring.onCallSoundPath = silence;
            return ring;
        }

        property int _nextHandler: 0

        /// A call the manager reports, as the nemo manager adds one to its list.
        function listCall(status) {
            var call = listedCallComponent.createObject(root, {
                handlerId: "/calls/tst-" + (++_nextHandler),
                status: status
            });
            wrapper.manager.voiceCalls.append(call);
            return call;
        }

        /// The call goes from the manager's list without a last state, as
        /// when ofonod dies under it.
        function dropFromList(call) {
            var calls = wrapper.manager.voiceCalls;
            for (var i = 0; i < calls.count; i++) {
                if (calls.get(i) === call) {
                    calls.remove(i);
                    return;
                }
            }
            fail("the call was not in the list");
        }

        /// Arms the end-of-stream message that is still waiting when the ring
        /// is stopped: the next time the player stops, it restarts itself as
        /// QGstreamerMediaPlayer does for EOS when doLoop() says a loop is left.
        function lateEndOfStream(player) {
            var armed = { done: false, restarted: false };
            var onState = function () {
                if (armed.done || player.playbackState !== MediaPlayer.StoppedState)
                    return;
                armed.done = true;
                player.playbackStateChanged.disconnect(onState);
                Qt.callLater(function () {
                    var loopLeft = player.loops === MediaPlayer.Infinite || player.loops > 1;
                    if (player.seekable && loopLeft && player.source.toString() !== "") {
                        armed.restarted = true;
                        player.play();
                    }
                });
            };
            player.playbackStateChanged.connect(onState);
            return armed;
        }

        function ringUntilPlaying(ring, call) {
            compare(ring.state, "ringing");
            tryCompare(playerOf(ring), "playbackState", MediaPlayer.PlayingState, 3000,
                       "the ring never played");
        }

        function staysSilent(ring, why) {
            var player = playerOf(ring);
            // Not a moment of playing, for long enough for the late
            // end-of-stream, the restart and two loops of the half-second
            // file.
            for (var t = 0; t < 12; t++) {
                compare(player.playbackState, MediaPlayer.StoppedState, why + " (" + t * 100 + " ms)");
                wait(100);
            }
            compare(player.playbackState, MediaPlayer.StoppedState, why);
            compare(ring.state, "default", why);
        }

        function answerBy(how, call) {
            switch (how) {
            case "screen":
                call.answer();      // IncomingCallPage, IncomingCallAlert
                break;
            case "wired button":
                compare(createTemporaryObject(headsetButtonComponent, root,
                                              { voiceCallManager: wrapper }).handleKey("playPause"),
                        "answer");
                break;
            case "bluetooth":
                // HFP answers in ofono: the app only sees the call go active.
                call.status = VoiceCall.STATUS_ACTIVE;
                break;
            }
            compare(call.status, VoiceCall.STATUS_ACTIVE);
        }

        function test_anAnsweredRingStaysStopped_data() {
            return [ { tag: "screen" }, { tag: "wired button" }, { tag: "bluetooth" } ];
        }

        function test_anAnsweredRingStaysStopped(data) {
            var ring = makePlayingRing();
            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            compare(wrapper.callCount, 1);

            lateEndOfStream(playerOf(ring));
            answerBy(data.tag, call);
            staysSilent(ring, "the ringtone plays on in the call");

            call.hangup();
            staysSilent(ring, "the ringtone plays on after the call");
        }

        function test_aRingThatStartsAgainIsStoppedAtOnce() {
            // Whatever starts the player while nothing rings - the late
            // end-of-stream or anything else - does not get to play.
            var ring = makePlayingRing();
            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            call.answer();
            compare(ring.state, "default");

            var player = playerOf(ring);
            player.source = silence;
            player.loops = MediaPlayer.Infinite;
            player.play();
            tryCompare(player, "playbackState", MediaPlayer.StoppedState, 1000,
                       "the ringtone played with no call ringing");
            staysSilent(ring, "the ringtone played with no call ringing");
            compare(player.audioOutput, null, "the ring kept its output");
        }

        function test_aStoppedRingLeavesNothingToLoopOver() {
            var ring = makePlayingRing();
            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            call.answer();
            var player = playerOf(ring);
            verify(player.loops !== MediaPlayer.Infinite && player.loops <= 1,
                   "loops left after the stop: " + player.loops);
            compare(player.source.toString(), "");
            compare(player.audioOutput, null);
        }

        function test_aRejectedRingStaysStopped() {
            var ring = makePlayingRing();
            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            lateEndOfStream(playerOf(ring));
            wrapper.reject();
            compare(call.status, VoiceCall.STATUS_DISCONNECTED);
            staysSilent(ring, "the rejected call's ringtone plays on");
        }

        function test_aMissedRingStaysStopped() {
            var ring = makePlayingRing();
            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            lateEndOfStream(playerOf(ring));
            call.status = VoiceCall.STATUS_DISCONNECTED;     // the caller gave up
            staysSilent(ring, "the missed call's ringtone plays on");
            dropFromList(call);
            staysSilent(ring, "the missed call's ringtone plays on");
        }

        function test_aWaitingCallsToneStaysStoppedWhenAnswered() {
            var ring = makePlayingRing();
            var first = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, first);
            first.answer();
            compare(ring.state, "default");

            var second = listCall(VoiceCall.STATUS_WAITING);
            compare(ring.state, "callWaiting");
            var player = playerOf(ring);
            tryCompare(player, "playbackState", MediaPlayer.PlayingState, 3000);
            compare(player.loops, 2);
            lateEndOfStream(player);
            first.status = VoiceCall.STATUS_HELD;
            second.answer();
            staysSilent(ring, "the call-waiting tone plays on");
        }

        function test_aRingAfterOfonoWentStaysStoppedWhenAnswered() {
            // The day's sequence: a call up when ofonod died (12:46:11), its
            // row gone from the list without a last state, ofonod back, and
            // then the next call answered on the screen at the loop's end.
            var ring = makePlayingRing();
            var before = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, before);
            before.answer();
            compare(ring.state, "default");
            dropFromList(before);                       // ofonod SEGV
            compare(wrapper.callCount, 0);

            var call = listCall(VoiceCall.STATUS_INCOMING);
            ringUntilPlaying(ring, call);
            compare(wrapper.callCount, 1, "a call from before ofonod went is still counted");
            lateEndOfStream(playerOf(ring));
            call.answer();
            staysSilent(ring, "the ringtone plays on in the call");
            call.hangup();
            staysSilent(ring, "the ringtone plays on after the call");
            dropFromList(call);
            staysSilent(ring, "the ringtone plays on after the call");
        }

        function test_theNextCallRingsAgain() {
            // Stopping for good does not stop the next ring.
            var ring = makePlayingRing();
            for (var r = 0; r < 3; r++) {
                var call = listCall(VoiceCall.STATUS_INCOMING);
                ringUntilPlaying(ring, call);
                compare(playerOf(ring).loops, MediaPlayer.Infinite);
                compare(playerOf(ring).source, silence);
                verify(playerOf(ring).audioOutput !== null, "ring " + (r + 1) + " has no output");
                wait(700);   // past the end of the file: the loop goes on
                compare(playerOf(ring).playbackState, MediaPlayer.PlayingState,
                        "ring " + (r + 1) + " did not loop");
                call.answer();
                staysSilent(ring, "ring " + (r + 1) + " plays on");
                call.hangup();
                dropFromList(call);
            }
        }
    }
}
