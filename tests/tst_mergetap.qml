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

import "../qml/views"
import "../qml/services"
import "fakes"

/**
 * A second tap on a merge or split that seems not to have happened. The
 * answer can take a second, the card changes shape when it comes, and the
 * finger is still where it was, against a fake network (see FakeCallNetwork):
 *
 * - the tap is real, at the spot on screen, so it goes to whatever is there;
 * - where the arrow was stays dead until the card has settled;
 * - End does not move when two lines become a conference, so that spot is
 *   no danger later on either, and End works throughout;
 * - coming to a conference with no lines before it there is nothing to keep,
 *   so End does move when it splits, and the same dead spot covers that;
 * - the row's hangup does not move when the arrow stops working.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "MergeTap"
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
            ActiveCallPage { width: 480; height: 800; tapGuardMs: 200 }
        }

        property var network: null
        property var wrapper: null
        property var page: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            verify(network !== null, "the fake network did not load");
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            verify(wrapper !== null, "the wrapper did not load");
        }

        function sent() { return network.commands.join(" "); }

        /// Call 1 on hold, call 2 talking, on the card.
        function twoCalls() {
            network.ring("0600000001");
            wrapper.answer();
            network.wait("0600000002").answer();
            network.commands = [];
            showPage();
        }

        function showPage() {
            page = createTemporaryObject(pageComponent, root, {
                voiceCallMgrWrapper: wrapper, appTheme: theme, voiceCall: wrapper.currentCall()
            });
            verify(page !== null, "the page did not load");
            waitForRendering(page);
        }

        function line(index) { return findChild(page, "callLine" + index); }
        function arrow(index) { return findChild(line(index), "joinArea"); }
        function end() { return findChild(page, "hangupArea"); }
        function guard() { return findChild(page, "tapGuard"); }

        /// Where the middle of `item` is on the page, now.
        function spot(item) {
            return item.mapToItem(page, item.width / 2, item.height / 2);
        }

        function contains(item, point) {
            var local = item.mapFromItem(page, point.x, point.y);
            return item.visible && local.x >= 0 && local.y >= 0 &&
                   local.x < item.width && local.y < item.height;
        }

        function tap(point) {
            mouseClick(page, point.x, point.y);
            // A positioner moves things on its next polish.
            wait(30);
        }

        function settled() {
            tryCompare(guard(), "enabled", false, 2000);
        }

        function test_theSameSpotAfterTheLowerArrowIsNotEnd() {
            twoCalls();
            var was = spot(arrow(1));

            tap(was);
            compare(sent(), "AT+CHLD=3");
            verify(page.conferenceOnly);

            tap(was);

            compare(sent(), "AT+CHLD=3");
            compare(network.voiceCalls.count, 2);
            verify(page.visible, "End closes the page");
        }

        // The case on the device: nearly three seconds on, long past the guard.
        function test_thatSpotIsNotEndLongAfterwards() {
            twoCalls();
            var was = spot(arrow(1));
            tap(was);
            settled();

            verify(!contains(end(), was));
            tap(was);

            compare(sent(), "AT+CHLD=3");
            compare(network.voiceCalls.count, 2);
            verify(page.visible, "End closes the page");
        }

        function test_endAndTheControlsStayPutThroughAMerge() {
            twoCalls();
            var endWas = spot(end());
            var swapWas = spot(findChild(page, "swapButton"));

            tap(spot(arrow(1)));

            compare(spot(end()).y, endWas.y);
            compare(spot(findChild(page, "splitButton")).y, swapWas.y);
        }

        function test_splitWaitsForTheCardToSettle() {
            twoCalls();
            var split = spot(findChild(page, "swapButton"));
            tap(spot(arrow(1)));

            tap(split);
            compare(sent(), "AT+CHLD=3");

            settled();
            tap(split);
            compare(network.commands.length, 2);
        }

        function test_aConferenceBackToOneCallIsCentredAgain() {
            twoCalls();
            var alone = network.voiceCalls.list[1];
            tap(spot(arrow(1)));
            network.end(network.voiceCalls.list[0]);
            wait(30);

            compare(page.lines.length, 1);
            verify(!page.conferenceOnly);
            compare(page.lines[0].call, alone);
            var first = page;
            showPage();
            compare(findChild(first, "callCard").y, findChild(page, "callCard").y);
        }

        function test_theSameSpotAfterTheUpperArrowOpensNoDrawer() {
            twoCalls();
            var was = spot(arrow(0));
            var members = findChild(page, "conferenceMembers");

            tap(was);
            tap(was);

            compare(members.openIndex, -1);
            compare(network.voiceCalls.count, 2);
        }

        function test_aTapWhileTheMergeGoesIsNotAnotherMerge() {
            twoCalls();
            network.mergeLags = true;
            var was = spot(arrow(1));

            tap(was);
            verify(wrapper.callControlPending);
            tap(was);
            wrapper.merge();

            compare(sent(), "AT+CHLD=3");
        }

        function test_theArrowGoesGreyAtTheTap() {
            twoCalls();
            network.mergeLags = true;
            compare(findChild(line(1), "joinSprite").frame, 0);

            tap(spot(arrow(1)));

            compare(findChild(line(1), "joinSprite").frame, 2);
            compare(findChild(line(0), "joinSprite").frame, 2);
            verify(!arrow(0).enabled);
        }

        // oFono says the held call is active before it says Multiparty: for
        // that moment there are two lines and nothing to merge.
        function test_theHangupStaysPutWhenTheArrowStopsWorking() {
            twoCalls();
            network.mergeLags = true;
            var hangup = findChild(line(1), "lineHangupArea");
            var width = hangup.width;
            var was = spot(arrow(1));

            tap(was);
            network.mergeStatus();

            verify(!line(1).canJoin);
            compare(page.lines.length, 2);
            compare(hangup.width, width);
            verify(!contains(hangup, was));

            tap(was);
            compare(network.voiceCalls.count, 2);
        }

        function test_nothingOnTheArrowWhenItCannotWork() {
            twoCalls();
            wrapper._callControlTurnMs = 50;
            network.mergeLags = true;
            tap(spot(arrow(1)));
            network.mergeStatus();
            settled();

            verify(!line(1).canJoin);
            verify(!wrapper.callControlPending);
            compare(findChild(line(1), "joinSprite").frame, 2);
            network.commands = [];
            tap(spot(arrow(1)));

            compare(sent(), "");
            compare(network.voiceCalls.count, 2);
        }

        function test_endAwayFromThatSpotWorksAtOnce() {
            twoCalls();
            var was = spot(arrow(1));
            tap(was);
            verify(guard().enabled);
            network.busyMs = 20;

            tap(spot(end()));

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0);
        }

        function test_endWorksOnceSettled() {
            twoCalls();
            tap(spot(arrow(1)));
            settled();
            network.busyMs = 20;

            tap(spot(end()));

            tryCompare(network.voiceCalls, "count", 0, 2000);
            compare(network.refused, 0);
            verify(!page.visible);
        }

        function test_theConferencesRowHangsUpOnceSettled() {
            twoCalls();
            tap(spot(arrow(1)));
            settled();
            var third = network.wait("0600000003");
            third.answer();
            network.busyMs = 20;
            verify(line(0).conference);
            wait(30);

            tap(spot(findChild(line(0), "lineHangupArea")));

            tryCompare(network.voiceCalls, "count", 1, 2000);
            compare(network.voiceCalls.list[0], third);
        }

        function test_aRefusedMergeCanBeTriedAgain() {
            twoCalls();
            network.refuseCallControl = true;
            var was = spot(arrow(1));

            tap(was);

            verify(!wrapper.callControlPending);
            compare(page.lines.length, 2);
            settled();
            network.refuseCallControl = false;
            network.commands = [];
            tap(was);
            compare(sent(), "AT+CHLD=3");
        }

        function test_anUnansweredMergeDoesNotBlockTheNextForever() {
            twoCalls();
            wrapper._callControlTurnMs = 50;
            network.mergeLags = true;

            wrapper.merge();
            verify(wrapper.callControlPending);

            tryCompare(wrapper, "callControlPending", false, 2000);
        }

        function test_theSameSpotAfterSplitIsNotEnd() {
            network.ring("0600000001");
            wrapper.answer();
            network.wait("0600000002").answer();
            wrapper.merge();
            network.commands = [];
            showPage();
            var was = spot(findChild(page, "splitButton"));

            tap(was);
            compare(network.commands.length, 1);
            compare(page.lines.length, 2);
            verify(contains(end(), was), "End has to have moved here for this to test anything");

            tap(was);

            compare(network.voiceCalls.count, 2);
            verify(page.visible, "End closes the page");
        }

        function test_theSameSpotAfterPrivateIsNotAMerge() {
            network.ring("0600000001");
            wrapper.answer();
            network.wait("0600000002").answer();
            wrapper.merge();
            network.commands = [];
            showPage();
            var members = findChild(page, "conferenceMembers");
            members.openIndex = 0;
            waitForRendering(page);
            var button = findChild(page, "privateButton");
            var was = button.mapToItem(page, button.width / 2, 5);

            tap(was);
            compare(network.commands.length, 1);
            verify(contains(arrow(0), was), "the arrow has to be here for this to test anything");

            tap(was);

            compare(network.commands.length, 1);
            verify(!wrapper.hasConference);
        }
    }
}
