/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import LunaNext.Common 0.1
import LuneOS.System 1.0

import "../model"

/**
 * The incoming call as legacy webOS put it up while the phone app was not in
 * front: a strip, not a page. phonePopups' IncomingCall laid it out as one
 * row - answer, the caller in the middle, ignore - and so does this, the
 * photo over the caller box when the contact has one.
 *
 * The handset draws it as 2.2.4 did, the tablet as 3.0.5 did; the differences
 * are all in the theme (see UiTheme's incomingAlert properties). The strip asks
 * for the height CallSynergizer opened the popup at, which depends on whether
 * there is a photo.
 */
Item {
    id: root

    property UiTheme appTheme
    property Contact currentContact

    signal answerClicked()
    signal rejectClicked()

    readonly property bool hasPhoto: !!root.currentContact && root.currentContact.hasPhoto
    readonly property bool known: !!root.currentContact && root.currentContact.personId.length > 0

    // The theme comes from a loader in main.qml and is not there yet when
    // the alert window is built; until it is, every measure reads as nothing.
    function themed(name) { return root.appTheme ? root.appTheme[name] : 0; }

    implicitHeight: !root.appTheme ? Units.gu(11)
                  : root.hasPhoto ? root.appTheme.incomingAlertPhotoHeight
                                  : root.appTheme.incomingAlertHeight

    /*
     * 2.2.4's .incoming-call: black, and over it the gloss, stretched to the
     * strip's height with its 22 pixel rounded sides kept. Old WebKit's
     * -webkit-border-image filled the middle too, which is what puts the
     * sheen across the whole strip. With a photo the full-size frame takes
     * the gloss's place.
     */
    Rectangle {
        anchors.fill: parent
        visible: root.themed("incomingAlertGloss")
        color: "black"

        BorderImage {
            anchors.fill: parent
            source: !root.themed("incomingAlertGloss") ? ""
                  : root.appTheme.image(root.hasPhoto ? "incoming-call-frame-full-size.png"
                                                      : "incoming-notification-gradient.png")
            // 22 of the artwork's 45 or 320 pixels, at whatever scale the
            // theme's copy is.
            border.left: Math.round(sourceSize.width * 22 / (root.hasPhoto ? 320 : 45))
            border.right: border.left
            horizontalTileMode: BorderImage.Repeat
            verticalTileMode: BorderImage.Stretch
        }
    }

    IncomingAcceptButton {
        id: answerButton

        appTheme: root.appTheme
        width: Units.gu(7)
        height: Units.gu(7)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.hasPhoto ? root.themed("incomingAlertButtonDrop") : 0

        onClicked: root.answerClicked()
    }

    IncomingRejectButton {
        id: rejectButton

        appTheme: root.appTheme
        width: Units.gu(7)
        height: Units.gu(7)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: answerButton.anchors.verticalCenterOffset

        onClicked: root.rejectClicked()
    }

    Column {
        id: callerColumn

        anchors {
            left: answerButton.right
            right: rejectButton.left
            verticalCenter: parent.verticalCenter
        }

        // The contact's photo, square, centred over the box.
        Item {
            width: parent.width
            height: root.themed("incomingAlertPhotoSize")
            visible: root.hasPhoto

            Image {
                id: photo

                anchors.centerIn: parent
                width: root.themed("incomingAlertPhotoSize")
                height: width
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true
                source: root.hasPhoto ? root.currentContact.avatarPath : ""
                visible: root.themed("incomingAlertPhotoRadius") <= 0
            }
            CornerShader {
                anchors.fill: photo
                source: photo
                radius: root.themed("incomingAlertPhotoRadius")
                visible: root.themed("incomingAlertPhotoRadius") > 0
            }
        }

        /*
         * .incoming-text-container: who is calling, in a box 82 high with
         * twelve pixel rounded ends on the handset, bare on the tablet. Name,
         * number, and what the number is - or for a stranger, where it is
         * from. Tapping a known caller opens the contact, as it did on webOS.
         */
        BorderImage {
            id: callerBox

            width: parent.width
            height: Units.gu(8.2)

            source: !root.themed("incomingAlertTextBox") ? ""
                  : root.appTheme.image(callerArea.pressed && root.known ? "incoming-text-pressed.png"
                                                                         : "incoming-text.png")
            border.left: Math.round(sourceSize.width * 12 / 178)
            border.right: border.left
            border.top: Math.round(sourceSize.height * 12 / 82)
            border.bottom: border.top

            Column {
                anchors.centerIn: parent
                width: parent.width - Units.gu(2.4)

                Text {
                    width: parent.width
                    height: root.themed("incomingAlertLineHeight")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: Units.gu(1.8)
                    font.bold: root.themed("incomingAlertNameBold")
                    text: !root.currentContact ? ""
                        : root.known ? root.currentContact.displayLabel : qsTr("Unknown")
                }
                Text {
                    width: parent.width
                    height: root.themed("incomingAlertLineHeight")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: Units.gu(1.8)
                    text: !root.currentContact ? ""
                        : root.known ? root.currentContact.addr : root.currentContact.lineId
                }
                Text {
                    width: parent.width
                    height: root.themed("incomingAlertLineHeight")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: Units.gu(1.4)
                    text: !root.currentContact ? ""
                        : root.known ? root.currentContact.numberType
                        : (root.currentContact.geoLocation !== "Unknown" ? root.currentContact.geoLocation : "")
                }
            }

            MouseArea {
                id: callerArea
                anchors.fill: parent
                enabled: root.known
                onClicked: launcher.launch("com.palm.app.contacts",
                                           { personId: root.currentContact.personId }, undefined,
                                           function(error) { console.log("Could not open the contact: " + error); })
            }
        }
    }

    AppLauncher {
        id: launcher
        clientName: "org.webosports.app.phone"
    }
}
