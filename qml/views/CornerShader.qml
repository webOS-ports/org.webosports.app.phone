/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import QtQuick.Effects

MultiEffect {
    property alias radius: roundedRect.radius

    // The mask has to be a layer for MultiEffect to sample it; hidden, it is
    // never drawn on its own.
    Rectangle {
        id: roundedRect
        visible: false
        layer.enabled: true
        anchors.fill: parent
        color: "black"
    }

    maskEnabled: true
    maskSource: roundedRect
    // MultiEffect's default mask is a hard cut at an alpha of 0.0001, which
    // loses the antialiased edge of the rounded rectangle. These two values
    // turn it into a smoothstep over the whole 0..1 alpha range, the closest
    // it gets to the straight alpha OpacityMask used.
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1.0
}
