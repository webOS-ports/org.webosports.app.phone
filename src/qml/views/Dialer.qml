import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Rectangle {
    id: pDialPage
    anchors.fill: parent
    color: main.appTheme.backgroundColor

    property alias numberEntryText: numentry.text

    /*TextField {
        id: phoneNumber
        y: 10
        height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("")
        font.pixelSize: 12


    }
    */

    Rectangle {
           id:bProviderSelect
           //text: main.providerLabel
           color: "#228B22"

           MouseArea {
               anchors.fill: parent
               onClicked: dProviderSelect.open();
           }
       }

    NumberEntry {
            id:numentry
            anchors {
                top:bProviderSelect.bottom
                bottom:numpad.top
                left:parent.left
                right:parent.right
            }
            color:'#ffffff'
   }

    NumPad {
         id:numpad
         width:main.width
         height:childrenRect.height
         anchors {bottom:rCallActions.top;margins:20}
         entryTarget:numentry
     }

    Row {
            id:rCallActions
            width:childrenRect.width;height:childrenRect.height
            anchors {bottom:parent.bottom;horizontalCenter:parent.horizontalCenter;margins:30}

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
