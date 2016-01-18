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
import LuneOS.Components 1.0

TabViewStyle {
    property PhoneUiTheme appTheme: PhoneUiTheme{}

    frameOverlap: 1
    tab: Rectangle {
        color: styleData.selected ? appTheme.backgroundColor : appTheme.unselectedTabColor
        border.color:  'white' //main.appTheme.backgroundColor
        implicitWidth: tabView.width/4
        implicitHeight: Units.gu(5)
        radius: 2

        ClippedImage {
            id: tabIcon

            source: tabView.getIcon(styleData.title)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            wantedWidth: styleData.title === "Voicemail" ? 72: 48
            wantedHeight: 48

            imageSize: styleData.title === "Voicemail" ? Qt.size(72, 96) : Qt.size(48, 96)
            patchGridSize: Qt.size(1, 2)
            patch: styleData.selected ? Qt.point(0,1): Qt.point(0,0)
        }

        //Text {
        //      id: text
        //      anchors.top: icon.bottom
        //      anchors.horizontalCenter: parent.horizontalCenter
        //      text: styleData.title
        //      color: styleData.selected ? main.appTheme.foregroundColor : main.appTheme.foregroundColor
        //}

    }
    frame: Rectangle { color: appTheme.backgroundColor }}
