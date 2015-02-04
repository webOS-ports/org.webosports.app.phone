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
    id: numPad

    property string mode: 'dial' // dial | dtmf | sim

    signal keyPressed(int keycode, string label)
    signal keyPressAndHold(int keycode, string label)

    property int keysWidth: Units.gu(11)
    property int keysHeight: Units.gu(8)

    Grid {
        id: keys

        rows: 4
        columns: 3
        columnSpacing: Units.gu(2.0)
        rowSpacing: Units.gu(0.5)
        anchors.centerIn: parent

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'1'
            sublabel: (mode === "sim") ? '': 'voicemail'
            keycode: Qt.Key_1
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'2'
            sublabel: 'ABC'
            keycode: Qt.Key_2
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'3'
            sublabel: 'DEF'
            keycode: Qt.Key_3
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'4'
            sublabel: 'GHI'
            keycode: Qt.Key_4
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'5'
            sublabel: 'JKL'
            keycode: Qt.Key_5
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'6'
            sublabel: 'MNO'
            keycode: Qt.Key_6
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'7'
            sublabel: 'PQRS'
            keycode: Qt.Key_7
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'8'
            sublabel: 'TUV'
            keycode: Qt.Key_8
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'9'
            sublabel: 'WXYZ'
            keycode: Qt.Key_9
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'*'
            keycode: Qt.Key_Asterisk
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label: '0'
            sublabel: '+'
            keycode: Qt.Key_0
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label: '#'
            keycode: Qt.Key_ssharp
            onKeyPressed: numPad.keyPressed(keycode, label)
            onKeyPressAndHold: numPad.keyPressAndHold(keycode, label)
        }
    }
}
