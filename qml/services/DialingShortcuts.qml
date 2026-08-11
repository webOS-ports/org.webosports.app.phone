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
 * Dialing shortcuts, as in the legacy app's Dialingshortcut preference: a
 * prefix that is prepended automatically when the user types a number of a
 * given length. Typing a 4-digit extension at the office turns it into the
 * full number.
 *
 * Stored in system preferences under 4DigitNumber ... 7DigitNumber, matching
 * the keys the legacy Dialer.DialStringWidget read.
 */
Item {
    id: dialingShortcuts

    readonly property var supportedLengths: [4, 5, 6, 7]

    property var _prefixes: ({})
    property bool hasShortcuts: false

    /// Prefix to prepend to a number of `length` digits, or "" for none.
    function prefixFor(length) {
        var prefix = _prefixes[length];
        return (typeof prefix === 'string') ? prefix : "";
    }

    function setPrefix(length, prefix) {
        var key = length + "DigitNumber";
        var payload = {};
        payload[key] = prefix || "";

        lunaService.call("luna://com.webos.service.systemservice/setPreferences",
                         JSON.stringify(payload), undefined,
                         function(error) { console.log("Could not store dialing shortcut: " + error); });
    }

    function _updateFromPreferences(preferences) {
        var prefixes = {};
        var any = false;

        supportedLengths.forEach(function(length) {
            var value = preferences[length + "DigitNumber"];
            if (typeof value === 'string' && value.trim().length > 0) {
                prefixes[length] = value.trim();
                any = true;
            }
        });

        _prefixes = prefixes;
        hasShortcuts = any;
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    Component.onCompleted: {
        var keys = supportedLengths.map(function(length) { return length + "DigitNumber"; });
        lunaService.subscribe("luna://com.webos.service.systemservice/getPreferences",
                              JSON.stringify({ keys: keys, subscribe: true }),
                              function(message) { _updateFromPreferences(JSON.parse(message.payload)); },
                              function(error) { console.log("No dialing shortcuts configured: " + error); });
    }
}
