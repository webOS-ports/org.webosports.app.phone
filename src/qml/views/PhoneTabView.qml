/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

TabView {
    id: tabView
    tabPosition: Qt.BottomEdge
    //currentIndex: 3
    //frameVisible: true
    //tabsVisible: true

    property alias pDialer: tabDialer.item
    property alias pHistory: tabHistory.item
    property alias pFavorites: tabFavorites.item

    Tab {
        id: tabDialer
        title: "Dial"
        sourceComponent: Dialer{ anchors.horizontalCenter: parent.horizontalCenter}
    }

    Tab {
        id: tabFavorites
        title: "Favorites"
        sourceComponent: FavouritePage{}
    }

    Tab {
        id: tabHistory
        title: "Call Log"
        sourceComponent: HistoryPage{}
    }

    Tab {
        id: tabVoiceMail
        title: "Voicemail"
        Item{}
        //sourceComponent: VoiceMail{}
    }

    onCurrentIndexChanged: {
        if(currentIndex == 3) {
            main.dial("443");
        }
    }

    style: PhoneTabViewStyle{}
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
