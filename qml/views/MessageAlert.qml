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
import QtQuick.Layouts 1.2

import Eos.Window 0.1
import LunaNext.Common 0.1
import LuneOS.Components 1.0 as LuneComponents

/**
 * A system-wide alert with a title, a message and up to two buttons.
 *
 * The legacy app had a separate window kind per popup -- DialFail, DroppedCall,
 * MissedCall, AirplaneMode, ServiceMessage, NoVoicemailNumberPrompt. They only
 * differed in their text, icon and buttons, so here they are all this one
 * window driven by showMessage()/showQuestion().
 *
 * Their styling is shared too, from phonePopups/popupStyle.css: an eighteen
 * pixel bold title over a twelve pixel message, a sixty-four pixel icon beside
 * it, and no background of its own -- the shell paints the strip these sit in,
 * which is why the original sets `background: transparent`.
 */
WebOSWindow {
    id: messageAlert

    property UiTheme appTheme;

    property string title: ""
    property string message: ""
    property url iconSource: ""
    property string acceptLabel: qsTr("Ok")
    property string cancelLabel: ""

    /// DialFail puts its icon after the text; the call popups put theirs
    /// before it. Both orders are the original's.
    property bool iconOnRight: false
    /// An action the user is being offered rather than merely told about, so
    /// its button is green and the way out of it is red.
    property bool affirmative: false

    /// Called when the user takes the affirmative action.
    property var acceptAction: null

    signal accepted();
    signal dismissed();

    width: Settings.displayWidth
    // .dialfail-popups-bg is between 125 and 150 pixels tall; the alert takes
    // what its text needs within that.
    height: Math.max(Units.gu(12.5), Math.min(Units.gu(15), content.implicitHeight + Units.gu(8)))

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    visible: false

    Component.onCompleted: {
        messageAlert.setWindowProperty("LuneOS_window", "popupalert");
    }

    /// Shows an alert the user can only acknowledge.
    function showMessage(alertTitle, alertMessage, icon) {
        console.log("MESSAGE popup: '" + alertTitle + "' / '" + alertMessage + "'");
        title = alertTitle || "";
        message = alertMessage || "";
        iconSource = icon || "";
        acceptLabel = qsTr("Ok");
        cancelLabel = "";
        affirmative = false;
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
        affirmative = true;
        acceptAction = action;
        show();
    }

    // What the shell paints behind an alert; the original leaves it to show
    // through rather than drawing a panel of its own.
    Rectangle {
        anchors.fill: parent
        color: "black"
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
            Layout.preferredWidth: Units.gu(6.4)
            Layout.preferredHeight: Units.gu(6.4)
            Layout.alignment: Qt.AlignVCenter
            fillMode: Image.PreserveAspectFit
            source: messageAlert.iconSource
            visible: String(messageAlert.iconSource).length > 0 && !messageAlert.iconOnRight
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Units.gu(0.5)

            Text {
                Layout.fillWidth: true
                color: "white"
                font.bold: true
                font.pixelSize: Units.gu(1.8)
                elide: Text.ElideRight
                text: messageAlert.title
                visible: messageAlert.title.length > 0
            }
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                wrapMode: Text.Wrap
                font.pixelSize: Units.gu(1.2)
                text: messageAlert.message
            }
        }

        Image {
            Layout.preferredWidth: Units.gu(6.4)
            Layout.preferredHeight: Units.gu(6.4)
            Layout.alignment: Qt.AlignVCenter
            fillMode: Image.PreserveAspectFit
            source: messageAlert.iconSource
            visible: String(messageAlert.iconSource).length > 0 && messageAlert.iconOnRight
        }
    }

    Row {
        id: buttons

        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        height: Units.gu(4)
        spacing: Units.gu(1)

        // Green to accept and red to decline where the user is being offered
        // something; the flat dark button where there is only "Ok".
        LuneComponents.DialogButton {
            text: messageAlert.acceptLabel
            color: messageAlert.affirmative ? "#2aa100" : "#171717"
            fontcolor: "white"
            buttonWidth: Units.gu(16)

            onClicked: {
                messageAlert.hide();
                if (messageAlert.acceptAction)
                    messageAlert.acceptAction();
                messageAlert.accepted();
            }
        }

        LuneComponents.DialogButton {
            text: messageAlert.cancelLabel
            color: "#be0003"
            fontcolor: "white"
            buttonWidth: Units.gu(16)
            visible: messageAlert.cancelLabel.length > 0

            onClicked: {
                messageAlert.hide();
                messageAlert.dismissed();
            }
        }
    }
}
