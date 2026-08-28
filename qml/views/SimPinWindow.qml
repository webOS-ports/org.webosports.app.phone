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
import QtQuick.Layouts 1.0

import Eos.Window 0.1

import LunaNext.Common 0.1
import LuneOS.Service 1.0

import QOfono 0.2
import "../services"
import "../services/PinTypes.js" as PinTypes
import "../services/CallMessages.js" as CallMessages

WebOSWindow {
    id: simPinWindow

    property TelephonyManager telephonyManager
    property VoiceCallMgrWrapper voiceCallMgrWrapper

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    keepAlive: true

    Component.onCompleted: {
        simPinWindow.setWindowProperty("LuneOS_window", "pin");
    }

    property string _enteredPuk: ""
    property int _confirmedPinType
    property bool _showNeeded: false

    function _finished(success) {
        if (success) {
            _enteredPuk = "";
            pinInput.clear();
            pinInput.retrying = false;
            simPinWindow.close();
        }
    }

    function _handlePinComplete(error, message) {
        switch (error) {
        case OfonoSimManager.NotImplementedError:
        case OfonoSimManager.UnknownError:
            console.log("PIN operation failed: " + message);
            _statusMessage = CallMessages.pinFailureDefault;
            _finished(false);
            break;
        case OfonoSimManager.InProgressError:
            break;
        case OfonoSimManager.InvalidArgumentsError:
        case OfonoSimManager.InvalidFormatError:
            _statusMessage = CallMessages.pinFailure["badformat"];
            pinInput.clear();
            break;
        case OfonoSimManager.FailedError:
            // A wrong PUK must not silently take the first half of a PUK+PIN
            // pair with it -- start the pair over so the user is not left
            // entering a new PIN against a PUK the SIM already rejected.
            _statusMessage = simManager.isPukType(_confirmedPinType)
                                 ? CallMessages.pukFailure["incorrect"]
                                 : CallMessages.pinFailure["incorrect"];
            _enteredPuk = "";
            pinInput.retrying = true;
            pinInput.resetEntry();
            break;
        case OfonoSimManager.NoError:
            _statusMessage = "";
            _finished(true);
            break;
        }
    }

    property string _statusMessage: ""

    function _handleSimPermBlocked() {
        _statusMessage = qsTr("This SIM card is permanently blocked. Contact your network operator.");
    }

    PhoneUiTheme { id: phoneUiAppTheme }

    OfonoManager {
        id: modemManager
    }

    OfonoSimManager {
        id: simManager

        modemPath: modemManager.defaultModem

        onEnterPinComplete: (error, errorString) => _handlePinComplete(error, errorString)
        onResetPinComplete: (error, errorString) => _handlePinComplete(error, errorString)

        onPinRetriesChanged: {
            for (var type in pinRetries) {
                if (type === PinTypes.SimPuk.toString() && pinRetries[type] === 0)
                    _handleSimPermBlocked();
            }
        }

        onPinRequiredChanged: {
            // Whatever half-finished PUK sequence was in flight no longer
            // applies once the SIM asks for something else.
            _enteredPuk = "";
            pinInput.resetEntry();

            if (simPinWindow.visible)
                return;

            if (simManager.pinRequired === OfonoSimManager.NoPin)
                return;

            simPinWindow.show();
        }
    }

    SimPinInput {
        id: pinInput

        anchors.fill: parent
        visible: !emergencyDialer.visible

        simManager: simManager
        requestedPinType: simManager.pinRequired
        statusMessage: simPinWindow._statusMessage

        onPinEntered: {
            _confirmedPinType = simManager.pinRequired
            simPinWindow._statusMessage = "";

            if (simManager.isPukType(simManager.pinRequired)) {
                if (_enteredPuk.length === 0) {
                    // First half of the PUK sequence: remember the PUK, then
                    // ask for the new PIN the SIM will be reset to.
                    _enteredPuk = pinInput.pin;
                    pinInput.requestNewPin();
                }
                else {
                    simManager.resetPin(simManager.pinRequired, _enteredPuk, pinInput.pin);
                }
            }
            else {
                simManager.enterPin(simManager.pinRequired, pinInput.pin);
            }
        }

        onEmergencyCallRequested: emergencyDialer.visible = true

        onCanceled: {
            simPinWindow.close();
        }
    }

    // A locked SIM must still be able to reach the emergency services; the
    // legacy app had a whole phoneEmergency card for exactly this.
    EmergencyDialerPage {
        id: emergencyDialer

        anchors.fill: parent
        visible: false

        appTheme: phoneUiAppTheme
        telephonyManager: simPinWindow.telephonyManager
        voiceCallMgrWrapper: simPinWindow.voiceCallMgrWrapper

        onClosed: emergencyDialer.visible = false
    }
}
