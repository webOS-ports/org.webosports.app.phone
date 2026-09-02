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
 * One of the two buttons along the foot of the SIM PIN card.
 *
 * The legacy .pin-menu-button: a sixty pixel high pill drawn from
 * pin-menu-button-tall.png, whose two bands are the button at rest and the
 * same pill lit while it is held. Either end is a rounded cap and only what
 * lies between them stretches to whatever width the button ends up with, so
 * the cap comes from the theme -- it is a measurement of the artwork, and the
 * two looks are drawn at different densities.
 */
Item {
    id: pinMenuButton

    property UiTheme appTheme: PhoneUiTheme {}

    property string text: ""

    signal clicked();

    height: Units.gu(6)

    BorderImage {
        anchors.fill: parent

        source: Qt.resolvedUrl(mouseArea.pressed ? appTheme.image("pin-menu-button-pressed.png")
                                                 : appTheme.image("pin-menu-button.png"))
        // The caps are named by the theme: the two looks draw this pill at
        // different densities, and the stylesheet's twenty-five is the width
        // of the cap on the tablet's 1x artwork alone.
        border {
            left: appTheme.pinMenuButtonCapWidth
            right: appTheme.pinMenuButtonCapWidth
            top: 0
            bottom: 0
        }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - Units.gu(3)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight

        color: 'white'
        font.pixelSize: Units.gu(1.6)
        lineHeight: Units.gu(2)
        lineHeightMode: Text.FixedHeight
        text: pinMenuButton.text
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: pinMenuButton.clicked()
    }
}
