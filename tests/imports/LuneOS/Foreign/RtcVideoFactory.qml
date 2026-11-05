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

pragma Singleton
import QtQuick 2.0

/**
 * Stands in for luneos-rtc-engine's RtcVideoFactory in the tests: no GStreamer
 * source here, and every call is written to the log for a test to read.
 */
QtObject {
    property var log: []
    /// Set to undefined to stand for a LuneOS.Foreign without it.
    property var stopShmSource: function(source) { log.push("stopShmSource"); }

    function available() { return false; }
    function createShmSource(path, width, height) { return null; }
}
