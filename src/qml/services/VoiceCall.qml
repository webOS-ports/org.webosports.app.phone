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

Item {

    property string lineId: ""
    property string statusText: ""
    property int duration: 0;


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
        statusText = "active"

    }

    function hangup(){
        console.log("hangup call")
        statusText = "inactive"

        main.manager.activeVoiceCall = null
        duration = 0
        call.lineId = ""

    }

    function hold(){
        console.log("call on hold")
    }



}
