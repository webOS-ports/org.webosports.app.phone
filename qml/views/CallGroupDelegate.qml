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
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * One call group in the call log.
 *
 * Laid out like com.palm.app.phone: the contact's photo on the left, their
 * name with the number of calls and a star if they are a favourite, the
 * service and number underneath, then the type of call, the time, and a button
 * that opens the individual calls.
 *
 * The artwork is the original's: call-log-list-light-sprite for the call type,
 * call-log-count-pill for the count, expand-button for the disclosure.
 */
Column {
    id: callGroupDelegate

    property var historyModel;
    property ContactsModel contacts;
    property var dialHandler;
    property var callTransports;
    property PhoneUiTheme appTheme: PhoneUiTheme {}

    /// True for the last group of its day, so the row above a day header does
    /// not also draw a divider.
    property bool lastOfDay: false

    property string callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
    property var contactAddress: model.recentcall_address
    property var remotePerson: (contactAddress && contactAddress.personId) ? contacts.personById(contactAddress.personId) : null

    /// Which account the calls in this group went over; cellular is unlabelled.
    readonly property string callService: (contactAddress && contactAddress.service)
                                              ? contactAddress.service : ""
    readonly property bool isSynergyCall: callService.length > 0 &&
                                          callService !== "com.palm.telephony"

    readonly property string serviceLabel: {
        if (!isSynergyCall || !callTransports) return "";
        return callTransports.labelFor(callService).toUpperCase();
    }

    readonly property string numberForDisplay:
        LibPhoneNumber.formatPhoneNumberForDisplay(contactAddress.addr, contacts.countryCode)

    /// True while the row is swiped aside to show its delete button.
    property bool pendingDelete: false

    // Swipe-to-delete, as on the legacy call log's SwipeableItem rows.
    Item {
        id: swipeRow

        width: parent.width
        height: Units.gu(7)

        Rectangle {
            anchors.fill: parent
            color: appTheme.deleteColor
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

            Rectangle {
                anchors.fill: parent
                color: rowArea.pressed ? appTheme.listSelectedColor : 'transparent'
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Units.gu(0.8)
                anchors.rightMargin: Units.gu(0.8)
                spacing: Units.gu(1)

                // The contact's photo, on the left as on the original.
                Item {
                    Layout.preferredWidth: Units.gu(4.4)
                    Layout.preferredHeight: Units.gu(4.4)

                    Image {
                        id: avatarPhotoImage
                        anchors.fill: parent
                        source: callGroupDelegate.remotePerson
                                    ? callGroupDelegate.remotePerson.photos.listPhotoPath
                                    : Qt.resolvedUrl('images/list-avatar-default.png')
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    CornerShader {
                        anchors.fill: avatarPhotoImage
                        source: avatarPhotoImage
                        radius: Units.gu(0.4)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Units.gu(0.2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Units.gu(0.6)

                        Text {
                            Layout.maximumWidth: parent.width * 0.7
                            color: appTheme.listTextColor
                            elide: Text.ElideRight
                            font.pixelSize: FontUtils.sizeToPixels("medium")
                            text: (callGroupDelegate.remotePerson && contactAddress.name)
                                      ? contactAddress.name
                                      : callGroupDelegate.numberForDisplay
                        }

                        // How many calls this group stands for.
                        Item {
                            Layout.preferredWidth: Units.gu(2.4)
                            Layout.preferredHeight: Units.gu(2.4)
                            visible: model.callcount > 1

                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl('images/call-log-count-pill.png')
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                anchors.centerIn: parent
                                color: 'white'
                                font.pixelSize: FontUtils.sizeToPixels("x-small")
                                text: model.callcount
                            }
                        }

                        Image {
                            Layout.preferredWidth: Units.gu(1.6)
                            Layout.preferredHeight: Units.gu(1.6)
                            fillMode: Image.PreserveAspectFit
                            source: Qt.resolvedUrl('images/favorites-star-blue.png')
                            visible: !!callGroupDelegate.remotePerson &&
                                     callGroupDelegate.remotePerson.favorite === true
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // "WHATSAPP +31 6 1342 2104": the service, then the number.
                    Text {
                        Layout.fillWidth: true
                        color: appTheme.listSecondaryTextColor
                        elide: Text.ElideRight
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: (callGroupDelegate.serviceLabel.length > 0
                                   ? callGroupDelegate.serviceLabel + " " : "") +
                              callGroupDelegate.numberForDisplay
                    }
                }

                // What kind of call it was, from the original's list sprite.
                ClippedImage {
                    Layout.preferredWidth: Units.gu(2.2)
                    Layout.preferredHeight: Units.gu(2.2)

                    source: Qt.resolvedUrl('images/call-log-list-light-sprite.png')
                    wantedWidth: Units.gu(2.2)
                    wantedHeight: Units.gu(2.2)
                    imageSize: Qt.size(22, 91)
                    patchGridSize: Qt.size(1, 4)
                    patch: (model.recentcall_type === "missed") ? Qt.point(0,0) :
                           (model.recentcall_type === "incoming") ? Qt.point(0,1) :
                           (model.recentcall_type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
                }

                Text {
                    Layout.preferredWidth: Units.gu(5)
                    horizontalAlignment: Text.AlignRight
                    color: appTheme.listSecondaryTextColor
                    font.pixelSize: FontUtils.sizeToPixels("small")

                    property date timeStamp: new Date(model.timestamp)
                    text: Qt.formatTime(timeStamp, Qt.locale().timeFormat(Locale.ShortFormat))
                }

                // Opens the individual calls in this group.
                Item {
                    Layout.preferredWidth: Units.gu(3.4)
                    Layout.preferredHeight: Units.gu(3.4)

                    ClippedImage {
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl('images/expand-button.png')
                        wantedWidth: Units.gu(3.4)
                        wantedHeight: Units.gu(3.4)
                        imageSize: Qt.size(50, 100)
                        patchGridSize: Qt.size(1, 2)
                        patch: expandArea.pressed ? Qt.point(0,1) : Qt.point(0,0)
                        rotation: callgroupDetail.active ? 180 : 0
                    }

                    MouseArea {
                        id: expandArea
                        anchors.fill: parent
                        onClicked: callgroupDetail.active = !callgroupDetail.active
                    }
                }
            }

            // Tapping the row calls back over whichever account it used;
            // dragging it sideways reveals the delete button.
            MouseArea {
                id: rowArea
                anchors.fill: parent
                z: -1

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
                        callGroupDelegate.dialHandler.dial(callGroupDelegate.contactAddress.addr,
                                                           callGroupDelegate.isSynergyCall ? callGroupDelegate.callService : "",
                                                           false);
                    }
                }
            }
        }
    }

    // No divider before a day header: the header brings its own rule.
    Rectangle {
        width: parent.width
        height: callGroupDelegate.lastOfDay ? 0 : 1
        color: appTheme.listDividerColor
    }

    Loader {
        id: callgroupDetail

        width: parent.width
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
