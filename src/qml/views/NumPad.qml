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
