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
