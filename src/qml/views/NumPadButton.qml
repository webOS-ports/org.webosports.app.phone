import QtQuick 2.0

Item {
   id:root
   width:numpad.cellWidth
   height:numpad.cellHeight

        Text {
            id:tKeyText
            anchors.centerIn:parent
            color:main.appTheme.foregroundColor
            font.pixelSize:42
            text:model.key
        }

        Text {
            id:tSubText
            anchors {horizontalCenter:parent.horizontalCenter;top:tKeyText.bottom}
            color:main.appTheme.subForegroundColor
            font.pixelSize:18
            text:model.sub ? model.sub : ''
        }

        /*
          TODO: Key Border

        Rectangle {
            anchors.fill:parent
            border {color:main.appTheme.foregroundColor;width:0.5}
            radius:10
            color:'#00000000'
        }
        */

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
                    if(waitingForDoubleClick && numpad.entryTarget.__previousCharacter === model.key && model.alt) {
                        numpad.entryTarget.backspace();
                        numpad.entryTarget.insertChar(model.alt);
                        waitingForDoubleClick = false;
                        clickTimer.stop();
                    } else {
                        numpad.entryTarget.insertChar(model.key);
                        waitingForDoubleClick = true;
                        clickTimer.start();
                    }
                }

                onPressAndHold: {
                    numpad.entryTarget.insertChar(model.alt || model.key);
                }

                // Audio feedback.
                onPressed: {
                    numpad.onPressed(model.key);
                }
                onReleased: {
                    numpad.onReleased();
                }
            }
}
