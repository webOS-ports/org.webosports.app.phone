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

    /// True when the buddy is reachable right now. Connectors that publish no
    /// presence at all are treated as available rather than hidden.
    function isAvailable(serviceName, username) {
        var buddy = buddyInfo(serviceName, username);
        if (!buddy)
            return true;

        return _availability(buddy) !== 0;
    }

    function _availability(buddy) {
        return buddy.personAvailability !== undefined ? buddy.personAvailability
                                                      : buddy.availability;
    }

    // The watch on this kind fires far more often than presence changes: every
    // connector signal ends up as a db8 merge, and a merge bumps _rev even when
    // it writes the same values. Only wake listeners when something they render
    // actually changed, or a busy roster rebuilds every contact list for nothing.
    function _refresh() {
        var buddies = {};
        var signature = [];

        for (var i = 0; i < buddyModel.count; ++i) {
            var buddy = buddyModel.get(i);
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

    Db8Model {
        id: buddyModel

        kind: "com.palm.imbuddystatus:1"
        watch: true
        query: ({})

        Component.onCompleted: {
            if(buddyModel.setTestDataFile) {
                buddyModel.setTestDataFile(Qt.resolvedUrl("../test/imbuddystatus.json"));
            }
        }

        onCountChanged: imBuddyStatus._refresh()
    }
}
