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
import MeeGo.QOfono 0.2
import "../services"
import "../services/PinTypes.js" as PinTypes

LuneOS.ApplicationWindow {
    id: simPinWindow

    width: Settings.displayWidth
    height: Settings.displayHeight
    color: phoneUiAppTheme.backgroundColor

    property string _enteredPuk: ""
    property int _confirmedPinType
    property bool _showNeeded: false

    function _finished(success) {
        if (success)
            simPinWindow.close();
    }

    function _handlePinComplete(error, message) {
        switch (error) {
        case OfonoSimManager.NotImplementedError:
        case OfonoSimManager.UnknownError:
            _finished(false);
            break;
        case OfonoSimManager.InProgressError:
            break;
        case OfonoSimManager.InvalidArgumentsError:
        case OfonoSimManager.InvalidFormatError:
        case OfonoSimManager.FailedError:
            pinInput.clear();
            break;
        case OfonoSimManager.NoError:
            if (simManager.isPukType(_confirmedPinType)) {

            }
            else {
                // PIN was correct
            }

            _finished(true);

            break;
        }
    }

    function _handleSimPermBlocked() {
    }

    PhoneUiTheme { id: phoneUiAppTheme }

    OfonoManager {
        id: modemManager
    }

    OfonoSimManager {
        id: simManager

        modemPath: modemManager.modems[0]

        onEnterPinComplete: _handlePinComplete(error, errorString)
        onResetPinComplete: _handlePinComplete(error, errorString)

        onPinRetriesChanged: {
            for (var type in pinRetries) {
                if (type === PinTypes.SimPuk.toString() && pinRetries[type] === 0)
                    _handleSimPermBlocked();
            }
        }

        onPinRequiredChanged: {
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

        simManager: simManager
        requestedPinType: simManager.pinRequired

        onPinEntered: {
            _confirmedPinType = simManager.pinRequired

            if (simManager.isPukType(simManager.pinRequired)) {
                if (_enteredPuk.length === 0) {
                    _enteredPuk = pinInput.pin;
                    pinInput.requestNewPin();
                }
                else {
                    simManager.resetPin(simManager.pinRequired, _enteredPuk, pinInput.pin);
                    _enteredPuk = "";
                }
            }
            else {
                simManager.enterPin(simManager.pinRequired, pinInput.pin);
            }
        }

        onCanceled: {
            simPinWindow.close();
        }
    }
}
