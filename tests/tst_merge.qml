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
import "../qml/services/CallLines.js" as CallLines
import "../qml/services/CallMessages.js" as CallMessages
import "fakes"

/**
 * Two calls joined and parted through the wrapper, as the blue arrow, the
 * conference's hangup and a member's private button do it, against a fake
 * network that behaves as oFono does (see FakeCallNetwork):
 *
 * - the arrow is CreateMultiparty, and the two calls become one line;
 * - a third call can join, up to the biggest conference there can be;
 * - a refused merge or split says so and leaves every call as it was;
 * - splitting leaves that call active and the rest on hold, and is not
 *   offered with a call on hold;
 * - ending a conference ends all of it though oFono takes one request at
 *   a time.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "Merge"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component {
            id: networkComponent
            FakeCallNetwork {}
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: pageComponent
            ActiveCallPage { width: 480; height: 800 }
        }

        SignalSpy { id: failedSpy; signalName: "callControlFailed" }

        property var network: null
        property var wrapper: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            verify(network !== null, "the fake network did not load");
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            verify(wrapper !== null, "the wrapper did not load");
            failedSpy.clear();
            failedSpy.target = wrapper;
        }

        function sent() { return network.commands.join(" "); }

        /// Call 1 on hold, call 2 talking.
        function twoCalls() {
            var first = network.ring("0600000001");
            wrapper.answer();
            var second = network.wait("0600000002");
            second.answer();
            network.commands = [];
            return [first, second];
        }

        function conference() {
            var calls = twoCalls();
            wrapper.merge();
            compare(sent(), "AT+CHLD=3");
            network.commands = [];
            return calls;
        }

        function lines() {
            return CallLines.group(wrapper.allCallsList);
        }

        function test_theArrowMakesOneConferenceLine() {
            var calls = twoCalls();
            verify(wrapper.canMerge);
            compare(lines().length, 2);

            wrapper.merge();

            compare(sent(), "AT+CHLD=3");
            compare(calls[0].status, VoiceCall.STATUS_ACTIVE);
            compare(calls[1].status, VoiceCall.STATUS_ACTIVE);
            verify(wrapper.hasConference);
            compare(wrapper.conferenceSize, 2);
            compare(lines().length, 1);
            verify(lines()[0].conference);
            compare(lines()[0].calls.length, 2);
            compare(failedSpy.count, 0);
        }

        function test_theCardShowsTheConferenceAsOne() {
            twoCalls();
            var page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: wrapper.currentCall()
            });
            compare(page.lines.length, 2);
            verify(page.multipleLines);

            wrapper.merge();

            compare(page.lines.length, 1);
            verify(page.conferenceOnly);
            verify(!page.multipleLines);
        }

        // oFono says Multiparty on a call whose state does not change, so
        // nothing bumps callsRevision for the call that was already active.
        function test_multipartyAloneRegroupsTheCard() {
            var calls = twoCalls();
            var page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: calls[1]
            });
            compare(page.lines.length, 2);

            calls[0].status = VoiceCall.STATUS_ACTIVE;
            var revision = wrapper.callsRevision;
            calls[0].isMultiparty = true;
            calls[1].isMultiparty = true;

            compare(wrapper.callsRevision, revision);
            verify(wrapper.hasConference);
            compare(page.lines.length, 1);
            verify(page.conferenceOnly);
        }

        function test_theConferenceIsNotOfferedToItself() {
            conference();
            verify(!wrapper.canMerge, "nothing on hold to join");
            verify(wrapper.canSplit);
        }

        function test_aThirdCallCanJoinTheConference() {
            conference();
            var third = network.wait("0612345678");
            third.answer();
            compare(sent(), "AT+CHLD=2");
            network.commands = [];
            verify(wrapper.canMerge);

            wrapper.merge();

            compare(sent(), "AT+CHLD=3");
            compare(wrapper.conferenceSize, 3);
            compare(lines().length, 1);
        }

        function test_aFullConferenceTakesNoMore() {
            conference();
            for (var i = 0; i < 3; ++i) {
                network.wait("061234567" + i).answer();
                wrapper.merge();
            }
            compare(wrapper.conferenceSize, wrapper.maxConferenceSize);

            network.wait("0612345679").answer();
            verify(wrapper.canSwap);
            verify(!wrapper.canMerge);
        }

        function test_aRefusedMergeSaysSoAndLeavesBothCallsUp() {
            var calls = twoCalls();
            network.refuseCallControl = true;

            wrapper.merge();

            compare(sent(), "AT+CHLD=3");
            compare(failedSpy.count, 1);
            compare(failedSpy.signalArguments[0][0], CallMessages.conferenceFailed);
            compare(calls[0].status, VoiceCall.STATUS_HELD);
            compare(calls[1].status, VoiceCall.STATUS_ACTIVE);
            verify(!wrapper.hasConference);
            verify(wrapper.canSwap, "the calls are still there to swap");
            compare(lines().length, 2);
        }

        function test_aRefusedMergeIsNotADialFailure() {
            var spy = createTemporaryObject(spyComponent, root, { target: wrapper, signalName: "dialFailed" });
            twoCalls();
            network.refuseCallControl = true;

            wrapper.merge();

            compare(spy.count, 0);
        }

        function test_aSecondTapWhileTheFirstGoesIsNotAFailure() {
            twoCalls();
            network.error("CreateMultiparty: org.ofono.Error.InProgress Operation already in progress");

            compare(failedSpy.count, 0);
        }

        function test_otherErrorsAreNotCallControlFailures() {
            twoCalls();
            network.error("some other error from the modem");

            compare(failedSpy.count, 0);
        }

        function test_splitLeavesThatCallActiveAndTheOtherHeld() {
            var calls = conference();

            wrapper.split(calls[1]);

            compare(sent(), "AT+CHLD=2" + calls[1].index);
            compare(calls[1].status, VoiceCall.STATUS_ACTIVE);
            compare(calls[0].status, VoiceCall.STATUS_HELD);
            verify(!calls[1].isMultiparty);
            verify(!calls[0].isMultiparty, "one call left is no conference");
            verify(!wrapper.hasConference);
            compare(lines().length, 2);
        }

        function test_splitOutOfThreeLeavesAConferenceOfTwoHeld() {
            var calls = conference();
            var third = network.wait("0612345678");
            third.answer();
            wrapper.merge();
            network.commands = [];

            wrapper.split(third);

            compare(sent(), "AT+CHLD=2" + third.index);
            compare(third.status, VoiceCall.STATUS_ACTIVE);
            compare(wrapper.conferenceSize, 2);
            compare(calls[0].status, VoiceCall.STATUS_HELD);
            compare(calls[1].status, VoiceCall.STATUS_HELD);
            compare(lines().length, 2);
        }

        function test_splitOnACallNotInItTakesFromTheConference() {
            var calls = conference();
            var outsider = network.wait("0612345678");

            wrapper.split(outsider);

            compare(sent(), "AT+CHLD=2" + calls[0].index);
        }

        function test_aRefusedSplitSaysSoAndLeavesTheConference() {
            var calls = conference();
            network.refuseCallControl = true;

            wrapper.split(calls[0]);

            compare(failedSpy.count, 1);
            compare(failedSpy.signalArguments[0][0], CallMessages.extractFailed);
            verify(wrapper.hasConference);
            compare(lines().length, 1);
        }

        function test_noSplitWithACallOnHold() {
            conference();
            network.wait("0612345678").answer();

            verify(wrapper.hasConference);
            verify(wrapper.hasHeldCall);
            verify(!wrapper.canSplit, "oFono's PrivateChat refuses with a call on hold");
        }

        function test_aHeldConferenceHasNoPrivateButton() {
            conference();
            var third = network.wait("0612345678");
            third.answer();
            network.end(third);
            verify(wrapper.hasConference);
            verify(wrapper.hasHeldCall);

            var page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: wrapper.conferenceCall()
            });
            verify(page.conferenceOnly);
            var members = findChild(page, "conferenceMembers");
            verify(members !== null);
            verify(!members.canPrivate);
        }

        function test_endingAConferenceEndsAllOfItOneAtATime() {
            conference();
            network.busyMs = 20;

            wrapper.hangupCalls(lines()[0].calls);

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0, "nothing was asked of oFono while it was busy");
            compare(network.commands.length, 2);
        }

        function test_somethingElseMovingDoesNotJumpTheQueue() {
            conference();
            network.busyMs = 50;

            wrapper.hangupInProgress();
            wrapper.callsRevision = wrapper.callsRevision + 1;
            wait(10);
            wrapper.callsRevision = wrapper.callsRevision + 1;

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0);
        }

        function test_theConferencesLineEndsAllOfIt() {
            var calls = conference();
            var third = network.wait("0612345678");
            third.answer();
            var page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: third
            });
            verify(page.multipleLines);
            var line = findChild(page, "callLine0");
            verify(line !== null);
            verify(line.conference);
            network.busyMs = 20;

            line.hangupRequested();

            tryCompare(network.voiceCalls, "count", 1, 2000);
            compare(network.voiceCalls.list[0], third);
            compare(network.refused, 0);
        }

        function test_theCardsHangupEndsAConference() {
            conference();
            network.busyMs = 20;

            wrapper.hangupInProgress();

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0);
        }

        function test_hangingUpOnAllEndsAnActiveAndAHeldCall() {
            twoCalls();
            network.busyMs = 20;

            wrapper.hangupAll();

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0);
        }

        function test_aCallThatWillNotGoDoesNotKeepTheRestUp() {
            twoCalls();
            wrapper._hangupTurnMs = 20;
            // oFono is busy with something else: the first hangup is turned away.
            network.busy = true;
            wrapper.hangupAll();
            compare(network.refused, 1);
            network.busy = false;

            tryCompare(network.voiceCalls, "count", 1, 2000);
        }

        function test_aRingingCallIsLeftAloneByTheQueue() {
            conference();
            var ringing = network.wait("0612345678");
            network.busyMs = 20;

            wrapper.hangupInProgress();

            tryCompare(network.voiceCalls, "count", 1, 2000);
            compare(network.voiceCalls.list[0], ringing);
        }

        Component {
            id: spyComponent
            SignalSpy {}
        }
    }
}
