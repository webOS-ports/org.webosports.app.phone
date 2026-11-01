/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

          .,
.      _,'f----.._
|\ ,-'"/  |     ,'
|,_  ,--.      /
/,-. ,'`.     (_
f  o|  o|__     "`-.
,-._.,--'_ `.   _.,-`
`"' ___.,'` j,-'
  `-.__.,--'

 */

import QtQuick 2.0
import QtMultimedia 6.3

import LuneOS.System 1.0
import org.nemomobile.voicecall 1.0

/**
 * Plays the ringtone for an incoming call.
 *
 * A call arriving while another one is up is not announced with the full
 * ringtone but with the short call-waiting tone, as the legacy app did through
 * the phoneIncomingCallOnCallSound preference. Ringing over a conversation in
 * progress is exactly what call waiting is meant to avoid.
 *
 * The tone plays on the "pfeedback" sink, as the keypad's beep in a call does,
 * not on "pringtones". Both end up on the droid card's primary output, which
 * on the Mediatek HAL goes to the modem as background sound: in the call's
 * route, not to the far end. But a stream on pringtones plays at the ringtone
 * volume, which is set for a phone ringing on the loudspeaker (30 dB down at
 * 26 of 100), it is muted with the ringtone, and it tells audiod that the
 * phone is ringing. Legacy kept this tone off the ringtones class as well.
 */
Item {
    id: ringMgrItem
    property VoiceCallMgrWrapper voiceCallManager

    readonly property string defaultRingtone: "/usr/palm/sounds/ringtone.mp3"
    // Synthesised for this app, modelled on what legacy played here.
    readonly property string defaultOnCallSound: Qt.resolvedUrl("../assets/call-waiting.wav")
    readonly property string onCallSinkName: "pfeedback"

    property string ringtonePath: defaultRingtone
    property string onCallSoundPath: defaultOnCallSound

    state: "default"
    states: [
        State {
            name: "default"
            StateChangeScript { script: ringMgrItem._stop(); }
        },
        State {
            name: "ringing"
            StateChangeScript {
                script: {
                    ringMgrItem._play(ringMgrItem.ringtonePath, MediaPlayer.Infinite,
                                    ringMgrItem._ringtoneSink());
                }
            }
        },
        State {
            name: "callWaiting"
            StateChangeScript {
                script: {
                    ringMgrItem._play(ringMgrItem.onCallSoundPath, 2,
                                    ringMgrItem._audioOutputNamed(ringMgrItem.onCallSinkName));
                }
            }
        }
    ]

    // No source until something needs to ring: binding it up front makes the
    // player open the file at startup, which fails noisily anywhere the system
    // sounds are not installed. The states below set it before playing.
    MediaPlayer {
         id: ringtone
         loops: MediaPlayer.Infinite

         // Nothing rings: whatever started the player again is overruled.
         onPlaybackStateChanged: {
             if (playbackState === MediaPlayer.PlayingState && ringMgrItem.state === "default") {
                 console.warn("phone: the ringtone started again with no call ringing, stopping it");
                 ringMgrItem._stop();
             }
         }

         onErrorOccurred: ringMgrItem._onCallSoundFailed()
    }

    // Ring through the "pringtones" sink rather than the default one: the
    // audio policy only knows a stream is a ringtone by the sink it is played
    // on, and gives it the ringtone volume and the loudspeaker as well as the
    // headphones. Without that sink (a desktop) the default output is kept.
    //
    // Every ring gets a fresh output. Once the player has been stopped, Qt's
    // GStreamer backend plays the next source on the default sink, whatever
    // device the old output still names, so only the first ring would reach
    // pringtones. Looking the sink up again each time also finds it after a
    // PulseAudio restart.
    Component {
        id: ringtoneOutput
        AudioOutput {}
    }

    MediaDevices {
        id: mediaDevices
    }

    property string ringtoneSinkName: "pringtones"

    function _ringtoneSink() {
        return _audioOutputNamed(ringtoneSinkName);
    }

    // An audio device's id is a QByteArray, which QML hands out as an
    // ArrayBuffer: compare its text. "id === name" is never true, and "=="
    // only matches through the ArrayBuffer's toString().
    function _audioOutputNamed(name) {
        var outputs = mediaDevices.audioOutputs;
        for (var i = 0; i < outputs.length; i++) {
            if (outputs[i].id.toString() === name)
                return outputs[i];
        }
        return null;
    }

    function _play(source, loops, sink) {
        var previous = ringtone.audioOutput;

        // Let go of the old output before taking the new one. Going straight
        // from one output to another, Qt 6.12's QMediaPlayer::setAudioOutput()
        // runs the old output's disconnect callback, which sets the player's
        // output to null under it: the property then reads null although the
        // new output plays, the next ring cannot find that output to drop it,
        // and the one left over keeps a callback into the player that takes a
        // later ring's output away when it goes, or runs on a player already
        // gone when the app closes.
        ringtone.audioOutput = null;
        ringtone.audioOutput = ringtoneOutput.createObject(ringMgrItem,
                                                           sink ? { device: sink } : {});
        if (previous)
            previous.destroy();

        ringtone.source = source;
        ringtone.loops = loops;
        ringtone.play();
    }

    // Stops the ring so that it stays stopped. stop() alone is not enough
    // with a looping player: Qt 6.12's GStreamer backend answers an
    // end-of-stream message with gst_play_play() whenever loops are left
    // (QGstreamerMediaPlayer::processBusMessageApplication, doLoop()),
    // without asking whether the player has been stopped since. A ring
    // answered just as the ringtone reached its end had that message waiting
    // behind the stop(), so the ringtone started over - on the default sink,
    // through the call and after it, until the app went.
    //
    // So: no loops left, then the stop, then no source (an end-of-stream
    // still to come finds nothing seekable to loop over), then no output (if
    // the pipeline plays all the same, it plays into a fakesink). Each ring
    // sets all of it up again.
    function _stop() {
        ringtone.loops = 1;
        ringtone.stop();
        ringtone.source = "";
        var output = ringtone.audioOutput;
        if (output) {
            ringtone.audioOutput = null;
            output.destroy();
        }
        return null;
    }

    // A sound picked in the preference that cannot be played (the legacy
    // default names a file that does not exist here) must not leave a second
    // call silent. Later, as the player is still inside its error.
    function _onCallSoundFailed() {
        Qt.callLater(_playDefaultOnCallSound);
    }

    function _playDefaultOnCallSound() {
        if (state !== "callWaiting" || ringtone.source.toString() === defaultOnCallSound)
            return;
        console.warn("phone: cannot play " + ringtone.source + ", using the default call-waiting tone");
        ringtone.source = defaultOnCallSound;
        ringtone.play();
    }

    function _silence() {
        ringMgrItem.state = "default";
        _stop();
    }

    Connections {
        target: ringMgrItem.voiceCallManager

        function onIncomingCall(voiceCall) {
            // Another call already up means this is call waiting, not a
            // ringing phone. Not activeVoiceCall: the manager makes the call
            // that is ringing its active call, so that would make every call
            // a waiting one, and the phone would never ring.
            var alreadyOnACall = voiceCall.status === VoiceCall.STATUS_WAITING ||
                                 ringMgrItem.voiceCallManager.callCount > 1;

            ringMgrItem.state = alreadyOnACall ? "callWaiting" : "ringing";
        }

        // Each of these stops the player itself as well: when the state is
        // "default" already, setting it again runs no StateChangeScript, and
        // a ring that started over behind it went on through the whole call.
        function onActiveCall(voiceCall) {
            ringMgrItem._silence();
        }

        function onEndingCall(voiceCall) {
            ringMgrItem._silence();
        }

        function onResetCall(voiceCall) {
            ringMgrItem._silence();
        }
    }

    SystemPreferences {
        clientName: "org.webosports.app.phone"
        keys: ["ringtone", "phoneIncomingCallOnCallSound"]
        onUpdated: (response) => ringMgrItem._getPreferencesSuccess(response)
        onError: (message) => ringMgrItem._getPreferencesFailure(message)
    }

    function _getPreferencesSuccess(response) {
        if (response.ringtone && response.ringtone.fullPath) {
            console.log("phone: set ringtone to: " + response.ringtone.fullPath);
            ringtonePath = response.ringtone.fullPath;
        }
        if (response.phoneIncomingCallOnCallSound) {
            onCallSoundPath = response.phoneIncomingCallOnCallSound;
        }
    }
    function _getPreferencesFailure(message) {
        ringtonePath = defaultRingtone;
        console.log("No ringtone found, default to : " + ringtonePath);
    }
}
