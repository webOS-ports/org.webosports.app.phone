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

   property UiTheme appTheme: PhoneUiTheme {}

   property alias label: label.text
   property alias sublabel: sublabel.text
   property int keycode
   property int longpresskeycode: keycode
   property bool disableSubLabel: false
   property string alt: ""
   property point posInPadGrid

   /// A key that carries artwork instead of a digit, e.g. the PIN pad's
   /// backspace. The source is a two-state sprite, at rest above pressed.
   property url icon

   property int fontSize: height/2.5

   signal sendKey(int keycode)

    Text {
        id: label
        anchors.centerIn: parent
        color: appTheme.foregroundColor
        font.pixelSize: fontSize
        font.bold: true
    }

    ClippedImage {
        id: iconImage

        visible: root.icon.toString() !== ""
        anchors.centerIn: parent

        source: root.icon
        // Sized from the sprite itself: it differs between the artwork sets.
        patchGridSize: Qt.size(1, 2)
        patch: Qt.point(0, mouseArea.pressed ? 1 : 0)

        // Both dimensions are given: ClippedImage only keeps a patch's own
        // proportions when the grid is square, and this sprite's is not.
        wantedWidth: Units.gu(3.6)
        wantedHeight: Units.gu(5)
    }

    Text {
        id: sublabel
        visible: !disableSubLabel
        anchors.horizontalCenter: parent.horizontalCenter
        // Held clear of the key's bottom edge rather than hung off the label's
        // line box. The bottom row of the pad is drawn with the patch that
        // carries the pad's outer frame - in both artwork sets the face stops
        // at 92% of the cell - so hanging from the label printed the "+" under
        // the 0 on the frame instead of on the key.
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.12
        color:appTheme.subForegroundColor
        font.pixelSize: fontSize/2.5
    }

    ClippedImage {
        id: box

        source: mouseArea.pressed ? appTheme.image("buttons-numpad-pressed.png") : appTheme.image("buttons-numpad.png")

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

        // try to send the correct keycode asap
        property bool _keySent: false
        onPressed: _keySent = false;
        onPressAndHold: {
            _keySent = true;
            sendKey(root.longpresskeycode);
        }
        onReleased: {
            if(!_keySent) {
                sendKey(root.keycode);
            }
        }
    }
}

