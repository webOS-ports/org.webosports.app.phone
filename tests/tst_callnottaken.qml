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

/*
 * A call we place over WhatsApp, Telegram, Signal or Teams that the other side
 * declines, is busy for or does not answer is not a failure to connect. The
 * connector says which (disconnectDetails.cause); the Phone app titles the
 * alert for it instead of "Unable to connect", which stays for calls that
 * really failed.
 */

import QtQuick 2.0
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "fakes"
import "../qml/services"
import "../qml/views"

Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "CallNotTaken"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.whatsapp" } }
        Component { id: classifierComponent; CallEndClassifier { waitMs: 100 } }
        Component { id: networkComponent; FakeCallNetwork {} }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }
        Component { id: dialFailComponent; DialFailAlert {} }
        Component { id: soundsComponent; CallAlertSounds {} }

        SignalSpy { id: failedSpy; signalName: "failed" }
        SignalSpy { id: notTakenSpy; signalName: "notTaken" }
        SignalSpy { id: wrapperFailedSpy; signalName: "dialFailed" }
        SignalSpy { id: wrapperNotTakenSpy; signalName: "callNotTaken" }
        SignalSpy { id: playedSpy; signalName: "played" }

        property int serial: 0

        function classifier() {
            var made = createTemporaryObject(classifierComponent, root);
            failedSpy.target = made;
            notTakenSpy.target = made;
            failedSpy.clear();
            notTakenSpy.clear();
            return made;
        }

        // --- the connector's cause, in the classifier's terms

        function test_connectorReason_data() {
            return [
                { tag: "rejected", cause: "rejected", reason: "declined" },
                { tag: "declined", cause: "declined", reason: "declined" },
                { tag: "busy", cause: "busy", reason: "busy" },
                { tag: "missed", cause: "missed", reason: "noanswer" },
                { tag: "timeout", cause: "timeout", reason: "noanswer" },
                { tag: "normal", cause: "normal", reason: "local" },
                { tag: "hangup", cause: "hangup", reason: "local" },
                { tag: "answered elsewhere", cause: "answeredElsewhere", reason: "local" },
                { tag: "error", cause: "error", reason: "network" },
                { tag: "offer failed", cause: "offer_failed", reason: "network" },
                { tag: "unknown", cause: "whatever", reason: "" },
                { tag: "none", cause: "", reason: "" },
                { tag: "a cellular call has none", cause: undefined, reason: "" }
            ];
        }

        function test_connectorReason(data) {
            compare(classifier().connectorReason(data.cause), data.reason);
        }

        // --- what a call that never connected was

        function test_notTaken_data() {
            return [
                { tag: "declined", reason: "declined" },
                { tag: "busy", reason: "busy" },
                { tag: "no answer", reason: "noanswer" }
            ];
        }

        function test_notTaken(data) {
            var made = classifier();
            made.reasonReported("8:peer", data.reason);
            made.callEnded({ lineId: "8:peer" }, false);
            compare(notTakenSpy.count, 1);
            compare(notTakenSpy.signalArguments[0][1], data.reason);
            compare(failedSpy.count, 0, "not a failure to connect");
        }

        function test_aConnectedCallIsNeverNotTaken() {
            var made = classifier();
            made.reasonReported("8:peer", "declined");
            made.callEnded({ lineId: "8:peer" }, true);
            wait(150);
            compare(notTakenSpy.count, 0);
            compare(failedSpy.count, 0);
        }

        function test_aRealFailureStillFails() {
            var made = classifier();
            made.reasonReported("8:peer", made.connectorReason("offer_failed"));
            made.callEnded({ lineId: "8:peer" }, false);
            compare(failedSpy.count, 1);
            compare(notTakenSpy.count, 0);
        }

        // --- the transport keeps the cause for the end

        function test_theCauseIsThereWhenTheCallEnds() {
            var transport = createTemporaryObject(transportComponent, root);
            var callId = "nottaken-" + (++serial);
            function push(state, extra) {
                var l = { state: state, calls: [{ id: callId, address: "8:peer" }] };
                for (var k in (extra || {})) l[k] = extra[k];
                transport._onLines([l], { returnValue: true, lines: [l] });
                return transport._findCall(callId);
            }
            var call = push("dialing");
            verify(call !== null);
            compare(call.disconnectCause, "", "nothing while it is up");
            var seen = null;
            call.statusChanged.connect(function() {
                if (call.status === VoiceCall.STATUS_DISCONNECTED)
                    seen = call.disconnectCause;
            });
            push("disconnected", { disconnectDetails: { cause: "rejected" } });
            compare(seen, "rejected");
        }

        // --- through the wrapper

        function wrapper() {
            var network = createTemporaryObject(networkComponent, root);
            var made = createTemporaryObject(wrapperComponent, root, { manager: network });
            made._callEnds.waitMs = 100;
            wrapperFailedSpy.target = made;
            wrapperNotTakenSpy.target = made;
            wrapperFailedSpy.clear();
            wrapperNotTakenSpy.clear();
            return made;
        }

        function test_aDeclinedCallIsReportedAsSuch() {
            var made = wrapper();
            var ended = { lineId: "8:peer", disconnectCause: "rejected" };
            made._reportConnectorCause(ended);
            made._callEnds.callEnded(ended, false);
            compare(wrapperNotTakenSpy.count, 1);
            compare(wrapperNotTakenSpy.signalArguments[0][0], "8:peer");
            compare(wrapperNotTakenSpy.signalArguments[0][1], "declined");
            wait(150);
            compare(wrapperFailedSpy.count, 0, "no \"Unable to connect\"");
        }

        // Cancelling our own call while it rings is no alert at all.
        function test_ourOwnCancelIsSilent() {
            var made = wrapper();
            var ended = { lineId: "8:peer", disconnectCause: "hangup" };
            made._reportConnectorCause(ended);
            made._callEnds.callEnded(ended, false);
            wait(150);
            compare(wrapperNotTakenSpy.count, 0);
            compare(wrapperFailedSpy.count, 0);
        }

        // A cellular call has no connector cause: unchanged, it fails once no
        // oFono reason comes.
        function test_aCellularCallIsUnchanged() {
            var made = wrapper();
            var ended = { lineId: "5550199" };
            made._reportConnectorCause(ended);
            made._callEnds.callEnded(ended, false);
            tryCompare(wrapperFailedSpy, "count", 1, 1000);
            compare(wrapperNotTakenSpy.count, 0);
        }

        // --- the real way through: the wrapper ends a call from a record of it

        property int nextCallIndex: 7000

        function placed(lineId) {
            var network = createTemporaryObject(networkComponent, root);
            nextCallIndex += 10;    // IncomingCallsService remembers calls by id
            network._nextIndex = nextCallIndex;
            var made = createTemporaryObject(wrapperComponent, root, { manager: network });
            made._callEnds.waitMs = 100;
            wrapperFailedSpy.target = made;
            wrapperNotTakenSpy.target = made;
            wrapperFailedSpy.clear();
            wrapperNotTakenSpy.clear();
            var call = network._add(lineId, VoiceCall.STATUS_NULL);
            call.status = VoiceCall.STATUS_DIALING;
            return { network: network, wrapper: made, call: call };
        }

        // The record _endCall gets in place of the call (which is soon gone)
        // keeps the cause: without it a declined call said "Unable to connect"
        // on sargo.
        function test_theRecordKeepsTheCause() {
            var setup = placed("8:peer");
            setup.call.disconnectCause = "rejected";
            compare(setup.wrapper._callRecord(setup.call, false).disconnectCause, "rejected");
            setup.call.disconnectCause = "";
            compare(setup.wrapper._callRecord(setup.call, false).disconnectCause, "");
        }

        function test_aDeclinedCallEndsAsDeclined() {
            var setup = placed("8:peer");
            setup.call.disconnectCause = "rejected";
            setup.network.end(setup.call);
            compare(wrapperNotTakenSpy.count, 1);
            compare(wrapperNotTakenSpy.signalArguments[0][1], "declined");
            wait(150);
            compare(wrapperFailedSpy.count, 0, "no \"Unable to connect\"");
        }

        function test_aDeclinedCallEndsAsDeclinedWithoutOfonoReasons() {
            var setup = placed("8:peer");
            setup.wrapper._callEnds.reasonsAvailable = false;
            setup.call.disconnectCause = "rejected";
            setup.network.end(setup.call);
            compare(wrapperNotTakenSpy.count, 1);
            compare(wrapperFailedSpy.count, 0);
        }

        function test_aCellularDialThatEndsStillFails() {
            var setup = placed("5550177");
            setup.network.end(setup.call);
            tryCompare(wrapperFailedSpy, "count", 1, 1000);
            compare(wrapperNotTakenSpy.count, 0);
        }

        function test_aReportedReasonCountsWithoutOfonoReasons() {
            var made = classifier();
            made.reasonsAvailable = false;
            made.reasonReported("8:peer", "busy");
            made.callEnded({ lineId: "8:peer" }, false);
            compare(notTakenSpy.count, 1);
            compare(notTakenSpy.signalArguments[0][1], "busy");
            compare(failedSpy.count, 0);
        }

        // --- the alert

        function test_theAlertIsTitledForWhatHappened_data() {
            return [
                { tag: "declined", reason: "declined", title: "Call declined" },
                { tag: "busy", reason: "busy", title: "Busy" },
                { tag: "no answer", reason: "noanswer", title: "No answer" }
            ];
        }

        function test_theAlertIsTitledForWhatHappened(data) {
            var sounds = createTemporaryObject(soundsComponent, root);
            playedSpy.target = sounds;
            playedSpy.clear();
            var alert = createTemporaryObject(dialFailComponent, root, { appTheme: theme, alertSounds: sounds });
            alert.showNotTaken("8:peer", data.reason);
            compare(playedSpy.count, 1, "the alert tone, as for a failed call");
            compare(alert.title, data.title);
            verify(alert.message.length > 0);
            verify(alert.title !== "Unable to connect");
        }
    }
}
