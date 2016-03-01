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
import QtQuick.Controls 1.1

import "../services"
import "../model"

TabView {
    id: tabView
    tabPosition: Qt.BottomEdge

    property PhoneUiTheme appTheme;

    property VoiceCallMgrWrapper voiceCallManager;
    property TelephonyManager telephonyManager;
    property ContactsModel contacts;
    property CallHistory historyModel;
    property FavoritesModel favoritesModel;

    function resetDialer() {
        tabDialer.item.reset();
    }

    Tab {
        id: tabDialer
        title: "Dial"
        sourceComponent: DialerPage {
            appTheme: tabView.appTheme
            voiceCallMgrWrapper: tabView.voiceCallManager
            telephonyManager: tabView.telephonyManager
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Tab {
        id: tabFavorites
        title: "Favorites"
        sourceComponent: FavouritePage{
            appTheme: tabView.appTheme;
            favoritesModel: tabView.favoritesModel
        }
    }

    Tab {
        id: tabHistory
        title: "Call Log"
        sourceComponent: HistoryPage{
            appTheme: tabView.appTheme;
            historyModel: tabView.historyModel
            contacts: tabView.contacts
        }
    }

    Tab {
        id: tabVoiceMail
        title: "Voicemail"
        Item{}
        //sourceComponent: VoiceMail{}
    }

    onCurrentIndexChanged: {
        if(currentIndex == 3) {
            tabView.phoneWindow.voiceCallManager.dial("453");
        }
    }

    style: PhoneTabViewStyle{ appTheme: tabView.appTheme }
    function getIcon(title) {
        if(title === "Dial") {
            return "images/menu-icon-dtmfpad.png"
        }
        if(title === "Favorites") {
            return "images/menu-icon-favorites.png"
        }
        if(title === "Call Log") {
            return "images/menu-icon-call-log.png"
        }
        if(title === "Voicemail") {
            return "images/menu-icon-voicemail.png"
        }
    }
}
