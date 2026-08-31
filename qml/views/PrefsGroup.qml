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

    property UiTheme appTheme: PhoneUiTheme {}
    property string title: ""

    readonly property bool labelled: title.length > 0

    /*
     * The artwork's own slices. A labelled group holds thirty-six pixels at
     * the top, of which the last eight are transparent -- so the caption band
     * reads as twenty-eight pixels tall while the rows start below all
     * thirty-six.
     */
    readonly property real bandHeight: 28
    readonly property real topInset: labelled ? 36 : 14
    readonly property real sideInset: 14

    implicitHeight: rowsColumn.height + topInset + sideInset
    height: implicitHeight

    BorderImage {
        anchors.fill: parent

        source: Qt.resolvedUrl(prefsGroup.labelled ? appTheme.image("group-labeled.png")
                                                   : appTheme.image("group-unlabeled.png"))
        border {
            left: prefsGroup.sideInset; right: prefsGroup.sideInset; bottom: prefsGroup.sideInset
            top: prefsGroup.topInset
        }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: Units.gu(1.1)
            top: parent.top
            verticalCenterOffset: 0
        }
        height: prefsGroup.bandHeight
        verticalAlignment: Text.AlignVCenter
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
            topMargin: prefsGroup.topInset
            leftMargin: Units.gu(0.8)
            rightMargin: Units.gu(0.8)
        }
    }

    /*
     * The rule between one row and the next: .enyo-row's bottom border, which
     * on this background is a grey line with a lighter one under it. Drawn
     * here rather than by the rows themselves so the last one in a group has
     * none, as the group's own edge closes it off.
     */
    Repeater {
        model: rowsColumn.children.length

        delegate: Item {
            required property int index
            readonly property Item row: rowsColumn.children[index]

            /// A Repeater filling the group is itself a child, and one with no
            /// height; so is a row that is hidden. Neither gets a rule, and
            /// neither counts when working out which row is the last.
            readonly property bool drawable: !!row && row.visible && row.height > 0
            readonly property bool lastDrawable: {
                for (var i = index + 1; i < rowsColumn.children.length; ++i) {
                    var other = rowsColumn.children[i];
                    if (other && other.visible && other.height > 0)
                        return false;
                }
                return true;
            }

            x: rowsColumn.x
            width: rowsColumn.width
            y: rowsColumn.y + (row ? row.y + row.height : 0)
            height: 2
            visible: drawable && !lastDrawable

            Rectangle { width: parent.width; height: 1; color: '#acacac' }
            Rectangle { y: 1; width: parent.width; height: 1; color: '#eaeaea' }
        }
    }
}
