/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import MeeGo.QOfono 0.2

Item {

    id: voiceCall

    property string statusText: ""
    property int duration: 0;

    property string voiceCallPath: ""

    property alias state: call.state
    property alias lineId: call.lineIdentification

    onVoiceCallPathChanged: {
        call.voiceCallPath = voiceCallPath
    }

    OfonoVoiceCall {
        id: call

        onStateChanged: {
            console.log("VoiceCall status changed to: ", call.state)
        }
    }

    Timer {
        id:callTimer
        interval:1000
        running:false
        repeat:true
        onTriggered:duration++
    }

    onStatusTextChanged: {

        if(statusText === "active") {
            callTimer.start()
        } else if(statusText === "inactive") {
            callTimer.stop()
        }

    }

    function answer(){
        console.log("answered call")
        call.answer()
        statusText = "active"
    }

    function hangup(){
        console.log("hangup call")
        if(statusText === "active"){
            console.log("voicecall->hangup()")
            call.hangup()
        }
        statusText = "inactive"
        duration = 0

    }

    function hold(){
        console.log("call on hold")
    }



}
