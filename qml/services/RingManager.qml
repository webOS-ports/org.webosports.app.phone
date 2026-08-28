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

import LuneOS.Service 1.0

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
         audioOutput: AudioOutput {}
    }

    Connections {
        target: voiceCallManager

        function onIncomingCall(voiceCall) {
            // Another call already up means this is call waiting, not a
            // ringing phone.
            var alreadyOnACall = voiceCallManager.callCount > 1 ||
                                 !!voiceCallManager.activeVoiceCall;

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

    Component.onCompleted: {
        __lunaNextLS2Service.subscribe("luna://com.palm.systemservice/getPreferences",
                                       JSON.stringify({ keys: ["ringtone", "phoneIncomingCallOnCallSound"],
                                                        subscribe: true }),
                                       _getPreferencesSuccess, _getPreferencesFailure)
    }
    LunaService {
        id: __lunaNextLS2Service
        name: "org.webosports.app.phone"
    }
    function _getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
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
