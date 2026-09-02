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
 * The strip along the foot of a preference scene, carrying the green button
 * that closes it. Every webOS preferences scene ends in one, rather than
 * leaving the way out to be scrolled to.
 */
Rectangle {
    id: doneBar

    property UiTheme appTheme: PhoneUiTheme {}
    property string text: qsTr("Done")

    signal clicked();

    height: Units.gu(6)
    color: appTheme.prefsFooterColor

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: appTheme.prefsRowDividerColor
    }

    Rectangle {
        id: button

        anchors.centerIn: parent
        width: Math.min(parent.width - Units.gu(4), Units.gu(32))
        height: Units.gu(4)
        radius: Units.gu(0.5)

        color: doneArea.pressed ? Qt.darker(appTheme.prefsDoneColor, 1.2)
                                : appTheme.prefsDoneColor

        Text {
            anchors.centerIn: parent
            color: 'white'
            font.pixelSize: FontUtils.sizeToPixels("medium")
            text: doneBar.text
        }

        MouseArea {
            id: doneArea
            anchors.fill: parent
            onClicked: doneBar.clicked()
        }
    }
}
