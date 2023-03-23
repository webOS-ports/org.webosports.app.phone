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
import QtQuick.Controls 2.0

import Eos.Window 0.1

import LunaNext.Common 0.1

import org.nemomobile.voicecall 1.0

import "../services"

WebOSWindow {
    id: incomingUSSDAlert

    property TelephonyManager telephonyManager;

    width: Settings.displayWidth
    height: Units.gu(24)

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_POPUP"
    color: "transparent"

    Connections {
        target: telephonyManager
        function onUssdResponse(ussdText) {
            ussdText.text = response;
            incomingUSSDAlert.show();
        }
    }

    Text {
        id: ussdText
        anchors {
            top: parent.top
            bottom: buttonHide.top
            margins: Units.gu(1)
            left: parent.left
            right: parent.right
        }

        font.pixelSize: Units.dp(30)
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "white"
        text: ""
    }

    Button {
        id: buttonHide
        height: Units.gu(6)
        width: Units.gu(10)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        text: "OK"

        onClicked: {
            incomingUSSDAlert.hide();
        }
    }
}
