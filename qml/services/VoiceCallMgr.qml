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

Item {
    id: root

    property alias calls: manager.voiceCalls
    property var activeCall: null
    property var outgoingCall: null
    property var incomingCall: null
    property var endingCall: null
    property var heldCall: null

    property string _dialNumberAfterHold: ""

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

    VoiceCallManager {
        id: manager
    }

    function _dial(number) {
        manager.dial(manager.defaultProviderId, number);
    }

    function _updateState() {
        console.log("Currently we have " + manager.voiceCalls.count + " calls");
        for (var n = 0; n < manager.voiceCalls.count; n++) {
            var call = manager.voiceCalls.instance(n);
            console.log("Looking at call " + call.lineId + " with state " + call.statusText + " "
                        + call.status);

            var newOutgoingCall = null;
            var newIncomingCall = null;
            var newHeldCall = null;
            var newEndingCall = null;

            switch (call.status) {
            case VoiceCall.STATUS_DIALING:
            case VoiceCall.STATUS_ALERTING:
                newOutgoingCall = call;
                break;
            case VoiceCall.STATUS_INCOMING:
            case VoiceCall.STATUS_WAITING:
                newIncomingCall = call;
                break;
            case VoiceCall.STATUS_HELD:
                newHeldCall = call;
                break;
            case VoiceCall.STATUS_DISCONNECTED:
            case VoiceCall.STATUS_NULL:
                newEndingCall = call;
                break;
            }
        }

        root.outgoingCall = newOutgoingCall;
        root.incomingCall = newIncomingCall;
        root.heldCall = newHeldCall;
        root.endingCall = newEndingCall;

        // FIXME determine current active call
    }

    Timer {
        id: updateStateTimer
        interval: 10
        running: false
        repeat: false
        onTriggered: _updateState()
    }

    Instantiator {
        model: manager.voiceCalls
        delegate: QtObject {
            property string callStatus: instance.status
            onCallStatusChanged: updateStateTimer.start()
        }
        onObjectAdded: updateStateTimer.start()
        onObjectRemoved: updateStateTimer.stop();
    }
}
