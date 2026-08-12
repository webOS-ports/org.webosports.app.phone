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
 * A titled group of preference rows.
 *
 * Drawn with the framework's own group artwork rather than a panel of our
 * own: group-labeled.png carries the caption band across its top, and
 * group-unlabeled.png is the same frame without one. Both are translucent, so
 * the band is the page showing through at a quarter darkness -- which is why
 * a group looks right whatever it is laid over.
 */
Item {
    id: prefsGroup

    default property alias content: rowsColumn.data

    property PhoneUiTheme appTheme: PhoneUiTheme {}
    property string title: ""

    readonly property bool labelled: title.length > 0
    /// The caption band of group-labeled.png, at the size it is drawn here.
    readonly property real bandHeight: Units.gu(3.4)

    implicitHeight: rowsColumn.height + (labelled ? bandHeight : Units.gu(1)) + Units.gu(1)
    height: implicitHeight

    BorderImage {
        anchors.fill: parent

        source: Qt.resolvedUrl(prefsGroup.labelled ? "images/group-labeled.png"
                                                   : "images/group-unlabeled.png")
        border {
            left: 21; right: 21; bottom: 21
            top: prefsGroup.labelled ? 54 : 21
        }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: Units.gu(1)
            top: parent.top
            topMargin: Units.gu(0.6)
        }
        visible: prefsGroup.labelled
        color: appTheme.prefsGroupLabelColor
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: prefsGroup.title
    }

    Column {
        id: rowsColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: prefsGroup.labelled ? prefsGroup.bandHeight : Units.gu(0.5)
            leftMargin: Units.gu(0.8)
            rightMargin: Units.gu(0.8)
        }
    }
}
