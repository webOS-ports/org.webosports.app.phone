/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 WebOS Ports
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

    property var dialHandler;
    property var supplementaryServices;
    property var audioRouteManager;
    property var dialingShortcuts;
    property var callTransports;
    property var imBuddyStatus;

    /// True only under the desktop host; see main-desktop.qml.
    property bool runningOnDesktop: false

    property Contact currentContact: Contact { contactsModel: contacts }

    visible: false
    keepAlive: true

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor

    property bool hideWindowWhenCallEnds: false

    /**
     * Navigation, driven both by the tabs and by launch parameters coming from
     * other apps (see LaunchActionHandler).
     */
    function showDialpad() {
        show();
        stackView.pop(null);
        if (tabView.item) tabView.item.showDialer();
    }

    function showCallLog() {
        show();
        stackView.pop(null);
        if (tabView.item) tabView.item.showCallLog();
    }

    function showFavorites() {
        show();
        stackView.pop(null);
        if (tabView.item) tabView.item.showFavorites();
    }

    function showActiveCall(force) {
        if (!voiceCallMgrWrapper.activeVoiceCall && voiceCallMgrWrapper.callCount === 0)
            return;

        activeCallDialog(voiceCallMgrWrapper.activeVoiceCall || voiceCallMgrWrapper.callAt(0));
    }

    /**
     * When PhoneApp is closed, hang up any active calls.
     */
    onVisibleChanged: {
        if(!visible) {
            console.log("Window not active - Cleaning up");
            voiceCallMgrWrapper.hangupAll();
            if (tabView.item)
                tabView.item.resetDialer();
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
                // Point the page at the call that triggered this, which the
                // previous code forgot to do -- a second call reused the page
                // but kept showing the first call.
                existingPage.voiceCall = voiceCall;
            }
            else {
                stackView.push(Qt.resolvedUrl(pageName),
                                {appTheme: phoneUiAppTheme,
                                             contacts: phoneWindowId.contacts,
                                             currentContact: phoneWindowId.currentContact,
                                             voiceCallMgrWrapper: phoneWindowId.voiceCallMgrWrapper,
                                             telephonyManager: phoneWindowId.telephonyManager,
                                             dialHandler: phoneWindowId.dialHandler,
                                             audioRouteManager: phoneWindowId.audioRouteManager,
                                             supplementaryServices: phoneWindowId.supplementaryServices,
                                             callTransports: phoneWindowId.callTransports,
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

            // Pick the audio route the moment the call goes live, so a docked
            // device or a plugged-in headset is honoured without the user
            // having to reach for the route button.
            if (audioRouteManager)
                audioRouteManager.applyDefaultRoute();
        }

        function onEndingCall(voiceCall) {
            console.log("VoiceCall " + voiceCall.lineId + " ended")

            // With another call still up, stay on the active call screen rather
            // than tearing the whole stack down.
            if (voiceCallMgrWrapper.callCount > 1) {
                currentContact.lineId = voiceCallMgrWrapper.activeVoiceCall
                                            ? voiceCallMgrWrapper.activeVoiceCall.lineId : "";
                return;
            }

            /*
             * Tear the call screen down whether or not the window has come up
             * yet. show() is asynchronous, so a call that ends as fast as it
             * started gets here while the window is still on its way -- and
             * gating this on being visible left the dead call screen on the
             * stack, to be put on screen a moment later with no call behind
             * it and no way back to the tabs.
             */
            if (hideWindowWhenCallEnds)
                phoneWindowId.hide();

            tabView.resetDialer();
            stackView.pop(null);

            // A handset's Phone tab is the keypad, so that is what finishing a
            // call goes back to. A tablet keeps the keypad behind a button and
            // returns to whatever tab was showing.
            if (tabView.phoneUi)
                tabView.showDialer();
            // Guarded: this handler still has work to do after it, and a
            // throw here would skip the rest of the cleanup.
            if (incomingCallAlertWindow && incomingCallAlertWindow.visible) {
                incomingCallAlertWindow.hide();
                incomingCallAlertWindow.voiceCall = null;
            }
            currentContact.lineId = "";
        }
    }

    // Something went wrong placing a call, or a connected call dropped.
    Connections {
        target: voiceCallMgrWrapper

        function onDialFailed(number, reason) {
            dialFailAlert.showDialFailure(number, reason);
        }
    }

    Connections {
        target: dialHandler

        function onMessage(text) {
            messageAlert.showMessage("", text, "");
        }

        function onDialFailed(number, reason) {
            dialFailAlert.showDialFailure(number, reason);
        }
    }

    DialFailAlert {
        id: dialFailAlert
        appTheme: phoneUiAppTheme
        dialHandler: phoneWindowId.dialHandler
        telephonyManager: phoneWindowId.telephonyManager
    }

    MessageAlert {
        id: messageAlert
        appTheme: phoneUiAppTheme
    }

    /**
     * Asked when a call could go over more than one account and the user has
     * not said which they prefer. It sits over the app rather than in the
     * shell's alert strip: the legacy dialog is a child of the dialer opened
     * with openAtCenter(), not a system popup.
     */
    PreferredServiceAlert {
        id: preferredServiceAlert

        anchors.fill: parent
        appTheme: phoneUiAppTheme
        callTransports: phoneWindowId.callTransports
        dialProxy: phoneWindowId.dialHandler ? phoneWindowId.dialHandler.dialProxy : null
        dialHandler: phoneWindowId.dialHandler
        contacts: phoneWindowId.contacts
        visible: false
    }

    function askPreferredService(callData) {
        preferredServiceAlert.ask(callData);
    }

    /// A call carries video only if the account placing it does; a cellular
    /// call has no such property at all.
    function _isVideoCall(voiceCall) {
        return !!voiceCall && voiceCall.isVideo === true;
    }

    function activeCallDialog(voiceCall) {
        console.log("Showing Active Call Dialog")

        // The call can be gone already: a dial that fails at once reports
        // itself placed and ended in the same turn. Opening the call screen
        // for a call that has ended leaves it up with nothing to show it.
        if (!voiceCall || !voiceCallMgrWrapper || voiceCallMgrWrapper.callCount === 0) {
            console.log("  ... but the call has already ended");
            return;
        }

        hideWindowWhenCallEnds = (phoneWindowId.visible === false);

        stackView.openPage(_isVideoCall(voiceCall) ? "VideoCall" : "ActiveCall", voiceCall);

        if (!phoneWindowId.visible) {
            phoneWindowId.show();
        }
    }

    /// Asked for by the status bar, which has no menu of its own to show.
    function openAppMenu() {
        if (tabView && tabView.openAppMenu)
            tabView.openAppMenu();
    }

    function incomingCall(voiceCall) {
        console.log("Showing Incoming Call Dialog");
        stackView.openPage("IncomingCall", voiceCall);
    }

    Component {
        id: tabViewComp
        PhoneTabView {
            appTheme: phoneUiAppTheme
            runningOnDesktop: phoneWindowId.runningOnDesktop
            historyModel: phoneWindowId.historyModel
            favoritesModel: phoneWindowId.favoritesModel
            voiceCallManager: phoneWindowId.voiceCallMgrWrapper
            telephonyManager: phoneWindowId.telephonyManager
            contacts: phoneWindowId.contacts
            dialHandler: phoneWindowId.dialHandler
            supplementaryServices: phoneWindowId.supplementaryServices
            dialingShortcuts: phoneWindowId.dialingShortcuts
            callTransports: phoneWindowId.callTransports
            imBuddyStatus: phoneWindowId.imBuddyStatus
        }
    }

    Loader {
        id: tabView

        function resetDialer() {
            if (item) item.resetDialer();
        }

        sourceComponent: tabViewComp
    }

    // "Add call" from the in-call screen puts the dialpad back in front while
    // the call carries on in the background.
    Connections {
        target: stackView.currentItem
        ignoreUnknownSignals: true

        function onAddCallRequested() {
            stackView.pop(null);
            if (tabView.item) tabView.item.showDialer();
        }
    }
}
