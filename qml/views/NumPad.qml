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

    property UiTheme appTheme

    // dial: the full pad. sim: digits only. pin: the legacy PinDialpad, which
    // blanks the bottom left key and puts a backspace where # would be.
    property string mode: 'dial' // dial, sim, pin

    readonly property bool _digitsOnly: (mode === 'sim' || mode === 'pin')

    signal sendKey(int keycode)

    property int keysWidth: ((numPad.width-Units.gu(2)) / keys.columns)
    property int keysHeight: ((numPad.height-Units.gu(2)) / keys.rows)

    // In 'sim' mode the two outer keys of the bottom row are drawn blank so a
    // caller can put its own buttons there. The grid is centred rather than
    // filling the item, so expose where it starts: without this a caller can
    // only guess, and Cancel/Enter end up floating over the keys instead of
    // landing in the cells left free for them.
    property alias gridX: keys.x
    property alias gridY: keys.y

    Image {
        source: appTheme.image("dialpad-bg.png")
        anchors.fill: parent
        fillMode: Image.TileVertically
    }

    Grid {
        id: keys

        rows: 4
        columns: 3
        anchors.centerIn: parent

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'1'
            sublabel: 'voicemail'
            keycode: Qt.Key_1
            longpresskeycode: Qt.Key_LaunchMail
            disableSubLabel: numPad._digitsOnly
            posInPadGrid: Qt.point(0,0)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'2'
            sublabel: 'ABC'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_2
            posInPadGrid: Qt.point(1,0)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'3'
            sublabel: 'DEF'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_3
            posInPadGrid: Qt.point(2,0)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'4'
            sublabel: 'GHI'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_4
            posInPadGrid: Qt.point(0,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'5'
            sublabel: 'JKL'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_5
            posInPadGrid: Qt.point(1,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'6'
            sublabel: 'MNO'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_6
            posInPadGrid: Qt.point(2,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'7'
            sublabel: 'PQRS'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_7
            posInPadGrid: Qt.point(0,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'8'
            sublabel: 'TUV'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_8
            posInPadGrid: Qt.point(1,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label:'9'
            sublabel: 'WXYZ'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_9
            posInPadGrid: Qt.point(2,1)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label: numPad._digitsOnly ? '' : '*'
            disableSubLabel: true
            // A blank key still sent an asterisk, which landed in the PIN.
            enabled: !numPad._digitsOnly
            keycode: Qt.Key_Asterisk
            posInPadGrid: Qt.point(0,2)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label: '0'
            sublabel: '+'
            disableSubLabel: numPad._digitsOnly
            keycode: Qt.Key_0
            longpresskeycode: Qt.Key_Plus
            posInPadGrid: Qt.point(1,2)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }

        NumPadButton {
            appTheme: numPad.appTheme
            width: keysWidth
            height: keysHeight
            label: numPad._digitsOnly ? '' : '#'
            disableSubLabel: true
            enabled: numPad.mode !== 'sim'

            // The PIN pad spends this key on a backspace: a tap rubs out the
            // last digit, holding it clears the whole entry.
            icon: (numPad.mode === 'pin') ? numPad.appTheme.image("dialpad-backspace.png") : ""
            keycode: (numPad.mode === 'pin') ? Qt.Key_Backspace : Qt.Key_NumberSign
            longpresskeycode: (numPad.mode === 'pin') ? Qt.Key_Clear : keycode

            posInPadGrid: Qt.point(2,2)
            onSendKey: (keycode) => { numPad.sendKey(keycode) }
        }
    }
}
