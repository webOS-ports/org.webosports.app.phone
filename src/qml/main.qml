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
import "views"
import "services"
import "model"
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0
import QtQuick.Window 2.1
import QtMultimedia 5.0
import LunaNext.Common 0.1


Window {
    id: main
    width: Settings.displayWidth
    height: Settings.displayHeight
    color: appTheme.backgroundColor

    property alias __window: main
    property alias stackView: stackView

    property PhoneUiTheme appTheme: PhoneUiTheme {}

    property string activationReason: 'invoked'
    property Contact activeVoiceCallPerson

    Component.onCompleted: {
        console.log("Parsing Launch Params: " + application.launchParameters);
        var params = JSON.parse(application.launchParameters);

        console.log(JSON.stringify(params));

        if (!params.launchedAtBoot) {
            __window.show();
        }

    }

    Connections {
        target: application
        onRelaunched: {
            console.log("DEBUG: Relaunched with parameters: " + parameters);
            // If we're launched at boot time we're not yet visible so bring our window
            // to the foreground
            if (!__window.visible){
                __window.show();
            }

            // default to the main screen.
            stackView.pop(tabView);
        }
    }

    /**
     * When PhoneApp is closed, hang up any active calls.
     */
    onVisibleChanged: {
        if(!visible) {
            console.log("Window not active - Cleaning up");
            main.hangup();
            if(tabView.pDialer) {
                tabView.pDialer.clear();
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: tabView

        delegate: StackViewDelegate {
            function transitionFinished(properties)
            {
                properties.exitItem.opacity = 1
            }

            property Component pushTransition: StackViewTransition {
                PropertyAnimation {
                    target: enterItem
                    property: "opacity"
                    from: 0
                    to: 1
                }
                PropertyAnimation {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                }
            }
        }

    }

    property VoiceCallManager manager: VoiceCallManager{
        id: manager
        modemPath: telephonyManager.getModemPath()

        onActiveVoiceCallChanged: {

            if(activeVoiceCall) {

                console.log("Active Call Status: ",activeVoiceCall.state)

                main.activeVoiceCallPerson = people.personByPhoneNumber(activeVoiceCall.lineId)
                manager.activeVoiceCall.statusText = "active"

                if(main.activationReason === "incoming"){
                    incomingCall()
                } else {
                    activeCallDialog()
                }

                if(!__window.visible)
                {
                    main.activationReason = 'activeVoiceCallChanged';
                    __window.show();
                }
            }
            else
            {
                console.log("No activeVoiceCall")

                tabView.pDialer.clear();
                stackView.pop()

                // console.log("TabIndex" + tabView.currentIndex);
                // If we were going back to Voicemail tab, go to first tab instead
                if(tabView.currentIndex == 3) {
                    tabView.currentIndex = 0;
                }

                main.activeVoiceCallPerson = null;

                if(main.activationReason != "invoked")
                {
                    main.activationReason = 'invoked'; // reset for next time
                    __window.close();
                }
            }
        }
    }



    function dial(msisdn) {
        if(msisdn === "999") {
            showSIMPinDialog()
        } else if(msisdn === "111") {
            main.activationReason = "incoming";
            main.incomingCall();
        } else {
            manager.dial(msisdn);
        }
    }

    function showSIMPinDialog(){
        if (!__window.visible)
            __window.show();
        stackView.push(Qt.resolvedUrl("views/SIMPin.qml"))
    }

    function activeCallDialog(){
        console.log("Showing Active Call Dialog")
        stackView.push(Qt.resolvedUrl("views/ActiveCallDialog.qml"))
    }

    function incomingCall() {
        console.log("Showing Incoming Call Dialog");


        console.log("hasAudio: " , ringTone.hasAudio)
        console.log("errorString: " , ringTone.errorString)
        console.log("bufferProgress: " , ringTone.bufferProgress)
        console.log("duration: " , ringTone.duration)
        console.log("metaData.audioCodec: " , ringTone.metaData.audioCodec)
        console.log("metaData.audioBitRate: " , ringTone.metaData.audioBitRate)
        console.log("metaData.mediaType: " , ringTone.metaData.mediaType)
        console.log("metaData.status: " , ringTone.status)

        ringTone.play()
        stackView.push(Qt.resolvedUrl("views/IncomingCallDialog.qml"));
    }

    function accept() {
        stackView.pop()
        ringTone.stop()
        manager.accept()
        activeCallDialog()
    }

    function hangup() {
        ringTone.stop()
        manager.hangup()
    }

    function reject() {
        console.log("rejecting Call");
        main.hangup()
        stackView.pop()
        main.activationReason = 'invoked'; // reset for next time
        __window.close()
    }

    function secondsToTimeString(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds - (h * 3600)) / 60);
        var s = seconds - h * 3600 - m * 60;
        if(h < 10) h = '0' + h;
        if(m < 10) m = '0' + m;
        if(s < 10) s = '0' + s;
        return '' + h + ':' + m + ':' + s;
    }

    PhoneTabView {
        id: tabView
    }

    ContactManager {
        id:people
    }

    TelephonyManager {
        id: telephonyManager
    }

    MediaPlayer {
        id: ringTone
        source: "assets/ringtone_buzz.wav"
        //source: "/usr/palm/sounds/ringtone.mp3"
        volume: 0.1
        loops: MediaPlayer.Infinite

        Component.onCompleted: {
            console.log("hasAudio: " , ringTone.hasAudio)
            console.log("errorString: " , ringTone.errorString)
            console.log("metaData.audioCodec: " , ringTone.metaData.audioCodec)
            console.log("metaData.audioBitRate: " , ringTone.metaData.audioBitRate)
            console.log("metaData.mediaType: " , ringTone.metaData.mediaType)
            console.log("metaData.status: " , ringTone.status)


        }

    }



}
