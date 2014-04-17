import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0

Rectangle {
    id: simPin
    width: appTheme.appWidth
    height: appTheme.appHeight
    color: main.appTheme.backgroundColor
    z: 10
    visible: false


    Rectangle {
        id: header
        width: appTheme.appWidth
        color: main.appTheme.headerColor
        radius: 2
        height: 100
        ColumnLayout{
            anchors.fill:parent
            anchors.margins: 8
            spacing: 16

            Text {
                id: label
                text: "Enter PIN to unlock SIM. 3 attempts remaining."
                font.pixelSize: 20
                color: main.appTheme.headerTip
                anchors.horizontalCenter:parent.horizontalCenter
            }

            RowLayout {
                height: parent.height
                anchors.left: parent.left
                anchors.right: parent.right

                Button {
                    text: "Cancel"
                    anchors.left: parent.left
                    anchors.leftMargin: 50
                    onClicked: simPin.visible = false
                }

                Text {
                    id: title
                    text: "SIM PIN"
                    font.pixelSize: 30
                    color: main.appTheme.headerTitle
                    anchors.horizontalCenter:parent.horizontalCenter
                }

                Button {
                    text: "Done"
                    anchors.right: parent.right
                    anchors.rightMargin: 50
                    onClicked: checkPin()

                    function checkPin(){
                        if(ofono.unlockPin("pin", pin.text)){
                            simPin.visible = false
                        }
                    }
                }


            }


        }

    }

    /*TextEdit {
        id:pin
        width:parent.width; height:90
        color:main.appTheme.foregroundColor
        anchors.top: header.bottom
        anchors.topMargin: 50
        horizontalAlignment:Text.Center


        onTextChanged: resizeText();

        Component.onCompleted: resizeText();

        function resizeText() {
            if(paintedWidth < 0 || paintedHeight < 0) return;
            while(paintedWidth > width)
                if(--font.pixelSize <= 0) break;

            while(paintedWidth < width)
                if(++font.pixelSize >= 38) break;
        }

        function insertChar(character) {

            if(text.length === 0) {
                text = character
            } else{
                text = text + character;
            }

        }
    }
    */

    NumberEntry {
        id:pin
        width:parent.width; height:90
        anchors.top: header.bottom
        anchors.topMargin: 50
        color:main.appTheme.foregroundColor

    }

    NumPad {
        id:keyboard
        anchors {
            horizontalCenter:parent.horizontalCenter
            top: pin.bottom
            bottom:parent.bottom
        }
        mode:'sim'
        entryTarget: pin
        width:parent.width - 50;height:childrenRect.height
        model: ListModel {
            ListElement {key:'1';sub:''}
            ListElement {key:'2';sub:'abc'}
            ListElement {key:'3';sub:'def'}
            ListElement {key:'4';sub:'ghi'}
            ListElement {key:'5';sub:'jkl'}
            ListElement {key:'6';sub:'mno'}
            ListElement {key:'7';sub:'pqrs'}
            ListElement {key:'8';sub:'tuv'}
            ListElement {key:'9';sub:'wxyz'}
            ListElement {key:''}
            ListElement {key:'0';sub:'';alt:''}
            ListElement {key:'';alt:''}
        }
    }


}
