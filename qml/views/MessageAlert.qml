/*
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
import QtQuick.Layouts 1.2

import Eos.Window 0.1
import LunaNext.Common 0.1

/**
 * A system-wide alert with a title, a message and up to two buttons.
 *
 * The legacy app had a separate window kind per popup -- DialFail, DroppedCall,
 * MissedCall, AirplaneMode, ServiceMessage, NoVoicemailNumberPrompt. They only
 * differed in their text, icon and buttons, so here they are all this one
 * window driven by showMessage()/showQuestion().
 */
WebOSWindow {
    id: messageAlert

    property PhoneUiTheme appTheme;

    property string title: ""
    property string message: ""
    property url iconSource: ""
    property string acceptLabel: qsTr("OK")
    property string cancelLabel: ""

    /// Called when the user takes the affirmative action.
    property var acceptAction: null

    signal accepted();
    signal dismissed();

    width: Settings.displayWidth
    height: Units.gu(24)

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    visible: false

    Component.onCompleted: {
        messageAlert.setWindowProperty("LuneOS_window", "popupalert");
    }

    /// Shows an alert the user can only acknowledge.
    function showMessage(alertTitle, alertMessage, icon) {
        title = alertTitle || "";
        message = alertMessage || "";
        iconSource = icon || "";
        acceptLabel = qsTr("OK");
        cancelLabel = "";
        acceptAction = null;
        show();
    }

    /// Shows an alert with an affirmative action, e.g. "Call back".
    function showQuestion(alertTitle, alertMessage, icon, affirmativeLabel, action) {
        title = alertTitle || "";
        message = alertMessage || "";
        iconSource = icon || "";
        acceptLabel = affirmativeLabel;
        cancelLabel = qsTr("Dismiss");
        acceptAction = action;
        show();
    }

    Rectangle {
        anchors.fill: parent
        gradient: appTheme ? appTheme.mainGradient : undefined
    }

    RowLayout {
        id: content

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: buttons.top
            margins: Units.gu(1.5)
        }
        spacing: Units.gu(1.5)

        Image {
            Layout.preferredWidth: Units.gu(6)
            Layout.preferredHeight: Units.gu(6)
            Layout.alignment: Qt.AlignVCenter
            fillMode: Image.PreserveAspectFit
            source: messageAlert.iconSource
            visible: String(messageAlert.iconSource).length > 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Units.gu(0.5)

            Text {
                Layout.fillWidth: true
                color: "white"
                font.bold: true
                font.pixelSize: FontUtils.sizeToPixels("large")
                elide: Text.ElideRight
                text: messageAlert.title
                visible: messageAlert.title.length > 0
            }
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                wrapMode: Text.Wrap
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: messageAlert.message
            }
        }
    }

    Row {
        id: buttons

        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        height: Units.gu(5)
        spacing: Units.gu(1)

        Button {
            height: parent.height
            width: Units.gu(16)
            text: messageAlert.acceptLabel

            onClicked: {
                messageAlert.hide();
                if (messageAlert.acceptAction)
                    messageAlert.acceptAction();
                messageAlert.accepted();
            }
        }

        Button {
            height: parent.height
            width: Units.gu(16)
            text: messageAlert.cancelLabel
            visible: messageAlert.cancelLabel.length > 0

            onClicked: {
                messageAlert.hide();
                messageAlert.dismissed();
            }
        }
    }
}
