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

    /**
     * How tall to draw the field.
     *
     * Seven grid units is what the background artwork is drawn for and what
     * every caller but one wants. The dialer overrides it on a screen with no
     * height to spare, where the field giving a little back is what buys the
     * keys a row worth pressing.
     */
    property real fieldHeight: Units.gu(7)

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
        height: numberEntry.fieldHeight
        source: appTheme.image("dialer-entry-bg.png")
    }

    Image {
        id:backspace

        /*
         * Hugs the glyph instead of reserving a box for it.
         *
         * The artwork is 49x27, drawn to fit whatever height the field has, so
         * a fixed width only pads it with emptiness -- and that padding came
         * straight off the number. Five grid units of icon and three of margin
         * is 128 pixels, better than a third of a Q25's field, which left a
         * ten-digit number needing 206 pixels of the 207 there were. It fitted
         * by one pixel, and anything longer did not fit at all.
         *
         * Kept inside the field as well: where the field has been squeezed, an
         * icon drawn for a full-height one would crowd the number beside it.
         *
         * The target does not shrink with the glyph; see the MouseArea.
         */
        height: Math.min(Units.gu(3), numberEntry.fieldHeight * 0.45)
        // Guarded because the theme is loaded rather than built alongside this,
        // so it arrives a pass after the bindings first run; square until it
        // lands, and the icon is invisible until there is text anyway.
        width: height * (appTheme ? appTheme.backspaceIconImageSize.width
                                    / appTheme.backspaceIconImageSize.height
                                  : 1)
        fillMode: Image.PreserveAspectFit
        visible: textEdit.text.length > 0

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            margins: Units.gu(2)
        }
        source: appTheme.image("icon-m-common-backspace.svg")

        MouseArea {
            // The icon is a small thing to hit with a thumb, so the target is
            // not the icon: it takes the full height of the entry bar and
            // reaches well past the icon on either side.
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            // Measured from the field, not from the glyph, so hugging the
            // artwork above did not quietly shrink what a thumb has to hit.
            width: parent.width + Units.gu(8)
            height: bgImage.height

            onClicked: numberEntry.backspace();
            onPressAndHold: numberEntry.clear();
        }
    }

    TextField {
        id: textEdit

        /*
         * The indents are the artwork's, and the artwork is a bar the width of
         * a Pre3. Held to a tenth of the field on anything narrower, or the
         * placeholder loses its last word to an indent drawn for a bar half as
         * wide again: "Enter pho...".
         *
         * And the backspace is only in the way when it is there to be in the
         * way. It keeps its geometry while hidden -- it is anchored, not laid
         * out -- so reaching past it to the edge of the field is what gives an
         * empty field the room the icon would otherwise reserve from it.
         */
        anchors {
            verticalCenter: backspace.verticalCenter
            right: backspace.visible ? backspace.left : parent.right
            left: parent.left
            leftMargin: Math.min(Units.gu(4), numberEntry.width * 0.1)
            // The gap to the backspace icon. Three grid units of it was
            // another forty-eight pixels of the number's, for a space that
            // only has to read as a gap.
            rightMargin: Units.gu(1.5)
        }

        activeFocusOnPress: false
        /*
         * Nothing typed in the phone app is prose, so the keyboard's word
         * ribbon has nothing to offer here -- and on a device with a hardware
         * keyboard it is up whenever a field has focus, a strip of guesses
         * laid over the bottom of the app. On the Q25 that is exactly where
         * the tab bar is. ImhNoPredictiveText is what maliit reads to turn
         * its word engine off (see InputMethod::update).
         */
        inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
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
                var size;
                if (length <= 12) size = FontUtils.sizeToPixels("large");
                else if (length <= 16) size = FontUtils.sizeToPixels("medium");
                else size = FontUtils.sizeToPixels("small");

                // Those steps assume the field is as tall as the artwork wants.
                // Where it is not, the number comes down with it rather than
                // filling the bar top to bottom.
                return Math.min(size, numberEntry.fieldHeight * 0.5);
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
