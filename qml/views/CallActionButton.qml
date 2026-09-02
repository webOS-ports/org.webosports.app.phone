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
import LuneOS.Components 1.0

/**
 * One of the call controls under the active call card -- Speaker, Mute,
 * Dialpad, Add Call and the Synergy additions.
 *
 * Shaped like the row on the TouchPad: a squat rounded charcoal tile with the
 * icon above a small label, turning blue while the control is on.
 */
Item {
    id: callActionButton

    property UiTheme appTheme

    property url iconSource
    property string label: ""
    property bool active: false
    property bool actionEnabled: true

    signal clicked();

    width: Units.gu(8)
    height: Units.gu(7)

    opacity: actionEnabled ? 1.0 : 0.35

    Rectangle {
        id: background

        anchors.fill: parent
        anchors.margins: Units.gu(0.2)
        radius: Units.gu(0.6)

        color: callActionButton.active ? appTheme.buttonActiveColor
                                       : (mouseArea.pressed ? appTheme.buttonPressedColor
                                                            : appTheme.buttonColor)
        border.color: appTheme.buttonBorderColor
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: Units.gu(0.4)

            SpriteIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Units.gu(3)
                height: Units.gu(3)
                source: callActionButton.iconSource
                frame: mouseArea.pressed ? 1 : 0
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: callActionButton.active ? appTheme.primaryTextColor
                                               : appTheme.secondaryTextColor
                font.pixelSize: FontUtils.sizeToPixels("x-small")
                text: callActionButton.label
                visible: callActionButton.label.length > 0
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: callActionButton.actionEnabled
        onClicked: callActionButton.clicked()
    }
}
