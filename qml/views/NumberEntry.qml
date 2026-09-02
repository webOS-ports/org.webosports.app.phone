/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * The dial string field.
 *
 * `text` is always the raw string to dial; what the user sees is the same
 * string formatted for their region, or the name of the matching contact once
 * one has been picked. Ported from the legacy Dialer.DialStringWidget, which
 * did the same split between rawString and dialString.
 */
Item {
    id: numberEntry

    property UiTheme appTheme

    height: bgImage.height

    property alias text: textEdit.text
    property string textColor: "white"
    property alias alignment: textEdit.horizontalAlignment
    property alias inputMethodHints: textEdit.inputMethodHints
    property alias echoMode: textEdit.echoMode

    property bool isPhoneNumber: true

    /// Region used to format the number, e.g. "NL".
    property string countryCode: "US"

    /// When set, the field shows this name instead of the number. Cleared as
    /// soon as the user types again, as in the legacy dialer.
    property string contactName: ""

    /// Emitted when the (empty) field is tapped, to open contact lookup.
    signal emptyFieldClicked();

    property string __previousCharacter

    readonly property string displayText: {
        if (contactName.length > 0)
            return contactName;
        if (!isPhoneNumber || textEdit.text.length === 0)
            return textEdit.text;

        return PhoneNumberUtils.formatForDisplay(textEdit.text, countryCode, true);
    }

    function insert(character) {
        var text = textEdit.text
        var cpos = textEdit.cursorPosition;

        contactName = "";

        if(text.length == 0) {
            textEdit.text = character
            textEdit.cursorPosition = textEdit.text.length
        } else {
            var newText = text.slice(0, cpos) + character + text.slice(cpos,text. length);
            textEdit.text = newText;
            textEdit.cursorPosition = cpos + (textEdit.text.length - text.length);
        }

        numberEntry.__previousCharacter = character;
        interactionTimeout.restart();
    }

    function backspace() {
        // Backspacing out of a contact name clears the whole entry, rather than
        // leaving the number the name stood for behind.
        if (contactName.length > 0) {
            clear();
            return;
        }

        var cpos = textEdit.cursorPosition == 0 ? 1 : textEdit.cursorPosition;
        var text = textEdit.text

        if(text.length == 0)
            return;

        var newText = text.slice(0, cpos - 1) + text.slice(cpos, text.length);
        textEdit.text = newText;
        textEdit.cursorPosition = cpos - (text.length - textEdit.text.length);

        numberEntry.__previousCharacter = '';
        interactionTimeout.restart();
    }

    function resetCursor() {
        textEdit.cursorPosition = textEdit.text.length;
    }

    function clear() {
        contactName = "";
        resetCursor();
        textEdit.text = '';
    }

    /// Fills the field from a contact the user picked in contact lookup.
    function setContact(name, number) {
        textEdit.text = number;
        contactName = name;
        resetCursor();
    }

    function getPhoneNumber(){
        return textEdit.text;
    }

    Timer {
        id: interactionTimeout
        interval: 10000
        running: false
        repeat: false
        onTriggered: numberEntry.resetCursor();
    }

    Image {
        id: bgImage
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Units.gu(7);
        source: appTheme.image("dialer-entry-bg.png")
    }

    Image {
        id:backspace

        width: Units.gu(5)
        height: Units.gu(3)
        fillMode: Image.PreserveAspectFit
        visible: textEdit.text.length > 0

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            margins: Units.gu(3)
        }
        source: appTheme.image("icon-m-common-backspace.svg")

        MouseArea {
            // The icon is a small thing to hit with a thumb, so the target is
            // not the icon: it takes the full height of the entry bar and
            // reaches well past the icon on either side.
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width + Units.gu(6)
            height: bgImage.height

            onClicked: numberEntry.backspace();
            onPressAndHold: numberEntry.clear();
        }
    }

    TextField {
        id: textEdit

        anchors {
            verticalCenter: backspace.verticalCenter
            right: backspace.left
            left: parent.left
            leftMargin: Units.gu(4)
            rightMargin: Units.gu(3)
        }

        activeFocusOnPress: false
        inputMethodHints: Qt.ImhDialableCharactersOnly
        color: "transparent"
        horizontalAlignment: TextInput.AlignLeft
        placeholderText: isPhoneNumber ? qsTr("Enter phone number") : ""

        Component.onCompleted: {
            // On desktop we don't have this field
            if (textEdit.passwordCharacter)
                textEdit.passwordCharacter = "•";
        }

        placeholderTextColor: numberEntry.textColor
        background: Rectangle {
            color: 'transparent'
        }

        // The field itself holds the raw string but is drawn transparent; what
        // the user sees is the formatted version painted on top, so that
        // formatting never changes what gets dialled.
        Text {
            id: displayLabel

            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: textEdit.horizontalAlignment
            elide: Text.ElideLeft

            color: numberEntry.textColor
            font.pixelSize: {
                // Shrink long dial strings so they stay on one line, following
                // the steps the legacy dialer used.
                var length = numberEntry.displayText.length;
                if (length <= 12) return FontUtils.sizeToPixels("large");
                if (length <= 16) return FontUtils.sizeToPixels("medium");
                return FontUtils.sizeToPixels("small");
            }

            text: (textEdit.echoMode === TextInput.Password)
                      ? Array(textEdit.text.length + 1).join("•")
                      : numberEntry.displayText
        }
    }

    MouseArea {
        anchors.fill:textEdit

        onPressed: (mouse) => {
            interactionTimeout.restart();
            if (numberEntry.isPhoneNumber && textEdit.text.length === 0)
                numberEntry.emptyFieldClicked();
            mouse.accepted = false;
        }
    }
}
