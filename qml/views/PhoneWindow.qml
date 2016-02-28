/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
 */

import QtQuick 2.0

import "../services"
import "../model"
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0

import LunaNext.Common 0.1
import LuneOS.Application 1.0

ApplicationWindow {
    id: phoneWindow

    property alias historyModel: tabView.historyModel
    property alias favoritesModel: tabView.favoritesModel
    property ContactsModel contacts;
    property VoiceCallMgrWrapper voiceCallManager;
    property IncomingCallAlert incomingCallAlertWindow;
    property SimPinWindow simPinWindow

    property Contact currentContact: Contact { contactsModel: contacts }

    keepAlive: true
    loadingAnimationDisabled: true

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor

    property bool hideWindowWhenCallEnds: false

    PhoneUiTheme { id: phoneUiAppTheme }

    onWindowIdChanged: {
        console.log("windowId: " + phoneWindow.windowId);
    }

    /**
     * When PhoneApp is closed, hang up any active calls.
     */
    onVisibleChanged: {
        if(!visible) {
            console.log("Window not active - Cleaning up");
            voiceCallManager.hangupAll();
            if (tabView.dialerPage)
                tabView.dialerPage.reset();
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: tabView

        function openPage(name, voiceCall) {
            var pageName = name + "Page.qml";

            var existingPage = stackView.find(function(stackedPage) {
                if( stackedPage.pageName === name ) return true;
            });

            if (existingPage) {
                stackView.pop(existingPage);
            }
            else {
                stackView.push({item: Qt.resolvedUrl(pageName),
                                properties: {voiceCallManager: voiceCallManager,
                                             appTheme: phoneUiAppTheme,
                                             voiceCall: voiceCall,
                                             currentContact: phoneWindow.currentContact,
                                             contacts: phoneWindow.contacts }});
            }
        }

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

    Connections {
        target: voiceCallManager

        onIncomingCall: {
            currentContact.lineId = voiceCall.lineId;

            if(voiceCall) {
                hideWindowWhenCallEnds = (phoneWindow.visible === false);

                if(voiceCall.lineId === "999") {
                    phoneWindow.hide();
                    simPinWindow.show();
                }
                else if(!phoneWindow.visible) {
                    // delegate management to incomingCallAlertWindow
                    incomingCallAlertWindow.voiceCall = voiceCall;
                    incomingCallAlertWindow.show();
                }
                else {
                    incomingCall(voiceCall);
                }
            }
        }
        onOutgoingCall: {
            currentContact.lineId = voiceCall.lineId;
            console.log("Outgoing Call Status: ",voiceCall.status)

            activeCallDialog(voiceCall);
        }
        onActiveCall: {
            currentContact.lineId = voiceCall.lineId;
            console.log("Active Call Status: ",voiceCall.status)

            activeCallDialog(voiceCall);
        }
        onEndingCall: {
            console.log("VoiceCall " + voiceCall.lineId + " ended")

            if(phoneWindow.visible) {
                if(hideWindowWhenCallEnds) phoneWindow.hide();

                tabView.dialerPage.reset();
                stackView.pop(null)

                // If we were going back to Voicemail tab, go to first tab instead
                if (tabView.currentIndex == 3)
                    tabView.currentIndex = 0;
            }
            currentContact.lineId = "";
        }
    }

    function activeCallDialog(voiceCall) {
        console.log("Showing Active Call Dialog")

        hideWindowWhenCallEnds = (phoneWindow.visible === false);

        stackView.openPage("ActiveCall", voiceCall);

        if (!phoneWindow.visible) {
            phoneWindow.show();
        }
    }

    function incomingCall(voiceCall) {
        console.log("Showing Incoming Call Dialog");
        stackView.openPage("IncomingCall", voiceCall);
    }

    PhoneTabView {
        id: tabView

        appTheme: phoneUiAppTheme
        voiceCallManager: phoneWindow.voiceCallManager
        contactsModel: contacts
    }
}
