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
import LuneOS.Telephony 1.0

import "../model"

/**
 * The incoming call, filling whatever it is given: the in-app page when the
 * phone is in front, the alert window when it is not, and over the lock screen.
 * One look for all three, so a call never looks different depending on where
 * the phone happened to be.
 *
 * The photo in its frame at the top, the legacy caller box under it - name,
 * number and what kind of number it is, as the webOS popup had them in
 * .incoming-text-container - and answer and ignore at the bottom. Legacy's
 * popup put the buttons either side of the box, but that was a strip across
 * the bottom of a 320x480 screen; on a phone the call takes the screen.
 */
Item {
    id: root

    property UiTheme appTheme
    property Contact currentContact

    signal answerClicked()
    signal rejectClicked()

    // The contact's photo, or the unknown-caller stand-in, in its frame.
    BorderImage {
        id: avatarBackground

        source: root.appTheme.image("frame-background.png")
        border.left: 70; border.top: 70
        border.right: 70; border.bottom: 70

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: callerBox.top
            margins: Units.gu(1)
        }
    }

    Image {
        id: imageAvatar
        anchors.centerIn: avatarBackground

        width: Math.min(avatarBackground.width * 0.6, avatarBackground.height * 0.75)
        height: width

        asynchronous: true
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: root.currentContact ? root.currentContact.avatarPath : ""

        visible: false
    }
    CornerShader {
        anchors.fill: imageAvatar
        source: imageAvatar
        radius: 35
    }
    Image {
        anchors.centerIn: imageAvatar

        width: imageAvatar.width + Units.gu(2)
        height: width
        source: root.appTheme.image("contacts-icon-frame.png")
        fillMode: Image.Stretch
        asynchronous: true
        smooth: true
    }

    /*
     * Who is calling. A known caller is name over number over number type; an
     * unknown one is the number over where it is from. Tapping a known caller
     * opens the contact, as tapping the box did on webOS.
     */
    BorderImage {
        id: callerBox

        readonly property bool known: !!root.currentContact && root.currentContact.personId.length > 0

        anchors {
            bottom: answerRejectBtns.top
            bottomMargin: Units.gu(1.5)
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(parent.width - Units.gu(4), Units.gu(36))
        height: Units.gu(8.2)

        source: root.appTheme.image(callerArea.pressed && callerBox.known ? "incoming-text-pressed.png"
                                                            : "incoming-text.png")
        // The legacy box's twelve pixel rounded ends, at whatever scale the
        // theme's copy of the artwork is.
        border.left: Math.round(sourceSize.width * 12 / 178)
        border.right: border.left
        border.top: Math.round(sourceSize.height * 12 / 82)
        border.bottom: border.top

        Column {
            anchors.centerIn: parent
            width: parent.width - Units.gu(2.4)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "white"
                font.pixelSize: Units.gu(1.8)
                text: !root.currentContact ? ""
                    : callerBox.known ? root.currentContact.displayLabel : root.currentContact.lineId
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "white"
                font.pixelSize: Units.gu(1.6)
                text: !root.currentContact ? ""
                    : callerBox.known ? root.currentContact.addr : root.currentContact.geoLocation
            }
            Text {
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "#cccccc"
                font.pixelSize: Units.gu(1.4)
                text: callerBox.known ? root.currentContact.numberType : ""
            }
        }

        MouseArea {
            id: callerArea
            anchors.fill: parent
            enabled: callerBox.known
            onClicked: launcher.launch("com.palm.app.contacts",
                                       { personId: root.currentContact.personId }, undefined,
                                       function(error) { console.log("Could not open the contact: " + error); })
        }
    }

    Item {
        id: answerRejectBtns
        height: Units.gu(13)
        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(1)
            left: parent.left
            leftMargin: Units.gu(3)
            right: parent.right
            rightMargin: Units.gu(3)
        }

        IncomingAcceptButton {
            appTheme: root.appTheme
            height: answerRejectBtns.height
            width: answerRejectBtns.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.answerClicked()
        }

        IncomingRejectButton {
            appTheme: root.appTheme
            height: answerRejectBtns.height
            width: answerRejectBtns.height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.rejectClicked()
        }
    }

    AppLauncher {
        id: launcher
        clientName: "org.webosports.app.phone"
    }
}
