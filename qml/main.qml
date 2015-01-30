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
import LuneOS.Application 1.0

ApplicationWindow {
    id: window

    keepAlive: true
    loadingAnimationDisabled: true

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: appTheme.backgroundColor

    property string activationReason: 'invoked'
    property Contact activeVoiceCallPerson

    property alias main: window
    property alias appTheme: phoneUiAppPhome

    Component.onCompleted: {
        console.log("Parsing Launch Params: " + application.launchParameters);
        var params = JSON.parse(application.launchParameters);

        if (!params.launchedAtBoot)
            window.show();
    }

    PhoneUiTheme { id: phoneUiAppPhome }

    Connections {
        target: application
        onRelaunched: {
            console.log("DEBUG: Relaunched with parameters: " + parameters);

            // If we're launched at boot time we're not yet visible so bring our window
            // to the foreground
            if (!window.visible)
                window.show();

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
            if (tabView.pDialer)
                tabView.pDialer.clear();
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: tabView

        delegate: StackViewDelegate {
            function transitionFinished(properties) {
                properties.exitItem.opacity = 1
            }

            pushTransition: StackViewTransition {
                PropertyAnimation { target: enterItem; property: "opacity"; from: 0; to: 1 }
                PropertyAnimation { target: exitItem; property: "opacity"; from: 1; to: 0 }
            }
        }
    }

    VoiceCallManager {
        id: manager
        modemPath: telephonyManager.getModemPath()

        onActiveVoiceCallChanged: {
            if (activeVoiceCall) {
                console.log("Active Call Status: ",activeVoiceCall.state)

                main.activeVoiceCallPerson = people.personByPhoneNumber(activeVoiceCall.lineId)
                manager.activeVoiceCall.statusText = "active"

                if (main.activationReason === "incoming")
                    incomingCall()
                else
                    activeCallDialog()

                if (!window.visible) {
                    main.activationReason = 'activeVoiceCallChanged';
                    window.show();
                }
            }
            else {
                console.log("No activeVoiceCall")

                tabView.pDialer.clear();
                stackView.pop()

                // If we were going back to Voicemail tab, go to first tab instead
                if (tabView.currentIndex == 3)
                    tabView.currentIndex = 0;

                main.activeVoiceCallPerson = null;

                if (main.activationReason !== "invoked") {
                    // reset for next time
                    main.activationReason = 'invoked';
                    window.close();
                }
            }
        }
    }

    function dial(number) {
        if (number === "999")
            showSIMPinDialog()
        else if (number === "111") {
            main.activationReason = "incoming";
            main.incomingCall();
        }
        else
            manager.dial(number);
    }

    function showSIMPinDialog() {
        if (!window.visible)
            window.show();
        stackView.push(Qt.resolvedUrl("views/SIMPin.qml"))
    }

    function activeCallDialog() {
        console.log("Showing Active Call Dialog")
        stackView.push(Qt.resolvedUrl("views/ActiveCallDialog.qml"))
    }

    function incomingCall() {
        console.log("Showing Incoming Call Dialog");
        stackView.push(Qt.resolvedUrl("views/IncomingCallDialog.qml"));
    }

    function accept() {
        console.log("accepting Call")
        stackView.pop()
        manager.accept()
        activeCallDialog()
    }

    function hangup() {
        console.log("hanging up Call")
        manager.hangup()
    }

    function reject() {
        console.log("rejecting Call")
        main.hangup()
        stackView.pop()
        main.activationReason = 'invoked'; // reset for next time
        window.close()
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
        id: people
    }

    TelephonyManager {
        id: telephonyManager
    }
}
