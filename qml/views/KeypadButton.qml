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

Button {
    id: buttonRoot

    width: Units.gu(5)
    height:Units.gu(5)

    checkable: true

    property PhoneUiTheme appTheme: PhoneUiTheme{}

    background: Rectangle{
        color: buttonRoot.checked ? appTheme.callActionBtnFgColorActive : appTheme.callActionBtnFgColor
        border.color:  'white'
        implicitWidth: Units.gu(5)
        implicitHeight: Units.gu(5)
        radius: 10

        Item {
            clip: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 48
            Image{
                x: 0
                y: buttonRoot.pressed ? -48: 0
                source: "images/menu-icon-dtmfpad.png"
            }
        }
    }
}
