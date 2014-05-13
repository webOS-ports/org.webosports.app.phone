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
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0
import LunaNext.Common 0.1

TabViewStyle {
    frameOverlap: 1
    tab: Rectangle {
        color: styleData.selected ? main.appTheme.backgroundColor : main.appTheme.unselectedTabColor
        border.color:  'white' //main.appTheme.backgroundColor
        implicitWidth: tabView.width/4
        implicitHeight: Units.gu(5)
        radius: 2

        Item {
            id: tabIcon
            clip: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: styleData.title === "Voicemail" ? 72: 48
            height: 48
            Image{
                id: icon
                x: 0
                y: styleData.selected ? -48: 0
                source: tabView.getIcon(styleData.title)
            }

        }


        //Text {
        //      id: text
        //      anchors.top: icon.bottom
        //      anchors.horizontalCenter: parent.horizontalCenter
        //      text: styleData.title
        //      color: styleData.selected ? main.appTheme.foregroundColor : main.appTheme.foregroundColor
        //}

    }
    frame: Rectangle { color: main.appTheme.backgroundColor }}
