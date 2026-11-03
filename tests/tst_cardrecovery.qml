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
import QtQuick.Window 2.2
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "../qml/views"
import "../qml/services"
import "fakes"

/**
 * The phone card coming forward for a call while it sits in card view.
 *
 * On sargo on 2026-11-03 a card put away to card view was logged unmapped by
 * the compositor, which then ignored its requests to come back; the call
 * screen never appeared. When the relaunch has not brought the card forward,
 * the window is hidden and shown again, which gives it a new surface - but
 * only while a call needs it, and never for a window that did come forward.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "CardRecovery"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: networkComponent; FakeCallNetwork {} }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }
        Component { id: windowComponent; PhoneWindow {} }
        // Takes the focus, as the launcher does when the card is put away.
        Component { id: otherComponent; Window { width: 100; height: 100; visible: true } }

        property var network: null
        property var wrapper: null
        property var phone: null

        function init() {
            network = createTemporaryObject(networkComponent, root);
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            phone = createTemporaryObject(windowComponent, root,
                                          { voiceCallMgrWrapper: wrapper, phoneUiAppTheme: theme });
            verify(phone !== null, "the phone window did not load");
        }

        function findByName(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            var kids = item.data || [];
            for (var i = 0; i < kids.length; ++i) {
                var found = findByName(kids[i], name);
                if (found)
                    return found;
            }
            return null;
        }

        // Counts the window going away and coming back.
        function watchVisibility() {
            var changes = [];
            phone.visibleChanged.connect(function() { changes.push(phone.visible); });
            return changes;
        }

        function test_aCardThatDidNotComeForwardIsShownAfresh() {
            network.ring("0600000001");
            wrapper.answer();
            compare(wrapper.callCount, 1);
            phone.visible = true;
            var other = createTemporaryObject(otherComponent, root);
            other.requestActivate();
            tryVerify(function() { return !phone.active; }, 2000,
                      "the card is in card view: another window has the focus");
            var changes = watchVisibility();
            findByName(phone, "surfaceRecovery").triggered();
            compare(changes, [false, true], "hidden, then shown again");
            // Hiding the window is how the app hangs up when it is closed;
            // this hide must not.
            compare(wrapper.callCount, 1, "the call is still up");
        }

        function test_noCallLeavesTheCardAlone() {
            phone.visible = true;
            var changes = watchVisibility();
            findByName(phone, "surfaceRecovery").triggered();
            compare(changes, []);
        }

        // Where an incoming call opens. A hidden card the compositor still
        // calls active (sargo, 2026-11-03) is not the window in front.
        function test_aHiddenCardThatStillLooksActiveDoesNotTakeTheCall() {
            verify(!phone.takesCallsInPlace(false, true, false, false));
        }

        function test_onlyTheCardInFrontTakesTheCallInPlace() {
            verify(phone.takesCallsInPlace(true, true, false, false), "the card in front");
            verify(!phone.takesCallsInPlace(true, false, false, false), "a card in card view");
            verify(!phone.takesCallsInPlace(true, true, true, false), "a locked screen");
            verify(!phone.takesCallsInPlace(true, true, false, true), "a call waiting");
        }

        function foreground(appId) {
            phone.__handleForegroundApp({ payload: JSON.stringify({ returnValue: true, appId: appId }) });
        }

        // The application manager's word for which card is on screen wins
        // over the window's own `active`, which a dropped card keeps.
        function test_theForegroundAppDecidesWhetherTheCardIsInFront() {
            phone.visible = true;
            phone.requestActivate();
            tryVerify(function() { return phone.active; }, 2000);
            verify(phone.inFront, "no foreground info yet: the window's active is used");
            foreground("com.palm.launcher");
            verify(!phone.inFront, "active, but another app is in front");
            foreground("org.webosports.app.phone");
            verify(phone.inFront);
            phone.visible = false;
            verify(!phone.inFront, "a hidden card is never in front");
        }

        function test_aFailedForegroundReplyIsIgnored() {
            foreground("com.palm.launcher");
            phone.__handleForegroundApp({ payload: JSON.stringify({ returnValue: false }) });
            compare(phone._foregroundAppId, "com.palm.launcher");
        }

        // The stale case itself: active, visible, but not the foreground app.
        function test_aCardActiveButNotInFrontIsShownAfresh() {
            network.ring("0600000001");
            wrapper.answer();
            phone.visible = true;
            phone.requestActivate();
            tryVerify(function() { return phone.active; }, 2000);
            foreground("com.palm.launcher");
            var changes = watchVisibility();
            findByName(phone, "surfaceRecovery").triggered();
            compare(changes, [false, true], "hidden, then shown again");
            compare(wrapper.callCount, 1, "the call is still up");
        }

        // Answered from the strip with the card hidden: show() alone can
        // leave it unmapped, so recovery is armed for that too.
        function test_showingAHiddenCardForACallArmsRecovery() {
            var call = network.ring("0600000001");
            wrapper.answer();
            // Hidden as a call ending hides it, without hanging up this one.
            phone._resurfacing = true;
            phone.visible = false;
            phone._resurfacing = false;
            compare(wrapper.callCount, 1);
            var recovery = findByName(phone, "surfaceRecovery");
            recovery.stop();
            phone.activeCallDialog(call);
            verify(phone.visible, "the card was not shown");
            verify(recovery.running, "recovery not armed after show()");
        }

        function test_aCardThatCameForwardIsLeftAlone() {
            network.ring("0600000001");
            wrapper.answer();
            verify(phone.visible, "the call puts the window up");
            phone.requestActivate();
            tryVerify(function() { return phone.active; }, 2000);
            var changes = watchVisibility();
            findByName(phone, "surfaceRecovery").triggered();
            compare(changes, []);
        }
    }
}
