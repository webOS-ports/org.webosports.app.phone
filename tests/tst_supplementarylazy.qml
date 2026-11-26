/*
 * Copyright (C) 2026 WebOS Ports
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
 * Call forwarding, call settings and call barring are only pointed at the
 * modem while something needs them. Pointed at it, libqofono reads them, and
 * each read is a request to the network that on LTE can move the phone onto
 * 3G and back; bound at start they made seven of those every time the app
 * or oFono started.
 */
Item {
    width: 720
    height: 2000

    PhoneUiTheme { id: theme }
    TelephonyManager { id: telephony }
    DialingShortcuts { id: shortcuts }
    CallTransports { id: transports }

    SupplementaryServices {
        id: supplementary
        modemPath: "/ril_0"
    }

    Component {
        id: prefsComponent
        PhonePrefsPage {
            anchors.fill: parent
            appTheme: theme
            telephonyManager: telephony
            supplementaryServices: supplementary
            dialingShortcuts: shortcuts
            callTransports: transports
        }
    }

    SignalSpy {
        id: completedSpy
        target: supplementary
        signalName: "completed"
    }

    TestCase {
        name: "SupplementaryServicesLazy"
        when: windowShown

        // The three network-backed objects, told apart by a property only
        // each of them has
        function service(marker) {
            for (var i = 0; i < supplementary.children.length; i++) {
                var o = supplementary.children[i];
                if (o[marker] !== undefined)
                    return o;
            }
            for (var j = 0; j < supplementary.resources.length; j++) {
                var r = supplementary.resources[j];
                if (r && r[marker] !== undefined)
                    return r;
            }
            return null;
        }
        function forwarding() { return service("voiceUnconditional"); }
        function settings() { return service("voiceCallWaiting"); }
        function barring() { return service("voiceOutgoing"); }

        function boundCount() {
            return [forwarding(), settings(), barring()].filter(function(o) {
                return o.modemPath.length > 0;
            }).length;
        }

        function init() {
            completedSpy.clear();
            supplementary._deferredTimeoutMs = 60000;
            supplementary.modemPath = "/ril_0";
            forwarding().voiceUnconditional = "";
            settings().voiceCallWaiting = "disabled";
            while (supplementary._holds > 0)
                supplementary.release();
            completedSpy.clear();
        }

        function test_notBoundAtStart() {
            verify(forwarding() && settings() && barring(), "found the three objects");
            compare(boundCount(), 0);
        }

        function test_holdBindsUntilReleased() {
            supplementary.hold();
            compare(boundCount(), 3);
            compare(forwarding().modemPath, "/ril_0");

            supplementary.hold();
            supplementary.release();
            compare(boundCount(), 3, "still held once");

            supplementary.release();
            compare(boundCount(), 0);

            supplementary.release();
            compare(supplementary._holds, 0, "an extra release does not go negative");
        }

        function test_mmiQueryWaitsForTheObjectThenLetsGo() {
            forwarding().voiceUnconditional = "+31612345678";
            completedSpy.clear();

            verify(supplementary.execute("forwardQuery", { condition: "unconditional" }));
            compare(boundCount(), 3, "bound for the command");
            completedSpy.wait(1000);
            compare(completedSpy.signalArguments[0][0], true);
            verify(completedSpy.signalArguments[0][1].indexOf("+31612345678") >= 0,
                   "answered from the object's settings: " + completedSpy.signalArguments[0][1]);
            compare(boundCount(), 0, "unbound once answered");
            compare(supplementary.busy, false);
        }

        function test_mmiChangeReachesTheObject() {
            verify(supplementary.execute("forwardRegister",
                                         { condition: "unconditional", number: "+31600000000" }));
            completedSpy.wait(1000);
            compare(forwarding().voiceUnconditional, "+31600000000");
            compare(completedSpy.signalArguments[0][0], true);
            compare(boundCount(), 0);
        }

        function test_mmiCallSettings() {
            verify(supplementary.execute("callWaitingSet", { enable: true }));
            completedSpy.wait(1000);
            compare(settings().voiceCallWaiting, "enabled");
            compare(boundCount(), 0);
        }

        function test_mmiWhileHeldStaysBound() {
            supplementary.hold();
            verify(supplementary.execute("callWaitingQuery", {}));
            compare(completedSpy.count, 1);
            compare(boundCount(), 3, "the page still holds them");
            supplementary.release();
        }

        function test_mmiGivesUpWithoutAModem() {
            supplementary.modemPath = "";
            supplementary._deferredTimeoutMs = 50;

            verify(supplementary.execute("forwardQuery", { condition: "unconditional" }));
            compare(completedSpy.count, 0, "waits for the object");
            verify(supplementary.busy);

            completedSpy.wait(1000);
            compare(completedSpy.signalArguments[0][0], false);
            compare(supplementary.busy, false);
            compare(supplementary._mmiNeedsNetwork, false);
        }

        function test_imeiNeedsNoNetwork() {
            verify(supplementary.execute("imeiQuery", {}));
            compare(completedSpy.count, 1);
            compare(boundCount(), 0, "never bound");
        }

        function test_prefsPageHoldsWhileOpen() {
            var page = createTemporaryObject(prefsComponent, parent);
            verify(page);
            compare(boundCount(), 3, "bound while the page is open");

            page.destroy();
            wait(0);
            tryCompare(supplementary, "_holds", 0);
            compare(boundCount(), 0, "let go when it closes");
        }
    }
}
