/*
 * Copyright (C) 2026 WebOS Ports
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
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1

/// A titled group of preference rows, in the style of the legacy groupboxes.
Column {
    id: prefsGroup

    default property alias content: rowsColumn.data

    property PhoneUiTheme appTheme: PhoneUiTheme {}
    property string title: ""

    spacing: Units.gu(0.5)

    Text {
        color: 'grey'
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: prefsGroup.title
        visible: prefsGroup.title.length > 0
    }

    Rectangle {
        width: prefsGroup.width
        height: rowsColumn.height + Units.gu(1)
        radius: Units.gu(1)
        color: appTheme.panelColor

        Column {
            id: rowsColumn
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: Units.gu(1)
            }
        }
    }
}
