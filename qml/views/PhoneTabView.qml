/*
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

import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Controls.LuneOS 2.0
import QtQuick.Layouts 1.3

import LunaNext.Common 0.1
import LuneOS.Components 1.0 as LuneComponents

import "../services"
import "../model"

/**
 * The app's main screen: the app menu and the tabs across the top, the
 * selected tab below.
 *
 * One view serves both orientations. There used to be a separate landscape
 * copy with its own tab bar at the bottom and its own subset of tabs, which
 * meant two layouts to keep in step and a jarring change when the device
 * turned. Here the difference is only that a wide screen has room to keep the
 * dialpad permanently beside the content instead of behind a tab.
 */
Item {
    id: tabView

    property UiTheme appTheme;

    property VoiceCallMgrWrapper voiceCallManager;
    property TelephonyManager telephonyManager;
    property ContactsModel contacts;
    property CallHistory historyModel;
    property FavoritesModel favoritesModel;
    property DialHandler dialHandler;
    property SupplementaryServices supplementaryServices;
    property DialingShortcuts dialingShortcuts;
    property CallTransports callTransports;
    property ImBuddyStatus imBuddyStatus;

    /// True only under the desktop host, which has no system app menu to use.
    property bool runningOnDesktop: false

    /**
     * A phone is not a small tablet.
     *
     * Its tabs run along the foot of the screen rather than the top, and it
     * opens on the keypad filling everything above them -- a phone is for
     * dialling first. Settings.tabletUi is what the shell itself reads to
     * tell the two apart.
     */
    readonly property bool phoneUi: !Settings.tabletUi

    readonly property bool hasVideoService: callTransports &&
                                            callTransports.videoCallableImTypes().length > 0

    // The stack always holds the same pages in the same order; the bar only
    // shows the ones that apply, so each tab carries the stack index it opens.
    // On a wide screen the dialpad is always on screen, so it loses its tab.
    readonly property var allTabs: [
        { key: "phone",     stackIndex: 0, icon: appTheme.image("menu-icon-Phone.png"),     label: qsTr("Phone") },
        { key: "video",     stackIndex: 1, icon: appTheme.image("menu-icon-video.png"),     label: qsTr("Video") },
        { key: "favorites", stackIndex: 2, icon: appTheme.image("menu-icon-favorites.png"), label: qsTr("Favorites") },
        { key: "calllog",   stackIndex: 3, icon: appTheme.image("menu-icon-call-log.png"),  label: qsTr("Call Log") }
    ]

    readonly property var tabs: allTabs.filter(function(tab) {
        return tab.key !== "video" || tabView.hasVideoService;
    })

    function _stackIndexOf(key) {
        for (var i = 0; i < allTabs.length; ++i) {
            if (allTabs[i].key === key) return allTabs[i].stackIndex;
        }
        return 0;
    }

    property alias currentIndex: contentStack.currentIndex

    function resetDialer() {
        if (dialpadOverlay.contentItem && dialpadOverlay.contentItem.reset)
            dialpadOverlay.contentItem.reset();
    }

    /// Opens the Phone tab and its dialpad, which is what a dial request means.
    function showDialer() {
        currentIndex = _stackIndexOf("phone");
        dialpadOverlay.open();
    }
    /*
     * The app menu, owned by the view rather than by the button that opens it
     * -- on a device there is no button, and the status bar asks for it by
     * relaunching the app.
     */
    PhoneAppMenu {
        id: phoneAppMenu

        dialHandler: tabView.dialHandler

        onPreferencesRequested: tabView.showOverlayPage(prefsLoader)
        onAccountsRequested: tabView.showOverlayPage(accountsLoader)
        onClearHistoryRequested: clearHistoryDialog.open()
    }

    function openAppMenu() {
        if (phoneAppMenu.visible) {
            phoneAppMenu.close();
            return;
        }

        // Out of the top left corner, where webOS drops it, whichever end of
        // the screen this layout keeps its tabs.
        phoneAppMenu.popup(tabView, 0, tabView.phoneUi ? 0 : header.height);
    }

    /**
     * On a handset the keypad is the face of the Phone tab, so its being up is
     * not an event to be fired at the right moment but a fact about which tab
     * is showing. Worked out from that rather than opened and closed by hand:
     * a missed call to open() left the phone sitting on the contact list with
     * no way back to the keys but the tab itself.
     */
    function syncDialpad() {
        /*
         * A page laid over the whole view -- preferences, accounts -- is not
         * the Phone tab, whatever the tabs say. It has to be closed for rather
         * than merely stacked over: the keypad is a Popup and so lives in the
         * window's overlay layer, which is drawn above every child of the view
         * no matter what z they are given, so leaving it up buries them.
         */
        if (prefsLoader.active || accountsLoader.active) {
            dialpadOverlay.close();
            return;
        }

        if (!tabView.phoneUi)
            return;

        if (contentStack.currentIndex === _stackIndexOf("phone"))
            dialpadOverlay.open();
        else
            dialpadOverlay.close();
    }

    /// Opening or closing a page that covers the view changes whether the
    /// keypad may be up, so both go through here.
    function showOverlayPage(loader) {
        loader.active = true;
        syncDialpad();
    }

    function hideOverlayPage(loader) {
        loader.active = false;
        syncDialpad();
    }

    onVisibleChanged: if (visible) syncDialpad()

    Connections {
        target: contentStack
        function onCurrentIndexChanged() { tabView.syncDialpad(); }
    }

    Component.onCompleted: syncDialpad()

    /*
     * Contacts live on the Phone tab, as they do on the reference.
     *
     * Each of these syncs the keypad rather than leaving that to
     * onCurrentIndexChanged: asking for the tab that is already showing sets
     * currentIndex to what it already holds, which emits nothing, and the
     * keypad never comes back. That is what a call placed from the keypad
     * did -- it ended on a bare contact list with no way back to the keys but
     * another tab. syncDialpad() decides afresh either way, so calling it
     * when the index did change costs nothing.
     */
    function showContacts() { currentIndex = _stackIndexOf("phone"); syncDialpad(); }
    function showFavorites() { currentIndex = _stackIndexOf("favorites"); syncDialpad(); }
    function showCallLog() { currentIndex = _stackIndexOf("calllog"); syncDialpad(); }
    function showVideo() { currentIndex = _stackIndexOf("video"); syncDialpad(); }

    Rectangle {
        anchors.fill: parent
        color: appTheme.backgroundColor
    }

    /**
     * Header: the app menu where webOS users look for it, then the tabs.
     **/

    Rectangle {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: tabView.phoneUi ? undefined : parent.top
            bottom: tabView.phoneUi ? parent.bottom : undefined
        }
        height: Units.gu(6)
        color: appTheme.tabBarColor

        LuneComponents.AppMenuButton {
            id: appMenuButton

            anchors {
                left: parent.left
                leftMargin: visible ? Units.gu(0.8) : 0
                verticalCenter: parent.verticalCenter
            }
            width: visible ? implicitWidth : 0
            height: Units.gu(3.6)

            // The status bar opens the menu on a device -- it relaunches the
            // app with palm-command open-app-menu, which the app answers. Only
            // the desktop host, which has no status bar, needs a button here.
            visible: tabView.runningOnDesktop

            text: qsTr("Phone")
            textColor: appTheme.primaryTextColor
            backgroundColor: appTheme.buttonColor
            pressedColor: appTheme.buttonPressedColor
            borderColor: appTheme.buttonBorderColor

            menu: phoneAppMenu
        }

        // The platform TabBar can stack an icon over a caption since this
        // branch, but in this app it kept rendering icon-only; until that is
        // understood the app draws its own bar rather than ship a bar with no
        // labels. The style change stands for other apps.
        PhoneTabBar {
            id: tabBar

            anchors {
                left: appMenuButton.right
                leftMargin: appMenuButton.visible ? Units.gu(0.8) : 0
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            appTheme: tabView.appTheme
            tabs: tabView.tabs

            // Translate between the bar's visible position and the stack's
            // fixed one, since which tabs exist depends on the layout.
            currentIndex: {
                for (var i = 0; i < tabView.tabs.length; ++i) {
                    if (tabView.tabs[i].stackIndex === contentStack.currentIndex) return i;
                }
                return 0;
            }

            onTabSelected: (index) => contentStack.currentIndex = tabView.tabs[index].stackIndex
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: tabView.phoneUi ? parent.top : undefined
                bottom: tabView.phoneUi ? undefined : parent.bottom
            }
            height: 1
            color: appTheme.tabBarBorderColor
        }
    }

    /**
     * Content
     **/

    // A plain stack rather than a SwipeView: the reference app switches tabs on
    // tap only, and swiping fights the swipe-to-delete in the call log.
    StackLayout {
        id: contentStack

        anchors {
            top: tabView.phoneUi ? parent.top : header.bottom
            bottom: tabView.phoneUi ? header.top : parent.bottom
            left: parent.left
            right: parent.right
        }

        Loader {
            id: tabPhone
            sourceComponent: ContactLookupPage {
                appTheme: tabView.appTheme
                contacts: tabView.contacts
                voiceCallMgrWrapper: tabView.voiceCallManager
                dialHandler: tabView.dialHandler
                callTransports: tabView.callTransports
                imBuddyStatus: tabView.imBuddyStatus
                showDialpadButton: true

                onDialpadRequested: dialpadOverlay.open()
            }
        }
        Loader {
            id: tabVideo
            active: tabView.hasVideoService
            sourceComponent: ContactLookupPage {
                appTheme: tabView.appTheme
                contacts: tabView.contacts
                voiceCallMgrWrapper: tabView.voiceCallManager
                dialHandler: tabView.dialHandler
                callTransports: tabView.callTransports
                imBuddyStatus: tabView.imBuddyStatus
                videoOnly: true
            }
        }
        Loader {
            id: tabFavorites
            sourceComponent: FavouritePage{
                appTheme: tabView.appTheme;
                favoritesModel: tabView.favoritesModel
                contacts: tabView.contacts
                dialHandler: tabView.dialHandler
                callTransports: tabView.callTransports
            }
        }
        Loader {
            id: tabHistory
            sourceComponent: HistoryPage{
                appTheme: tabView.appTheme;
                historyModel: tabView.historyModel
                contacts: tabView.contacts
                dialHandler: tabView.dialHandler
                callTransports: tabView.callTransports
            }
        }
    }

    // The dialpad sits over the page it was opened from, as on the reference,
    // rather than taking a column of its own.
    /*
     * The keypad.
     *
     * On a tablet it is a panel over the middle of the screen, dimming what is
     * behind it. On a phone it is the face of the Phone tab: it fills
     * everything above the tabs, and leaves them alone so the user can still
     * move between tabs while it is up.
     */
    Popup {
        id: dialpadOverlay

        parent: Overlay.overlay
        modal: !tabView.phoneUi
        dim: !tabView.phoneUi
        closePolicy: tabView.phoneUi ? Popup.NoAutoClose
                                     : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
        padding: 0

        // Popup positions itself with x/y rather than anchors. On a handset it
        // takes everything above the tab bar; on a tablet it is a panel in the
        // middle of the screen.
        width: tabView.phoneUi ? tabView.width
                               : Math.min(tabView.width - Units.gu(4), Units.gu(34))
        height: tabView.phoneUi ? tabView.height - header.height
                                : Math.min(tabView.height - Units.gu(8), Units.gu(52))
        x: tabView.phoneUi ? 0
                           : (parent ? Math.round((parent.width - width) / 2) : 0)
        y: tabView.phoneUi ? 0
                           : (parent ? Math.round((parent.height - height) / 2) : 0)

        /*
         * A handset's keypad is not modal, so the tabs stay reachable -- but
         * that also means a press it does not use carries on down to whatever
         * is behind it. Behind it is the contact list, where a stray tap
         * places a call. This catches those.
         */
        background: Item {
            MouseArea {
                anchors.fill: parent
                enabled: tabView.phoneUi
                onPressed: (mouse) => mouse.accepted = true
            }
        }

        contentItem: DialerPage {
            appTheme: tabView.appTheme
            fillsScreen: tabView.phoneUi
            voiceCallMgrWrapper: tabView.voiceCallManager
            telephonyManager: tabView.telephonyManager
            contacts: tabView.contacts
            dialHandler: tabView.dialHandler

            onContactLookupRequested: (prefix) => {
                dialpadOverlay.close();
                tabView.showContacts();
                if (tabPhone.item) tabPhone.item.initialFilter = prefix;
            }

            // Once the call is placed the keypad has done its job; leaving it
            // up hides the call it just started.
            onDialled: dialpadOverlay.close()
        }

        onClosed: if (contentItem && contentItem.reset) contentItem.reset()
    }

    /**
     * Things the app menu opens
     **/

    Dialog {
        id: clearHistoryDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true

        title: qsTr("Clear Call History")
        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            width: parent ? parent.width : implicitWidth
            wrapMode: Text.Wrap
            text: qsTr("Are you sure you want to clear all of the calls in your call history?")
        }

        onAccepted: {
            if (tabView.historyModel)
                tabView.historyModel.clearHistory();
        }
    }

    Loader {
        id: prefsLoader
        anchors.fill: parent
        active: false
        z: 10

        sourceComponent: PhonePrefsPage {
            appTheme: tabView.appTheme
            telephonyManager: tabView.telephonyManager
            // The SIM PIN card offers an emergency dialpad, which needs to be
            // able to place the call.
            voiceCallMgrWrapper: tabView.voiceCallManager
            supplementaryServices: tabView.supplementaryServices
            dialingShortcuts: tabView.dialingShortcuts

            onClosed: tabView.hideOverlayPage(prefsLoader)
        }
    }

    Loader {
        id: accountsLoader
        anchors.fill: parent
        active: false
        z: 10

        sourceComponent: PhoneAccountsPage {
            appTheme: tabView.appTheme
            callTransports: tabView.callTransports

            onClosed: tabView.hideOverlayPage(accountsLoader)
        }
    }
}
