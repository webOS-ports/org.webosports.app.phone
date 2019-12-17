/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

import LuneOS.Service 1.0
import org.nemomobile.voicecall 1.0

import "../model"

Item {
    id: root

    LunaService {
        id: __lunaNextLS2Service
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    property VoiceCallManager manager: VoiceCallManager {
        id: voiceCallManagerId
    }

    property alias calls: voiceCallManagerId.voiceCalls
    property alias activeVoiceCall: voiceCallManagerId.activeVoiceCall

    property string countryCode: 'US'

    property var heldCall: null
    property string _dialNumberAfterHold: ""

    signal activeCall(var voiceCall);
    signal outgoingCall(var voiceCall);
    signal incomingCall(var voiceCall);
    signal endingCall(var voiceCall);
    signal resetCall(var voiceCall);

    function __setCallModeError(message) {
        console.log("Problem when calling luna://org.webosports.service.audio/setCallMode : " + message);
    }

    onActiveVoiceCallChanged: {
        console.log("Active VoiceCall changed -> setting audio to " + !!activeVoiceCall);
        __lunaNextLS2Service.call("luna://org.webosports.service.audio/setCallMode", JSON.stringify({ inCall: (!!activeVoiceCall) }),
                                  undefined, root.__setCallModeError);
    }

    onHeldCallChanged: {
        if (!root.heldCall || root._dialNumberAfterHold.length === 0)
            return;

        _dial(_dialNumberAfterHold);
    }

    function dial(number) {
        // FIXME normalize number
        var normalizedNumber = number;
        if (activeCall && activeCall.status === VoiceCall.STATUS_ACTIVE && !heldCall) {
            _dialNumberAfterHold = normalizedNumber;
            return;
        }

        _dial(normalizedNumber);
    }

    function hangupAll() {
        for(var iCall = calls.count; iCall>0; iCall--) {
            var voiceCall = calls.instance(iCall);
            if(voiceCall) voiceCall.hangup();
        }
    }

    function _dial(number) {
        manager.dial(manager.defaultProviderId, number);
    }

    function _updateState(voiceCall, isIncoming) {
        console.log("Currently we have " + manager.voiceCalls.count + " calls");

        console.log("Looking at call " + voiceCall.lineId + " with state " + voiceCall.statusText + " "
                    + voiceCall.status);

        switch (voiceCall.status) {
        case VoiceCall.STATUS_ACTIVE:
            root.activeCall(voiceCall);
            break;
        case VoiceCall.STATUS_DIALING:
        case VoiceCall.STATUS_ALERTING:
            root.outgoingCall(voiceCall);
            break;
        case VoiceCall.STATUS_INCOMING:
        case VoiceCall.STATUS_WAITING:
            root.incomingCall(voiceCall);
            break;
        case VoiceCall.STATUS_HELD:
            root.heldCall = voiceCall;
            break;
        case VoiceCall.STATUS_DISCONNECTED:
            // the voicecall object is soon to be destroyed, so save its state before sending the signal
            var endedVoiceCall = {
                handlerId: voiceCall.handlerId,
                provider: voiceCall.provider,
                status: voiceCall.status,
                statusText: voiceCall.statusText,
                lineId:voiceCall.lineId,
                startedAt: voiceCall.startedAt,
                duration: voiceCall.duration,
                isIncoming: isIncoming,
                isEmergency: voiceCall.isEmergency,
                isMultiparty: voiceCall.isMultiparty,
                isForwarded: voiceCall.isForwarded,
                isRemoteHeld: voiceCall.isRemoteHeld
            };

            root.endingCall(endedVoiceCall);
            break;
        case VoiceCall.STATUS_NULL:
            root.resetCall(voiceCall);
            break;
        }
    }

    Connections {
        target: calls
        onRowsInserted: {
            for(var i=first;i<=last;++i) {
                var object = calls.instance(i);
                addStatusObserver(object);
                _updateState(object, object.isIncoming); // initialize the state
            }
        }
        function addStatusObserver(object) {
            console.log("Adding status observer for " + object);
            var isIncoming=object.isIncoming; // memorize the incoming status asap
            object.statusChanged.connect( function() { _updateState(object, isIncoming) } );
        }
    }

    Component.onCompleted: {
        __lunaNextLS2Service.call("luna://com.palm.systemservice/getPreferences", JSON.stringify({ keys: ["region"], subscribe: false }), _getPreferencesSuccess, _getPreferencesFailure)
    }
    function _getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
        if (response.region && response.region.countryCode) {
            countryCode = response.region.countryCode;
            console.log("phone: set current country code to: " + response.region.countryCode);
        }
    }
    function _getPreferencesFailure(message) {
        console.log("No region found, default to US: " + message);
        countryCode = 'US'
        console.log("phone: set current country code to: " + response.region.countryCode);
    }
}
