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

        section.property: "timestamp_day"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            width: parent.width
            height: childrenRect.height
            Rectangle {
                width: Units.gu(1) //parent.width
                color: '#25394A'
                height: sectionTextId.height/5
                anchors.left: parent.left
                anchors.verticalCenter: sectionTextId.verticalCenter
            }
            Text {
                id: sectionTextId
                x: Units.gu(2)
                color: "lightgrey"
                font.bold: true
                font.pixelSize: FontUtils.sizeToPixels("18pt")
                property date _timestamp: new Date(Number(section)*86400000) //  convert timestamp_day to ms
                text: _timestamp.toLocaleDateString()
            }
            Rectangle {
                width: parent.width - sectionTextId.contentWidth - Units.gu(3) //Units.gu(1) //parent.width
                color: '#25394A'
                height: sectionTextId.height/5
                anchors.right: parent.right
                anchors.verticalCenter: sectionTextId.verticalCenter
            }

        }

        delegate: Column {
            width:parent.width

            property var _callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
            property var contact: model.recentcall_address

            // Description of the call group
            RowLayout {
                id: callGroupRowLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Units.gu(1)
                anchors.rightMargin: Units.gu(1)
                height:Units.gu(7)
                spacing: 5
                // On the left: details of the person
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        Layout.fillWidth: true
                        color: 'white'
                        font.pixelSize: FontUtils.sizeToPixels("18pt")
                        text:(contact && contact.name) ? contact.name : model.recentcall_address.addr
                    }
                    Text {
                        Layout.fillWidth: true
                        color: 'white'
                        font.pixelSize: FontUtils.sizeToPixels("14pt")
                        text:(contact && contact.addr) ? contact.addr : "Unknown"
                    }
                }
                // On the middle: type of call and time of call
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.minimumWidth: Units.gu(3.2)
                    ClippedImage {
                        Layout.preferredHeight: Units.gu(3.2)

                        source: 'images/call-log-list-sprite.png'

                        wantedWidth: Units.gu(3.2)
                        wantedHeight: Units.gu(3.2)

                        imageSize: Qt.size(44, 182)
                        patchGridSize: Qt.size(1, 4)
                        patch: (model.recentcall_type==="missed") ? Qt.point(0,0) :
                               (model.recentcall_type === "incoming") ? Qt.point(0,1) :
                               (model.recentcall_type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
                        anchors.horizontalCenter: timeStampText.horizontalCenter
                    }
                    Text {
                        id: timeStampText
                        Layout.fillHeight: true

                        property date timeStamp: new Date(model.timestamp);

                        color:'white'
                        font.pixelSize: FontUtils.sizeToPixels("15pt")
                        text: Qt.formatTime(timeStamp, Qt.locale().timeFormat(Locale.ShortFormat));
                    }
                }
                // On the right: image of person with eventual mask with number of calls,
                // and arrow to show details

                Item {
                    id: avatarDisclosureItem
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: callGroupRowLayout.height

                    property url personPhotoUrl: (model.recentcall_address && model.recentcall_address.personId) ?
                                                     contacts.personById(model.recentcall_address.personId).photos.listPhotoPath :
                                                     Qt.resolvedUrl('images/generic-details-view-avatar.png');

                    Image {
                        id: avatarPhotoImage
                        anchors {
                            top: avatarDisclosureMask.top
                            topMargin: 5*avatarDisclosureMask.height/90
                            left: avatarDisclosureMask.left
                            leftMargin: 6*avatarDisclosureMask.width/108
                        }
                        width: 60*avatarDisclosureMask.height/90
                        height: 75*avatarDisclosureMask.height/90
                        source: avatarDisclosureItem.personPhotoUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }
                    CornerShader {
                        id: cornerShader
                        anchors.fill: avatarPhotoImage
                        sourceItem: avatarPhotoImage
                        radius: 5*avatarDisclosureMask.height/90
                    }

                    ClippedImage {
                        id: avatarDisclosureMask
                        source: 'images/avatar-disclosure.png'

                        anchors.fill: parent

                        wantedWidth: avatarDisclosureItem.width
                        wantedHeight: avatarDisclosureItem.height

                        imageSize: Qt.size(108, 360)
                        patchGridSize: Qt.size(1, 4)
                        patch: callgroupDetail.active ? (avatarDisclosureMouseArea.pressed ? Qt.point(0,3) : Qt.point(0,2) ) :
                                                        (avatarDisclosureMouseArea.pressed ? Qt.point(0,1) : Qt.point(0,0) )
                    }
                    Image {
                        source: 'images/call-log-count-pill.png'
                        anchors {
                            top: avatarDisclosureMask.top
                            topMargin: -Units.gu(0.5)
                            left: avatarDisclosureMask.left
                            leftMargin: -Units.gu(0.5)
                        }
                        width: Units.gu(3.2)
                        height: Units.gu(3.2)

                        Text {
                            anchors.centerIn: parent
                            text: model.callcount
                            color: 'white'
                            font.pixelSize: FontUtils.sizeToPixels("12pt")
                            anchors.verticalCenterOffset: -Units.gu(0.2)
                        }
                    }

                    MouseArea {
                        id: avatarDisclosureMouseArea
                        anchors.fill: parent
                        onClicked: callgroupDetail.active = !callgroupDetail.active
                    }
                }
            }
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                property bool _isLastGroupOfDay: (index+1)<historyModel.count && historyModel.get(index+1).timestamp_day !== model.timestamp_day
                height: callgroupDetail.visible ? callgroupDetail.height : _isLastGroupOfDay ? 0 : 1
                color: '#25394A'

                Loader {
                    id: callgroupDetail
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: Units.gu(1)
                        rightMargin: Units.gu(3)
                    }
                    active: false
                    visible: active
                    sourceComponent: Component {
                      Column {
                          Repeater {
                            id: modelRepeater
                            width:parent.width
                            model: CallGroupItems { callGroupId: _callGroupId }
                            delegate: RowLayout {
                                id: callphoneDelegate
                                spacing: Units.gu(0.5)

                                // NUMBER_TYPE number (duration) icon time

                                property date _timestamp: new Date(model.timestamp)
                                property var _remotePerson: (model.type !== "outgoing") ? model.from : (Array.isArray(model.to) ? model.to[0] : model.to.get(0))
                                property string _duration: secondsToTimeString(duration/1000)

                                function secondsToTimeString(seconds) {
                                    if(seconds===0) return '';

                                    var h = Math.floor(seconds / 3600);
                                    var m = Math.floor((seconds - (h * 3600)) / 60);
                                    var s = Math.round(seconds - h * 3600 - m * 60);

                                    var result = '(';
                                    if(h>0) result += h + 'h';
                                    if(m>0) result += m + 'm';
                                    if(s>0) result += s + 's';
                                    result += ')';

                                    return result;
                                }

                                width:modelRepeater.width
                                height: Units.gu(3.2)
                                Text {
                                    font.pixelSize: FontUtils.sizeToPixels("12pt")
                                    color:'white'
                                    text: _remotePerson.personAddressType ? _addressTypeMap[_remotePerson.personAddressType]: "";

                                    property var _addressTypeMap: { "type_mobile": "MOBILE",
                                                                    "type_work": "WORK" };
                                }
                                Text {
                                    font.pixelSize: FontUtils.sizeToPixels("12pt")
                                    color:'grey'
                                    text: _remotePerson.addr
                                }
                                Text {
                                    Layout.fillWidth: true
                                    font.pixelSize: FontUtils.sizeToPixels("12pt")
                                    color:'grey'
                                    text: _duration;
                                }
                                ClippedImage {
                                    Layout.preferredHeight: callphoneDelegate.height
                                    Layout.preferredWidth: callphoneDelegate.height

                                    source: 'images/call-log-list-sprite.png'

                                    wantedWidth: callphoneDelegate.height
                                    wantedHeight: callphoneDelegate.height

                                    imageSize: Qt.size(44, 182)
                                    patchGridSize: Qt.size(1, 4)
                                    patch: (model.type==="missed") ? Qt.point(0,0) :
                                           (model.type === "incoming") ? Qt.point(0,1) :
                                           (model.type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
                                }
                                Text {
                                    font.pixelSize: FontUtils.sizeToPixels("12pt")
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
                font.pixelSize: FontUtils.sizeToPixels("20pt")
                text: "No calls yet"
            }
        }
    }
}

