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

Rectangle {
    id: pDialPage
    anchors.fill: parent
    color: main.appTheme.backgroundColor

    property alias numberEntryText: numentry.text

    NumberEntry {
            id:numentry
            anchors {
                top: pDialPage.top
                topMargin: 70
                left:parent.left
                right:parent.right
            }
            color:'#ffffff'
   }

    NumPad {
         id:numpad
         width: (main.height -300) * 1.25
         height:childrenRect.height
         anchors {
             top: numentry.bottom
             margins:20
             horizontalCenter:parent.horizontalCenter
         }
         entryTarget:numentry
     }

    Row {
            id:rCallActions
            width:childrenRect.width
            height:childrenRect.height
            anchors {
                bottom: parent.bottom;
                horizontalCenter:parent.horizontalCenter;
                margins:30
            }

            AcceptButton {
                id:bCallNumber
                width:numpad.width * 0.66
                onClicked: {
                    if(numentry.text.length > 0) {
                        main.dial(numentry.text);
                    } else {
                        console.log('*** QML *** VCI WARNING: Number entry is blank.');
                    }
                }
            }
        }

}
