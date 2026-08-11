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

import "../services/DialStringParser.js" as DialStringParser
import "../services/CallMessages.js" as CallMessages

/**
 * The emergency dialpad shown over a locked SIM or a locked device.
 *
 * Ports the legacy phoneEmergency card: a plain dialpad that will only place a
 * call to a number the network recognises as an emergency number, so it can be
 * offered without unlocking anything. The QML app had no emergency dialling at
 * all -- with a PIN-locked SIM there was no way to call 112.
 */
BasePage {
    id: emergencyPage

    pageName: "EmergencyDialer"

    signal closed();

    // Numbers the network reports, falling back to the standard list so this
    // still works before the modem has registered.
    readonly property var emergencyNumbers: (telephonyManager && telephonyManager.emergencyNumbers &&
                                             telephonyManager.emergencyNumbers.length > 0)
                                                ? telephonyManager.emergencyNumbers
                                                : DialStringParser.DefaultEmergencyNumbers

    readonly property bool isEmergencyNumber: DialStringParser.isEmergencyNumber(numEntry.text,
                                                                                 emergencyNumbers)

    function reset() {
        numEntry.clear();
    }

    Text {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: 'white'
        font.pixelSize: FontUtils.sizeToPixels("medium")
        text: qsTr("Emergency calls only")
    }

    NumberEntry {
        id: numEntry

        anchors {
            top: header.bottom
            left: dialButton.left
            right: dialButton.right
        }

        textColor: '#ffffff'
        isPhoneNumber: false
    }

    Text {
        id: hint

        anchors {
            top: numEntry.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(0.5)
        }
        horizontalAlignment: Text.AlignHCenter
        color: 'grey'
        font.pixelSize: FontUtils.sizeToPixels("x-small")
        text: emergencyPage.emergencyNumbers.slice(0, 6).join("  ")
    }

    NumPad {
        anchors {
            top: hint.bottom
            bottom: dialButton.top
            left: dialButton.left
            right: dialButton.right
        }
        mode: 'sim'

        onSendKey: (keycode) => numEntry.insert(String.fromCharCode(keycode))
    }

    DialButton {
        id: dialButton

        anchors {
            bottom: cancelButton.top
            left: parent.left
            right: parent.right
        }

        // Greyed out until what has been typed is actually an emergency number,
        // so it is obvious the pad will not place an ordinary call.
        opacity: emergencyPage.isEmergencyNumber ? 1.0 : 0.4

        onClicked: {
            if (!emergencyPage.isEmergencyNumber) {
                console.log(numEntry.text + " is not an emergency number");
                return;
            }

            // Emergency calls bypass the dial handler's MMI and shortcut
            // handling entirely and go straight to the modem.
            if (telephonyManager && !telephonyManager.radioOnline)
                telephonyManager.setRadioOnline(true);

            voiceCallMgrWrapper.dial(numEntry.text);
            numEntry.clear();
        }
    }

    PinInputButton {
        id: cancelButton

        width: parent.width / 3
        height: Units.gu(5)

        text: qsTr("Cancel")

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Units.gu(1)

        onClicked: {
            numEntry.clear();
            emergencyPage.closed();
        }
    }
}
