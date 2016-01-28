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
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.2
import LunaNext.Common 0.1
import LuneOS.Components 1.0
import "../model"

BasePage {
    pageName: "History"

    property alias historyModel: historyList.model

    // All / Missed button chooser
    Row {
        id: allOrMissedRect
        anchors {
            top:parent.top
            horizontalCenter: parent.horizontalCenter
        }
        height: Units.gu(3)
        spacing: Units.gu(3)

        ExclusiveGroup { id: allOrMissedGroup }
        AllOrMissedButton {
            isMissed: false
            height: parent.height
            width: Units.gu(14)
            exclusiveGroup: allOrMissedGroup
        }
        AllOrMissedButton {
            isMissed: true
            height: parent.height
            width: Units.gu(14)
            exclusiveGroup: allOrMissedGroup
        }
    }

    ListView {
        id:historyList
        anchors {
            top:allOrMissedRect.bottom
            bottom:parent.bottom
            left: parent.left
            right: parent.right
        }
        spacing:4
        clip:true

        section.property: "date"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            width: parent.width
            height: childrenRect.height
            Rectangle {
                width: parent.width
                color: '#25394A'
                height: sectionText.height/5
                anchors.verticalCenter: sectionText.verticalCenter
            }
            Text {
                id: sectionText
                x: Units.gu(2)
                color: "lightgrey"
                font.bold: true
                font.pixelSize: Units.gu(1)
                text: section
            }
        }

        delegate: Column {
            width:parent.width

            property var _callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
            property var contact: model.recentcall_address

            // Description of the call group
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Units.gu(1)
                anchors.rightMargin: Units.gu(1)
                height:Units.gu(5)
                spacing: 5
                // On the left: details of the person
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        Layout.fillWidth: true
                        color:(model.recentcall_type==="missed") ? 'red' : 'white'
                        font.pixelSize:Units.gu(2)
                        text:(contact && contact.name) ? contact.name : model.recentcall_address.addr
                    }
                    Text {
                        Layout.fillWidth: true
                        color:(model.recentcall_type==="missed") ? 'red' : 'white'
                        font.pixelSize:Units.gu(2)
                        text:(contact && contact.addr) ? contact.addr : "Unknown"
                    }
                }
                // On the middle: type of call and time of call
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.minimumWidth: 44
                    ClippedImage {
                        Layout.preferredHeight: 44

                        source: 'images/call-log-list-sprite.png'

                        wantedWidth: 44
                        wantedHeight: 44

                        imageSize: Qt.size(44, 182)
                        patchGridSize: Qt.size(1, 4)
                        patch: (model.recentcall_type==="missed") ? Qt.point(0,0) : ((model.recentcall_type === "incoming") ? Qt.point(0,1) : Qt.point(0,2))
                    }
                    Text {
                        Layout.fillHeight: true

                        property date timeStamp: new Date(model.timestamp);

                        color:'white'
                        font.pixelSize:Units.gu(1.5)
                        text: Qt.formatTime(timeStamp, Qt.locale().timeFormat(Locale.ShortFormat));
                    }
                }
                // On the right: image of person with eventual mask with number of calls,
                // and arrow to show details
                Button {
                    Layout.fillHeight: true
                    Layout.minimumWidth: height
                    width:Units.gu(5);height:Units.gu(5)
                    iconSource:'images/generic-details-view-avatar-small.png'

                    checkable: true
                    onClicked: callgroupDetail.active = checked
                }
            }
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Units.gu(2)
                    rightMargin: Units.gu(2)
                }
                height: callgroupDetail.visible ? callgroupDetail.height : 1
                color: '#25394A'

                Loader {
                    id: callgroupDetail
                    width:parent.width
                    active: false
                    visible: active
                    sourceComponent: Component {
                      Column {
                          Repeater {
                            id: modelRepeater
                            width:parent.width
                            model: CallGroupItems { callGroupId: _callGroupId }
                            delegate: Item {

                                property date _timestamp: new Date(timestamp)
                                property string _type: type
                                property var _fromAddr: from.addr
                                property var _toAddr: to.get ? to.get(0).addr : to[0].addr

                                  width:modelRepeater.width
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
                                      text: Qt.formatTime(_timestamp, Qt.locale().timeFormat(Locale.ShortFormat));
                                  }
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

