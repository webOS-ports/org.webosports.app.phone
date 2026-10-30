/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "../qml/views"
import "../qml/services"
import "../qml/model"
import "../qml/services/IncomingCallsService.js" as IncomingCallsService

/**
 * What the call screens make of a call that changes state without the
 * phone app's own buttons: answered by a headset, a car kit or another
 * modem client, or a waiting call taken with hold and answer.
 *
 * - the call counts as answered, not missed;
 * - the incoming strip goes once the call stops ringing;
 * - a call line shows no label for a provider the registry does not know.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "CallState"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component {
            id: callComponent
            QtObject {
                property string handlerId: ""
                property string providerId: "ofono/phonesim"
                property string lineId: "5550100"
                property int status: VoiceCall.STATUS_NULL
                property string statusText: ""
                property bool isIncoming: true
                property bool isMultiparty: false
                function answer() { status = VoiceCall.STATUS_ACTIVE; }
                function hangup() { status = VoiceCall.STATUS_DISCONNECTED; }
            }
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: alertComponent
            IncomingCallAlert {}
        }
        Component {
            id: lineComponent
            CallLineDelegate { width: 480 }
        }
        Component {
            id: transportsComponent
            CallTransports {}
        }

        function makeCall(handlerId, status) {
            var call = createTemporaryObject(callComponent, root,
                                             { handlerId: handlerId, status: status });
            verify(call !== null, "the call did not load");
            return call;
        }

        // --- answered, however it was answered ---

        function test_incomingCallThatWentLiveWasAnswered() {
            IncomingCallsService.setIncomingForCall("in-1", true);
            IncomingCallsService.callWentLive("in-1");
            compare(IncomingCallsService.getActionForCall("in-1"), IncomingCallsService.Accepted);
        }

        function test_outgoingCallIsNotMarkedAnswered() {
            IncomingCallsService.setIncomingForCall("out-1", false);
            IncomingCallsService.callWentLive("out-1");
            // Never registered as an action: the default, for an incoming
            // call that ended untouched.
            compare(IncomingCallsService.getActionForCall("out-1"), IncomingCallsService.Missed);
        }

        function test_callOfUnknownDirectionIsLeftAlone() {
            IncomingCallsService.callWentLive("unknown-1");
            compare(IncomingCallsService.getActionForCall("unknown-1"), IncomingCallsService.Missed);
        }

        function test_wrapperRecordsAnAnswerItDidNotMake() {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");

            var call = makeCall("headset-1", VoiceCall.STATUS_INCOMING);
            wrapper._updateState(call, true);
            compare(IncomingCallsService.getActionForCall("headset-1"), IncomingCallsService.Missed);

            // Answered by a headset button: oFono reports it active.
            call.status = VoiceCall.STATUS_ACTIVE;
            wrapper._updateState(call, true);
            compare(IncomingCallsService.getActionForCall("headset-1"), IncomingCallsService.Accepted);
        }

        function test_wrapperStillMissesACallThatRangOut() {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            var call = makeCall("rangout-1", VoiceCall.STATUS_INCOMING);
            wrapper._updateState(call, true);
            call.status = VoiceCall.STATUS_DISCONNECTED;
            wrapper._updateState(call, true);
            compare(IncomingCallsService.getActionForCall("rangout-1"), IncomingCallsService.Missed);
        }

        // --- the strip follows its call ---

        function showAlertFor(call) {
            var alert = createTemporaryObject(alertComponent, root, { appTheme: theme });
            verify(alert !== null, "the alert did not load");
            alert.voiceCall = call;
            alert.show();
            verify(alert.visible);
            return alert;
        }

        function test_stripGoesWhenTheCallIsAnsweredElsewhere() {
            var call = makeCall("strip-1", VoiceCall.STATUS_INCOMING);
            var alert = showAlertFor(call);
            call.status = VoiceCall.STATUS_ACTIVE;
            verify(!alert.visible, "the strip stayed up over an answered call");
            compare(alert.voiceCall, null);
        }

        function test_stripGoesWhenTheCallerHangsUp() {
            var call = makeCall("strip-2", VoiceCall.STATUS_INCOMING);
            var alert = showAlertFor(call);
            call.status = VoiceCall.STATUS_DISCONNECTED;
            verify(!alert.visible);
        }

        function test_stripGoesWhenAWaitingCallIsTaken() {
            var call = makeCall("strip-3", VoiceCall.STATUS_WAITING);
            var alert = showAlertFor(call);
            call.status = VoiceCall.STATUS_ACTIVE;
            verify(!alert.visible);
        }

        function test_stripStaysWhileTheCallRings() {
            var call = makeCall("strip-4", VoiceCall.STATUS_INCOMING);
            var alert = showAlertFor(call);
            // Incoming turning into waiting - another call went live first -
            // is still a call to answer.
            call.status = VoiceCall.STATUS_WAITING;
            verify(alert.visible);
            compare(alert.voiceCall, call);
        }

        // --- labels ---

        function test_callLineHasNoLabelForAnUnknownProvider() {
            var transports = createTemporaryObject(transportsComponent, root);
            verify(transports !== null, "the transport registry did not load");
            var call = makeCall("label-1", VoiceCall.STATUS_ACTIVE);
            var line = createTemporaryObject(lineComponent, root,
                                             { voiceCall: call, callTransports: transports, appTheme: theme });
            verify(line !== null, "the call line did not load");
            compare(line.serviceLabel, "");
        }
    }
}
