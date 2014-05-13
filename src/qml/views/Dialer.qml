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
import QtQuick.Window 2.1
import LunaNext.Common 0.1

Rectangle {
    id: pDialPage
    anchors.fill: parent
    color: main.appTheme.backgroundColor

    property alias numberEntryText: numentry.text

    NumberEntry {
        id:numentry
        anchors {
            top: pDialPage.top
            topMargin: Units.gu(5)
            left:parent.left
            right:parent.right
        }
        color:'#ffffff'
    }

    NumPad {
        id:numpad
        //width:  Units.gu(50)
        //height:childrenRect.height
        anchors {
            bottom: bCallNumber.top
            topMargin: Units.gu(3)
            //margins: Units.gu(1)
            horizontalCenter:parent.horizontalCenter
        }
        entryTarget:numentry
    }

    DialButton {
        id:bCallNumber
        anchors {
            bottom: parent.bottom;
            horizontalCenter:parent.horizontalCenter;
            margins:Units.gu(2)
        }
        //width:numpad.width
        onClicked: {
            if(numentry.text.length > 0) {
                main.dial(numentry.text);
            } else {
                console.log('*** QML *** VCI WARNING: Number entry is blank.');
            }
        }
    }

}
