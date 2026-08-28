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

/**
 * A button on a preference scene: pale face, dark label, as "Add account" and
 * "Connect Phone" are drawn there. The Controls button is styled for the
 * app's dark chrome and would sit on a light page as a black slab.
 */
Rectangle {
    id: lightButton

    property PhoneUiTheme appTheme: PhoneUiTheme {}
    property alias text: label.text

    signal clicked();

    height: Units.gu(4.4)
    radius: Units.gu(0.5)

    color: buttonArea.pressed ? Qt.darker('#dddddd', 1.1) : '#dddddd'
    border.color: '#b4b4b4'
    border.width: 1

    Text {
        id: label

        anchors.centerIn: parent
        color: appTheme.prefsTextColor
        font.pixelSize: FontUtils.sizeToPixels("medium")
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        onClicked: lightButton.clicked()
    }
}
