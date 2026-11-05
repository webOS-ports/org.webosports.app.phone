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

import LuneOS.Service 1.0

/**
 * Live buddy presence, shared by every list that offers a Synergy call.
 *
 * Ported from the legacy ImBuddyStatusCache. Every connector publishes into the
 * polymorphic base kind com.palm.imbuddystatus:1, so watching that one kind
 * covers all of them with no per-service code. Entries are keyed by
 * "serviceName|username", because a username is no longer unique across
 * services -- the same phone number can be on two connectors at once.
 */
Item {
    id: imBuddyStatus

    /// Bumped when presence actually changed, so bindings can depend on it.
    property int revision: 0

    property var _buddies: ({})
    property string _signature: ""

    /// Presence record for one buddy, or null.
    function buddyInfo(serviceName, username) {
        revision;
        if (!serviceName || !username)
            return null;

        return _buddies[serviceName + "|" + username] || null;
    }

    /// The availability values every connector writes, imlibpurple's
    /// PalmAvailability and the legacy IMAddress.STATUS: the lower, the more
    /// reachable.
    readonly property var availability: ({ online: 0, mobile: 1, idle: 2, invisible: 3,
                                           offline: 4, pending: 5, noPresence: 6 })

    /// True when the buddy is reachable right now: online, on mobile, or idle
    /// (busy), as the legacy phone offered a call to 0 and 2. Invisible,
    /// offline and pending are not. Connectors that publish no presence at
    /// all, or no presence for this buddy, are treated as available rather
    /// than hidden.
    function isAvailable(serviceName, username) {
        var buddy = buddyInfo(serviceName, username);
        if (!buddy)
            return true;

        var value = _availability(buddy);
        return value !== availability.invisible && value !== availability.offline
                && value !== availability.pending;
    }

    function _availability(buddy) {
        return buddy.personAvailability !== undefined ? buddy.personAvailability
                                                      : buddy.availability;
    }

    // The watch on this kind fires far more often than presence changes: every
    // connector signal ends up as a db8 merge, and a merge bumps _rev even when
    // it writes the same values. Only wake listeners when something they render
    // actually changed, or a busy roster rebuilds every contact list for nothing.
    function _refresh(rows) {
        var buddies = {};
        var signature = [];

        for (var i = 0; i < rows.length; ++i) {
            var buddy = rows[i];
            if (!buddy.username || !buddy.serviceName)
                continue;

            var key = buddy.serviceName + "|" + buddy.username;
            buddies[key] = buddy;
            signature.push(key + "=" + _availability(buddy));
        }

        var joined = signature.sort().join(",");
        if (joined === _signature)
            return;

        _signature = joined;
        _buddies = buddies;
        coalesceTimer.restart();
    }

    // A roster coming online signals one buddy at a time; coalesce the burst so
    // listeners re-render once instead of once per buddy.
    Timer {
        id: coalesceTimer
        interval: 500
        onTriggered: imBuddyStatus.revision = imBuddyStatus.revision + 1
    }

    // Presence is transient, so imlibpurple and the connectors keep this kind
    // in tempdb, not in the main db8. Db8Model only reaches com.palm.db, where
    // the kind does not exist ("kind not registered"), so the watch is made on
    // tempdb directly.
    readonly property string _findUri: "luna://com.webos.service.tempdb/find"
    property var _watch: null
    property int _generation: 0

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
    }

    Component.onCompleted: _query()

    /// Reads every buddy again; the first page carries the watch.
    function _query() {
        _generation = _generation + 1;
        if (_watch && _watch.cancel)
            _watch.cancel();
        _watch = _page(null, [], _generation);
    }

    function _page(page, rows, generation) {
        var params = { query: { from: "com.palm.imbuddystatus:1" } };
        if (page)
            params.query.page = page;
        else
            params.watch = true;

        return _send(params, !page, function(response) {
            if (generation !== _generation)
                return;
            if (response.fired) {
                _query();
                return;
            }
            if (response.returnValue === false) {
                console.warn("ImBuddyStatus: " + response.errorText);
                return;
            }
            rows = rows.concat(response.results || []);
            if (response.next)
                _page(response.next, rows, generation);
            else
                _refresh(rows);
        });
    }

    /// One find on tempdb. A watch stays open for its "fired" reply, a later
    /// page is a single reply. The tests replace this.
    function _send(params, watch, onReply) {
        var reply = function(message) { onReply(JSON.parse(message.payload)); };
        var error = function(text) { console.warn("ImBuddyStatus: " + text); };
        if (watch)
            return lunaService.subscribe(_findUri, JSON.stringify(params), reply, error);
        return lunaService.call(_findUri, JSON.stringify(params), reply, error);
    }
}
