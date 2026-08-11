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

    function reset() {
        numEntry.clear();
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
        usePrivateBus: true
    }

    // The dialpad keeps a fixed, phone-sized footprint and is centred, rather
    // than stretching to whatever the window happens to be. A key is about
    // 4:3, so the pad's height follows from its width.
    readonly property real padWidth: Math.min(width - Units.gu(2), Units.gu(32))
    // Keys are roughly 4:3, so four rows come to about the pad's own width.
    readonly property real padKeysHeight: padWidth * 0.95

    Item {
        id: dialpadPanel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: pDialPage.padWidth
        height: numEntry.height + matchStrip.height + pDialPage.padKeysHeight + dialButton.height

        NumberEntry {
            id: numEntry

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

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
        height: visible ? Units.gu(3.5) : 0
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
        id: numPad
        anchors {
            top: matchStrip.bottom
            bottom: dialButton.top
            left: parent.left
            right: parent.right
        }

        function vibrateFailure(message) {
            console.log("Unable to vibrate");
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

            if ((feedback === "vibrateSound" || feedback === "soundOnly") && voiceCallMgrWrapper)
                voiceCallMgrWrapper.manager.startDtmfTone(character);

            numEntry.insert(character);
        }
    }

    DialButton {
        id: dialButton

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        onClicked: {
            if (numEntry.text.length === 0) {
                // Dial on an empty field brings back the last number dialled,
                // ready to be sent again, as the original dialer did.
                var last = pDialPage.dialHandler ? pDialPage.dialHandler.lastDialedNumber : "";
                if (last.length > 0)
                    numEntry.text = last;
                else
                    pDialPage.contactLookupRequested("");
                return;
            }

            // Every dial string -- number, MMI code, USSD, in-call digit --
            // goes through the dial handler so the GSM rules apply uniformly.
            pDialPage.dialHandler.dial(numEntry.getPhoneNumber());
        }
    }
    }
}
