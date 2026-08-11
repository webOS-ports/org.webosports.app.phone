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

import LunaNext.Common 0.1

/// A read-only "label: value" preference row.
Item {
    id: prefsInfoRow

    property string label: ""
    property string value: ""

    width: parent ? parent.width : 0
    height: Units.gu(4)

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: 'white'
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: prefsInfoRow.label
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width / 2
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        color: 'grey'
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: prefsInfoRow.value
    }
}
