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
import QtQuick.Controls 2.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0

TabButton {
    id: tabButton
    property PhoneUiTheme appTheme: PhoneUiTheme{}
    property alias iconSource: tabIcon.source
    property int imageWidth: 48

    implicitHeight: Units.gu(5)

    background: Item {}
    contentItem: Rectangle {
        gradient: tabButton.selected ? appTheme.selectedGradient : appTheme.unSelectedGradient
        border.color:  appTheme.backgroundColor
        radius: 2

        ClippedImage {
            id: tabIcon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            wantedWidth: tabButton.imageWidth
            wantedHeight: 48

            imageSize: Qt.size(tabButton.imageWidth, 96)
            patchGridSize: Qt.size(1, 2)
            patch: tabButton.selected ? Qt.point(0,1): Qt.point(0,0)
        }
    }
}
