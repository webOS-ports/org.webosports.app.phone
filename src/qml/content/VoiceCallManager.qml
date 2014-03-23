/*
  A dummy module until we wire this in to the backend
 */

import QtQuick 2.0


QtObject{

    property VoiceCall call: VoiceCall{}
    property VoiceCall activeVoiceCall: null

    property string audioMode: ""


    function onAudioModeChanged() {
        console.log("audioMode: " + audioMode)
    }

    function startDtmfTone(key) {
        console.log("Dial Tone for key: " + key)
    }

    function stopDtmfTone() {
        console.log("Stop DialTone")
    }

    function dial(providerId, msisdn){
       console.log("Dialing  " + msisdn)
       activeVoiceCall = call
       call.lineId = msisdn
    }

    function setMuteMicrophone(mute){
        if(mute){
            console.log("Muting mic")
        } else{
            console.log("Unmuting mic")
        }


    }

}

