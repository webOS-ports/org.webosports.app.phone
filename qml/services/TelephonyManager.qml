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
import QtQml 2.2

import MeeGo.QOfono 0.2

Item {
    id: telephonyManager

    /**
     * public API
     **/

    property bool present: simManager.present
    property string subscriberIdentity: simManager.subscriberIdentity
    property string mobileCountryCode: simManager.mobileCountryCode
    property string mobileNetworkCode: simManager.mobileNetworkCode

    signal ussdResponse(string response);

    function initiateUssd(command) {
        ofonoUSSD.initiate(command);
    }

    /**
     * private API
     **/

    function getModemPath() {
        return modemManager.defaultModem
    }

    OfonoManager {
        id: modemManager

        onAvailableChanged: {
            console.log("Ofono is " + available + (modemManager.available ? network.currentOperatorPath :"Ofono not available"))
        }
        onModemAdded: {
            console.log("modem added "+modem)
        }
        onModemRemoved: console.log("modem removed")
    }

    OfonoSimManager {
        id: simManager
        modemPath: modemManager.defaultModem

        onPresentChanged: console.log("simManager->present:" , JSON.stringify(simManager.present));
        onSubscriberNumbersChanged: console.log("simManager->subscriberNumbers:" , JSON.stringify(simManager.subscriberNumbers));
        onMobileCountryCodeChanged: console.log("simManager->mobileCountryCode:" , JSON.stringify(simManager.mobileCountryCode));
        onMobileNetworkCodeChanged: console.log("simManager->mobileNetworkCode:" , JSON.stringify(simManager.mobileNetworkCode));
        onLockedPinsChanged: console.log("simManager->lockedPins:" , JSON.stringify(simManager.lockedPins));
        onServiceNumbersChanged: console.log("simManager->serviceNumbers:" , JSON.stringify(simManager.serviceNumbers));
        onPinRequiredChanged: console.log("simManager->pinRequired:" , JSON.stringify(simManager.pinRequired));
        onPinRetriesChanged: console.log("simManager->pinRetries:" , JSON.stringify(simManager.pinRetries));

        // these two may be sensitive, do not risk having them on a paste on internet
        //onCardIdentifierChanged: console.log("simManager->CardIdentifier:" , JSON.stringify(simManager.cardIdentifier));
        //onSubscriberIdentityChanged: console.log("simManager->SubscriberIdentity:" , JSON.stringify(simManager.subscriberIdentity));
    }

    OfonoSupplementaryServices {
        id: ofonoUSSD
        modemPath: modemManager.defaultModem

        onUssdResponse: telephonyManager.ussdResponse(response);
        onInitiateFailed: telephonyManager.ussdResponse("USSD request failed.");
    }

/*
    OfonoConnMan {
        id: ofono1
        modemPath: modemManager.defaultModem
    }

    OfonoModem {
        id: modem
        modemPath: modemManager.defaultModem

        onOnlineChanged: console.log("modem->online:" , JSON.stringify(modem.online));
        onPoweredChanged: console.log("modem->powered:" , JSON.stringify(modem.powered));
        onNameChanged: console.log("modem->name:" , JSON.stringify(modem.name));
        onManufacturerChanged: console.log("modem->manufacturer:" , JSON.stringify(modem.manufacturer));
        onFeaturesChanged: console.log("modem->features:" , JSON.stringify(modem.features));
        onRevisionChanged: console.log("modem->revision:" , JSON.stringify(modem.revision));
        onSerialChanged: console.log("modem->serial:" , JSON.stringify(modem.serial));
    }

    Instantiator {
        model: ofono1.contexts
        delegate: OfonoContextConnection {
            id: contextConnection
            contextPath: modelData

            onTypeChanged: console.log("contextConnection("+contextPath+")->type:" , JSON.stringify(contextConnection.type));
            onActiveChanged: console.log("contextConnection("+contextPath+")->active:" , JSON.stringify(contextConnection.active));
        }
    }

    OfonoNetworkRegistration {
        id: network
        modemPath: modemManager.defaultModem

        onCurrentOperatorPathChanged: console.log("network->currentOperatorPath" , JSON.stringify(network.currentOperatorPath));
        onTechnologyChanged: console.log("network->technology:" , JSON.stringify(network.technology));
        onModeChanged: console.log("network->mode:" , JSON.stringify(network.mode));
        onStatusChanged: console.log("network->status:" , JSON.stringify(network.status));
        onNameChanged: console.log("network->name:" , JSON.stringify(network.name));

        onNetworkOperatorsChanged : console.log("network->networkOperators" , JSON.stringify(network.networkOperators));

        onScanError: {
            console.log("Network Scan Failed");
        }
    }

    OfonoNetworkOperator {
        id: networkOperator
    }
    */
}

