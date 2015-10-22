/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import LunaNext.Compositor 0.1
import LuneOS.Application 1.0 as LuneOS

LuneOS.ApplicationWindow {
    id: incomingCallAlert

    property Item voiceCallManager

    width: Settings.displayWidth
    height: Units.gu(30)

    type: WindowType.PopupAlert
    color: "transparent"

    Image {
        id: avatar

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Units.gu(3)
        }

        width: Units.gu(10)
        height: Units.gu(10)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        smooth: true

        Rectangle {
            anchors.fill: parent
            border { color: "white" /*main.appTheme.foregroundColor*/; width: 2 }
            radius: 10
            color: '#00000000'
        }

        source: 'images/generic-details-view-avatar.png';
    }

    Text {
        anchors {
            top: avatar.bottom
            topMargin: Units.gu(5)
            bottom: buttons.top
            bottomMargin: Units.gu(5)
            horizontalCenter:parent.horizontalCenter
        }

        id: title
        font.pixelSize: FontUtils.sizeToPixels("large")
        color: "white"
        text: voiceCallManager.incomingCall ? voiceCallManager.incomingCall.lineId : ""
    }

    Row {
        id: buttons
        height: Units.gu(12)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        spacing: Units.gu(16)

        IncomingAcceptButton {
            height: 215
            width: 215
            onClicked: {
                voiceCallManager.incomingCall.answer();
            }
        }

        IncomingRejectButton {
            height: 210
            width: 210
            onClicked: {
                voiceCallManager.incomingCall.hangup();
            }
        }
    }
}
