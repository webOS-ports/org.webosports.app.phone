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

import LuneOS.Service 1.0

import "../qml/services"

/**
 * Who can be called over an IM transport right now.
 *
 * The connectors write imlibpurple's PalmAvailability: the lower the value,
 * the more reachable. 0 is online -- the one value a call must never be
 * refused for.
 */
TestCase {
    name: "ImBuddyStatus"
    when: windowShown

    ImBuddyStatus {
        id: status
    }

    /// Writes into the same mock store the component watches.
    Db8Model {
        id: store
        kind: "com.palm.imbuddystatus:1"
        query: ({})
    }

    function _buddy(username, availability) {
        return { _id: "++Tst" + username, serviceName: "type_test", username: username,
                 availability: availability };
    }

    function initTestCase() {
        store.put([_buddy("online", 0), _buddy("mobile", 1), _buddy("idle", 2),
                   _buddy("invisible", 3), _buddy("offline", 4), _buddy("pending", 5),
                   _buddy("nopresence", 6)]);
        tryVerify(function() { return status.buddyInfo("type_test", "nopresence") !== null; }, 3000);
    }

    function test_online_mobile_and_idle_can_be_called() {
        verify(status.isAvailable("type_test", "online"), "online");
        verify(status.isAvailable("type_test", "mobile"), "mobile");
        verify(status.isAvailable("type_test", "idle"), "idle (busy)");
    }

    function test_invisible_offline_and_pending_cannot() {
        verify(!status.isAvailable("type_test", "invisible"), "invisible");
        verify(!status.isAvailable("type_test", "offline"), "offline");
        verify(!status.isAvailable("type_test", "pending"), "pending");
    }

    /// No presence, from a buddy or a whole connector, does not hide a way to call.
    function test_no_presence_is_not_a_reason_to_hide() {
        verify(status.isAvailable("type_test", "nopresence"));
        verify(status.isAvailable("type_test", "nobody"));
        verify(status.isAvailable("type_unknown", "online"));
    }

    /// A buddy signing in changes no row count; the list must still hear of it.
    function test_a_change_in_presence_is_seen() {
        var before = status.revision;
        store.merge([{ _id: "++Tstoffline", availability: 0 }]);
        tryVerify(function() { return status.revision > before; }, 3000);
        verify(status.isAvailable("type_test", "offline"));

        store.merge([{ _id: "++Tstoffline", availability: 4 }]);
        tryVerify(function() { return !status.isAvailable("type_test", "offline"); }, 3000);
    }
}
