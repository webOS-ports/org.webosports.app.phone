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
import LunaNext.Common 0.1

Item {
   id:root

   property alias label: label.text
   property alias sublabel: sublabel.text
   property int keycode
   property string alt: ""

   property int size: 25

   signal keyPressed
   signal keyPressAndHold

    Text {
        id: label
        anchors.centerIn: parent
        color: phoneUiAppTheme.foregroundColor
        font.pixelSize: Units.dp(size)
        font.bold: true
    }

    Text {
        id: sublabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:label.bottom
        color:phoneUiAppTheme.subForegroundColor
        font.pixelSize: Units.dp(10)
    }

    Rectangle {
        id: box
        anchors.fill: parent
        border { color:phoneUiAppTheme.foregroundColor; width:0.5}
        radius: 10
        color: mouseArea.pressed ? '#6495ed' : '#000000'
        z: -10
    }

    MouseArea {
        id: mouseArea
        anchors.fill:parent
        onPressed: keyPressed()
        onPressAndHold: keyPressAndHold()
    }
}

