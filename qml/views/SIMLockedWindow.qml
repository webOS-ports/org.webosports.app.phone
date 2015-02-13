/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1
import LunaNext.Common 0.1
import LuneOS.Service 1.0
import LuneOS.Application 1.0 as LuneOS
import "../services"

LuneOS.ApplicationWindow {
    id: simLockedWindow

    property QtObject mainWindow

    type: LuneOS.ApplicationWindow.Pin

    width: Settings.displayWidth
    height: Settings.displayHeight

    PhoneUiTheme { id: phoneUiAppTheme }

    color: phoneUiAppTheme.backgroundColor

    // Possible states are: none, pin, pin-retry, puk, puk-retry
    property string state:  "none"
    // Possible states are: puk, pin, pin-verify
    property string pukState: "puk"
    property bool showNeeded: false
    property string storedPuk: ""
    property string storedPin: ""

    Connections {
        target: mainWindow
        onVisibleChanged: {
            if (mainWindow.visible && !simLockedWindow.visible && simManager.isPinRequired()) {
                if (mainWindow.windowId === 0)
                    showNeeded = true;
                else {
                    updateStateFromSIM();
                    simLockedWindow.show();
                }
            }
        }
        onWindowIdChanged: {
            if (mainWindow.windowId === 0)
                return;

            if (!showNeeded)
                return;

            updateStateFromSIM();
            simLockedWindow.show();
        }
    }

    function updateStateFromSIM() {
        console.log("SIM state " + simManager.pinRequired);

        switch (simManager.pinRequired) {
        case "pin":
            advanceState("pin");
            simLockedWindow.show();
            break;
        case "puk":
            advanceState("puk");
            simLockedWindow.show();
            break;
        case "blocked":
            // FIXME present banner so users knows he can't try again
            break;
        default:
            break;
        }
    }

    SimManager {
        id: simManager
        onPinRequiredChanged: updateStateFromSIM()
    }

    LunaService {
        id: pin1Verify
        usePrivateBus: true
        service: "palm://com.palm.telephony"
        method: "pin1Verify"

        onResponse: function (message) {
            var response = JSON.parse(message.payload);

            if (!response.returnValue) {
                console.log("Failed to verify pin: ". response.errorText);
                state = "pin-retry";
                return;
            }

            simLockedWindow.close();
        }
    }

    LunaService {
        id: pin1Unblock
        usePrivateBus: true
        service: "palm://com.palm.telephony"
        method: "pin1Unblock"

        onResponse: function (message) {
            var response = JSON.parse(message.payload);

            if (!response.returnValue) {
                console.log("Failed to enter puk: ". response.errorText);
                state = "puk-retry";
                return;
            }

            simLockedWindow.close();
        }
    }

    function advanceState(newState) {
        state = newState;

        console.log("State is now " + state);

        pinEntry.text = "";

        switch (state) {
        case "pin":
            title.text = "Enter SIM PIN";
            break;
        case "pin-retry":
            title.text = "Entered PIN is invalid. Please try again. You have <n> tries left.";
            break;
        case "puk":
            title.text = "Enter SIM PUK";
            break;
        case "puk-retry":
            title.text = "Entered PUK is invalid. Please try again. You have <n> tries left.";
            break;
        default:
            break;
        }
    }

    function advancePukState(newState) {
        pukState = newState;

        switch (pukState) {
        case "puk":
            title.text = "Enter SIM PUK";
            break;
        case "pin":
            title.text = "Please enter a new SIM PIN";
            break;
        case "pin-verify":
            title.text = "Please enter your new PIN for verification again";
            break;
        default:
            break;
        }
    }

    function inPinState() {
        return state === "pin" || state === "pin-retry";
    }

    function inPukState() {
        return state === "puk" || state === "puk-retry";
    }

    Rectangle {
        id: header
        width: Settings.displayWidth
        anchors.left: parent.left
        anchors.right: parent.right
        color: phoneUiAppTheme.headerColor
        radius: 2
        height: Units.gu(10)
        ColumnLayout{
            anchors.fill:parent
            anchors.margins: 8
            spacing: Units.gu(2)

            RowLayout {
                height: parent.height
                anchors.left: parent.left
                anchors.right: parent.right

                Button {
                    text: "Cancel"
                    anchors.left: parent.left
                    anchors.leftMargin: Units.gu(5)
                    width: Units.gu(10)
                    onClicked: stackView.pop()

                    style: CustomButtonStyle {}
                }

                Text {
                    id: title
                    font.pixelSize: Units.dp(18)
                    color: phoneUiAppTheme.headerTitle
                    anchors.horizontalCenter:parent.horizontalCenter
                }

                Button {
                    text: "OK"
                    anchors.right: parent.right
                    anchors.rightMargin: Units.gu(3)
                    onClicked: {
                        if (inPinState()) {
                            console.log("Trying to unlock pin with " + pinEntry.text);
                            pin1Verify.call({"pin": pinEntry.text});
                        }
                        else if (inPukState()) {
                            switch (pukState) {
                            case "puk":
                                storedPuk = pinEntry.text;
                                pinEntry.text = "";
                                advancePukState("pin");
                                break;
                            case "pin":
                                storedPin = pinEntry.text;
                                pinEntry.text = "";
                                advancePukState("pin-verify");
                                break;
                            case "pin-verify":
                                if (storedPin !== pinEntry.text) {
                                    advanceState("puk-retry");
                                    return;
                                }

                                pin1Unblock.call(JSON.stringify({"puk": storedPuk, "newPin": storedPin}));

                                storedPuk = "";
                                storedPin = "";

                                break;
                            default:
                                break;
                            }
                        }
                    }

                    style: CustomButtonStyle {}
                }
            }
        }
    }

    NumberEntry {
        id: pinEntry
        width:parent.width
        height: 90
        anchors.top: header.bottom
        anchors.topMargin: 50
        textColor: phoneUiAppTheme.foregroundColor
        echoMode: TextInput.Password
        isPhoneNumber: false
    }

    NumPad {
        id:keyboard
        anchors {
            horizontalCenter:parent.horizontalCenter
            top: pinEntry.bottom
            bottom: parent.bottom
            topMargin: Units.gu(3)
        }
        mode:'sim'

        onKeyPressed: {
            // Don't allow more than four digits for a PIN
            if (inPinState() && pinEntry.text.length === 4)
                return;

            pinEntry.insert(label);
        }
    }
}
