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
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import LuneOS.Components 1.0

Button {
    width:210
    height:210

    style: ButtonStyle {
        background: ClippedImage {
            source: "images/button-ignore-answer.png"

            wantedHeight: control.height
            wantedWidth: control.width

            imageSize: Qt.size(420, 420)
            patchGridSize: Qt.size(2, 2)
            patch: control.pressed ? Qt.point(1,1): Qt.point(1,0)
        }
    }
}
