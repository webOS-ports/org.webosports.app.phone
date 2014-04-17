import QtQuick 2.0
import QtQuick.Controls 1.1
import "../model"

Rectangle {
    anchors.fill: parent
    color: main.appTheme.backgroundColor

    ListView {
            id:historyList
            anchors {/*top:parent.bottom;bottom:parent.bottom;*/margins:5;horizontalCenter:parent.horizontalCenter}
            anchors.fill: parent
            spacing:4
            clip:true
            model: CallHistory {}

            delegate: Item {
                width:parent.width;height:72
                property Contact contact: Contact{}

                Component.onCompleted: contact = people.personByPhoneNumber(model.remoteUid);


                Row {
                    anchors {left:parent.left; leftMargin:10; verticalCenter:parent.verticalCenter}
                    spacing:10

                    Image {
                        anchors.verticalCenter:parent.verticalCenter
                        smooth:true
                        source: 'images/icon-m-telephony-call-' + (model.isMissedCall ? 'missed' : (model.direction === "inbound" ? 'received' : 'initiated')) + '.svg'
                    }

                    Column {
                        Text {
                            color:model.isMissedCall ? 'red' : 'white'
                            font.pixelSize:28
                            text:contact ? contact.displayLabel : model.remoteUid
                        }
                        Text {
                            color:'grey'
                            font.pixelSize:18
                            text:Qt.formatDateTime(model.startTime, Qt.DefaultLocaleShortDate)
                        }
                    }
                }

                Row {
                    anchors {right:parent.right; rightMargin:10; verticalCenter:parent.verticalCenter}
                    spacing:10
                    Button {
                        width:72;height:60
                        iconSource:'images/icon-m-telephony-accept.svg'
                        onClicked:main.dial(model.remoteUid);
                    }
                }
            }

            Rectangle {
                visible: historyList.count === 0
                Text {
                    color: "white"
                    font.pixelSize:28
                    text: "No calls yet"
                }
            }
        }


}

