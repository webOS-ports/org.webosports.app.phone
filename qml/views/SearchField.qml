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
import QtQuick.Controls 2.5

import LunaNext.Common 0.1

/**
 * The white pill a list is searched with: the one light element on a page
 * otherwise made of charcoal, as in com.palm.app.phone.
 *
 * The magnifier and the cross that replaces it once something has been typed
 * are the phone app's own artwork. A Unicode glyph stood in for the magnifier
 * once and came out small and mirrored -- U+2315 is a telephone recorder.
 */
TextField {
    id: searchField

    height: Units.gu(4)

    color: '#2a2929'
    placeholderTextColor: '#8a8a8a'
    font.pixelSize: FontUtils.sizeToPixels("medium")
    leftPadding: Units.gu(1.2)
    rightPadding: Units.gu(3.5)

    background: Rectangle {
        color: '#ffffff'
        radius: height / 2
    }

    Image {
        id: searchIcon

        anchors {
            right: parent.right
            rightMargin: Units.gu(1)
            verticalCenter: parent.verticalCenter
        }
        width: Units.gu(2.4)
        height: Units.gu(2.4)
        fillMode: Image.PreserveAspectFit
        smooth: true

        source: Qt.resolvedUrl(searchField.text.length > 0 ? "images/search-button-cancel.png"
                                                           : "images/search-button.png")
        opacity: clearArea.pressed ? 0.6 : 1.0

        MouseArea {
            id: clearArea
            anchors.fill: parent
            anchors.margins: -Units.gu(1)
            enabled: searchField.text.length > 0
            onClicked: searchField.text = ""
        }
    }
}
