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
import QtQuick.Controls 2.0

// The menus, switches and fields here are the platform's, so they have to
// be drawn by the platform's style rather than whatever Controls defaults to.
import QtQuick.Controls.LuneOS 2.0

import LunaNext.Common 0.1

/// A preference row holding an editable phone number or prefix.
Item {
    id: prefsTextRow

    property string label: ""
    property string placeholder: ""
    property string value: ""

    /// Emitted when the user finishes editing, not on every keystroke.
    signal committed(string text);

    width: parent ? parent.width : 0
    height: Units.gu(4)

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.5
        elide: Text.ElideRight
        color: appTheme.prefsTextColor
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: prefsTextRow.label
    }

    TextField {
        id: field
        anchors.right: parent.right
        anchors.left: labelText.right
        anchors.verticalCenter: parent.verticalCenter

        horizontalAlignment: TextInput.AlignRight
        inputMethodHints: Qt.ImhDialableCharactersOnly
        placeholderText: prefsTextRow.placeholder
        color: appTheme.prefsTextColor
        placeholderTextColor: 'grey'
        font.pixelSize: FontUtils.sizeToPixels("small")

        background: Rectangle { color: 'transparent' }

        // Follow the stored value unless the user is busy typing into it.
        text: prefsTextRow.value
        onActiveFocusChanged: if (!activeFocus) text = Qt.binding(function() { return prefsTextRow.value; })

        onEditingFinished: {
            if (field.text !== prefsTextRow.value)
                prefsTextRow.committed(field.text);
        }
    }
}
