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

Item {
    id: ringingMgrItem
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

    transitions: [
        Transition {
            from: "default"
            to: "ringing"

        }
    ]

    Audio {
         id: ringtone
         loops: Audio.Infinite
         source: "/usr/palm/sounds/ringtone.mp3"
    }

    Connections {
        target: voiceCallManager
        onIncomingCall: ringingMgrItem.state = "ringing";
        onActiveCall: ringingMgrItem.state = "default";
        onEndingCall: ringingMgrItem.state = "default";
        onResetCall: ringingMgrItem.state = "default";
    }
}
