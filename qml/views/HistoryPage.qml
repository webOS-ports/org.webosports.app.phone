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
import QtQuick.Controls 1.1
import LunaNext.Common 0.1
import LuneOS.Components 1.0
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
        
            MouseArea {
                anchors.fill: parent
                onClicked:main.dial(model.remoteUid);
            }

            width:parent.width
            height:Units.gu(5)

            property Contact contact: Contact{}

            Component.onCompleted: contact = people.personByPhoneNumber(model.remoteUid);


            Row {
                anchors {left:parent.left; leftMargin:10; verticalCenter:parent.verticalCenter}
                spacing:10

                ClippedImage {
                    source: 'images/call-log-list-sprite.png'

                    anchors.verticalCenter: parent.verticalCenter

                    wantedWidth: 44
                    wantedHeight: 44

                    imageSize: Qt.size(44, 182)
                    patchGridSize: Qt.size(1, 4)
                    patch: model.isMissedCall ? Qt.point(0,0) : ((model.direction === "inbound") ? Qt.point(0,1) : Qt.point(0,2))
                }

                Column {
                    Text {
                        color:model.isMissedCall ? 'red' : 'white'
                        font.pixelSize:Units.dp(20)
                        text:contact ? contact.displayLabel : model.remoteUid
                    }
                    Text {
                        color:'grey'
                        font.pixelSize:Units.dp(10)
                        text:Qt.formatDateTime(model.startTime, Qt.DefaultLocaleShortDate)
                    }
                }
            }

            Row {
                anchors {
                    right:parent.right
                    rightMargin:10
                    verticalCenter:parent.verticalCenter
                }
                spacing:10
                Button {
                    width:Units.gu(5);height:Units.gu(5)
                    iconSource:'images/generic-details-view-avatar-small.png'
                }
            }
        }

        Rectangle {
            visible: historyList.count === 0
            Text {
                color: "white"
                font.pixelSize:Units.dp(20)
                text: "No calls yet"
            }
        }
    }


}

