/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

BasePage {
    pageName: "History"

    property alias historyModel: historyList.model

    ListView {
        id:historyList
        anchors {/*top:parent.bottom;bottom:parent.bottom;*/margins:5;horizontalCenter:parent.horizontalCenter}
        anchors.fill: parent
        spacing:4
        clip:true

        delegate: Column {
            width:parent.width

            property var _callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
            property var contact: model.recentcall_address

            Item {
        
                width:parent.width
                height:Units.gu(5)

                // layout to rework

                Row {
                    id: callGroupDetails
                    anchors {left:parent.left; leftMargin:10; verticalCenter:parent.verticalCenter}
                    spacing:10

                    ClippedImage {
                        source: 'images/call-log-list-sprite.png'

                        anchors.verticalCenter: parent.verticalCenter

                        wantedWidth: 44
                        wantedHeight: 44

                        imageSize: Qt.size(44, 182)
                        patchGridSize: Qt.size(1, 4)
                        patch: (model.recentcall_type==="missed") ? Qt.point(0,0) : ((model.recentcall_type === "incoming") ? Qt.point(0,1) : Qt.point(0,2))
                    }

                    Column {
                        Text {
                            color:(model.recentcall_type==="missed") ? 'red' : 'white'
                            font.pixelSize:Units.dp(20)
                            text:(contact && contact.name) ? contact.name : model.recentcall_address.addr
                        }
                        Text {
                            property date timeStamp: new Date(model.timestamp);
                            color:'grey'
                            font.pixelSize:Units.dp(10)
                            text: timeStamp.toLocaleString();
                        }
                    }
                }
                MouseArea {
                    anchors.fill: callGroupDetails
                    onClicked: voiceCallManager.dial(model.recentcall_address.addr);
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

                        MouseArea {
                            anchors.fill: parent
                            onClicked:callgroupDetail.active = !callgroupDetail.active
                        }
                    }
                }
            }
            Loader {
                id: callgroupDetail
                width:parent.width
                active: false
                visible: active
                sourceComponent: Component {
                    Column {
                        Repeater {
                        model: CallGroupItems { callGroupId: _callGroupId }
                        delegate: Item {

                            property date _timestamp: new Date(timestamp)
                            property string _type: type
                            property var _fromAddr: from.addr
                            property var _toAddr: to.get ? to.get(0).addr : to[0].addr

                              width:parent.width
                              height: Units.dp(12)
                              Text {
                                  anchors.left: parent.left
                                  font.pixelSize:Units.dp(10)
                                  color:'grey'
                                  text: (_type !== "outgoing" ? _fromAddr : _toAddr )
                              }
                              Text {
                                  anchors.right: parent.right
                                  font.pixelSize:Units.dp(10)
                                  color:'grey'
                                  text: _timestamp.toLocaleTimeString()
                              }
                            }
                        }
                    }
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

