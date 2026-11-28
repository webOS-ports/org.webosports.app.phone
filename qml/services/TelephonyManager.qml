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
import LuneOS.Service 1.0

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
    /// The SIM asks for its PIN at power-on ("Lock SIM Card" in the preferences)
    readonly property bool simPinLocked: !!simManager.lockedPins
                                         && simManager.lockedPins.indexOf(OfonoSimManager.SimPin) >= 0
    readonly property bool pukRequired: simManager.pinRequired === OfonoSimManager.SimPuk

    // Network registration
    property string networkStatus: netreg.status        // unregistered/registered/searching/denied/unknown/roaming
    property string networkName: netreg.name
    property string networkTechnology: netreg.technology
    property int signalStrength: netreg.strength
    property bool roaming: netreg.status === "roaming"
    /**
     * The modem is registered with IMS and can make voice calls over it: what
     * a status bar shows as VoLTE. A call can still go circuit-switched (no
     * IMS where the phone is, a handover), so a call says for itself where
     * voicecall can tell; see CallTransports.callBearerLabel().
     */
    readonly property bool imsVoice: imsReg.registered && imsReg.voiceCapable
    /**
     * IMS goes over Wi-Fi (VoWiFi) rather than LTE: telephonyd's "vowifi",
     * which the status bar shows as VoWiFi too. oFono's own
     * IpMultimediaSystem does not say which bearer IMS uses; telephonyd
     * reads it from the modem's extension where there is one, and is false
     * elsewhere.
     */
    property bool imsWifi: false
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
    /// The count above is the SIM's and no longer just the starting zero.
    readonly property bool voicemailCountKnown: messageWaiting.valid === true

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

    /// Leaves airplane mode altogether, as the legacy popup did: the shell owns
    /// it and acts on this preference, for every radio and the status bar.
    function turnOffAirplaneMode() {
        __systemService.call("luna://com.webos.service.systemservice/setPreferences",
                             JSON.stringify({ "airplaneMode": false }),
                             function (message) { },
                             function (message) {
                                 console.log("Could not turn off airplane mode: " + message.payload);
                             });
    }

    LunaService {
        id: __systemService
        name: "org.webosports.app.phone"
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

    OfonoIpMultimediaSystem {
        id: imsReg
        modemPath: modemManager.defaultModem

        onRegisteredChanged: console.log("ims->registered:" , JSON.stringify(imsReg.registered));
        onVoiceCapableChanged: console.log("ims->voiceCapable:" , JSON.stringify(imsReg.voiceCapable));
    }

    Timer {
        id: networkStatusResubscribe
        interval: 2000
        onTriggered: networkStatusQuery.subscribe(JSON.stringify({"subscribe": true}))
    }

    // Only for "vowifi"; the rest of the network status comes from oFono.
    LunaService {
        id: networkStatusQuery
        service: "luna://com.palm.telephony"
        method: "networkStatusQuery"

        onInitialized: networkStatusQuery.subscribe(JSON.stringify({"subscribe": true}))

        onResponse: function (message) {
            var response;
            try {
                response = JSON.parse(message.payload);
            } catch (e) {
                return;
            }
            if (!response || !response.returnValue) {
                telephonyManager.imsWifi = false;
                networkStatusResubscribe.start();
                return;
            }
            if (response.extended && response.extended.vowifi !== undefined)
                telephonyManager.imsWifi = response.extended.vowifi === true;
        }

        onError: function (message) {
            telephonyManager.imsWifi = false;
            networkStatusResubscribe.start();
        }
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
