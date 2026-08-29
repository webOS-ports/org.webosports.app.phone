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

import QtQuick 2.6

import "../services"
import "../model"
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import Eos.Window 0.1

import LunaNext.Common 0.1
import LuneOS.Service 1.0

WebOSWindow {
    id: phoneWindowId

    property CallHistory historyModel
    property FavoritesModel favoritesModel
    property ContactsModel contacts;
    property VoiceCallMgrWrapper voiceCallMgrWrapper;
    property TelephonyManager telephonyManager;
    property IncomingCallAlert incomingCallAlertWindow;
    property SimPinWindow simPinWindow
    property PhoneUiTheme phoneUiAppTheme;

    property Contact currentContact: Contact { contactsModel: contacts }

    visible: false
    keepAlive: true

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor

    property bool hideWindowWhenCallEnds: false

    // Video calling needs an actual camera, not just the platform
    // capability: gate on the rtc engine's capabilities, which probe the
    // real camera count. (Queried over LS2 rather than QtMultimedia's
    // device enumeration, which probes kernel video nodes and can corrupt
    // the vendor camera HAL session on droid devices.)
    property bool videoCallAvailable: false
    property bool videoCallProbeDone: false
    property var __pendingVideoCallParams: null

    Component.onCompleted: {
        cameraProbeService.call("luna://org.webosports.rtcengine/capabilities",
            JSON.stringify({}),
            function(message) {
                var response = JSON.parse(message.payload);
                videoCallAvailable = !!(response.returnValue &&
                                        response.videoCallCapable);
                videoCallProbeDone = true;
                console.warn("Video call availability: " + videoCallAvailable);
                __openPendingVideoCall();
            },
            function(message) {
                console.warn("Video capability probe failed: " + message.payload);
                videoCallProbeDone = true;
                __openPendingVideoCall();
            });
    }

    LunaService {
        id: cameraProbeService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    function __openPendingVideoCall() {
        var params = __pendingVideoCallParams;
        __pendingVideoCallParams = null;
        if (params && videoCallAvailable)
            videoCallOverlay.open(params);
    }

    function openVideoCall(params) {
        if (!videoCallProbeDone) {
            // camera probe still in flight; open when it answers
            __pendingVideoCallParams = params || {};
            return;
        }
        if (!videoCallAvailable) {
            console.warn("Video call requested but no camera present");
            return;
        }
        videoCallOverlay.open(params);
    }

    function closeVideoCall() {
        videoCallOverlay.close();
    }

    /**
     * When PhoneApp is closed, hang up any active calls.
     */
    onVisibleChanged: {
        if(!visible) {
            console.log("Window not active - Cleaning up");
            voiceCallMgrWrapper.hangupAll();
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
                stackView.push(Qt.resolvedUrl(pageName),
                                {appTheme: phoneUiAppTheme,
                                             contacts: phoneWindowId.contacts,
                                             currentContact: phoneWindowId.currentContact,
                                             voiceCallMgrWrapper: phoneWindowId.voiceCallMgrWrapper,
                                             telephonyManager: phoneWindowId.telephonyManager,
                                             voiceCall: voiceCall });
            }
        }
    }

    Connections {
        target: voiceCallMgrWrapper

        function onIncomingCall(voiceCall) {
            currentContact.lineId = voiceCall.lineId;

            if(voiceCall) {
                hideWindowWhenCallEnds = (phoneWindowId.visible === false);

                if(voiceCall.lineId === "999") {
                    phoneWindowId.hide();
                    simPinWindow.show();
                }
                else if(!phoneWindowId.visible) {
                    // delegate management to incomingCallAlertWindow
                    incomingCallAlertWindow.voiceCall = voiceCall;
                    incomingCallAlertWindow.show();
                }
                else {
                    incomingCall(voiceCall);
                }
            }
        }
        
        function onOutgoingCall(voiceCall) {
            currentContact.lineId = voiceCall.lineId;
            console.log("Outgoing Call Status: ",voiceCall.status)

            activeCallDialog(voiceCall);
        }
        
        function onActiveCall(voiceCall) {
            currentContact.lineId = voiceCall.lineId;
            console.log("Active Call Status: ",voiceCall.status)

            activeCallDialog(voiceCall);
        }
        
        function onEndingCall(voiceCall) {
            console.log("VoiceCall " + voiceCall.lineId + " ended")

            videoCallOverlay.close();

            if(phoneWindowId.visible) {
                if(hideWindowWhenCallEnds) phoneWindowId.hide();

                tabView.resetDialer();
                stackView.pop(null)

                // If we were going back to Voicemail tab, go to first tab instead
                if (tabView.currentIndex == 3)
                    tabView.currentIndex = 0;
            }
            if(incomingCallAlertWindow.visible) {
                incomingCallAlertWindow.hide();
                incomingCallAlertWindow.voiceCall = null;
            }
            currentContact.lineId = "";
        }
    }

    function activeCallDialog(voiceCall) {
        console.log("Showing Active Call Dialog")

        hideWindowWhenCallEnds = (phoneWindowId.visible === false);

        stackView.openPage("ActiveCall", voiceCall);

        if (!phoneWindowId.visible) {
            phoneWindowId.show();
        }
    }

    function incomingCall(voiceCall) {
        console.log("Showing Incoming Call Dialog");
        stackView.openPage("IncomingCall", voiceCall);
    }

    Component {
        id: tabViewComp
        PhoneTabView {
            appTheme: phoneUiAppTheme
            historyModel: phoneWindowId.historyModel
            favoritesModel: phoneWindowId.favoritesModel
            voiceCallManager: phoneWindowId.voiceCallMgrWrapper
            telephonyManager: phoneWindowId.telephonyManager
            contacts: phoneWindowId.contacts
        }
    }
    Component {
        id: tabViewLandscapeComp
        PhoneTabLandscapeView {
            appTheme: phoneUiAppTheme
            historyModel: phoneWindowId.historyModel
            favoritesModel: phoneWindowId.favoritesModel
            voiceCallManager: phoneWindowId.voiceCallMgrWrapper
            telephonyManager: phoneWindowId.telephonyManager
            contacts: phoneWindowId.contacts
        }
    }

    VideoCallOverlay {
        id: videoCallOverlay
        anchors.fill: parent
        z: 100
    }

    Loader {
        id: tabView

        function resetDialer() {
            item.resetDialer();
        }

        sourceComponent: {
            if (phoneWindowId.height/phoneWindowId.width > 1)
                return tabViewComp;
            else
                return tabViewLandscapeComp;
        }
    }
}
