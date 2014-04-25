import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

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
         width: main.appTheme.keypadWidth
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
            anchors {bottom: parent.bottom; horizontalCenter:parent.horizontalCenter;margins:30}

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
