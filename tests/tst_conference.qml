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
import "../qml/services/CallLines.js" as CallLines

/**
 * A conference is one entry, as on webOS 2.x: one line in the call card
 * however many are in it, and with nothing else up the card is the
 * conference, listing who is in it.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "Conference"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component {
            id: callComponent
            QtObject {
                property string handlerId: ""
                property string providerId: ""
                property string lineId: ""
                property int status: VoiceCall.STATUS_ACTIVE
                property string statusText: "active"
                property bool isIncoming: false
                property bool isMultiparty: false
                property int duration: 0
                property int hangups: 0
                function hangup() { hangups = hangups + 1; }
                function split() { isMultiparty = false; }
            }
        }
        Component {
            id: membersComponent
            ConferenceMembers { width: 480 }
        }
        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: lineComponent
            CallLineDelegate { width: 480 }
        }
        Component {
            id: pageComponent
            ActiveCallPage { width: 480; height: 800 }
        }

        function makeCall(id, multiparty, duration) {
            var call = createTemporaryObject(callComponent, root,
                                             { handlerId: id, lineId: "555010" + id.slice(-1),
                                               isMultiparty: multiparty, duration: duration || 0 });
            verify(call !== null, "the call did not load");
            return call;
        }

        // --- lines ---

        function test_aCallOnItsOwnIsALine() {
            var a = makeCall("a1", false);
            var lines = CallLines.group([a]);
            compare(lines.length, 1);
            verify(!lines[0].conference);
            compare(lines[0].call, a);
        }

        function test_twoCallsAreTwoLines() {
            var lines = CallLines.group([makeCall("b1", false), makeCall("b2", false)]);
            compare(lines.length, 2);
        }

        function test_aConferenceIsOneLine() {
            var a = makeCall("c1", true), b = makeCall("c2", true), c = makeCall("c3", true);
            var lines = CallLines.group([a, b, c]);
            compare(lines.length, 1);
            verify(lines[0].conference);
            compare(lines[0].calls.length, 3);
            compare(lines[0].call, a);
        }

        function test_theConferenceTakesItsFirstMembersPlace() {
            var single = makeCall("d1", false), a = makeCall("d2", true), b = makeCall("d3", true);
            var lines = CallLines.group([a, single, b]);
            compare(lines.length, 2);
            verify(lines[0].conference);
            compare(lines[0].calls.length, 2);
            compare(lines[1].call, single);
            compare(CallLines.lineOf(lines, b), lines[0]);
            compare(CallLines.lineOf(lines, single), lines[1]);
        }

        function test_aConferenceHasBeenUpAsLongAsItsLongestCall() {
            var lines = CallLines.group([makeCall("e1", true, 5000), makeCall("e2", true, 90000)]);
            compare(CallLines.duration(lines[0]), 90000);
        }

        // --- who is in it ---

        SignalSpy { id: hangupSpy; signalName: "hangupRequested" }
        SignalSpy { id: privateSpy; signalName: "privateRequested" }

        function makeMembers(calls) {
            var members = createTemporaryObject(membersComponent, root,
                                                { calls: calls, appTheme: theme });
            verify(members !== null, "the member list did not load");
            hangupSpy.clear(); hangupSpy.target = members;
            privateSpy.clear(); privateSpy.target = members;
            return members;
        }

        function test_oneRowPerMemberNoDrawerOpen() {
            var members = makeMembers([makeCall("f1", true), makeCall("f2", true)]);
            waitForRendering(members);
            compare(members.openIndex, -1);
            // Two rows of 48 and their hairlines, no drawer.
            verify(members.height > 0);
            var closedHeight = members.height;
            mouseClick(members, members.width / 2, 10);
            compare(members.openIndex, 0);
            // A Column lays its rows out again on the next polish.
            tryVerify(function() { return members.height > closedHeight; }, 1000, "the drawer did not open");
        }

        function findChild(item, name) {
            if (item.objectName === name && item.visible)
                return item;
            for (var i = 0; i < item.children.length; ++i) {
                var found = findChild(item.children[i], name);
                if (found) return found;
            }
            return null;
        }

        function test_theDrawerHangsUpOrTakesAsideThatMember() {
            var a = makeCall("g1", true), b = makeCall("g2", true);
            var members = makeMembers([a, b]);
            waitForRendering(members);

            members.openIndex = 1;
            waitForRendering(members);
            var hangup = findChild(members, "hangupButton");
            verify(hangup !== null, "no hang up button in the open drawer");
            mouseClick(hangup);
            compare(hangupSpy.count, 1);
            compare(hangupSpy.signalArguments[0][0], b);
            compare(members.openIndex, -1);

            members.openIndex = 0;
            waitForRendering(members);
            var aside = findChild(members, "privateButton");
            mouseClick(aside);
            compare(privateSpy.count, 1);
            compare(privateSpy.signalArguments[0][0], a);
        }

        // --- the conference's line next to another call ---

        function test_theConferenceLineIsTitledAndTimedAsAWhole() {
            var a = makeCall("k1", true, 5000);
            var line = createTemporaryObject(lineComponent, root,
                                             { voiceCall: a, appTheme: theme, lineDuration: 125000 });
            verify(line !== null, "the call line did not load");
            compare(line.displayName, "Conference call");
            compare(line.displayAddress, "");
            compare(line.stateText, "02:05");
        }

        function test_aCallLineStillShowsWhoItIs() {
            var a = makeCall("l1", false, 5000);
            var line = createTemporaryObject(lineComponent, root, { voiceCall: a, appTheme: theme });
            verify(line.displayName !== "Conference call");
            verify(line.displayAddress.length > 0);
        }

        // --- the call card ---

        function makePage(calls) {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            wrapper.synergyTransports = { "test": { calls: calls } };
            wrapper.callsRevision = wrapper.callsRevision + 1;
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCallMgrWrapper: wrapper,
                                               voiceCall: calls[0] });
            verify(page !== null, "the call page did not load");
            return page;
        }

        function test_aConferenceAloneIsTheCard() {
            var a = makeCall("i1", true), b = makeCall("i2", true);
            var page = makePage([a, b]);
            verify(page.conferenceOnly);
            verify(!page.multipleLines);
            compare(page.lines.length, 1);
        }

        function test_aConferenceAndACallAreTwoLines() {
            var a = makeCall("j1", true), b = makeCall("j2", true), c = makeCall("j3", false);
            var page = makePage([a, b, c]);
            verify(!page.conferenceOnly);
            verify(page.multipleLines);
            compare(page.lines.length, 2);
        }
    }
}
