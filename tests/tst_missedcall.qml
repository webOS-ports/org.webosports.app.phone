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

/**
 * The missed call alert minimizes as 2.2.4's did: up for a minute, then
 * into the notifications with the red missed call icon - unless "Call back"
 * or "Dismiss" answered it.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "MissedCall"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component {
            id: alertComponent
            MissedCallAlert { timeoutMs: 200 }
        }
        Component {
            id: managerComponent
            NotificationManager {}
        }

        SignalSpy { id: minimizedSpy; signalName: "minimized" }

        function makeAlert() {
            var alert = createTemporaryObject(alertComponent, root, { appTheme: theme });
            verify(alert !== null, "the alert did not load");
            minimizedSpy.clear();
            minimizedSpy.target = alert;
            return alert;
        }

        function test_anUnansweredAlertMinimizesAfterItsTime() {
            var alert = makeAlert();
            alert.showMissedCall("5550100", "Alice");
            verify(alert.visible);
            compare(minimizedSpy.count, 0);

            minimizedSpy.wait(2000);
            compare(minimizedSpy.count, 1);
            compare(minimizedSpy.signalArguments[0][0], "5550100");
            compare(minimizedSpy.signalArguments[0][1], "Alice");
            verify(!alert.visible, "the alert stayed up");
        }

        function test_callBackDoesNotMinimize() {
            var alert = makeAlert();
            alert.showMissedCall("5550101", "");
            alert.accepted();
            wait(500);
            compare(minimizedSpy.count, 0);
            // Nor later, when another missed call takes the alert.
            alert.showMissedCall("5550111", "");
            compare(minimizedSpy.count, 0);
        }

        function test_dismissDoesNotMinimize() {
            var alert = makeAlert();
            alert.showMissedCall("5550102", "");
            alert.dismissed();
            wait(500);
            compare(minimizedSpy.count, 0);
            alert.showMissedCall("5550112", "");
            compare(minimizedSpy.count, 0);
        }

        function test_aSecondMissedCallMinimizesTheFirst() {
            var alert = makeAlert();
            alert.timeoutMs = 60000;
            alert.showMissedCall("5550103", "First");
            alert.showMissedCall("5550104", "Second");
            compare(minimizedSpy.count, 1);
            compare(minimizedSpy.signalArguments[0][0], "5550103");
            verify(alert.visible, "the second call's alert is not up");
        }

        function test_theScreenComingOnLateMinimizes() {
            var alert = makeAlert();
            alert.timeoutMs = 60000;
            alert.showMissedCall("5550105", "");
            // The device slept through the minute.
            alert._missedAt = new Date(Date.now() - 61000);
            alert._displayStatus({ payload: JSON.stringify({ event: "displayOn" }) });
            compare(minimizedSpy.count, 1);
        }

        function test_theScreenComingOnEarlyLeavesItUp() {
            var alert = makeAlert();
            alert.timeoutMs = 60000;
            alert.showMissedCall("5550106", "");
            alert._displayStatus({ payload: JSON.stringify({ event: "displayOn" }) });
            compare(minimizedSpy.count, 0);
            verify(alert.visible);
        }

        function test_theShellClosingItMinimizes() {
            var alert = makeAlert();
            alert.timeoutMs = 60000;
            alert.showMissedCall("5550107", "");
            alert.windowCloseRequested(null);
            compare(minimizedSpy.count, 1);
        }

        function test_theMinimizedCallIsPostedWithTheRedIcon() {
            var manager = createTemporaryObject(managerComponent, root);
            verify(manager !== null, "the notification manager did not load");
            var toast = manager.postMissedCall("5550108", "Bob", new Date());
            compare(toast.title, "Missed call");
            verify(toast.message.indexOf("Bob") === 0, "message: " + toast.message);
            verify(/notification-large-missed\.png$/.test(toast.iconUrl), "icon: " + toast.iconUrl);
            compare(toast.onclick.params.action, "calllog");
        }
    }
}
