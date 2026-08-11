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
import QtQuick.Layouts 1.3

import LunaNext.Common 0.1

import "../services"
import "../model"

/**
 * The app's main screen: a tab bar across the top and the selected tab below,
 * laid out like the webOS 3.x phone app on the TouchPad.
 *
 * The Video tab only appears when a Synergy account that supports video is
 * signed in, so the bar matches what the device can actually do.
 */
Item {
    id: tabView

    property PhoneUiTheme appTheme;

    property VoiceCallMgrWrapper voiceCallManager;
    property TelephonyManager telephonyManager;
    property ContactsModel contacts;
    property CallHistory historyModel;
    property FavoritesModel favoritesModel;
    property var dialHandler;
    property var supplementaryServices;
    property var dialingShortcuts;
    property var callTransports;
    property var imBuddyStatus;

    readonly property bool hasVideoService: callTransports &&
                                            callTransports.videoCallableImTypes().length > 0

    // The stack always holds the same pages in the same order; the bar only
    // shows the ones that apply, so each tab carries the stack index it opens.
    readonly property var allTabs: [
        { key: "phone",     stackIndex: 0, icon: Qt.resolvedUrl("images/menu-icon-dial.png"),      label: qsTr("Phone") },
        { key: "video",     stackIndex: 1, icon: Qt.resolvedUrl("images/menu-icon-video.png"),     label: qsTr("Video") },
        { key: "contacts",  stackIndex: 2, icon: Qt.resolvedUrl("images/menu-icon-contacts.png"),  label: qsTr("Contacts") },
        { key: "favorites", stackIndex: 3, icon: Qt.resolvedUrl("images/menu-icon-favorites.png"), label: qsTr("Favorites") },
        { key: "calllog",   stackIndex: 4, icon: Qt.resolvedUrl("images/menu-icon-call-log.png"),  label: qsTr("Call Log") }
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
        if (tabDialer.item) tabDialer.item.reset();
    }

    function showDialer() { currentIndex = _stackIndexOf("phone"); }
    function showContacts() { currentIndex = _stackIndexOf("contacts"); }
    function showFavorites() { currentIndex = _stackIndexOf("favorites"); }
    function showCallLog() { currentIndex = _stackIndexOf("calllog"); }
    function showVideo() { currentIndex = _stackIndexOf("video"); }

    Rectangle {
        anchors.fill: parent
        color: appTheme.backgroundColor
    }

    // The app menu the legacy app had and this one never did: clearing the
    // call log, calling voicemail, and getting to the preferences.
    PhoneAppMenu {
        id: appMenu
        dialHandler: tabView.dialHandler

        onPreferencesRequested: prefsLoader.active = true
        onAccountsRequested: accountsLoader.active = true
        onClearHistoryRequested: clearHistoryDialog.open()
    }

    // Owned by the page rather than the menu: anything declared inside a Menu
    // becomes one of its entries.
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
            supplementaryServices: tabView.supplementaryServices
            dialingShortcuts: tabView.dialingShortcuts

            onClosed: prefsLoader.active = false
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

            onClosed: accountsLoader.active = false
        }
    }

    PhoneTabBar {
        id: tabBar

        anchors { top: parent.top; left: parent.left; right: menuButton.left }
        appTheme: tabView.appTheme
        tabs: tabView.tabs

        // Translate between the bar's visible position and the stack's fixed one.
        currentIndex: {
            for (var i = 0; i < tabView.tabs.length; ++i) {
                if (tabView.tabs[i].stackIndex === contentStack.currentIndex) return i;
            }
            return 0;
        }

        onTabSelected: (index) => contentStack.currentIndex = tabView.tabs[index].stackIndex
    }

    ToolButton {
        id: menuButton

        anchors { top: parent.top; right: parent.right }
        height: tabBar.height
        width: Units.gu(5)

        text: "⋮"
        font.pixelSize: FontUtils.sizeToPixels("large")

        background: Rectangle { color: tabView.appTheme.tabBarColor }
        contentItem: Text {
            text: menuButton.text
            font: menuButton.font
            color: tabView.appTheme.primaryTextColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: appMenu.popup(menuButton, 0, menuButton.height)
    }

    // A plain stack rather than a SwipeView: the reference app switches tabs on
    // tap only, and swiping conflicts with the swipe-to-delete in the call log.
    StackLayout {
        id: contentStack

        anchors {
            top: tabBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Loader {
            id: tabDialer
            sourceComponent: DialerPage {
                appTheme: tabView.appTheme
                voiceCallMgrWrapper: tabView.voiceCallManager
                telephonyManager: tabView.telephonyManager
                contacts: tabView.contacts
                dialHandler: tabView.dialHandler

                onContactLookupRequested: (prefix) => {
                    tabView.showContacts();
                    if (tabContacts.item) tabContacts.item.initialFilter = prefix;
                }
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
            id: tabContacts
            sourceComponent: ContactLookupPage {
                appTheme: tabView.appTheme
                contacts: tabView.contacts
                voiceCallMgrWrapper: tabView.voiceCallManager
                dialHandler: tabView.dialHandler
                callTransports: tabView.callTransports
                imBuddyStatus: tabView.imBuddyStatus
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

}
