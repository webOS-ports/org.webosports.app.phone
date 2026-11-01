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

import LunaNext.Common 0.1

import "../qml/views"
import "../qml/model"

/**
 * The incoming call strip, in both looks: the height each legacy release
 * opened its popup at, with and without a photo, the gloss only on the
 * handset, and answer and ignore on the sides they were on.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        id: testCase
        name: "IncomingStrip"
        when: windowShown

        PhoneUiTheme  { id: phone }
        TabletUiTheme { id: tablet }

        Contact { id: stranger; lineId: "" }
        Contact { id: friend; lineId: "" }

        Component {
            id: stripComponent
            IncomingCallStrip { width: 480 }
        }

        SignalSpy { id: answerSpy; signalName: "answerClicked" }
        SignalSpy { id: rejectSpy; signalName: "rejectClicked" }

        function makeStrip(theme, contact) {
            var strip = createTemporaryObject(stripComponent, root,
                                              { appTheme: theme, currentContact: contact });
            verify(strip !== null, "the strip did not load");
            return strip;
        }

        function init() {
            friend.personId = "p1";
            friend.givenName = "Ada";
            friend.familyName = "Lovelace";
            friend.avatarPath = Qt.resolvedUrl("../qml/views/images/phone/contacts-icon-frame.png");
            answerSpy.clear();
            rejectSpy.clear();
        }

        function test_a_stranger_has_no_photo() {
            verify(!stranger.hasPhoto);
            verify(friend.hasPhoto);
        }

        // CallSynergizer.handleIncoming: 2.2.4 opened it 195 with a photo, 110
        // without; 3.0.5 140 and 110.
        function test_heights_follow_the_legacy_popups() {
            compare(makeStrip(phone, stranger).implicitHeight, Units.gu(11));
            compare(makeStrip(phone, friend).implicitHeight, Units.gu(19.5));
            compare(makeStrip(tablet, stranger).implicitHeight, Units.gu(11));
            compare(makeStrip(tablet, friend).implicitHeight, Units.gu(14));
        }

        function test_only_the_handset_has_the_gloss() {
            verify(phone.incomingAlertGloss);
            verify(!tablet.incomingAlertGloss);
            verify(phone.incomingAlertTextBox);
            verify(!tablet.incomingAlertTextBox);
        }

        function test_answer_on_the_left_ignore_on_the_right() {
            var strip = makeStrip(phone, stranger);
            strip.height = strip.implicitHeight;
            answerSpy.target = strip;
            rejectSpy.target = strip;

            mouseClick(strip, Units.gu(3.5), strip.height / 2);
            compare(answerSpy.count, 1);
            compare(rejectSpy.count, 0);

            mouseClick(strip, strip.width - Units.gu(3.5), strip.height / 2);
            compare(rejectSpy.count, 1);
            compare(answerSpy.count, 1);
        }

        // .incoming-small-has-image: 3.0.5 drops the buttons level with the box
        // when there is a photo; 2.2.4 leaves them centred.
        function test_the_tablet_drops_the_buttons_beside_a_photo() {
            var strip = makeStrip(tablet, friend);
            strip.height = strip.implicitHeight;
            answerSpy.target = strip;
            mouseClick(strip, Units.gu(3.5), strip.height / 2 + tablet.incomingAlertButtonDrop);
            compare(answerSpy.count, 1);
            verify(tablet.incomingAlertButtonDrop > 0);
            compare(phone.incomingAlertButtonDrop, 0);
        }
    }
}
