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

    id: voiceCallManager

    property VoiceCall voiceCall: VoiceCall{}
    property VoiceCall activeVoiceCall: null

    property string audioMode: "earpiece"
    property bool isAudioRouted: false
    property bool isMicrophoneMuted: false
    property bool isSpeakerMuted: false

    property string modemPath: null

    onModemPathChanged: {
        callManager.modemPath = voiceCallManager.modemPath
    }

    OfonoVoiceCallManager {
        id: callManager


        Component.onCompleted: {
            console.log("voiceCallManager init")
        }

        onCallAdded: {
            console.log("Call Added" , arguments[0])
            voiceCall.voiceCallPath = arguments[0]

            if(main.activationReason !== "dialing"){
                main.activationReason = "incoming"
            }
            voiceCall.resetCall()
            activeVoiceCall = voiceCall
        }

        onCallRemoved: {
            console.log("Call Removed",arguments[0])
            callManager.hangupAll()
            activeVoiceCall = null
        }

    }

    function startDtmfTone(key) {
        console.log("Dial Tone for key: " + key)
        //callManager.sendTones(key)
    }

    function stopDtmfTone() {
        console.log("Stop DialTone")
    }

    function dial(msisdn){
        console.log("Dialing: ", msisdn)
        main.activationReason = "dialing"
        callManager.dial(msisdn, "")
    }

    function accept(providerId, msisdn){
        console.log("Accepting call from: ", msisdn)
        activeVoiceCall.answer()
    }

    function hangup() {
        console.log("Hanging Up Calls")
        callManager.hangupAll()
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

