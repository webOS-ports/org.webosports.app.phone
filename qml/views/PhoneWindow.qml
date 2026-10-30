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
    property UiTheme phoneUiAppTheme;

    property DialHandler dialHandler;
    property SupplementaryServices supplementaryServices;
    property AudioRouteManager audioRouteManager;
    property DialingShortcuts dialingShortcuts;
    property CallTransports callTransports;
    property ImBuddyStatus imBuddyStatus;

    /// True only under the desktop host; see main-desktop.qml.
    property bool runningOnDesktop: false

    property Contact currentContact: Contact { contactsModel: contacts }

    visible: false
    keepAlive: true

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor

    property bool hideWindowWhenCallEnds: false

    /*
     * The lock screen covers the window without taking it out of front, so
     * the window stays active under it: a call taken in place would ring
     * behind the lock screen with nothing to answer it on.
     */
    property bool screenLocked: false

    function __handleLockStatus(message) {
        var status = JSON.parse(message.payload);
        if (status.lockState !== undefined)
            screenLocked = (status.lockState === "locked");
    }

    /*
     * The call screen over the lock screen, as legacy's PIN card was: up for
     * as long as the screen is locked with a call in progress, whether the
     * call was answered on the lock screen or the screen locked during it.
     * Not while a call is ringing - the incoming call alert has the screen
     * then - and not once "Unlock" has sent the user to the lock screen.
     */
    property LockedCallWindow lockedCallWindow
    property bool lockedCallSteppedAside: false
    readonly property bool lockedCallWanted: screenLocked
        && !!voiceCallMgrWrapper && voiceCallMgrWrapper.hasCallInProgress
        && !lockedCallSteppedAside
        && !(incomingCallAlertWindow && incomingCallAlertWindow.visible)

    onLockedCallWantedChanged: {
        if (!lockedCallWindow)
            return;
        if (lockedCallWanted) {
            lockedCallWindow.voiceCall = voiceCallMgrWrapper.activeVoiceCall || voiceCallMgrWrapper.callAt(0);
            lockedCallWindow.show();
        } else {
            lockedCallWindow.dismiss();
        }
    }
    // Stepping aside lasts until the lock state changes or the call is over.
    onScreenLockedChanged: lockedCallSteppedAside = false
    Connections {
        target: voiceCallMgrWrapper
        function onHasCallInProgressChanged() {
            if (!voiceCallMgrWrapper.hasCallInProgress)
                phoneWindowId.lockedCallSteppedAside = false;
        }
    }
    Connections {
        target: lockedCallWindow
        function onUnlockRequested() { phoneWindowId.lockedCallSteppedAside = true; }
    }

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
                else if(!phoneWindowId.active || phoneWindowId.screenLocked) {
                    // delegate management to incomingCallAlertWindow. Not
                    // only when the window is hidden: a card in card view is
                    // visible but a thumbnail, and a window behind another
                    // alert is not in front either. Only the window the user
                    // is using takes the call in place. Hidden first, so a
                    // window left showing by a call we never saw end is put
                    // up afresh for this one.
                    incomingCallAlertWindow.dismiss();
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

            // A handset's Phone tab is the keypad, so finishing a call goes
            // back to it; the tab view puts the keys up itself once that tab
            // is the one showing. Through the loader's item: the loader
            // carries none of this itself, and asking it silently answers
            // undefined rather than failing.
            if (tabView.item && tabView.item.phoneUi)
                tabView.item.showContacts();
            // Guarded: this handler still has work to do after it, and a
            // throw here would skip the rest of the cleanup. Not gated on the
            // alert being visible: a window the shell has taken off screen (it
            // used to close every alert on a tap outside, the lock screen
            // hides them) still holds the ended call, and kept it for the
            // next one, which then never showed.
            if (incomingCallAlertWindow)
                incomingCallAlertWindow.dismiss();
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
        } else if (!phoneWindowId.active) {
            // Answered from the alert while the card was in card view: show()
            // does nothing for a window that is already visible, and the call
            // screen would stay a thumbnail. A relaunch is what brings a card
            // forward (see main.qml's relaunch handling).
            appManager.call("luna://com.webos.service.applicationmanager/launch",
                            JSON.stringify({ id: "org.webosports.app.phone" }), undefined,
                            function(error) { console.log("Could not bring the phone forward: " + error); });
        }
    }

    LunaService {
        id: appManager
        name: "org.webosports.app.phone"
        Component.onCompleted: {
            appManager.subscribe("luna://com.palm.display/control/lockStatus",
                                 JSON.stringify({ subscribe: true }),
                                 phoneWindowId.__handleLockStatus,
                                 function(error) { console.log("No lock status: " + error); });
        }
    }

    /// Asked for by the status bar, which has no menu of its own to show.
    function openAppMenu() {
        if (tabView.item && tabView.item.openAppMenu)
            tabView.item.openAppMenu();
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
