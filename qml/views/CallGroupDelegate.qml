/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 WebOS Ports
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
import QtQuick.Layouts 1.2
import QtQml

import LunaNext.Common 0.1
import LuneOS.Components 1.0
import LuneOS.Telephony 1.0

import "../model"

Column {
    id: callGroupDelegate

    property var historyModel;
    property ContactsModel contacts;
    property var dialHandler;
    property var callTransports;
    property PhoneUiTheme appTheme: PhoneUiTheme {}

    // Which calling account this group's calls went over. Cellular is the
    // default and stays unlabelled; a Synergy call says which service it used.
    property string callService: (contactAddress && contactAddress.service) ? contactAddress.service : ""
    property bool isSynergyCall: callService.length > 0 && callService !== "com.palm.telephony"

    property string callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
    property var contactAddress: model.recentcall_address
    property var remotePerson: (contactAddress && contactAddress.personId) ? contacts.personById(contactAddress.personId) : null

    property string _callGroupPhoneNumberForDisplay: LibPhoneNumber.formatPhoneNumberForDisplay(contactAddress.addr, contacts.countryCode);

    /// True while the row is swiped aside to show its delete button.
    property bool pendingDelete: false

    // Swipe-to-delete, as on the legacy call log's SwipeableItem rows: the row
    // slides left to uncover a delete button rather than deleting straight away.
    Item {
        id: swipeRow

        width: parent.width
        height: Units.gu(7)

        Rectangle {
            anchors.fill: parent
            color: '#8B2020'
            visible: callGroupDelegate.pendingDelete

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Units.gu(3)
                color: 'white'
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: qsTr("Delete")
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    callGroupDelegate.pendingDelete = false;
                    historyModel.deleteCallGroup(callGroupDelegate.callGroupId);
                }
            }
        }

        Item {
            id: swipeContainer

            width: parent.width
            height: parent.height
            x: callGroupDelegate.pendingDelete ? -Units.gu(10) : 0

            Behavior on x { NumberAnimation { duration: 150 } }

            // Tapping the description calls the number back and dragging it
            // sideways reveals the delete button. It sits outside the layout so
            // the layout does not try to manage it as a cell.
            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: callGroupRowLayout.height * 2
                z: 1

                property real _pressX: 0

                onPressed: (mouse) => { _pressX = mouse.x; }
                onReleased: (mouse) => {
                    var delta = mouse.x - _pressX;

                    if (delta < -Units.gu(4)) {
                        callGroupDelegate.pendingDelete = true;
                    } else if (delta > Units.gu(4)) {
                        callGroupDelegate.pendingDelete = false;
                    } else if (!callGroupDelegate.pendingDelete &&
                               callGroupDelegate.dialHandler && callGroupDelegate.contactAddress.addr) {
                        // Call back over whichever account the call used.
                        callGroupDelegate.dialHandler.dial(callGroupDelegate.contactAddress.addr,
                                                           callGroupDelegate.isSynergyCall ? callGroupDelegate.callService : "",
                                                           false);
                    }
                }
            }

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
                    id: descriptionColumn

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        Layout.fillWidth: true
                        color: 'white'
                        font.pixelSize: FontUtils.sizeToPixels("18pt")
                        text:(remotePerson) ? contactAddress.name : _callGroupPhoneNumberForDisplay
                    }
                    Text {
                        id: detailTextId
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: 'white'
                        font.pixelSize: FontUtils.sizeToPixels("14pt")

                        // A Synergy call names its service rather than trying to
                        // geolocate an address that is not a phone number.
                        readonly property string _servicePrefix:
                            callGroupDelegate.isSynergyCall && callGroupDelegate.callTransports
                                ? (callGroupDelegate.callTransports.labelFor(callGroupDelegate.callService) + " · ")
                                : ""

                        text: _servicePrefix +
                              ((remotePerson) ? _callGroupPhoneNumberForDisplay : "Unknown") // (needs geolocalization of number)

                        Component.onCompleted: {
                            if(!remotePerson && !callGroupDelegate.isSynergyCall) {
                                LibPhoneNumber.getNumberGeolocation(contactAddress.addr, contacts.countryCode, setTextFromGeoLocation);
                            }
                        }

                        function setTextFromGeoLocation(geoLocation) {
                            var location = geoLocation.location || "Unknown";
                            var country = geoLocation.country || {};
                            var countryShortName = country.sn || "Unknown Country";
                            detailTextId.text = location + ", " + countryShortName;
                        }
                    }

                }
                // On the middle: type of call and time of call
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.minimumWidth: Units.gu(3.2)
                    ClippedImage {
                        Layout.preferredHeight: Units.gu(3.2)
                        Layout.alignment: Qt.AlignHCenter

                        source: Qt.resolvedUrl('images/call-log-list-sprite.png')

                        wantedWidth: Units.gu(3.2)
                        wantedHeight: Units.gu(3.2)

                        imageSize: Qt.size(44, 182)
                        patchGridSize: Qt.size(1, 4)
                        patch: (model.recentcall_type==="missed") ? Qt.point(0,0) :
                               (model.recentcall_type === "incoming") ? Qt.point(0,1) :
                               (model.recentcall_type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
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

                    property url personPhotoUrl: callGroupDelegate.remotePerson ?
                                                     callGroupDelegate.remotePerson.photos.listPhotoPath :
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
                        source: avatarPhotoImage
                        radius: 5*avatarDisclosureMask.height/90
                    }
                    ClippedImage {
                        id: avatarDisclosureMask
                        source: Qt.resolvedUrl('images/avatar-disclosure.png')

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
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
        }
        property bool _isLastGroupOfDay: (index+1)<historyModel.count && historyModel.get(index+1).timestamp_day !== model.timestamp_day
        height: callgroupDetail.visible ? callgroupDetail.height : _isLastGroupOfDay ? 0 : 1
        color: appTheme.listDividerColor

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
                            CallGroupDetails {
                                callGroupId: callGroupDelegate.callGroupId
                                callGroupRemotePerson: callGroupDelegate.remotePerson
                                callGroupAddress: callGroupDelegate.contactAddress
                                contacts: callGroupDelegate.contacts
                                dialHandler: callGroupDelegate.dialHandler
                                callTransports: callGroupDelegate.callTransports
                            }
                         }
        }
    }
}
