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

import LunaNext.Common 0.1

import "../services"
import "../model"

Item {
    id: tabView

    property PhoneUiTheme appTheme;

    property VoiceCallMgrWrapper voiceCallManager;
    property TelephonyManager telephonyManager;
    property ContactsModel contacts;
    property CallHistory historyModel;
    property FavoritesModel favoritesModel;

    function resetDialer() {
        tabDialer.item.reset();
    }

    TabBar {
        id: tabBar
        width: parent.width
        anchors.bottom: parent.bottom

        TabButton {
            LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-dtmfpad.png")
            anchors.verticalCenter: parent.verticalCenter
            height: 48
        }

        TabButton {
            LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-favorites.png")
            anchors.verticalCenter: parent.verticalCenter
            height: 48
        }

        TabButton {
            LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-call-log.png")
            anchors.verticalCenter: parent.verticalCenter
            height: 48
        }

        TabButton {
            LuneOSButton.image: Qt.resolvedUrl("images/menu-icon-voicemail.png")
            anchors.verticalCenter: parent.verticalCenter
            height: 48
        }
    }

    SwipeView {
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: tabBar.top

        currentIndex: tabBar.currentIndex

        Loader {
            id: tabDialer
            sourceComponent: DialerPage {
                appTheme: tabView.appTheme
                voiceCallMgrWrapper: tabView.voiceCallManager
                telephonyManager: tabView.telephonyManager
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
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
        Loader {
            id: tabVoiceMail
            sourceComponent: Item{}
            //sourceComponent: VoiceMail{}
        }

        onCurrentIndexChanged: {
            if(currentIndex === 3) {
                voiceCallManager.dial("453");
            }
        }
    }
}
