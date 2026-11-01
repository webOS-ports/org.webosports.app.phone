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
import "fakes"

/**
 * A call waiting, as on the Mindphone on 2026-10-31: call 1 answered, call
 * 2 waiting, hold and answer, then call 2 ended with call 1 on hold. The
 * fake network behaves as voicecall-manager over oFono does - in particular
 * activeVoiceCall stays the first call throughout, held or not - and
 * records the AT+CHLD each step would have sent.
 *
 * - Swap swaps, both ways, with AT+CHLD=2;
 * - once the active call ends, the held one is what the call screen shows,
 *   it stays on hold (as on legacy), and Resume takes it back;
 * - end-and-answer, reject, and the other end hanging up the held call.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "CallWaiting"
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

        SignalSpy { id: endingSpy; signalName: "endingCall" }

        property var network: null
        property var wrapper: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            verify(network !== null, "the fake network did not load");
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            verify(wrapper !== null, "the wrapper did not load");
            endingSpy.clear();
            endingSpy.target = wrapper;
        }

        function sent() { return network.commands.join(" "); }

        /// Call 1 talking, call 2 taken with hold and answer.
        function holdAndAnswer() {
            var first = network.ring("0600000001");
            wrapper.answer();
            compare(first.status, VoiceCall.STATUS_ACTIVE);

            var second = network.wait("0600000002");
            compare(wrapper.incomingVoiceCall(), second);
            verify(wrapper.isCallWaiting(second), "a second call is a call waiting");
            // What the strip's Answer does with a waiting call.
            second.answer();

            compare(sent(), "ATA AT+CHLD=2");
            compare(first.status, VoiceCall.STATUS_HELD);
            compare(second.status, VoiceCall.STATUS_ACTIVE);
            // What the real manager does, and what threw the app.
            compare(wrapper.activeVoiceCall, first);
            return [first, second];
        }

        function test_theCallBeingTalkedOnIsTheActiveOne() {
            var calls = holdAndAnswer();
            compare(wrapper.currentCall(), calls[1]);
            // Were the call being talked on to end, the held one is next.
            compare(wrapper.callAfterEnding(calls[1].handlerId), calls[0]);
            verify(wrapper.hasActiveCall);
            verify(wrapper.canSwap);
            verify(!wrapper.canResume);
        }

        function test_swapSwapsBothWays() {
            var calls = holdAndAnswer();
            wrapper.swap();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=2");
            compare(calls[0].status, VoiceCall.STATUS_ACTIVE);
            compare(calls[1].status, VoiceCall.STATUS_HELD);
            compare(wrapper.currentCall(), calls[0]);

            wrapper.swap();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=2 AT+CHLD=2");
            compare(calls[0].status, VoiceCall.STATUS_HELD);
            compare(calls[1].status, VoiceCall.STATUS_ACTIVE);
        }

        function test_theHeldCallIsLeftOnHoldAndCanBeResumed() {
            var calls = holdAndAnswer();
            calls[1].hangup();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=12");
            compare(endingSpy.count, 1);
            compare(endingSpy.signalArguments[0][0].handlerId, calls[1].handlerId);

            compare(wrapper.callCount, 1);
            // Legacy left it held until Resume was tapped.
            compare(calls[0].status, VoiceCall.STATUS_HELD);
            compare(wrapper.callAfterEnding(calls[1].handlerId), calls[0]);
            verify(!wrapper.hasActiveCall, "a held call is not an active one");
            verify(!wrapper.canSwap, "nothing to swap with");
            verify(wrapper.canResume);

            wrapper.resume();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=12 AT+CHLD=2");
            compare(calls[0].status, VoiceCall.STATUS_ACTIVE);
            verify(!wrapper.canResume);
            compare(wrapper.currentCall(), calls[0]);
        }

        function test_swapWithOnlyAHeldCallResumesIt() {
            var calls = holdAndAnswer();
            calls[1].hangup();
            wrapper.swap();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=12 AT+CHLD=2");
            compare(calls[0].status, VoiceCall.STATUS_ACTIVE);
        }

        function test_theCallScreenMovesToTheHeldCallAndResumesIt() {
            var calls = holdAndAnswer();
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCallMgrWrapper: wrapper,
                                               voiceCall: calls[1] });
            verify(page !== null, "the call page did not load");
            verify(page.multipleLines);
            var resume = findChild(page, "resumeButton");
            var swap = findChild(page, "swapButton");
            verify(resume !== null && swap !== null, "no Resume or Swap button");
            verify(swap.visible);
            verify(!resume.visible);

            calls[1].hangup();

            verify(!page.multipleLines);
            compare(page.selectedCall, calls[0]);
            compare(findChild(page, "callState").text, "On hold");
            verify(!swap.visible, "Swap offered with nothing to swap with");
            verify(resume.visible, "no Resume for the held call");

            // Let the row lay its buttons out again now Swap has gone.
            waitForRendering(page);
            mouseClick(resume);
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=12 AT+CHLD=2");
            compare(calls[0].status, VoiceCall.STATUS_ACTIVE);
            verify(!resume.visible);
            verify(page.voiceCallIsActive);
        }

        function test_aCallThatGoesWithoutDisconnectingStillLeavesTheHeldOne() {
            network.disconnectBeforeRemoval = false;
            var calls = holdAndAnswer();
            calls[1].hangup();
            compare(endingSpy.count, 1);
            compare(wrapper.callAfterEnding(calls[1].handlerId), calls[0]);
            verify(wrapper.canResume);
        }

        function test_theHeadsetButtonEndsTheCallBeingTalkedOn() {
            var calls = holdAndAnswer();
            // HeadsetCallButton hangs up currentCall().
            wrapper.currentCall().hangup();
            compare(sent(), "ATA AT+CHLD=2 AT+CHLD=12");
            compare(calls[0].status, VoiceCall.STATUS_HELD);
        }

        function test_endAndAnswer() {
            var first = network.ring("0600000001");
            wrapper.answer();
            var second = network.wait("0600000002");
            wrapper.releaseActiveAndAnswer();
            compare(first.status, VoiceCall.STATUS_DISCONNECTED);
            compare(second.status, VoiceCall.STATUS_ACTIVE);
            compare(wrapper.callCount, 1);
            compare(wrapper.currentCall(), second);
            verify(!wrapper.canResume);
        }

        function test_rejectTheWaitingCall() {
            var first = network.ring("0600000001");
            wrapper.answer();
            var second = network.wait("0600000002");
            wrapper.reject();
            compare(sent(), "ATA AT+CHLD=0");
            compare(first.status, VoiceCall.STATUS_ACTIVE);
            compare(wrapper.callAfterEnding(second.handlerId), first);
            compare(wrapper.currentCall(), first);
            verify(!wrapper.canResume);
        }

        function test_theCardsHangupLeavesTheCallWaitingRinging() {
            var first = network.ring("0600000001");
            wrapper.answer();
            var second = network.wait("0600000002");
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCallMgrWrapper: wrapper,
                                               voiceCall: first });
            verify(page !== null, "the call page did not load");
            verify(page.multipleLines);
            waitForRendering(page);
            mouseClick(findChild(page, "hangupArea"));
            compare(sent(), "ATA AT+CHLD=11");
            compare(second.status, VoiceCall.STATUS_WAITING);
            compare(wrapper.incomingVoiceCall(), second);
        }

        function test_theOtherEndHangsUpTheHeldCall() {
            var calls = holdAndAnswer();
            network.end(calls[0]);
            compare(wrapper.callAfterEnding(calls[0].handlerId), calls[1]);
            compare(wrapper.currentCall(), calls[1]);
            verify(!wrapper.canSwap);
            verify(!wrapper.canResume);
        }

        function test_theLastCallEndingLeavesNothing() {
            var first = network.ring("0600000001");
            wrapper.answer();
            first.hangup();
            compare(wrapper.callAfterEnding(first.handlerId), null);
            verify(!wrapper.isCallWaiting(network.ring("0600000001")),
                   "a call on its own is not a call waiting");
        }
    }
}
