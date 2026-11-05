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

import "../qml/services"

/**
 * Who can be called over an IM transport right now.
 *
 * The connectors write imlibpurple's PalmAvailability: the lower the value,
 * the more reachable. 0 is online -- the one value a call must never be
 * refused for.
 *
 * Presence lives in tempdb, so the component's tempdb find is replaced by a
 * fake store here, which answers in pages of three and can fire the watch.
 */
TestCase {
    name: "ImBuddyStatus"
    when: windowShown

    property var rows: []
    property var finds: []
    property var watchers: []
    property int cancelled: 0
    property bool failNext: false

    function _fire() {
        var open = watchers;
        watchers = [];
        open.forEach(function(w) { if (!w.cancelled) w.onReply({ fired: true }); });
    }

    function _merge(id, availability) {
        rows = rows.map(function(r) {
            if (r._id !== id) return r;
            var copy = JSON.parse(JSON.stringify(r));
            copy.availability = availability;
            return copy;
        });
        _fire();
    }

    ImBuddyStatus {
        id: status

        function _send(params, watch, onReply) {
            finds.push({ params: params, watch: watch });
            if (failNext) {
                failNext = false;
                onReply({ returnValue: false, errorText: "db: permission denied" });
                return null;
            }
            var start = params.query.page ? parseInt(params.query.page) : 0;
            var reply = { returnValue: true, results: rows.slice(start, start + 3) };
            if (start + 3 < rows.length)
                reply.next = String(start + 3);
            var call = { onReply: onReply, cancelled: false,
                         cancel: function() { this.cancelled = true; cancelled = cancelled + 1; } };
            if (watch)
                watchers.push(call);
            onReply(reply);
            return call;
        }
    }

    function _buddy(username, availability) {
        return { _id: "++Tst" + username, serviceName: "type_test", username: username,
                 availability: availability };
    }

    function initTestCase() {
        rows = [_buddy("online", 0), _buddy("mobile", 1), _buddy("idle", 2),
                _buddy("invisible", 3), _buddy("offline", 4), _buddy("pending", 5),
                _buddy("nopresence", 6)];
        _fire();
        tryVerify(function() { return status.buddyInfo("type_test", "nopresence") !== null; }, 3000);
    }

    /// Every page is read, and only the first one asks for the watch.
    function test_reads_every_page_from_tempdb_with_one_watch() {
        verify(status._findUri.indexOf("luna://com.webos.service.tempdb/") === 0, status._findUri);
        var last = finds.slice(-3);
        compare(last.map(function(f) { return f.watch; }), [true, false, false]);
        compare(last[0].params.watch, true);
        compare(last[0].params.query.from, "com.palm.imbuddystatus:1");
        compare(last[2].params.query.page, "6");
        verify(status.buddyInfo("type_test", "online") !== null, "first page");
        verify(status.buddyInfo("type_test", "nopresence") !== null, "last page");
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

    /// A buddy signing in changes no row count; the list must still hear of it,
    /// and the old watch is given up for the new one.
    function test_a_change_in_presence_is_seen() {
        var before = status.revision;
        var cancelledBefore = cancelled;
        _merge("++Tstoffline", 0);
        tryVerify(function() { return status.revision > before; }, 3000);
        verify(status.isAvailable("type_test", "offline"));
        compare(cancelled, cancelledBefore + 1);
        compare(watchers.length, 1);

        _merge("++Tstoffline", 4);
        tryVerify(function() { return !status.isAvailable("type_test", "offline"); }, 3000);
    }

    /// A refused find leaves what was known rather than emptying it.
    function test_an_error_keeps_the_last_presence() {
        failNext = true;
        _fire();
        verify(status.buddyInfo("type_test", "online") !== null);
        verify(!status.isAvailable("type_test", "offline"));
        status._query();   // watch again for the other cases
        compare(watchers.length, 1);
    }
}
