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

    property alias number: numEntry.text

    function reset() {
        numEntry.text = "";
    }

    anchors.fill: parent
    color: main.appTheme.backgroundColor

    NumberEntry {
        id: numEntry

        anchors {
            top: pDialPage.top
            topMargin: Units.gu(5)
            left:parent.left
            right:parent.right
        }

        color:'#ffffff'
    }

    NumPad {
        id: numPad
        anchors {
            top: numEntry.bottom
            bottom: dialButton.top
            topMargin: Units.gu(2)
            horizontalCenter: parent.horizontalCenter
        }

        onKeyPressed: {
            numEntry.insert(label);
        }
    }

    DialButton {
        id: dialButton

        anchors {
            bottom: parent.bottom;
            horizontalCenter: parent.horizontalCenter;
            margins: Units.gu(2)
        }

        onClicked: {
            if(numEntry.text.length > 0) {
                main.dial(numEntry.getPhoneNumber());
            } else {
                console.log('Number entry is blank.');
            }
        }
    }
}
