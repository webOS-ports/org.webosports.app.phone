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
 */
Item {
    id: ringMgrItem
    property VoiceCallMgrWrapper voiceCallManager

    readonly property string defaultRingtone: "/usr/palm/sounds/ringtone.mp3"
    readonly property string defaultOnCallSound:
        "/usr/palm/applications/com.palm.app.phone/sounds/incoming-call-active.wav"

    property string ringtonePath: defaultRingtone
    property string onCallSoundPath: defaultOnCallSound

    state: "default"
    states: [
        State {
            name: "default"
            StateChangeScript { script: ringtone.stop(); }
        },
        State {
            name: "ringing"
            StateChangeScript {
                script: {
                    ringMgrItem._play(ringMgrItem.ringtonePath, MediaPlayer.Infinite);
                }
            }
        },
        State {
            name: "callWaiting"
            StateChangeScript {
                script: {
                    ringMgrItem._play(ringMgrItem.onCallSoundPath, 2);
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

    function _play(source, loops) {
        var previous = ringtone.audioOutput;
        var sink = _ringtoneSink();

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

    Connections {
        target: voiceCallManager

        function onIncomingCall(voiceCall) {
            // Another call already up means this is call waiting, not a
            // ringing phone. Not activeVoiceCall: the manager makes the call
            // that is ringing its active call, so that would make every call
            // a waiting one, and the phone would never ring.
            var alreadyOnACall = voiceCall.status === VoiceCall.STATUS_WAITING ||
                                 voiceCallManager.callCount > 1;

            ringMgrItem.state = alreadyOnACall ? "callWaiting" : "ringing";
        }

        function onActiveCall(voiceCall) {
            ringMgrItem.state = "default";
        }

        function onEndingCall(voiceCall) {
            ringMgrItem.state = "default";
        }

        function onResetCall(voiceCall) {
            ringMgrItem.state = "default";
        }
    }

    SystemPreferences {
        clientName: "org.webosports.app.phone"
        keys: ["ringtone", "phoneIncomingCallOnCallSound"]
        onUpdated: (response) => _getPreferencesSuccess(response)
        onError: (message) => _getPreferencesFailure(message)
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
