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

        // --- a call that goes without disconnecting ---

        SignalSpy { id: endingSpy; signalName: "endingCall" }

        function makeWrapperWithSpy() {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            endingSpy.clear();
            endingSpy.target = wrapper;
            return wrapper;
        }

        // Stands in for a transport whose list the call is still in.
        function listCalls(wrapper, calls) {
            wrapper.synergyTransports = { "test": { calls: calls } };
            wrapper.callsRevision = wrapper.callsRevision + 1;
        }

        function test_aCallThatVanishesWhileActiveIsEnded() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("vanish-1", VoiceCall.STATUS_INCOMING);
            listCalls(wrapper, [call]);
            wrapper._updateState(call, true);
            call.status = VoiceCall.STATUS_ACTIVE;
            wrapper._updateState(call, true);

            // Both ends hung up at once: the row goes, still active.
            listCalls(wrapper, []);
            wrapper._endVanishedCalls();

            compare(endingSpy.count, 1);
            var ended = endingSpy.signalArguments[0][0];
            compare(ended.handlerId, "vanish-1");
            compare(ended.lineId, "5550100");
            compare(ended.status, VoiceCall.STATUS_DISCONNECTED);
            verify(ended.isIncoming);
        }

        function test_aCallStillListedIsNotEnded() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("listed-1", VoiceCall.STATUS_ACTIVE);
            listCalls(wrapper, [call]);
            wrapper._updateState(call, true);
            wrapper._endVanishedCalls();
            compare(endingSpy.count, 0);
        }

        function test_aLateDisconnectDoesNotEndTheCallTwice() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("late-1", VoiceCall.STATUS_ACTIVE);
            listCalls(wrapper, [call]);
            wrapper._updateState(call, true);
            listCalls(wrapper, []);
            wrapper._endVanishedCalls();

            call.status = VoiceCall.STATUS_DISCONNECTED;
            wrapper._updateState(call, true);
            compare(endingSpy.count, 1);
        }

        function test_aDisconnectedCallIsNotEndedAgainWhenItsRowGoes() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("normal-1", VoiceCall.STATUS_ACTIVE);
            listCalls(wrapper, [call]);
            wrapper._updateState(call, true);
            call.status = VoiceCall.STATUS_DISCONNECTED;
            wrapper._updateState(call, true);
            listCalls(wrapper, []);
            wrapper._endVanishedCalls();
            compare(endingSpy.count, 1);
        }

        // --- what audiod hears ---

        function test_aSynergyCallIsInProgressButNotACellularOne() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("whatsapp-1", VoiceCall.STATUS_ACTIVE);
            call.providerId = "com.palm.whatsapp";
            listCalls(wrapper, [call]);
            // The call screens follow it...
            verify(wrapper.hasCallInProgress);
            // ...but audiod must not put the modem's voice path on for it:
            // its connector plays and records on the normal audio path.
            verify(!wrapper.hasCellularCallInProgress);
        }

        function test_aRingingSynergyCallIsNotInProgress() {
            var wrapper = makeWrapperWithSpy();
            var call = makeCall("whatsapp-2", VoiceCall.STATUS_INCOMING);
            listCalls(wrapper, [call]);
            verify(!wrapper.hasCallInProgress);
        }

        Component {
            id: synergyCallComponent
            SynergyCall {}
        }
        SignalSpy { id: controlSpy; signalName: "callControlRequested" }

        function test_aSynergyCallIsHungUpWithDisconnect() {
            var call = createTemporaryObject(synergyCallComponent, root,
                                             { transport: "com.palm.whatsapp", callId: "wa-1" });
            verify(call !== null, "the call did not load");
            controlSpy.clear();
            controlSpy.target = call;
            call.hangup();
            compare(controlSpy.count, 1);
            // What the connectors implement; "hangup" is not a method there.
            compare(controlSpy.signalArguments[0][0], "disconnect");
            compare(controlSpy.signalArguments[0][1].id, "wa-1");
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
