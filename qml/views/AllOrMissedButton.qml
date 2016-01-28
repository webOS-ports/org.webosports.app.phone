/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import LunaNext.Common 0.1

Button {

    property PhoneUiTheme appTheme: PhoneUiTheme{}
    property bool isMissed: false

    checked:!isMissed
    checkable: true
    text: isMissed ? "Missed" : "All"

    style: ButtonStyle {
        background: Rectangle {
            radius: Units.gu(1)
            gradient: control.checked ? appTheme.selectedGradient : appTheme.unSelectedGradient
        }
        label: Text {
            text: control.text
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: historyModel.showOnlyMissed = isMissed;
}
