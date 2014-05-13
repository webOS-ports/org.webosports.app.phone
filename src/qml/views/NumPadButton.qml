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
import LunaNext.Common 0.1

Item {
   id:root
   //width:numpad.cellWidth
   //height:numpad.cellHeight
   width: Units.gu(11)
   height: Units.gu(8)

   property string sub: ""
   property string key: ""
   property string alt: ""

        Text {
            id:tKeyText
            anchors.centerIn:parent
            color:main.appTheme.foregroundColor
            font.pixelSize:42
            text: key
        }

        Text {
            id:tSubText
            anchors {horizontalCenter:parent.horizontalCenter;top:tKeyText.bottom}
            color:main.appTheme.subForegroundColor
            font.pixelSize:18
            text: sub ? sub : ''
        }

        /*
          TODO: Key Border
        */
        Rectangle {
            anchors.fill:parent
            border {color:main.appTheme.foregroundColor;width:0.5}
            radius:10
            color:'#00000000'
        }


        MouseArea {
                anchors.fill:parent

                property bool waitingForDoubleClick: false

                Timer {
                    id:clickTimer
                    interval:520
                    running:false
                    repeat:false
                    onTriggered:parent.waitingForDoubleClick = false;
                }

                onClicked: {
                    if(waitingForDoubleClick && numpad.entryTarget.__previousCharacter === key && alt) {
                        numpad.entryTarget.backspace();
                        numpad.entryTarget.insertChar(alt);
                        waitingForDoubleClick = false;
                        clickTimer.stop();
                    } else {
                        numpad.entryTarget.insertChar(key);
                        waitingForDoubleClick = true;
                        clickTimer.start();
                    }
                }

                onPressAndHold: {
                    numpad.entryTarget.insertChar(alt || key);
                }

                // Audio feedback.
                onPressed: {
                    numpad.onPressed(key);
                }
                onReleased: {
                    numpad.onReleased();
                }
            }
}
