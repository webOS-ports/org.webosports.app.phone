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
import QtQuick.Layouts 1.0

import LunaNext.Common 0.1

import LuneOS.Telephony 1.0

import "../services/IncomingCallsService.js" as IncomingCallsService

BasePage {
    id: incommingCallDialog
    pageName: "IncomingCall"

    BorderImage {
        id: avatarBackground

        source: "images/frame-background.png"
        border.left: 70; border.top: 70
        border.right: 70; border.bottom: 70

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: answerRejectBtns.top
            margins: Units.gu(1)
        }
    }

    Image {
        id:imageAvatar
        anchors {
            top: avatarBackground.top
            topMargin: Units.gu(3)
            horizontalCenter:avatarBackground.horizontalCenter
        }

        width: avatarBackground.width*0.6
        height: width

        asynchronous:true
        fillMode:Image.PreserveAspectCrop
        smooth:true
        source: currentContact.avatarPath
    }
    CornerShader {
        radius: 35
        sourceItem: imageAvatar
        anchors.fill: imageAvatar
    }
    Image {
        id: avatarFrame
        anchors.centerIn: imageAvatar

        width: imageAvatar.width + Units.gu(2)
        height: width
        source: "images/contacts-icon-frame.png"
        fillMode:Image.Stretch
        asynchronous:true
        smooth:true
    }

    Text {
        id: lineIdText
        anchors {
            top: imageAvatar.bottom
            bottom: avatarBackground.bottom
            topMargin: Units.gu(1)
            bottomMargin: Units.gu(1)
            leftMargin: 50
            rightMargin: 50
            left: avatarBackground.left
            right: avatarBackground.right
        }

        font.pixelSize: Units.dp(30)
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: appTheme.headerTitle
        text: currentContact.personId ? (currentContact.displayLabel +"\n" + currentContact.addr) :
                                        (currentContact.lineId + "\n"+ currentContact.geoLocation);
    }

    Item {
        id: answerRejectBtns
        height: Units.gu(12)
        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(2)
            left: parent.left
            leftMargin: Units.gu(3)
            right: parent.right
            rightMargin: Units.gu(3)
        }

        IncomingAcceptButton {
            height: 210
            width: 210
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Accepted);
                voiceCall.answer();
            }
        }

        IncomingRejectButton {
            height: 210
            width: 210
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Ignored);
                voiceCall.hangup();
            }
        }
    }
}
