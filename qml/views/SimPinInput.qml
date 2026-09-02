/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import QtQuick.Layouts 1.1
import QOfono 0.2

import "../services/PinTypes.js" as PinTypes

import LunaNext.Common 0.1

Item {
    id: simPinInput

    property UiTheme appTheme

    property OfonoSimManager simManager
    property int requestedPinType: 0
    property bool retrying: false
    property alias pin: pinEntry.text

    /// Set by the window when an attempt failed, e.g. "Incorrect PUK code".
    property string statusMessage: ""

    signal pinEntered
    signal canceled
    /// The user wants the emergency dialpad instead of unlocking.
    signal emergencyCallRequested

    function clear() {
        pin = "";
    }

    /// Back to asking for whatever the SIM currently wants, discarding any
    /// half-entered new PIN.
    function resetEntry() {
        _enteringNewPin = false;
        _newPin = "";
        clear();
    }

    function requestNewPin() {
        _enteringNewPin = true;
        _newPin = "";
        clear();
    }

    property bool _enteringNewPin: false
    property int _currentPinType: _enteringNewPin && simManager.isPukType(requestedPinType) ?
                                        simManager.pukToPin(requestedPinType) : requestedPinType
    property int _minimumPinLength: simManager.minimumPinLength(_currentPinType)
    property int _maximumPinLength: simManager.maximumPinLength(_currentPinType)
    property int _pinRetries: (simPinInput.requestedPinType !== PinTypes.NoPin) ?
                                  simManager.pinRetries[simPinInput.requestedPinType] : 0

    property string _newPin: ""

    ColumnLayout{
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Units.gu(2)
        height: Units.gu(10)

        Label {
            id: title
            font.pixelSize: FontUtils.sizeToPixels("large")
            color: appTheme.headerTitle
            Layout.alignment: Qt.AlignHCenter
            text: {
                // The PUK flow asks for three things in turn -- the PUK, then
                // the new PIN, then the same PIN again -- so the title has to
                // follow the step rather than only the PIN type.
                if (_enteringNewPin)
                    return _newPin.length === 0 ? qsTr("Enter new PIN")
                                                : qsTr("Enter new PIN again");

                switch (requestedPinType) {
                case PinTypes.SimPin:
                    return retrying ? qsTr("Incorrect PIN code") : qsTr("Enter PIN code");
                case PinTypes.SimPin2:
                    return retrying ? qsTr("Incorrect PIN2 code") : qsTr("Enter PIN2 code");
                case PinTypes.SimPuk:
                    return retrying ? qsTr("Incorrect PUK code") : qsTr("Enter PUK code");
                case PinTypes.SimPuk2:
                    return retrying ? qsTr("Incorrect PUK2 code") : qsTr("Enter PUK2 code");
                default:
                    break;
                }

                return "";
            }
        }

        Label {
            id: warning
            color: appTheme.headerTitle
            font.pixelSize: FontUtils.sizeToPixels("medium")
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (simPinInput.statusMessage.length > 0)
                    return simPinInput.statusMessage;

                if (_enteringNewPin)
                    return "";

                switch (requestedPinType) {
                case PinTypes.SimPin:
                case PinTypes.SimPin2:
                    if (isNaN(_pinRetries) || _pinRetries === 0)
                        return "";
                    return _pinRetries === 1
                        ? qsTr("Only 1 attempt left. If this goes wrong your SIM will be locked and you will need a PUK code to unlock it.")
                        : qsTr("%1 attempts left").arg(_pinRetries);
                case PinTypes.SimPuk:
                case PinTypes.SimPuk2:
                    if (isNaN(_pinRetries) || _pinRetries === 0)
                        return "";
                    return _pinRetries === 1
                        ? qsTr("Only 1 attempt left. If this goes wrong your SIM card will be permanently blocked.")
                        : qsTr("%1 attempts left. Ask your network service provider for the PUK code.").arg(_pinRetries);
                default:
                    break;
                }

                return "";
            }
        }
    }

    NumberEntry {
        appTheme: simPinInput.appTheme
        id: pinEntry

        anchors {
            top: header.bottom
            left:parent.left
            right:parent.right
        }

        textColor: appTheme.foregroundColor
        echoMode: TextInput.Password
        isPhoneNumber: false
    }

    NumPad {
        appTheme: simPinInput.appTheme
        id: keyboard

        anchors {
            top: pinEntry.bottom
            left: parent.left
            right: parent.right
            // stop above the emergency button rather than at the window edge,
            // so the two buttons that sit on the blank keys are not covered
            bottom: emergencyButton.top
        }

        mode:'sim'

        onSendKey: (keycode) => {
            if (pinEntry.text.length >= _maximumPinLength)
                return;
            pinEntry.insert(String.fromCharCode(keycode));
        }
    }

    // Cancel and Enter fill the two cells the keypad leaves blank in 'sim'
    // mode, so the bottom row reads Cancel / 0 / Enter. They used to be
    // anchored to the bottom of the window while the keypad was stretched to
    // their bottom edge as well, which drew both of them across the last row
    // of keys.
    PinInputButton {
        id: cancelButton

        width: keyboard.keysWidth
        height: keyboard.keysHeight

        text: qsTr("Cancel")

        x: keyboard.x + keyboard.gridX
        y: keyboard.y + keyboard.gridY + keyboard.keysHeight * 3

        onClicked: {
            simPinInput.canceled();
        }
    }

    // A locked SIM still has to be able to reach the emergency services.
    PinInputButton {
        id: emergencyButton

        width: parent.width / 3
        height: Units.gu(5)

        text: qsTr("Emergency")

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: height / 3

        onClicked: simPinInput.emergencyCallRequested()
    }

    PinInputButton {
        id: okButton

        width: keyboard.keysWidth
        height: keyboard.keysHeight

        text: qsTr("Enter")

        x: keyboard.x + keyboard.gridX + keyboard.keysWidth * 2
        y: keyboard.y + keyboard.gridY + keyboard.keysHeight * 3

        onClicked: {
            // The original test rejected nothing: a length could never be both
            // below the minimum and above the maximum, so short PINs went
            // straight to the SIM and burned a retry.
            if (pinEntry.text.length < simManager.minimumPinLength(_currentPinType) ||
                pinEntry.text.length > simManager.maximumPinLength(_currentPinType))
                return;

            if (_enteringNewPin) {
                if (_newPin.length === 0) {
                    _newPin = pin;
                    clear();
                }
                else {
                    if (_newPin === pin) {
                        simPinInput.pinEntered();
                        _newPin = "";
                    }
                    else {
                        simPinInput.statusMessage = qsTr("The PINs don't match");
                        _newPin = "";
                        clear();
                    }
                }
            }
            else {
                simPinInput.pinEntered();
            }
        }
    }
}
