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

import "fakes"
import "../qml/views"
import "../qml/services"
import "../qml/services/IncomingCallsService.js" as IncomingCallsService

/**
 * The sounds of the call alerts, as legacy had them:
 *
 * - voicemail and a missed call on the notifications class, a dropped call
 *   and a failed dial on the alerts class;
 * - nothing for a call the user ended or rejected, or that the other side
 *   hung up on;
 * - in a call the tone goes on palerts like any other, and one of two calls
 *   dropping alerts for that one;
 * - mute, and a tone audiod will not take.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "CallAlerts"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: networkComponent; FakeCallNetwork {} }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }
        Component { id: soundsComponent; CallAlertSounds {} }
        Component { id: classifierComponent; CallEndClassifier { waitMs: 100 } }
        Component { id: droppedComponent; DroppedCallAlert { timeoutMs: 100 } }
        Component { id: dialFailComponent; DialFailAlert {} }
        Component { id: managerComponent; NotificationManager {} }
        Component { id: reasonsComponent; CallEndReasons {} }

        SignalSpy { id: playedSpy; signalName: "played" }
        SignalSpy { id: droppedSpy; signalName: "dropped" }
        SignalSpy { id: failedSpy; signalName: "failed" }
        SignalSpy { id: wrapperDroppedSpy; signalName: "callDropped" }
        SignalSpy { id: wrapperFailedSpy; signalName: "dialFailed" }
        SignalSpy { id: reasonSpy; signalName: "reasonReported" }

        property var sounds: null
        property int nextCallIndex: 1000

        function init() {
            sounds = createTemporaryObject(soundsComponent, root);
            playedSpy.target = sounds;
            playedSpy.clear();
        }

        function classifier() {
            var made = createTemporaryObject(classifierComponent, root);
            droppedSpy.target = made;
            failedSpy.target = made;
            droppedSpy.clear();
            failedSpy.clear();
            return made;
        }

        // --- which class, which tone

        function test_theAlertAndNotificationTonesAreDifferent() {
            sounds.playAlert();
            sounds.playNotification();
            compare(playedSpy.count, 2);
            compare(playedSpy.signalArguments[0][0], "/usr/palm/sounds/alert.wav");
            compare(playedSpy.signalArguments[1][0], "/usr/palm/sounds/notification.wav");
        }

        function test_thePreferredTonesAreUsed() {
            sounds._preferences({ alerttone: { fullPath: "/media/a.wav" },
                                  notificationtone: { fullPath: "/media/n.wav" } });
            sounds.playAlert();
            sounds.playNotification();
            compare(playedSpy.signalArguments[0][0], "/media/a.wav");
            compare(playedSpy.signalArguments[1][0], "/media/n.wav");
        }

        function test_theToneGoesOnTheAlertsSink() {
            var request = sounds._playSoundRequest("/usr/palm/sounds/alert.wav");
            compare(request.sink, "palerts");
            compare(request.fileName, "/usr/palm/sounds/alert.wav");
        }

        function test_audiodOnlyGetsWav() {
            verify(sounds._audiodTakes("/usr/palm/sounds/alert.wav"));
            verify(!sounds._audiodTakes("/media/internal/ringtones/tone.mp3"));
        }

        function test_muteSilencesBoth() {
            sounds._preferences({ muteSound: true });
            sounds.playAlert();
            sounds.playNotification();
            compare(playedSpy.count, 0);
            sounds._preferences({ muteSound: false });
            sounds.playAlert();
            compare(playedSpy.count, 1);
        }

        function test_aPreferenceWithoutMuteLeavesItAlone() {
            sounds._preferences({ muteSound: true });
            sounds._preferences({ alerttone: { fullPath: "/media/a.wav" } });
            verify(sounds.muted);
        }

        function test_voicemailAsksForTheNotificationsClass() {
            var manager = createTemporaryObject(managerComponent, root, { alertSounds: sounds });
            compare(manager.notifyVoicemail(1).soundClass, "notifications");
            compare(playedSpy.count, 0, "the shell plays a toast's sound, not the app");
        }

        function test_aMissedCallPlaysTheNotificationToneOnce() {
            var manager = createTemporaryObject(managerComponent, root, { alertSounds: sounds });
            manager.notifyMissedCall("5550123", "");
            compare(playedSpy.count, 1);
            compare(playedSpy.signalArguments[0][0], "/usr/palm/sounds/notification.wav");
        }

        function test_aMinimizedMissedCallIsSilent() {
            var manager = createTemporaryObject(managerComponent, root, { alertSounds: sounds });
            var payload = manager.postMissedCall("5550123", "", new Date());
            verify(payload.soundClass === undefined);
            compare(playedSpy.count, 0);
        }

        function test_aDialFailurePlaysTheAlertTone() {
            var alert = createTemporaryObject(dialFailComponent, root, { appTheme: theme, alertSounds: sounds });
            alert.showDialFailure("5550123", "noservice");
            compare(playedSpy.count, 1);
            compare(playedSpy.signalArguments[0][0], "/usr/palm/sounds/alert.wav");
        }

        function test_aDroppedCallPlaysTheAlertTone() {
            var alert = createTemporaryObject(droppedComponent, root, { appTheme: theme, alertSounds: sounds });
            alert.showDropped("5550123", "", "networkfailure");
            compare(playedSpy.count, 1);
            compare(playedSpy.signalArguments[0][0], "/usr/palm/sounds/alert.wav");
            compare(alert.acceptLabel, "Redial");
        }

        function test_callsDroppingTogetherAlertOnce() {
            var alert = createTemporaryObject(droppedComponent, root,
                                              { appTheme: theme, alertSounds: sounds, timeoutMs: 5000 });
            alert.showDropped("5550123", "", "networkfailure");
            alert.showDropped("5550124", "", "networkfailure");
            compare(playedSpy.count, 1);
            verify(alert.message.indexOf("5550123") >= 0);
        }

        function test_theNextDropAlertsOnceTheLastIsAnswered() {
            var alert = createTemporaryObject(droppedComponent, root,
                                              { appTheme: theme, alertSounds: sounds, timeoutMs: 5000 });
            alert.showDropped("5550123", "", "networkfailure");
            alert.hide();
            alert.dismissed();
            alert.showDropped("5550124", "", "networkfailure");
            compare(playedSpy.count, 2);
        }

        function test_aDroppedCallWithNoNumberOffersNoRedial() {
            var alert = createTemporaryObject(droppedComponent, root, { appTheme: theme, alertSounds: sounds });
            alert.showDropped("", "", "networkfailure");
            compare(alert.acceptLabel, "Ok");
        }

        function test_theDroppedAlertGoesByItself() {
            var alert = createTemporaryObject(droppedComponent, root, { appTheme: theme, alertSounds: sounds });
            alert.showDropped("5550123", "", "networkfailure");
            verify(alert.visible);
            tryCompare(alert, "visible", false, 1000);
        }

        // --- voicemail: what is news

        function test_voicemailSoundsWhenTheCountGoesUp() {
            var manager = createTemporaryObject(managerComponent, root);
            manager._voicemailCount = 1;
            compare(manager._voicemailCountUpdated(2, true).soundClass, "notifications");
        }

        function test_voicemailIsSilentWhenTheCountGoesDown() {
            var manager = createTemporaryObject(managerComponent, root);
            manager._voicemailCount = 3;
            verify(manager._voicemailCountUpdated(2, true).soundClass === undefined);
        }

        function test_theFirstVoicemailCountIsSilent() {
            var manager = createTemporaryObject(managerComponent, root);
            verify(manager._voicemailCountUpdated(4, false).soundClass === undefined);
        }

        function test_voicemailFromZeroSounds() {
            var manager = createTemporaryObject(managerComponent, root);
            manager._voicemailCount = 0;
            compare(manager._voicemailCountUpdated(1, true).soundClass, "notifications");
        }

        function test_noVoicemailsPostsNothing() {
            var manager = createTemporaryObject(managerComponent, root);
            manager._voicemailCount = 1;
            verify(manager._voicemailCountUpdated(0, true) === undefined);
            compare(manager._voicemailCount, 0);
        }

        // --- what an ended call was

        function test_endedCalls_data() {
            return [
                { tag: "connected, network", connected: true, reason: "network", drops: 1, fails: 0 },
                { tag: "connected, we hung up", connected: true, reason: "local", drops: 0, fails: 0 },
                { tag: "connected, they hung up", connected: true, reason: "remote", drops: 0, fails: 0 },
                { tag: "dialling, we took it back", connected: false, reason: "local", drops: 0, fails: 0 },
                { tag: "dialling, busy", connected: false, reason: "remote", drops: 0, fails: 1 },
                { tag: "dialling, network", connected: false, reason: "network", drops: 0, fails: 1 }
            ];
        }

        function test_endedCalls(data) {
            var made = classifier();
            made.reasonReported("5550123", data.reason);
            made.callEnded({ lineId: "5550123" }, data.connected);
            compare(droppedSpy.count, data.drops, "reason first");
            compare(failedSpy.count, data.fails, "reason first");

            made = classifier();
            made.callEnded({ lineId: "5550123" }, data.connected);
            compare(droppedSpy.count, 0, "nothing before the reason");
            compare(failedSpy.count, 0, "nothing before the reason");
            made.reasonReported("5550123", data.reason);
            compare(droppedSpy.count, data.drops, "reason last");
            compare(failedSpy.count, data.fails, "reason last");
        }

        function test_noReasonIsNoDrop() {
            var made = classifier();
            made.callEnded({ lineId: "5550123" }, true);
            wait(250);
            compare(droppedSpy.count, 0);
            compare(failedSpy.count, 0);
        }

        function test_noReasonStillFailsADial() {
            var made = classifier();
            made.callEnded({ lineId: "5550123" }, false);
            compare(failedSpy.count, 0);
            tryCompare(failedSpy, "count", 1, 1000);
        }

        function test_withoutReasonsNothingWaits() {
            var made = classifier();
            made.reasonsAvailable = false;
            made.callEnded({ lineId: "5550123" }, false);
            compare(failedSpy.count, 1);
            made.callEnded({ lineId: "5550124" }, true);
            compare(droppedSpy.count, 0);
        }

        function test_aStaleReasonIsNotKept() {
            var made = classifier();
            made.reasonReported("5550123", "network");
            wait(250);
            made.callEnded({ lineId: "5550123" }, true);
            wait(250);
            compare(droppedSpy.count, 0);
        }

        function test_aReasonIsUsedOnce() {
            var made = classifier();
            made.reasonReported("5550123", "network");
            made.callEnded({ lineId: "5550123" }, true);
            made.callEnded({ lineId: "5550123" }, true);
            wait(250);
            compare(droppedSpy.count, 1);
        }

        function test_aReasonGoesToItsOwnLine() {
            var made = classifier();
            made.callEnded({ lineId: "5550123" }, true);
            made.callEnded({ lineId: "5550124" }, true);
            made.reasonReported("5550124", "network");
            made.reasonReported("5550123", "local");
            compare(droppedSpy.count, 1);
            compare(droppedSpy.signalArguments[0][0].lineId, "5550124");
        }

        // --- through the wrapper

        function wrapped() {
            var network = createTemporaryObject(networkComponent, root);
            // IncomingCallsService remembers calls by id, across tests too.
            nextCallIndex += 10;
            network._nextIndex = nextCallIndex;
            var wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            wrapper._callEnds.waitMs = 100;
            wrapperDroppedSpy.target = wrapper;
            wrapperFailedSpy.target = wrapper;
            wrapperDroppedSpy.clear();
            wrapperFailedSpy.clear();
            return { network: network, wrapper: wrapper };
        }

        function up(setup, lineId) {
            var call = setup.network.ring(lineId);
            setup.network.answer(call);
            return call;
        }

        function dialling(setup, lineId) {
            var call = setup.network._add(lineId, VoiceCall.STATUS_NULL);
            call.status = VoiceCall.STATUS_DIALING;
            return call;
        }

        function test_theReasonsFileLoads() {
            verify(wrapped().wrapper._callEnds.reasonsAvailable);
        }

        function test_aCallLostToTheNetworkDrops() {
            var setup = wrapped();
            var call = up(setup, "5550131");
            setup.wrapper._callEnds.reasonReported("5550131", "network");
            setup.network.end(call);
            compare(wrapperDroppedSpy.count, 1);
            compare(wrapperDroppedSpy.signalArguments[0][0].lineId, "5550131");
            compare(wrapperDroppedSpy.signalArguments[0][1], "networkfailure");
            compare(wrapperFailedSpy.count, 0);
        }

        function test_anOrdinaryHangupIsSilent_data() {
            return [ { tag: "we hung up", reason: "local" }, { tag: "they hung up", reason: "remote" } ];
        }

        function test_anOrdinaryHangupIsSilent(data) {
            var setup = wrapped();
            var call = up(setup, "5550132");
            setup.network.end(call);
            setup.wrapper._callEnds.reasonReported("5550132", data.reason);
            wait(250);
            compare(wrapperDroppedSpy.count, 0);
            compare(wrapperFailedSpy.count, 0);
        }

        function test_oneOfTwoCallsDropping() {
            var setup = wrapped();
            var first = up(setup, "5550133");
            var second = setup.network.wait("5550134");
            setup.network.answer(second);
            setup.wrapper._callEnds.reasonReported("5550134", "network");
            setup.network.end(second);
            compare(wrapperDroppedSpy.count, 1);
            compare(wrapperDroppedSpy.signalArguments[0][0].lineId, "5550134");
            setup.wrapper._callEnds.reasonReported("5550133", "local");
            setup.network.end(first);
            wait(250);
            compare(wrapperDroppedSpy.count, 1);
        }

        function test_aRejectedCallIsSilent() {
            var setup = wrapped();
            var call = setup.network.ring("5550135");
            IncomingCallsService.setActionForCall(call.handlerId, IncomingCallsService.Ignored);
            setup.wrapper._callEnds.reasonReported("5550135", "local");
            setup.network.end(call);
            wait(250);
            compare(wrapperDroppedSpy.count, 0);
            compare(wrapperFailedSpy.count, 0);
        }

        function test_aDialTakenBackIsSilent() {
            var setup = wrapped();
            var call = dialling(setup, "5550136");
            setup.wrapper._callEnds.reasonReported("5550136", "local");
            setup.network.end(call);
            wait(250);
            compare(wrapperFailedSpy.count, 0);
        }

        function test_aDialThatFailsIsReported() {
            var setup = wrapped();
            var call = dialling(setup, "5550137");
            setup.wrapper._callEnds.reasonReported("5550137", "remote");
            setup.network.end(call);
            compare(wrapperFailedSpy.count, 1);
            compare(wrapperFailedSpy.signalArguments[0][1], "callfailed");
        }

        // --- the bus

        function test_theBusReachesTheClassifier() {
            var setup = wrapped();
            var reasons = null;
            for (var i = 0; i < setup.wrapper.data.length; i++) {
                if (setup.wrapper.data[i].item && setup.wrapper.data[i].item.reasonReported)
                    reasons = setup.wrapper.data[i].item;
            }
            verify(reasons !== null);

            var call = up(setup, "5550139");
            reasons.reasonReported("5550139", "network");
            setup.network.end(call);
            compare(wrapperDroppedSpy.count, 1);
        }

        // The mock takes anything; the real plugin only calls a typed handler.
        function test_theHandlerIsTyped() {
            var request = new XMLHttpRequest();
            request.open("GET", Qt.resolvedUrl("../qml/services/CallEndReasons.qml"), false);
            request.send();
            verify(request.responseText.indexOf("function disconnectReason(reason: string)") >= 0);
        }

        function test_theReasonComesWithTheLine() {
            var reasons = createTemporaryObject(reasonsComponent, root);
            reasonSpy.target = reasons;
            reasonSpy.clear();

            reasons._watch("/ril_0/voicecall01");
            var watched = reasons._watched["/ril_0/voicecall01"];
            verify(watched);
            var call = watched.data[0];
            var bus = watched.data[1];
            compare(call.voiceCallPath, "/ril_0/voicecall01");
            compare(bus.path, "/ril_0/voicecall01");
            compare(bus.iface, "org.ofono.VoiceCall");
            compare(bus.service, "org.ofono");
            verify(bus.signalsEnabled);

            call.lineIdentification = "5550138";
            bus.disconnectReason("network");
            compare(reasonSpy.count, 1);
            compare(reasonSpy.signalArguments[0][0], "5550138");
            compare(reasonSpy.signalArguments[0][1], "network");

            reasons._unwatch("/ril_0/voicecall01");
            verify(!reasons._watched["/ril_0/voicecall01"]);
        }
    }
}
