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
import LuneOS.Components 1.0

Item {
   id:root

   property alias label: label.text
   property alias sublabel: sublabel.text
   property int keycode
   property string alt: ""
   property point posInPadGrid

   property int fontSize: height/2.5

   signal keyPressed
   signal keyPressAndHold

    Text {
        id: label
        anchors.centerIn: parent
        color: phoneUiAppTheme.foregroundColor
        font.pixelSize: fontSize
        font.bold: true
    }

    Text {
        id: sublabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:label.bottom
        color:phoneUiAppTheme.subForegroundColor
        font.pixelSize: fontSize/2.5
    }

    ClippedImage {
        id: box

        source: mouseArea.pressed ? "images/buttons-numpad-pressed.png" : "images/buttons-numpad.png"

        wantedWidth: parent.width
        wantedHeight: parent.height

        imageSize: Qt.size(297, 297)
        patchGridSize: Qt.size(3, 3)
        patch: posInPadGrid
        z: -10
    }

    MouseArea {
        id: mouseArea
        anchors.fill:parent
        onPressed: keyPressed()
        onPressAndHold: keyPressAndHold()
    }
}

