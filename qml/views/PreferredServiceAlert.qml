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

import LunaNext.Common 0.1
import LuneOS.Components 1.0 as LuneComponents

/**
 * "Which service would you like to use?"
 *
 * Ports the legacy PreferredPhSvcDlg. Shown at dial time when several calling
 * accounts could place the call and the user has not said which they prefer.
 * One button per transport, built from the registry, so a newly installed
 * connector appears here without any code change.
 */
Item {
    id: preferredServiceAlert

    property PhoneUiTheme appTheme;
    property var callTransports
    property var dialProxy
    property var dialHandler
    property var contacts

    property var callData: ({})
    property bool remember: false

    /// One row per transport, plus the title, the question, the reminder
    /// checkbox and Cancel.
    readonly property int _serviceCount: serviceButtons.count
    readonly property real _dialogHeight: Units.gu(16) + (_serviceCount + 1) * Units.gu(5.4)

    anchors.fill: parent
    visible: false

    function ask(data) {
        callData = data || {};
        remember = false;
        visible = true;
    }

    function _choose(transportId) {
        visible = false;

        if (remember)
            dialProxy.setPreferredService(transportId, callData.isInternational === true);

        dialHandler.dialWithTransport(callData.address, transportId, callData.video === true);
    }

    /*
     * Centred over the app with the rest of it dimmed, which is what the
     * legacy dialog's openAtCenter() does. It is not a system alert: an alert
     * is docked into the strip along the foot of the screen, and a dialog
     * asking a question belongs over the app that asked it.
     *
     * The platform's own dialog, which is the webOS one: the frame, the
     * buttons and the scrim all come from LuneOS.Components rather than being
     * drawn here. The legacy app got the same look for the same reason -- its
     * PreferredPhSvcDlg is a plain enyo ModalDialog and inherits it.
     */
    LuneComponents.Dialog {
        id: dialog

        anchors.fill: parent

        title: preferredServiceAlert.callData.isInternational === true
                   ? qsTr("International Call") : qsTr("Call")
        message: qsTr("Which service would you like to use?\nThis preference can be set in Preferences & Accounts.")

        dialogWidth: Math.min(Units.gu(40), preferredServiceAlert.width - Units.gu(6))
        dialogHeight: preferredServiceAlert._dialogHeight

        // One button per calling account, so a newly installed connector
        // appears here without any code change. A transport whose network is
        // down is left out rather than offered and refused.
        Repeater {
            id: serviceButtons

            model: preferredServiceAlert.callTransports
                       ? preferredServiceAlert.callTransports.callableTransportIds() : []

            delegate: LuneComponents.DialogButton {
                required property var modelData

                text: preferredServiceAlert.callTransports.labelFor(modelData)
                color: preferredServiceAlert.callTransports.isAvailable(modelData) ? "#4b4b4b" : "#333333"
                fontcolor: preferredServiceAlert.callTransports.isAvailable(modelData) ? "white" : "#7a7a7a"
                buttonWidth: dialog.dialogWidth - Units.gu(4)

                onClicked: {
                    if (preferredServiceAlert.callTransports.isAvailable(modelData))
                        preferredServiceAlert._choose(modelData);
                }
            }
        }

        LuneComponents.DialogCheckBox {
            checked: preferredServiceAlert.remember
            labelWidth: dialog.dialogWidth - Units.gu(7)
            text: qsTr("Always use this service for these calls")

            onCheckedChanged: preferredServiceAlert.remember = checked
        }

        // Red, as .enyo-button-negative is in the theme the legacy dialog used.
        LuneComponents.DialogButton {
            text: qsTr("Cancel")
            color: "#be0003"
            fontcolor: "white"
            buttonWidth: dialog.dialogWidth - Units.gu(4)

            onClicked: preferredServiceAlert.visible = false
        }
    }
}
