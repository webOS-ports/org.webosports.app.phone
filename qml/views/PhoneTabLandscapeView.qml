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

    function resetDialer() {
        dislerPageId.reset();
    }

    DialerPage {
        id: dislerPageId

        Layout.fillHeight: true
        Layout.fillWidth: true

        appTheme: tabView.appTheme
        voiceCallMgrWrapper: tabView.voiceCallManager
        telephonyManager: tabView.telephonyManager
    }

    Item{
        id: tabBarItem

        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.minimumWidth: Units.gu(4.8)
        Layout.preferredWidth: Units.gu(4.8)

        TabBar {
            id: tabBar

            width: parent.height
            height: parent.width
            rotation: 90
            anchors.centerIn: parent

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
    }

    SwipeView {
        id: swipeViewId

        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true

        currentIndex: tabBar.currentIndex

        Loader {
            id: tabFavorites
            sourceComponent: FavouritePage{
                appTheme: tabView.appTheme;
                favoritesModel: tabView.favoritesModel
            }
        }
        Loader {
            id: tabHistory
            sourceComponent: HistoryPage{
                appTheme: tabView.appTheme;
                historyModel: tabView.historyModel
                contacts: tabView.contacts
            }
        }

        onCurrentIndexChanged: {
            tabBar.currentIndex = currentIndex;
        }
    }
}
