/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtMultimedia 5.5

import LuneOS.Service 1.0

Item {
    id: ringMgrItem
    property VoiceCallMgrWrapper voiceCallManager

    state: "default"
    states: [
        State {
            name: "default"
            StateChangeScript { script: ringtone.stop();}
        },
        State {
            name: "ringing"
            StateChangeScript { script: ringtone.play();}
        }
    ]

    Audio {
         id: ringtone
         loops: Audio.Infinite
         source: "/usr/palm/sounds/ringtone.mp3"
    }

    Connections {
        target: voiceCallManager
        function onIncomingCall() { 
            ringMgrItem.state = "ringing";
        }
        
        function onActiveCall() {
            ringMgrItem.state = "default";
        }
        
        function onEndingCall() {
            ringMgrItem.state = "default";
        }
        
        function onResetCall() {
            ringMgrItem.state = "default";
        }
    }

    Component.onCompleted: {
        __lunaNextLS2Service.call("luna://com.palm.systemservice/getPreferences", JSON.stringify({ keys: ["ringtone"], subscribe: true }), _getPreferencesSuccess, _getPreferencesFailure)
    }
    LunaService {
        id: __lunaNextLS2Service
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
    function _getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
        if (response.ringtone) {
            console.log("phone: set ringtone to: " + response.ringtone.fullPath);
            ringtone.source = response.ringtone.fullPath;
        }
    }
    function _getPreferencesFailure(message) {
        ringtone.source = "/usr/palm/sounds/ringtone.mp3"
        console.log("No ringtone found, default to : " + ringtone.source);
    }
}
