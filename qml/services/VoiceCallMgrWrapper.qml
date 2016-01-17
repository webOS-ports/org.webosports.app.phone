/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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

import org.nemomobile.voicecall 1.0

import "../model"

Item {
    id: root

    VoiceCallManager {
        id: manager
    }

    property alias calls: manager.voiceCalls
    property alias activeVoiceCall: manager.activeVoiceCall

    property var heldCall: null
    property string _dialNumberAfterHold: ""

    signal activeCall(var voiceCall);
    signal outgoingCall(var voiceCall);
    signal incomingCall(var voiceCall);
    signal endingCall(var voiceCall);
    signal resetCall(var voiceCall);

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
        for(var iCall = statusObserver.count; iCall>0; iCall--) {
            var voiceCall = statusObserver.objectAt(iCall);
            if(voiceCall) voiceCall.hangup();
        }
    }

    function _dial(number) {
        manager.dial(manager.defaultProviderId, number);
    }

    function _updateState(voiceCall) {
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
            root.endingCall(voiceCall);
            break;
        case VoiceCall.STATUS_NULL:
            root.resetCall(voiceCall);
            break;
        }
    }

    Instantiator {
        id: statusObserver
        model: manager.voiceCalls
        onObjectAdded: {
            console.log("Adding status observer for " + object);
            object.statusChanged.connect( function() { _updateState(object) } );
        }
    }
}
