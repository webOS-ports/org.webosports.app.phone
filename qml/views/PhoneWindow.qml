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
import org.nemomobile.voicecall 1.0

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
    property CallAlertSounds alertSounds;
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

    /**
     * Whether this card is the one on screen, by the application manager's
     * account rather than the window's.
     *
     * The window's own `active` is not to be trusted for that: a card hidden
     * when a call ends, or one whose surface the compositor dropped, can stay
     * active with nothing on screen, the compositor sending no focus change
     * (sargo, 2026-11-03). The application manager reports the foreground app
     * from the compositor's side. Where it is not there to ask - a desktop, a
     * test - the window's `active` is all there is.
     */
    readonly property bool inFront: _foregroundKnown
                                    ? (visible && _foregroundAppId === "org.webosports.app.phone")
                                    : active
    property bool _foregroundKnown: false
    property string _foregroundAppId: ""

    function __handleForegroundApp(message) {
        var info = JSON.parse(message.payload);
        if (info.appId === undefined)  // a failed reply carries none
            return;
        _foregroundAppId = info.appId;
        _foregroundKnown = true;
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

    /// Set while surfaceRecovery hides and shows the window for a new surface:
    /// that hide is not the app being closed.
    property bool _resurfacing: false

    /**
     * When PhoneApp is closed, hang up any active calls.
     */
    onVisibleChanged: {
        if(!visible && !_resurfacing) {
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
                else if(!phoneWindowId.takesCallsInPlace(phoneWindowId.visible, phoneWindowId.inFront,
                                                         phoneWindowId.screenLocked,
                                                         voiceCallMgrWrapper.isCallWaiting(voiceCall))) {
                    // delegate management to incomingCallAlertWindow. Not
                    // only when the window is hidden: a card in card view is
                    // visible but a thumbnail, and a window behind another
                    // alert is not in front either. Only the window the user
                    // is using takes the call in place. Hidden first, so a
                    // window left showing by a call we never saw end is put
                    // up afresh for this one.
                    //
                    // A call waiting always goes to the strip, the call card
                    // staying up behind it: 2.2.4 opened the same small
                    // IncomingCall popup for it as for any call
                    // (CallSynergizer.handleIncoming), never a page over the
                    // call in progress.
                    incomingCallAlertWindow.present(voiceCall);
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

            /*
             * With another call still up, stay on the call screen and point
             * it at that call - the one being talked on, else the one on
             * hold, which then offers Resume. Not "callCount > 1": the ended
             * call is still counted when its disconnected state comes in
             * before its row goes, and not when it went without one, which
             * tore the screen down over a call on hold. And not
             * activeVoiceCall, which is whichever call came first (the held
             * one here): the screen stayed on the call that had ended, with
             * no Resume and a Swap that did nothing.
             */
            var remaining = voiceCallMgrWrapper.callAfterEnding(voiceCall.handlerId);
            if (remaining) {
                currentContact.lineId = remaining.lineId;
                if (remaining.status === VoiceCall.STATUS_INCOMING ||
                    remaining.status === VoiceCall.STATUS_WAITING) {
                    // Only a call ringing is left: it has its strip (or its
                    // page) already, and the call screen has nothing to show.
                    if (stackView.currentItem as ActiveCallPage)
                        stackView.pop(null);
                } else {
                    stackView.openPage(_isVideoCall(remaining) ? "VideoCall" : "ActiveCall", remaining);
                }
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

        function onCallControlFailed(message) {
            messageAlert.showMessage("", message, "");
        }

        function onCallDropped(voiceCall, reason) {
            var match = contacts ? contacts.personByPhoneNumber(voiceCall.lineId) : null;
            var person = match ? match.foundPerson : null;
            var name = !person ? ""
                     : person.nickname ? person.nickname
                     : (person.name.givenName + " " + person.name.familyName).trim();
            droppedCallAlert.showDropped(voiceCall.lineId, name, reason);
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
        alertSounds: phoneWindowId.alertSounds
    }

    DroppedCallAlert {
        id: droppedCallAlert
        appTheme: phoneUiAppTheme
        dialHandler: phoneWindowId.dialHandler
        alertSounds: phoneWindowId.alertSounds
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

    /// The call screen shows video once a messaging call's far-side picture
    /// is being decoded and the user let it on; a cellular call has no such
    /// property at all.
    function _isVideoCall(voiceCall) {
        return !!voiceCall && voiceCall.showsVideo === true;
    }

    /**
     * Video on a messaging call, as 2.2.4's phonePopups VideoRequest: the far
     * side starts sending, and the user is asked whether to switch to video.
     */
    MessageAlert {
        id: videoRequestAlert
        appTheme: phoneUiAppTheme
        property var voiceCall: null
    }

    function _videoCallerName(voiceCall) {
        if (voiceCall.displayName && String(voiceCall.displayName).length > 0)
            return voiceCall.displayName;
        if (currentContact && currentContact.lineId === voiceCall.lineId
                && String(currentContact.displayLabel || "").trim().length > 0)
            return String(currentContact.displayLabel).trim();
        return voiceCall.lineId;
    }

    function _askVideo(voiceCall) {
        videoRequestAlert.voiceCall = voiceCall;
        videoRequestAlert.showQuestion(qsTr("Switch to video?"),
            qsTr("%1 wants to start a video call.").arg(_videoCallerName(voiceCall)), "",
            qsTr("Accept"),
            function() {
                voiceCall.acceptVideo(voiceCallMgrWrapper.videoSendCapable);
                videoRequestAlert.voiceCall = null;
            },
            qsTr("Reject"),
            function() {
                voiceCall.refuseVideo();
                videoRequestAlert.voiceCall = null;
            });
    }

    property bool _videoCapabilityAsked: false

    Connections {
        target: voiceCallMgrWrapper

        function onVideoRequested(voiceCall) {
            if (!voiceCall)
                return;
            // What we can send decides whether accepting turns our camera on
            // too, so learn it before the question is put.
            if (phoneWindowId._videoCapabilityAsked) {
                phoneWindowId._askVideo(voiceCall);
                return;
            }
            phoneWindowId._videoCapabilityAsked = true;
            appManager.call("luna://org.webosports.rtcengine/capabilities", "{}",
                function(message) {
                    var reply = JSON.parse(message.payload);
                    voiceCallMgrWrapper.videoSendCapable = reply.returnValue === true
                                                           && reply.videoCallCapable === true;
                    phoneWindowId._askVideo(voiceCall);
                },
                function(error) {
                    console.log("No video call capabilities: " + error);
                    phoneWindowId._askVideo(voiceCall);
                });
        }

        // Switch the call screen between voice and video for the call on it.
        function onCallVideoChanged(voiceCall) {
            var page = stackView.currentItem as BasePage;
            if (!page || page.voiceCall !== voiceCall)
                return;
            if (page.pageName !== "ActiveCall" && page.pageName !== "VideoCall")
                return;
            stackView.openPage(_isVideoCall(voiceCall) ? "VideoCall" : "ActiveCall", voiceCall);
        }

        function onEndingCall(voiceCall) {
            if (videoRequestAlert.voiceCall === voiceCall) {
                videoRequestAlert.hide();
                videoRequestAlert.voiceCall = null;
            }
        }
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
            // A hidden card shown again can be left unmapped too (sargo,
            // 2026-11-03: answered from the strip, no call screen).
            surfaceRecovery.restart();
        } else if (!phoneWindowId.inFront) {
            // Answered from the alert while the card was in card view: show()
            // does nothing for a window that is already visible, and the call
            // screen would stay a thumbnail. A relaunch is what brings a card
            // forward (see main.qml's relaunch handling).
            appManager.call("luna://com.webos.service.applicationmanager/launch",
                            JSON.stringify({ id: "org.webosports.app.phone" }), undefined,
                            function(error) { console.log("Could not bring the phone forward: " + error); });
            surfaceRecovery.restart();
        }
    }

    /*
     * A card put away to card view can lose its surface: the compositor logs
     * it unmapped, and from then on it ignores the window's requests to come
     * back ("state change on unmapped surface"). Qt still holds the window
     * visible, so show() does nothing, and the call screen never appears --
     * on sargo three calls out of five that found the card put away. If the
     * relaunch has not brought the card forward by now, give it a new
     * surface: hidden and shown again, it maps afresh in front.
     */
    Timer {
        id: surfaceRecovery
        objectName: "surfaceRecovery"
        interval: 1500
        onTriggered: {
            if (phoneWindowId.inFront)
                return;
            if (!voiceCallMgrWrapper || voiceCallMgrWrapper.callCount === 0)
                return;
            console.log("Phone card did not come forward for the call; showing it afresh");
            phoneWindowId._resurfacing = true;
            phoneWindowId.hide();
            phoneWindowId.show();
            phoneWindowId._resurfacing = false;
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
            appManager.subscribe("luna://com.webos.service.applicationmanager/getForegroundAppInfo",
                                 JSON.stringify({ subscribe: true }),
                                 phoneWindowId.__handleForegroundApp,
                                 function(error) { console.log("No foreground app info: " + error); });
        }
    }

    /// Asked for by the status bar, which has no menu of its own to show.
    function openAppMenu() {
        if (tabView.item && tabView.item.openAppMenu)
            tabView.item.openAppMenu();
    }

    /**
     * Whether an incoming call opens on the call screen inside this window
     * rather than in the alert strip: only when the window is the one the
     * user is looking at, unlocked, and the call is not a call waiting.
     *
     * Visible as well as active: a card hidden when the call before ended can
     * stay active, the compositor sending no focus change when it unmaps a
     * window nothing else takes the focus from. On sargo on 2026-11-03 two
     * calls in a row after a hung-up one opened their page in that hidden
     * window - the ringtone, and nothing on screen.
     */
    function takesCallsInPlace(visible, active, locked, waiting) {
        return visible === true && active === true && !locked && !waiting;
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
