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

GridView {
    id:numpad

    property string mode: 'dial' // dial | dtmf | sim
    property Item entryTarget

    cellWidth:width / 3
    cellHeight: cellWidth * 0.6

    interactive:false

    model: ListModel {
        ListElement {key:'1';sub:'voicemail'}
        ListElement {key:'2';sub:'abc'}
        ListElement {key:'3';sub:'def'}
        ListElement {key:'4';sub:'ghi'}
        ListElement {key:'5';sub:'jkl'}
        ListElement {key:'6';sub:'mno'}
        ListElement {key:'7';sub:'pqrs'}
        ListElement {key:'8';sub:'tuv'}
        ListElement {key:'9';sub:'wxyz'}
        ListElement {key:'*'}
        ListElement {key:'0';sub:'+';alt:'+'}
        ListElement {key:'#';alt:'p'}
    }

    delegate: NumPadButton {}

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
