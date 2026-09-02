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
 * The card the app asks for a numeric code on.
 *
 * A port of the legacy shared/phoneprefs PinCode: the sky backdrop, a heading
 * naming what is being asked for, a line under it naming the step, the entry
 * shown as a run of dots, the PIN dialpad, and the two buttons along the foot.
 * Every measurement here is the one the original stylesheet gives -- the
 * heading is twenty-six pixels, the step line seventeen, the dots thirty-two
 * and bold, the form they sit in sixty-four tall, and the buttons sixty.
 *
 * It asks for one thing at a time and knows nothing about which; the owner
 * sets `title` and `subText` for the step it wants and reads `pin` back when
 * the card is accepted, which is how PinCode walked through old PIN, new PIN
 * and new PIN again. The call barring password is asked for on the same card,
 * being another short run of digits the network wants back.
 */
Item {
    id: pinCard

    property UiTheme appTheme

    /// The heading, e.g. "Enter PIN".
    property string title: ""
    /// The line under it naming the step, e.g. "Enter old PIN".
    property string subText: ""

    property int maximumLength: 8

    /**
     * What the left button does.
     *
     * The SIM PIN card reaches the emergency dialpad, as the legacy card did:
     * whoever is looking at it may be locked out of their own SIM and still
     * needs to be able to call for help. A card standing in front of nothing
     * more than a preference offers a way back instead.
     */
    property bool emergencyCallEnabled: true

    /// What has been keyed in so far.
    property string pin: ""

    /// The user pressed Done.
    signal accepted
    /// The user asked for the emergency dialpad.
    signal emergencyCallRequested
    /// The user backed out, on a card that offers that instead of emergency
    /// calling.
    signal canceled
    /// A digit was keyed in. The original used this to drop an error message
    /// as soon as the user started over.
    signal keyed

    function clear() {
        pin = "";
    }

    function backspace() {
        pin = pin.slice(0, -1);
    }

    /*
     * Keyed with the dialpad only. The original took the hardware keypad too,
     * but DialerPage claims key focus back the moment it loses it and stays
     * visible under anything the tab view lays over it, so a Keys handler here
     * would never see a press.
     */
    function _append(digit) {
        pinCard.keyed();
        if (pin.length >= maximumLength)
            return;
        pin += digit;
    }

    /// .pinCardBackground -- the same sky the first-use screens are drawn on.
    Image {
        anchors.fill: parent
        source: pinCard.appTheme.image("backdrop-firstuse.png")
        fillMode: Image.PreserveAspectCrop
    }

    /*
     * The card proper.
     *
     * The handset gives the whole screen over to it. The tablet floats a panel
     * in the middle instead -- PinCode wraps itself in .unlock-pin-screen at
     * four hundred by five hundred -- so everything below sits in here rather
     * than against the edges of the screen.
     */
    Item {
        id: card

        anchors.centerIn: parent
        width: pinCard.appTheme.pinCardIsPanel ? pinCard.appTheme.pinCardPanelWidth : parent.width
        height: pinCard.appTheme.pinCardIsPanel ? pinCard.appTheme.pinCardPanelHeight : parent.height

        Column {
            id: header

            anchors { top: parent.top; left: parent.left; right: parent.right }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap

                color: pinCard.appTheme.foregroundColor
                font.pixelSize: pinCard.appTheme.pinCardTitleSize
                text: pinCard.title
            }

            /// The original's pinForm: a fixed sixty-four pixel block, so the
            /// dialpad below it does not shift as the entry fills up.
            Item {
                width: parent.width
                height: Units.gu(6.4)

                Text {
                    id: subLabel

                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap

                    color: pinCard.appTheme.foregroundColor
                    font.pixelSize: pinCard.appTheme.pinCardSubTextSize
                    text: pinCard.subText
                }

                Text {
                    anchors { top: subLabel.bottom; left: parent.left; right: parent.right }
                    horizontalAlignment: Text.AlignHCenter

                    color: pinCard.appTheme.pinCardEntryColor
                    font.pixelSize: pinCard.appTheme.pinCardEntrySize
                    font.bold: pinCard.appTheme.pinCardEntryBold
                    // A period per digit, as the original drew it.
                    text: new Array(pinCard.pin.length + 1).join(".")
                }
            }
        }

        NumPad {
            id: keypad
            appTheme: pinCard.appTheme

            anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: footer.top }

            mode: 'pin'

            onSendKey: keycode => {
                switch (keycode) {
                case Qt.Key_Backspace:
                    pinCard.backspace();
                    return;
                case Qt.Key_Clear:
                    pinCard.clear();
                    return;
                }

                pinCard._append(String.fromCharCode(keycode));
            }
        }

        Row {
            id: footer

            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: pinCard.appTheme.pinCardButtonHeight

            PinMenuButton {
                appTheme: pinCard.appTheme
                width: parent.width / 2
                height: parent.height
                text: pinCard.emergencyCallEnabled ? qsTr("Emergency Call") : qsTr("Cancel")

                onClicked: {
                    if (pinCard.emergencyCallEnabled)
                        pinCard.emergencyCallRequested();
                    else
                        pinCard.canceled();
                }
            }

            PinMenuButton {
                appTheme: pinCard.appTheme
                width: parent.width / 2
                height: parent.height
                text: qsTr("Done")
                onClicked: pinCard.accepted()
            }
        }
    }
}
