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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.2

import Eos.Window 0.1
import LunaNext.Common 0.1

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * "Which service would you like to use?"
 *
 * Ports the legacy PreferredPhSvcDlg. Shown at dial time when several calling
 * accounts could place the call and the user has not said which they prefer.
 * One button per transport, built from the registry, so a newly installed
 * connector appears here without any code change.
 */
WebOSWindow {
    id: preferredServiceAlert

    property PhoneUiTheme appTheme;
    property var callTransports
    property var dialProxy
    property var dialHandler
    property var contacts

    property var callData: ({})
    property bool remember: false

    width: Settings.displayWidth
    height: Units.gu(34)

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    visible: false

    Component.onCompleted: {
        preferredServiceAlert.setWindowProperty("LuneOS_window", "popupalert");
    }

    function ask(data) {
        callData = data || {};
        remember = false;
        show();
    }

    function _choose(transportId) {
        hide();

        if (remember)
            dialProxy.setPreferredService(transportId, callData.isInternational === true);

        dialHandler.dialWithTransport(callData.address, transportId, callData.video === true);
    }

    Rectangle {
        anchors.fill: parent
        gradient: appTheme ? appTheme.mainGradient : undefined
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Units.gu(1.5)
        spacing: Units.gu(0.5)

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            font.bold: true
            font.pixelSize: FontUtils.sizeToPixels("large")
            text: preferredServiceAlert.callData.isInternational === true
                      ? qsTr("International call") : qsTr("Call")
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("small")
            text: qsTr("Which service would you like to use to call %1?")
                      .arg(PhoneNumberUtils.formatForDisplay(preferredServiceAlert.callData.address || "",
                                                             contacts ? contacts.countryCode : "US", false))
        }

        // One button per calling account. Unavailable transports are shown but
        // disabled, so the user can see why a service is not on offer.
        Repeater {
            model: preferredServiceAlert.callTransports
                       ? preferredServiceAlert.callTransports.callableTransportIds() : []

            delegate: Button {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: Units.gu(5)

                enabled: preferredServiceAlert.callTransports.isAvailable(modelData)
                text: preferredServiceAlert.callTransports.labelFor(modelData)

                onClicked: preferredServiceAlert._choose(modelData)
            }
        }

        RowLayout {
            Layout.fillWidth: true

            CheckBox {
                id: rememberBox
                checked: preferredServiceAlert.remember
                onToggled: preferredServiceAlert.remember = rememberBox.checked
            }
            Text {
                Layout.fillWidth: true
                color: "white"
                wrapMode: Text.Wrap
                font.pixelSize: FontUtils.sizeToPixels("x-small")
                text: qsTr("Always use this service for these calls")
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: Units.gu(5)
            text: qsTr("Cancel")
            onClicked: preferredServiceAlert.hide()
        }
    }
}
