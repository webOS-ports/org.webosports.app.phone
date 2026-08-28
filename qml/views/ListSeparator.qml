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

import LunaNext.Common 0.1

/**
 * The rule between two rows of a list.
 *
 * com.palm.app.phone draws this with call-log-list-separator.png, tiled across
 * the row (`.call-log-separator`, and the contact list's own item border). It is
 * two pixels tall: a dark line with a faint highlight under it, which is what
 * gives the lists their engraved look. A flat one-pixel rectangle does not.
 */
Image {
    /// Set false on the last row before a section header, which brings its own
    /// rule; two together read as a gap in the list.
    property bool drawn: true

    height: drawn ? 2 : 0
    visible: drawn

    source: Qt.resolvedUrl("images/call-log-list-separator.png")
    fillMode: Image.Tile
    horizontalAlignment: Image.AlignLeft
    verticalAlignment: Image.AlignTop
}
