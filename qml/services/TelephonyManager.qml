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
import QtQml 2.2

import QOfono 0.2

/**
 * Facade over the oFono modem: SIM state, network registration, radio power,
 * emergency numbers, voicemail and supplementary services (USSD).
 *
 * The legacy Enyo app spread this across TelephonyStatusInterface,
 * MultimodeInterface, VoicemailService and the TIL "call capabilities"; on
 * LuneOS oFono exposes all of it directly, so it lives in one place.
 */
Item {
    id: telephonyManager

    /**
     * public API
     **/

    // SIM
    property bool present: simManager.present
    property string subscriberIdentity: simManager.subscriberIdentity
    property string mobileCountryCode: simManager.mobileCountryCode
    property string mobileNetworkCode: simManager.mobileNetworkCode
    property string serviceProviderName: simManager.serviceProviderName
    property var subscriberNumbers: simManager.subscriberNumbers
    property var serviceNumbers: simManager.serviceNumbers
    property bool fixedDialing: simManager.fixedDialing
    property int pinRequired: simManager.pinRequired

    // Network registration
    property string networkStatus: netreg.status        // unregistered/registered/searching/denied/unknown/roaming
    property string networkName: netreg.name
    property string networkTechnology: netreg.technology
    property int signalStrength: netreg.strength
    property bool roaming: netreg.status === "roaming"
    property bool registered: netreg.status === "registered" || roaming

    // Radio. `online === false` is what LuneOS surfaces as airplane mode.
    property bool radioOnline: modem.online
    property bool radioPowered: modem.powered

    // Emergency numbers as reported by the network, with the legacy fallback
    // list applied by DialStringParser when this is empty.
    property var emergencyNumbers: ofonoVoiceCallManager.emergencyNumbers

    // Voicemail, from the SIM's message-waiting indication.
    property string voicemailNumber: messageWaiting.voicemailMailboxNumber
    property bool voicemailWaiting: messageWaiting.voicemailWaiting
    property int voicemailMessageCount: messageWaiting.voicemailMessageCount

    // True when a call could plausibly be placed right now.
    readonly property bool canPlaceCalls: radioOnline && registered

    signal ussdResponse(string response);
    signal ussdRequest(string message);
    signal ussdNotification(string message);
    signal ussdFailed();

    // Emitted once a supplementary-service query initiated over USSD comes back.
    signal supplementaryServiceResponse(string operation, string service, var details);

    function initiateUssd(command) {
        console.log("Initiating USSD request: " + command);
        ofonoUSSD.initiate(command);
    }

    function respondToUssd(reply) {
        ofonoUSSD.respond(reply);
    }

    function cancelUssd() {
        ofonoUSSD.cancel();
    }

    /// Brings the radio back up, e.g. so an emergency call can go out with
    /// airplane mode on. Returns false when there is no modem at all.
    function setRadioOnline(online) {
        if (!modem.modemPath || modem.modemPath.length === 0)
            return false;

        modem.powered = true;
        modem.online = online;
        return true;
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
            console.log("oFono is " + (modemManager.available ? "available" :"not available"))
        }
        onModemAdded: {
            console.log("modem added "+modem)
        }
        onModemRemoved: console.log("modem removed")
    }

    OfonoModem {
        id: modem
        modemPath: modemManager.defaultModem

        onOnlineChanged: console.log("modem->online:" , JSON.stringify(modem.online));
        onPoweredChanged: console.log("modem->powered:" , JSON.stringify(modem.powered));
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

    OfonoNetworkRegistration {
        id: netreg
        modemPath: modemManager.defaultModem

        onStatusChanged: console.log("netreg->status:" , JSON.stringify(netreg.status));
        onNameChanged: console.log("netreg->name:" , JSON.stringify(netreg.name));
        onTechnologyChanged: console.log("netreg->technology:" , JSON.stringify(netreg.technology));
    }

    OfonoMessageWaiting {
        id: messageWaiting
        modemPath: modemManager.defaultModem

        onVoicemailMailboxNumberChanged: console.log("messageWaiting->voicemail mailbox is set");
        onVoicemailWaitingChanged: console.log("messageWaiting->voicemailWaiting:" , JSON.stringify(messageWaiting.voicemailWaiting));
    }

    // Only used for its emergencyNumbers property; calls themselves go through
    // the nemo voicecall manager so that non-cellular providers keep working.
    OfonoVoiceCallManager {
        id: ofonoVoiceCallManager
        modemPath: modemManager.defaultModem

        onEmergencyNumbersChanged: console.log("ofono->emergencyNumbers:" , JSON.stringify(ofonoVoiceCallManager.emergencyNumbers));
    }

    OfonoSupplementaryServices {
        id: ofonoUSSD
        modemPath: modemManager.defaultModem

        onUssdResponse: (response) => telephonyManager.ussdResponse(response);
        onRequestReceived: (message) => telephonyManager.ussdRequest(message);
        onNotificationReceived: (message) => telephonyManager.ussdNotification(message);
        onInitiateFailed: {
            telephonyManager.ussdFailed();
            telephonyManager.ussdResponse("USSD request failed.");
        }

        // Network answers to supplementary-service interrogations dialled as MMI.
        onCallForwardingResponse: (ssOp, cfService, cfMap) =>
            telephonyManager.supplementaryServiceResponse(ssOp, "callforwarding:" + cfService, cfMap);
        onCallBarringResponse: (ssOp, cbService, cbMap) =>
            telephonyManager.supplementaryServiceResponse(ssOp, "callbarring:" + cbService, cbMap);
        onCallWaitingResponse: (ssOp, cwMap) =>
            telephonyManager.supplementaryServiceResponse(ssOp, "callwaiting", cwMap);
        onCallingLineRestrictionResponse: (ssOp, status) =>
            telephonyManager.supplementaryServiceResponse(ssOp, "clir", { status: status });
        onCallingLinePresentationResponse: (ssOp, status) =>
            telephonyManager.supplementaryServiceResponse(ssOp, "clip", { status: status });
    }

    /// Exposed so SupplementaryServices can drive the same modem.
    property alias simManagerObject: simManager
    property alias modemObject: modem
    property alias networkRegistrationObject: netreg
    property alias messageWaitingObject: messageWaiting
}
