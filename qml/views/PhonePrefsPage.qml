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

// The menus, switches and fields here are the platform's, so they have to
// be drawn by the platform's style rather than whatever Controls defaults to.
import QtQuick.Controls.LuneOS 2.0
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1

import "../services"

/**
 * Phone preferences.
 *
 * Ports the parts of the legacy shared/phoneprefs that still apply on LuneOS:
 * call forwarding, call waiting, caller ID, call barring, the voicemail number,
 * dialing shortcuts and the SIM PIN. The CDMA-only pages (PRL, provisioning,
 * MSL, world phone) are deliberately left out -- oFono has no equivalent and
 * the hardware they targeted is long gone.
 */
BasePage {
    id: prefsPage

    pageName: "PhonePrefs"

    // A preference scene is light, and belongs to the settings world rather
    // than to the call -- so it does not take the call card's gradient.
    gradient: null
    color: appTheme.prefsBackgroundColor

    Rectangle {
        id: prefsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Units.gu(5)
        color: appTheme.prefsHeaderColor

        Row {
            anchors.centerIn: parent
            spacing: Units.gu(0.8)

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: Units.gu(2.8)
                height: Units.gu(2.8)
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl("../../icon.png")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: appTheme.prefsTextColor
                font.pixelSize: FontUtils.sizeToPixels("large")
                text: qsTr("Phone Preferences")
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: appTheme.prefsRowDividerColor
        }
    }

    property DialingShortcuts dialingShortcuts

    signal closed();

    Flickable {
        anchors {
            top: prefsHeader.bottom
            left: parent.left
            right: parent.right
            bottom: doneBar.top
            margins: Units.gu(1.5)
        }
        contentHeight: prefsColumn.height
        clip: true

        ColumnLayout {
            id: prefsColumn
            width: parent.width
            spacing: Units.gu(1)

            // ---- Call forwarding -------------------------------------------

            PrefsGroup {
                Layout.fillWidth: true
                appTheme: prefsPage.appTheme
                title: qsTr("Call Forwarding")

                PrefsTextRow {
                    label: qsTr("Always forward to")
                    placeholder: qsTr("Off")
                    value: supplementaryServices ? supplementaryServices.callForwardingUnconditional : ""
                    onCommitted: (text) => supplementaryServices.callForwardingUnconditional = text
                }
                PrefsTextRow {
                    label: qsTr("When busy")
                    placeholder: qsTr("Off")
                    value: supplementaryServices ? supplementaryServices.callForwardingBusy : ""
                    onCommitted: (text) => supplementaryServices.callForwardingBusy = text
                }
                PrefsTextRow {
                    label: qsTr("When unanswered")
                    placeholder: qsTr("Off")
                    value: supplementaryServices ? supplementaryServices.callForwardingNoReply : ""
                    onCommitted: (text) => supplementaryServices.callForwardingNoReply = text
                }
                PrefsTextRow {
                    label: qsTr("When unreachable")
                    placeholder: qsTr("Off")
                    value: supplementaryServices ? supplementaryServices.callForwardingNotReachable : ""
                    onCommitted: (text) => supplementaryServices.callForwardingNotReachable = text
                }
                PrefsButtonRow {
                    label: qsTr("Turn all forwarding off")
                    onClicked: supplementaryServices.disableAllForwarding()
                }
            }

            // ---- Calls -----------------------------------------------------

            PrefsGroup {
                Layout.fillWidth: true
                appTheme: prefsPage.appTheme
                title: qsTr("Calls")

                PrefsSwitchRow {
                    label: qsTr("Call waiting")
                    checked: supplementaryServices && supplementaryServices.callWaiting === "enabled"
                    onToggled: (on) => supplementaryServices.callWaiting = on ? "enabled" : "disabled"
                }
                PrefsSwitchRow {
                    label: qsTr("Hide my caller ID")
                    checked: supplementaryServices && supplementaryServices.hideCallerId === "enabled"
                    onToggled: (on) => supplementaryServices.hideCallerId = on ? "enabled" : "disabled"
                }
                PrefsTextRow {
                    label: qsTr("Voicemail number")
                    placeholder: qsTr("Not set")
                    value: telephonyManager ? telephonyManager.voicemailNumber : ""
                    onCommitted: (text) => telephonyManager.messageWaitingObject.voicemailMailboxNumber = text
                }
            }

            // ---- Call barring ----------------------------------------------

            PrefsGroup {
                Layout.fillWidth: true
                appTheme: prefsPage.appTheme
                title: qsTr("Call Barring")

                PrefsInfoRow {
                    label: qsTr("Outgoing calls")
                    value: (supplementaryServices && supplementaryServices.barringOutgoing.length > 0)
                               ? supplementaryServices.barringOutgoing : qsTr("Not barred")
                }
                PrefsInfoRow {
                    label: qsTr("Incoming calls")
                    value: (supplementaryServices && supplementaryServices.barringIncoming.length > 0)
                               ? supplementaryServices.barringIncoming : qsTr("Not barred")
                }
                PrefsButtonRow {
                    label: qsTr("Turn all barring off")
                    onClicked: barringPasswordDialog.open()
                }
            }

            // ---- Dialing shortcuts -----------------------------------------

            PrefsGroup {
                Layout.fillWidth: true
                appTheme: prefsPage.appTheme
                title: qsTr("Dialing Shortcuts")

                Repeater {
                    model: prefsPage.dialingShortcuts ? prefsPage.dialingShortcuts.supportedLengths : []

                    delegate: PrefsTextRow {
                        required property var modelData

                        label: qsTr("Prefix for %1-digit numbers").arg(modelData)
                        placeholder: qsTr("None")
                        value: prefsPage.dialingShortcuts.prefixFor(modelData)
                        onCommitted: (text) => prefsPage.dialingShortcuts.setPrefix(modelData, text)
                    }
                }
            }

            // ---- SIM --------------------------------------------------------

            PrefsGroup {
                Layout.fillWidth: true
                appTheme: prefsPage.appTheme
                title: qsTr("SIM")

                PrefsInfoRow {
                    label: qsTr("Network")
                    value: telephonyManager ? (telephonyManager.networkName || qsTr("No service")) : ""
                }
                PrefsInfoRow {
                    label: qsTr("Signal")
                    value: telephonyManager ? (telephonyManager.signalStrength + "%") : ""
                }
                PrefsButtonRow {
                    label: qsTr("Change SIM PIN")
                    onClicked: pinDialog.open()
                }
            }

        }
    }

    PrefsDoneBar {
        id: doneBar

        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        appTheme: prefsPage.appTheme
        onClicked: prefsPage.closed()
    }

    Dialog {
        id: barringPasswordDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: qsTr("Call barring password")
        standardButtons: Dialog.Ok | Dialog.Cancel

        TextField {
            id: barringPasswordField
            echoMode: TextInput.Password
            placeholderText: qsTr("Password")
        }

        onAccepted: {
            supplementaryServices.disableAllBarring(barringPasswordField.text);
            barringPasswordField.text = "";
        }
    }

    Dialog {
        id: pinDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: qsTr("Change SIM PIN")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            TextField {
                id: oldPinField
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly
                placeholderText: qsTr("Current PIN")
            }
            TextField {
                id: newPinField
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly
                placeholderText: qsTr("New PIN")
            }
        }

        onAccepted: {
            supplementaryServices.changeSimPin(oldPinField.text, newPinField.text);
            oldPinField.text = "";
            newPinField.text = "";
        }
    }
}
