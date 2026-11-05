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

import "../qml/services"
import "../qml/services/LaunchActionHandler.js" as LaunchActionHandler

/**
 * A "dial" launch from another app (Messaging's call buttons) keeps the
 * service and video flag it asked for, so a call from a Signal chat goes over
 * Signal and a video call stays video.
 */
TestCase {
    name: "LaunchDial"

    CallTransports { id: transports }

    // The steps after the service is settled, recorded instead of dialled.
    DialHandler {
        id: dialHandler
        callTransports: transports
        property var placed: []
        function _dialOver(address, transport, video) {
            placed.push({ address: address, transport: transport, video: video });
        }
        function _dialNormal(action) {
            placed.push({ address: action.number, transport: _requestedTransport, video: _requestedVideo });
        }
    }

    property var dialled: []

    function services() {
        var test = this;
        return {
            dialHandler: {
                dial: function(address, transport, video) {
                    test.dialled.push({ address: address, transport: transport, video: video });
                }
            }
        };
    }

    function init() {
        dialled = [];
    }

    function test_dialOverService() {
        verify(LaunchActionHandler.handle({ action: "dial", address: "+31611745571",
                                            transport: "type_signal", video: false }, services()));
        compare(dialled.length, 1);
        compare(dialled[0].address, "+31611745571");
        compare(dialled[0].transport, "type_signal");
        compare(dialled[0].video, false);
    }

    function test_videoStaysVideo() {
        LaunchActionHandler.handle({ action: "dial", address: "+31611745571",
                                     transport: "type_whatsapp", video: true }, services());
        compare(dialled[0].transport, "type_whatsapp");
        compare(dialled[0].video, true);
    }

    function test_plainDialIsCellular() {
        LaunchActionHandler.handle({ action: "dial", address: "4157773456" }, services());
        compare(dialled[0].transport, undefined);
        compare(dialled[0].video, false);
    }

    function test_serviceNameReachesItsDriver() {
        // Messaging names the service "type_signal"; the driver is "com.palm.signal".
        transports.transports["com.palm.signal"] = { templateId: "com.palm.signal", serviceName: "type_signal" };
        dialHandler.placed = [];
        dialHandler.dial("+31611745571", "type_signal", false);
        compare(dialHandler.placed.length, 1);
        compare(dialHandler.placed[0].transport, "com.palm.signal");
        dialHandler.dial("alice.42", "type_signal", true);
        compare(dialHandler.placed[1].transport, "com.palm.signal");
        compare(dialHandler.placed[1].video, true);
    }

    function test_noAddressNoCall() {
        LaunchActionHandler.handle({ action: "dial", transport: "type_signal" }, services());
        compare(dialled.length, 0);
    }
}
