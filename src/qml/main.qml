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

    property string providerId: "sim1"
    property string providerType: "GSM"
    property string providerLabel: "Vodaphone"


    Component.onCompleted: {
        console.log("Parsing Launch Params: " + application.launchParameters);
        var params = JSON.parse(application.launchParameters);

        console.log(JSON.stringify(params));

        if (!params.launchedAtBoot) {
            __window.show();
        }


        if(params.incommingCall){
           main.activationReason = "incomming";
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
            tabView.pDialer.clear();

        }
    }

    StackView {
        id: stackView
        anchors.fill: main
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

         Component.onCompleted: {
          console.log("Tab loaded");

             if(main.activationReason === "incomming"){
                main.incommingCall();
             }
         }
    }

    property VoiceCallManager manager: VoiceCallManager{
        id: manager

        onActiveVoiceCallChanged: {

            if(activeVoiceCall) {
                console.log("Active Call")
                main.activeVoiceCallPerson = people.personByPhoneNumber(activeVoiceCall.lineId);
                manager.activeVoiceCall.statusText = "active"

                stackView.push(Qt.resolvedUrl("views/ActiveCallDialog.qml"))
                if(!__window.visible)
                {
                    main.activationReason = 'activeVoiceCallChanged';
                    __window.show();
                }
            }
            else
            {

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
            stackView.push(Qt.resolvedUrl("views/SIMPin.qml"))
        } else if(msisdn === "111") {
            main.activationReason = "incomming";
            main.incommingCall();
        } else {
            manager.dial(providerId, msisdn);
        }
    }

    function incommingCall() {
        console.log("Incomming Call");
        stackView.push(Qt.resolvedUrl("views/IncommingCallDialog.qml"));
    }

    function accept() {
       stackView.pop();
       manager.dial(providerId, "11111");
    }

    function hangup() {
        if(manager.activeVoiceCall) {
            manager.activeVoiceCall.hangup();
        }
    }

    function reject() {
        console.log("rejecting Call");
        main.hangup();
        stackView.pop();
        main.activationReason = 'invoked'; // reset for next time
        __window.close();
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

    PhoneTabView {id: tabView}

    ContactManager {id:people}

    OfonoManager {id: ofono}

}
