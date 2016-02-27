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

import QtQuick 2.5
import LunaNext.Common 0.1

Item {
    id: numPad

    property string mode: 'dial' // dial, sim

    signal sendKey(int keycode)

    property int keysWidth: (numPad.width / keys.columns) - Units.gu(2)
    property int keysHeight: (numPad.height / keys.rows) - Units.gu(2)

    Image {
        source: "images/dialpad-bg.png"
        anchors.fill: parent
        fillMode: Image.TileVertically
    }

    Grid {
        id: keys

        rows: 4
        columns: 3
        anchors.centerIn: parent

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'1'
            sublabel: 'voicemail'
            keycode: Qt.Key_1
            disableSubLabel: (mode === "sim")
            posInPadGrid: Qt.point(0,0)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'2'
            sublabel: 'ABC'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_2
            posInPadGrid: Qt.point(1,0)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'3'
            sublabel: 'DEF'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_3
            posInPadGrid: Qt.point(2,0)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'4'
            sublabel: 'GHI'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_4
            posInPadGrid: Qt.point(0,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'5'
            sublabel: 'JKL'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_5
            posInPadGrid: Qt.point(1,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'6'
            sublabel: 'MNO'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_6
            posInPadGrid: Qt.point(2,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'7'
            sublabel: 'PQRS'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_7
            posInPadGrid: Qt.point(0,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'8'
            sublabel: 'TUV'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_8
            posInPadGrid: Qt.point(1,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label:'9'
            sublabel: 'WXYZ'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_9
            posInPadGrid: Qt.point(2,1)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label: (mode === "sim") ? '' : '*'
            disableSubLabel: true
            keycode: Qt.Key_Asterisk
            posInPadGrid: Qt.point(0,2)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label: '0'
            sublabel: '+'
            disableSubLabel: (mode === "sim")
            keycode: Qt.Key_0
            longpresskeycode: Qt.Key_Plus
            posInPadGrid: Qt.point(1,2)
            onSendKey: numPad.sendKey(keycode)
        }

        NumPadButton {
            width: keysWidth
            height: keysHeight
            label: (mode === "sim") ? '' : '#'
            disableSubLabel: true
            keycode: Qt.Key_ssharp
            posInPadGrid: Qt.point(2,2)
            onSendKey: numPad.sendKey(keycode)
        }
    }
}
