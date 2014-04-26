/*
  A dummy module until we wire this in to the backend
 */

import QtQuick 2.0


QtObject{

    property VoiceCall call: VoiceCall{}
    property VoiceCall activeVoiceCall: null

    property string audioMode: "earpiece"
    property bool isAudioRouted: false
    property bool isMicrophoneMuted: false
    property bool isSpeakerMuted: false

    function startDtmfTone(key) {
        console.log("Dial Tone for key: " + key)
    }

    function stopDtmfTone() {
        console.log("Stop DialTone")
    }

    function dial(providerId, msisdn){
       console.log("Dialing  " + msisdn)
        call.lineId = msisdn
       activeVoiceCall = call
       call.lineId = msisdn
    }

    function setMuteMicrophone(mute){
       isMicrophoneMuted = mute;
       console.log(mute ? "Mic mute On": "Mic mute Off");
    }

    function setMuteSpeaker(mute) {
        isSpeakerMuted = mute;
        console.log(mute? "Speaker mute On": "Speaker mute Off")
    }

    function setAudioMode(mode) {
        audioMode = mode;
        console.log("audioMode: " + audioMode)
    }

}

