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
import MeeGo.QOfono 0.2

Item {
    id: telephonyManager

    /**
     * public API
     **/

    property bool present: true

    property string subscriberIdentity: ""
    property string mobileCountryCode: ""
    property string mobileNetworkCode: ""
    property bool pinRequired: false

    property int pinRetry: 3

    function changePin(type, oldPin, newPin){

    }

    function enterPin(type, pin) {
        if (!_validatePin(pin))
            return false;

        simManager.enterPin(_convertPinType(type), pin);
        return true;
    }

    function resetPin(type, puk, newpin){

    }

    function lockPin(type, pin){

    }

    function unlockPin(type, pin) {
        if (!_validatePin(pin))
            return false;
        simManager.unlockPin(_convertPinType(type), pin);
        return true;
    }

    function getPinRetries(type) {
        return simManager.pinRetries[_convertPinType(type)];
    }

    /**
     * private API
     **/

    function _convertPinType(type) {
        switch (type) {
        case 'pin':
            return OfonoSimManager.SimPin;
        default:
            break;
        }

        return OfonoSimManager.NoPin;
    }

    function _validatePin(pin) {
        console.log("minimumPinLength: " + simManager.minimumPinLength(OfonoSimManager.SimPin));
        console.log("maxmimumPinLength: " + simManager.maximumPinLength(OfonoSimManager.SimPin));
        return (pin >= simManager.minimumPinLength(OfonoSimManager.SimPin) && pin <= simManager.maximumPinLength(OfonoSimManager.SimPin));
    }

    function getModemPath() {
        return modemManager.modems[0]
    }

    onPinRequiredChanged: {
        if (telephonyManager.pinRequired) {
            console.log("SIM PIN is required");
            main.showSIMPinDialog()
        }
        else {
            console.log("SIM PIN is not required");
        }
    }

    OfonoManager {
        id: modemManager

        Component.onCompleted: {
            console.log("modem->online:" , JSON.stringify(modem.online));
            console.log("modem->powered:" , JSON.stringify(modem.powered));
            console.log("modem->name:" , JSON.stringify(modem.name));
            console.log("modem->manufacturer:" , JSON.stringify(modem.manufacturer));
            console.log("modem->features:" , JSON.stringify(modem.features));
            console.log("modem->revision:" , JSON.stringify(modem.revision));
            console.log("modem->serial:" , JSON.stringify(modem.serial));
        }

        onAvailableChanged: {
            console.log("Ofono is " + available)
            console.log(modemManager.available ? network.currentOperator["Name"].toString() :"Ofono not available")
        }
        onModemAdded: {
            console.log("modem added "+modem)
        }
        onModemRemoved: console.log("modem removed")
    }

    OfonoConnMan {
        id: ofono1
        Component.onCompleted: {
            console.log("modems: " + modemManager.modems)
        }
        modemPath: modemManager.modems[0]
    }

    OfonoModem {
        id: modem
        modemPath: modemManager.modems[0]
    }

    OfonoContextConnection {
        id: context1
        contextPath : ofono1.contexts[0]

        Component.onCompleted: {
            console.log(context1.active ? "Connection online" : "Connection offline");
        }

        onActiveChanged: {
            console.log(context1.active ? "Connection online" : "Connection offline");
        }
    }

    OfonoSimManager {
        id: simManager
        modemPath: modemManager.modems[0]


        Component.onCompleted: {
            console.log("simManager->present:" , JSON.stringify(simManager.present));
            console.log("simManager->CardIdentifier:" , JSON.stringify(simManager.cardIdentifier));
            console.log("simManager->SubscriberIdentity:" , JSON.stringify(simManager.subscriberIdentity));
            console.log("simManager->SubscriberNumbers:" , JSON.stringify(simManager.subscriberNumbers));
            console.log("simManager->LockedPins:" , JSON.stringify(simManager.lockedPins));
            console.log("simManager->ServiceNumbers:" , JSON.stringify(simManager.serviceNumbers));
            console.log("simManager->PinRequired:" , JSON.stringify(simManager.pinRequired));
            console.log("simManager->Retries:" , JSON.stringify(simManager.retries));
            console.log("pinRetries:" , JSON.stringify(simManager.pinRetries));

            telephonyManager.subscriberIdentity = simManager.subscriberIdentity
            telephonyManager.present = simManager.present

        }

        onPinRequiredChanged: {
            if (simManager.pinRequired === OfonoSimManager.SimPin)
                telephonyManager.pinRequired = true;
            else
                telephonyManager.pinRequired = false;
            /* FIXME support other pin types too */
        }
    }

    OfonoNetworkRegistration {
        id: network
        modemPath: modemManager.modems[0]

        Component.onCompleted: {
            console.log("network->currentOperatorPath" , JSON.stringify(network.currentOperatorPath));
            console.log("network->technology:" , JSON.stringify(network.technology));
            console.log("network->mode:" , JSON.stringify(network.mode));
            console.log("network->status:" , JSON.stringify(network.status));
            console.log("network->name:" , JSON.stringify(network.name));

        }

        onNetworkOperatorsChanged : {
            console.log("onNetworkOperatorsChanged")
            console.log("network->currentOperatorPath" , JSON.stringify(network.currentOperatorPath));
            if(network.currentOperatorPath) {
                console.log("network->technology:" , JSON.stringify(network.technology));
                console.log("network->mode:" , JSON.stringify(network.mode));
                console.log("network->status:" , JSON.stringify(network.status));
                console.log("network->name:" , JSON.stringify(network.name));
            }else{
                console.log("Not Registered with a network")
            }
        }

        onScanError: {
            console.log("Network Scan Failed");
        }
    }

    OfonoNetworkOperator {
        id: networkOperator

    }

}

