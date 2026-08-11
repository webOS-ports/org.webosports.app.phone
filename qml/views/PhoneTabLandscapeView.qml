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
import QtQuick.Layouts

import LunaNext.Common 0.1

import "../services"
import "../model"

RowLayout {
    id: tabView

    spacing: 0

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

    readonly property int contactsIndex: 0
    readonly property int favoritesIndex: 1
    readonly property int historyIndex: 2

    function resetDialer() {
        dialerPageId.reset();
    }

    // In landscape the dialpad is always on screen, so "show the dialer" only
    // has to clear whatever was typed into it.
    function showDialer() { dialerPageId.reset(); }
    function showContacts() { swipeView.currentIndex = contactsIndex; }
    function showFavorites() { swipeView.currentIndex = favoritesIndex; }
    function showCallLog() { swipeView.currentIndex = historyIndex; }

    DialerPage {
        id: dialerPageId

        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.minimumWidth: Math.min(tabView.height, tabView.width/2)
        Layout.preferredWidth: Math.min(tabView.height, tabView.width/2)

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

    Item {
        id: tabBarItem

        Layout.fillHeight: true
        Layout.fillWidth: true

        PhoneAppMenu {
            id: appMenu
            dialHandler: tabView.dialHandler

            onPreferencesRequested: prefsLoader.active = true
            onAccountsRequested: accountsLoader.active = true
            onClearHistoryRequested: clearHistoryDialog.open()
        }

        // Owned by the page rather than the menu: anything declared inside a
        // Menu becomes one of its entries.
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

        TabBar {
            id: tabBar
            width: parent.width - menuButton.width
            height: Units.gu(4.8)
            anchors.bottom: parent.bottom
            anchors.left: parent.left

            TabButton {
                LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-contacts.png")
                anchors.verticalCenter: parent.verticalCenter
                height: tabBar.height
            }

            TabButton {
                LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-favorites.png")
                anchors.verticalCenter: parent.verticalCenter
                height: tabBar.height
            }

            TabButton {
                LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-call-log.png")
                anchors.verticalCenter: parent.verticalCenter
                height: tabBar.height
            }
        }

        ToolButton {
            id: menuButton

            anchors.bottom: parent.bottom
            anchors.right: parent.right
            height: tabBar.height
            width: Units.gu(5)

            text: "⋮"
            font.pixelSize: FontUtils.sizeToPixels("large")

            onClicked: appMenu.popup(menuButton, 0, -appMenu.height)
        }

        SwipeView {
            id: swipeView

            width: parent.width
            anchors.top: parent.top
            anchors.bottom: tabBar.top
            clip: true

            currentIndex: tabBar.currentIndex

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

            onCurrentIndexChanged: {
                tabBar.currentIndex = currentIndex;
            }
        }
    }
}
