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
    id:numpad

    property string mode: 'dial' // dial | dtmf | sim
    property Item entryTarget

    property int fontPixelSize: Units.dp(43)
    property int keysWidth: Units.gu(11)
    property int keysHeight: Units.gu(8)

    width: keys.width
    height: keys.height


    signal keyPressed(int keycode, string label)

    Grid {
        id: keys

        rows: 4
        columns: 3
        spacing: Units.gu(1)

        anchors {
            horizontalCenter:parent.horizontalCenter
        }

        NumPadButton {key:'1';sub: (mode === "sim") ? '': 'voicemail'}
        NumPadButton {key:'2';sub:'ABC'}
        NumPadButton {key:'3';sub:'DEF'}
        NumPadButton {key:'4';sub:'GHI'}
        NumPadButton {key:'5';sub:'JKL'}
        NumPadButton {key:'6';sub:'MNO'}
        NumPadButton {key:'7';sub:'PQRS'}
        NumPadButton {key:'8';sub:'TUV'}
        NumPadButton {key:'9';sub:'WXYZ'}
        NumPadButton {key: (mode === "sim") ? '': '\u002A'; size: 40}
        NumPadButton {key:'0';sub: (mode === "sim") ? '': '+';alt: (mode === "sim") ? '': '+'}
        NumPadButton {key:(mode === "sim") ? '': '#';alt: (mode === "sim") ? '': 'p'}
    }

    Rectangle {
        anchors.fill:parent
        border {color:main.appTheme.foregroundColor;width:0.5}
        radius:10
        color:'#00000000'
    }

    // Audio feedback.
    function onPressed(key) {
        if(mode === 'dial' || mode === 'dtmf'){
            main.manager.startDtmfTone(key);
        }
    }

    function onReleased() {
        if(mode === 'dial' || mode === 'dtmf'){
            main.manager.stopDtmfTone();
        }
    }
}
