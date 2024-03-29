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
import QtQuick.Controls 2.0
import LunaNext.Common 0.1

import LuneOS.Components 1.0

Button {
    id: buttonRoot

    property PhoneUiTheme appTheme: PhoneUiTheme{}

    checkable: true

    background: Rectangle{
        color: buttonRoot.checked ? appTheme.callActionBtnFgColorActive : appTheme.callActionBtnFgColor
        border.color:  'white'
        implicitWidth: buttonRoot.width
        implicitHeight: buttonRoot.height
        radius: buttonRoot.width*0.2

        ClippedImage {
            source: Qt.resolvedUrl('images/button-sprite.png')

            wantedWidth: buttonRoot.width
            wantedHeight: buttonRoot.height

            imageSize: Qt.size(183, 244)
            patchGridSize: Qt.size(3, 4)
            patch: buttonRoot.checked ? (buttonRoot.pressed ? Qt.point(0,3) : Qt.point(0,2) ) :
                                        (buttonRoot.pressed ? Qt.point(0,1) : Qt.point(0,0) )
        }
    }
}
