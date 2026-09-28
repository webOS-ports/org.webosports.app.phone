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
import QtQuick.Window 2.1

import LuneOS.Service 1.0
import LuneOS.Components 1.0
import LunaNext.Common 0.1

import "../AppTweaks"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

BasePage {
    id: pDialPage

    pageName: "Dialer"
    property alias number: numEntry.text

    /// Emitted when the user wants to pick a contact instead of typing.
    signal contactLookupRequested(string prefix);
    /// A call has been placed from here, so whatever is showing the keypad can
    /// put it away.
    signal dialled();

    // Hardware numeric keypad -> dialer. The page itself holds key focus -- not
    // numEntry's TextField, which is activeFocusOnPress:false -- so physical keys
    // reach us without raising the on-screen keyboard or activating the maliit
    // input context. The tab/stack machinery briefly hands focus elsewhere just
    // after load, so reclaim it whenever the dialer is the visible page.
    focus: true
    onVisibleChanged: if (visible) pDialPage.forceActiveFocus();
    onActiveFocusChanged: if (!activeFocus && visible) refocusTimer.restart();
    Component.onCompleted: pDialPage.forceActiveFocus();

    Keys.onPressed: (event) => {
        var k = event.key;
        if ((k >= Qt.Key_0 && k <= Qt.Key_9) ||
            k === Qt.Key_Asterisk || k === Qt.Key_NumberSign || k === Qt.Key_Plus) {
            // Route through the on-screen pad's signal so hardware keys get the
            // same feedback, in-call DTMF and insert handling as tapped keys.
            numPad.sendKey(k);
        } else if (k === Qt.Key_Backspace || k === Qt.Key_Delete) {
            numEntry.backspace();
        } else if (k === Qt.Key_Call || k === Qt.Key_Yes ||
                   k === Qt.Key_Return || k === Qt.Key_Enter) {
            pDialPage.dial();
        } else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Timer {
        id: refocusTimer
        interval: 0
        onTriggered: if (pDialPage.visible && !pDialPage.activeFocus) pDialPage.forceActiveFocus();
    }

    function reset() {
        numEntry.clear();
    }

    // Shared by the dial button and the hardware Call/Enter keys.
    function dial() {
        if (numEntry.text.length === 0) {
            // Dial on an empty field brings back the last number dialled.
            var last = pDialPage.dialHandler ? pDialPage.dialHandler.lastDialedNumber : "";
            if (last.length > 0)
                numEntry.text = last;
            else
                pDialPage.contactLookupRequested("");
            return;
        }
        pDialPage.dialHandler.dial(numEntry.getPhoneNumber());
        pDialPage.dialled();
    }

    /// Fills the dialpad from contact lookup without dialling yet.
    function setContact(name, phoneNumber) {
        numEntry.setContact(name, phoneNumber);
    }

    // Contacts with a number starting with what has been typed so far. The
    // legacy dialer showed the same running match above the dialpad.
    property var matchingContacts: (contacts && numEntry.text.length >= 3 &&
                                    numEntry.contactName.length === 0)
                                       ? contacts.matchByNumberPrefix(numEntry.text)
                                       : []

    LunaService {
        id: service
        name: "org.webosports.app.phone"
    }

    /**
     * On a handset the keypad is the screen, so it takes all of it. On a
     * tablet it keeps a fixed, phone-sized footprint in the middle, rather
     * than stretching keys across a screen far wider than a thumb.
     */
    property bool fillsScreen: false

    // A key is about 4:3, so the pad's height follows from its width -- except
    // where it fills the screen, and the height it is given comes first.
    readonly property real padWidth: fillsScreen ? width - Units.gu(1)
                                                 : Math.min(width - Units.gu(2), Units.gu(32))

    /**
     * How the page is divided between the keys and everything else.
     *
     * The field and the dial button each have a natural size. The field is
     * seven grid units tall; the button keeps its artwork's proportions, so
     * drawn the full width of the page it is about a fifth of that width
     * tall. On a handset shaped like a Pre3 the two together come to roughly
     * a quarter of the page and the keys take the rest, which is the layout
     * these numbers were drawn for.
     *
     * A square screen breaks that. The Q25's page is no taller than it is
     * wide, so the same two naturals eat close to half of it and leave each
     * key four times wider than it is tall -- a row of letterboxes, and the
     * first thing anyone complains about.
     *
     * So the keys are budgeted first: they keep at least this share of the
     * page, and the chrome gets the remainder. What it cannot have comes off
     * both pieces in proportion rather than out of one of them, so on a short
     * screen the dialer still looks like itself, only tighter.
     */
    readonly property real keysMinimumShare: 0.7

    /**
     * The keys and the dial button are drawn the same width, always.
     *
     * They are the two things on the page a thumb aims at, sitting one above
     * the other, and a button that stops short of the keys above it reads as a
     * mistake -- which is what the first pass at this produced.
     *
     * Which of them gives way is settled by the artwork. buttons-numpad.png is
     * a nine-slice and stretches to any size at all; dial-button.png is a
     * fixed plate with the handset glyph painted into the middle of it, so its
     * proportions are the one thing on this page that cannot bend. The keys
     * come to the button's width, then, and not the other way about.
     *
     * The pad's backdrop still fills the page either side of them, so this
     * narrows the block of keys rather than leaving a column of page down both
     * edges.
     */
    readonly property real naturalKeypadWidth: padWidth - Units.gu(2)

    readonly property real naturalEntryHeight: Units.gu(7)
    readonly property real naturalMatchHeight: matchingContacts.length > 0 ? Units.gu(3.5) : 0
    /// heightPerWidth is the button's own: only it knows how its sprite is cut.
    readonly property real naturalDialHeight: naturalKeypadWidth * dialButton.heightPerWidth
    readonly property real naturalChromeHeight: naturalEntryHeight + naturalMatchHeight
                                                + naturalDialHeight

    /**
     * One below on a page too short for the chrome's natural size, one
     * otherwise. Nothing here reads a child's actual height, so none of it
     * can chase the sizes it is deciding.
     */
    readonly property real chromeScale: {
        if (!fillsScreen || naturalChromeHeight <= 0)
            return 1;
        var allowed = height * (1 - keysMinimumShare);
        return allowed < naturalChromeHeight ? allowed / naturalChromeHeight : 1;
    }

    readonly property real entryHeight: naturalEntryHeight * chromeScale
    readonly property real matchHeight: naturalMatchHeight * chromeScale
    readonly property real dialHeight: naturalDialHeight * chromeScale

    /**
     * What the button comes out at once its height has been capped, and so
     * what the keys above it are drawn at too.
     *
     * Rounded down to a whole number of columns. NumPad's key width is an int,
     * so three of them fall short of any width that is not a multiple of
     * three, and the button would overhang the keys by a pixel or two -- which
     * is precisely the misalignment this is here to remove.
     */
    readonly property real keypadWidth: 3 * Math.floor(naturalKeypadWidth * chromeScale / 3)

    readonly property real padKeysHeight: fillsScreen
                                              ? Math.max(0, height - entryHeight
                                                            - matchHeight - dialHeight)
                                              : padWidth * 0.95

    Item {
        id: dialpadPanel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: pDialPage.padWidth
        height: pDialPage.entryHeight + pDialPage.matchHeight
                + pDialPage.padKeysHeight + pDialPage.dialHeight

        NumberEntry {
            appTheme: pDialPage.appTheme
            id: numEntry

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            fieldHeight: pDialPage.entryHeight
            textColor: '#ffffff'
            countryCode: contacts ? contacts.countryCode : "US"

            onEmptyFieldClicked: pDialPage.contactLookupRequested("")
        }

    // A single match fills the field; several open the full contact list.
    Rectangle {
        id: matchStrip

        anchors {
            top: numEntry.bottom
            left: parent.left
            right: parent.right
        }
        height: pDialPage.matchHeight
        visible: pDialPage.matchingContacts.length > 0

        color: appTheme.panelFooterColor

        Text {
            anchors.fill: parent
            anchors.leftMargin: Units.gu(2)
            verticalAlignment: Text.AlignVCenter
            color: 'white'
            elide: Text.ElideRight
            font.pixelSize: FontUtils.sizeToPixels("small")
            text: pDialPage.matchingContacts.length === 1
                      ? PhoneNumberUtils.personDisplayName(pDialPage.matchingContacts[0].person)
                      : qsTr("%1 matching contacts").arg(pDialPage.matchingContacts.length)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (pDialPage.matchingContacts.length === 1) {
                    var match = pDialPage.matchingContacts[0];
                    numEntry.setContact(PhoneNumberUtils.personDisplayName(match.person),
                                        match.phoneNumber.value);
                } else {
                    pDialPage.contactLookupRequested(numEntry.text);
                }
            }
        }
    }

    NumPad {
        appTheme: pDialPage.appTheme
        id: numPad
        // Named so the layout tests can measure it.
        objectName: "numPad"
        anchors {
            top: matchStrip.bottom
            bottom: dialButton.top
            left: parent.left
            right: parent.right
        }

        // Same width as the dial button below, which is the width the button's
        // artwork can be drawn at without stretching the handset on it.
        gridWidth: pDialPage.keypadWidth

        function vibrateFailure(message) {
            console.log("Unable to vibrate");
        }

        function dtmfFailure(message) {
            console.log("Unable to play DTMF tone");
        }

        onSendKey: (keycode) => {
            var feedback = AppTweaks.dialpadFeedbackTweakValue;

            if (feedback === "vibrateSound" || feedback === "vibrateOnly") {
                service.call("luna://com.palm.vibrate/vibrate", JSON.stringify({
                                                              period: 100, duration: 10
                                                          }), undefined,
                                           vibrateFailure)
            }

            if (keycode === Qt.Key_LaunchMail) {
                // Long press on 1 calls voicemail, as on the original dialpad.
                pDialPage.dialHandler.dialVoicemail();
                return;
            }

            var character = String.fromCharCode(keycode);

            // With a call up, the dialpad doubles as a DTMF pad.
            if (voiceCallMgrWrapper && voiceCallMgrWrapper.activeVoiceCall) {
                voiceCallMgrWrapper.sendDtmf(character);
                return;
            }

            // Local dialpad feedback tone via audiod's DTMF generator
            // (com.palm.audio/dtmf/playDTMF). Nemo's manager.startDtmfTone()
            // routes through ngfd, which LuneOS does not run, so it is silent
            // here. audiod plays a self-stopping one-shot; only 0-9, * and #
            // have tones.
            if ((feedback === "vibrateSound" || feedback === "soundOnly") &&
                ((character >= "0" && character <= "9") || character === "*" || character === "#"))
                service.call("luna://com.palm.audio/dtmf/playDTMF",
                             JSON.stringify({name: character}), undefined, dtmfFailure);

            numEntry.insert(character);
        }
    }

    DialButton {
        appTheme: pDialPage.appTheme
        id: dialButton
        // Named so the layout tests can measure it.
        objectName: "dialButton"

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        // The button keeps its artwork's proportions, so it is narrowed to the
        // height it is allowed rather than drawn the full width of the panel
        // and squashed onto it. The keys above are drawn to match.
        preferredWidth: pDialPage.keypadWidth
        maximumHeight: pDialPage.dialHeight

        // Every dial string -- number, MMI code, USSD, in-call digit -- goes
        // through the dial handler (via pDialPage.dial()) so the GSM rules apply
        // uniformly, whether triggered by this button or the hardware Call key.
        onClicked: pDialPage.dial()
    }
    }
}
