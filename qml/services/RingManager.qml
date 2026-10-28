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
                    ringtone.source = ringMgrItem.ringtonePath;
                    ringtone.loops = MediaPlayer.Infinite;
                    ringtone.play();
                }
            }
        },
        State {
            name: "callWaiting"
            StateChangeScript {
                script: {
                    ringtone.source = ringMgrItem.onCallSoundPath;
                    ringtone.loops = 2;
                    ringtone.play();
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
         audioOutput: AudioOutput { id: ringtoneOutput }
    }

    // Ring through the "pringtones" sink rather than the default one: the
    // audio policy only knows a stream is a ringtone by the sink it is played
    // on, and gives it the ringtone volume and the loudspeaker as well as the
    // headphones. Without that sink (a desktop) the default output is kept.
    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: ringMgrItem._useRingtoneSink()
    }

    Component.onCompleted: _useRingtoneSink()

    function _useRingtoneSink() {
        var outputs = mediaDevices.audioOutputs;
        for (var i = 0; i < outputs.length; i++) {
            if (outputs[i].id == "pringtones") {
                ringtoneOutput.device = outputs[i];
                return;
            }
        }
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
