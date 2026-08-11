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
import QtQuick.Controls 2.0

import Eos.Window 0.1
import LunaNext.Common 0.1

import "../services"

/**
 * Shows what the network sends back after a USSD request, and -- new here --
 * lets the user reply to it.
 *
 * Most USSD menus (prepaid balance, top-up, operator services) are a
 * conversation: the network sends a menu and waits for a choice. The original
 * window could only display a response, and did not even manage that: its
 * handler assigned the alert's own text to itself and dropped the message.
 */
WebOSWindow {
    id: incomingUSSDAlert

    property TelephonyManager telephonyManager;
    property PhoneUiTheme appTheme: PhoneUiTheme {}

    width: Settings.displayWidth
    height: Units.gu(32)

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    color: "transparent"

    /// True while the network is waiting for the user to answer.
    property bool awaitingReply: false

    Component.onCompleted: {
        incomingUSSDAlert.setWindowProperty("LuneOS_window", "popupalert");
    }

    function _present(message, needsReply) {
        ussdText.text = message;
        awaitingReply = needsReply;
        replyField.text = "";
        incomingUSSDAlert.show();
    }

    Connections {
        target: incomingUSSDAlert.telephonyManager

        function onUssdResponse(response) {
            incomingUSSDAlert._present(response, false);
        }

        // A request is a menu the network expects an answer to.
        function onUssdRequest(message) {
            incomingUSSDAlert._present(message, true);
        }

        // A notification is informational and needs no answer.
        function onUssdNotification(message) {
            incomingUSSDAlert._present(message, false);
        }

        function onUssdFailed() {
            incomingUSSDAlert._present(qsTr("The request could not be sent."), false);
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: appTheme ? appTheme.mainGradient : undefined
    }

    Flickable {
        anchors {
            top: parent.top
            bottom: replyField.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        contentHeight: ussdText.height
        clip: true

        Text {
            id: ussdText
            width: parent.width

            wrapMode: Text.Wrap
            font.pixelSize: FontUtils.sizeToPixels("medium")
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            text: ""
        }
    }

    TextField {
        id: replyField

        anchors {
            bottom: buttonRow.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        height: visible ? Units.gu(5) : 0
        visible: incomingUSSDAlert.awaitingReply

        placeholderText: qsTr("Your reply")
        color: "white"
        placeholderTextColor: "grey"

        background: Rectangle {
            color: appTheme.panelFooterColor
            radius: Units.gu(0.5)
        }

        onAccepted: sendButton.send()
    }

    Row {
        id: buttonRow

        height: Units.gu(5)
        spacing: Units.gu(1)
        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }

        Button {
            id: sendButton
            height: parent.height
            width: Units.gu(12)
            text: qsTr("Send")
            visible: incomingUSSDAlert.awaitingReply

            function send() {
                incomingUSSDAlert.telephonyManager.respondToUssd(replyField.text);
                incomingUSSDAlert.awaitingReply = false;
                incomingUSSDAlert.hide();
            }

            onClicked: send()
        }

        Button {
            height: parent.height
            width: Units.gu(12)
            text: incomingUSSDAlert.awaitingReply ? qsTr("Cancel") : qsTr("OK")

            onClicked: {
                // Leaving a session open ties up the modem's USSD channel, so
                // dismissing an unanswered menu cancels it properly.
                if (incomingUSSDAlert.awaitingReply)
                    incomingUSSDAlert.telephonyManager.cancelUssd();

                incomingUSSDAlert.awaitingReply = false;
                incomingUSSDAlert.hide();
            }
        }
    }
}
