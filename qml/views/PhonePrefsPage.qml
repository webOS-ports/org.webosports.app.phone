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

import LunaNext.Common 0.1

import "../services"
import "../services/CallMessages.js" as CallMessages

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
                    onClicked: prefsPage._startBarring()
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
                    label: qsTr("Change SIM Card PIN")
                    onClicked: prefsPage._startPinChange()
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

    /*
     * The call barring password.
     *
     * There is no legacy scene to follow here: the Enyo app never offered
     * barring in its preferences at all, and reached it only through the MMI
     * strings, which carry the password in the dial string itself. So it is
     * asked for on the card the SIM PIN uses -- a barring password is another
     * four digits the network wants back, and a keypad the app already draws
     * beats a text field the platform has no style for.
     */
    Loader {
        id: barringCardLoader

        anchors.fill: parent
        active: false
        z: 1

        sourceComponent: SimPinCard {
            appTheme: prefsPage.appTheme

            title: prefsPage._barringTitle
            subText: prefsPage._barringSubText
            /// GSM barring passwords are four digits, always.
            maximumLength: 4
            emergencyCallEnabled: false

            onAccepted: prefsPage._barringAccepted(pin)
            onCanceled: prefsPage._endBarring()
            onKeyed: prefsPage._clearBarringError()
        }
    }

    property string _barringTitle: ""
    property string _barringSubText: ""
    property bool _barringInError: false

    function _resetBarring() {
        _barringTitle = qsTr("Enter barring password");
        _barringSubText = qsTr("Enter 4 numbers for the barring password");
        _barringInError = false;

        if (barringCardLoader.item)
            barringCardLoader.item.clear();
    }

    function _startBarring() {
        _resetBarring();
        barringCardLoader.active = true;
    }

    function _endBarring() {
        barringCardLoader.active = false;
    }

    function _clearBarringError() {
        if (_barringInError)
            _resetBarring();
    }

    function _barringAccepted(entered) {
        if (entered.length === 0) {
            _endBarring();
            return;
        }

        supplementaryServices.disableAllBarring(entered);
    }

    Connections {
        /*
         * Switched by the target rather than by `enabled`: the Qt the device
         * runs has no such property on Connections, so setting it bound
         * nothing and left this listening the whole time -- which meant the
         * other card's handler ran on every completion too.
         */
        target: barringCardLoader.active ? prefsPage.supplementaryServices : null

        function onCompleted(success, message) {
            if (success) {
                prefsPage._endBarring();
                return;
            }

            // Not necessarily a wrong password: oFono reports one failure for
            // the lot, so the heading says what did not happen rather than
            // guessing why.
            prefsPage._resetBarring();
            prefsPage._barringTitle = qsTr("Could not turn barring off");
            prefsPage._barringSubText = message;
            prefsPage._barringInError = true;
        }
    }

    /*
     * Changing the SIM PIN.
     *
     * Not a popup: SecurityScene's "Change SIM Card PIN" swapped the whole
     * preferences card for PinCode, which asked for the old PIN, the new one
     * and the new one again in turn, each on the same dialpad. This is that
     * card, and it walks the same three steps under the same headings.
     */
    Loader {
        id: pinCardLoader

        anchors.fill: parent
        active: false
        z: 1

        sourceComponent: SimPinCard {
            appTheme: prefsPage.appTheme

            title: prefsPage._pinTitle
            subText: prefsPage._pinSubText
            maximumLength: 8

            onAccepted: prefsPage._pinAccepted(pin)
            onEmergencyCallRequested: emergencyLoader.active = true
            onKeyed: prefsPage._clearPinError()
        }
    }

    /// A SIM the user is locked out of still has to reach the emergency
    /// services, which is what the legacy card's left button was for.
    Loader {
        id: emergencyLoader

        anchors.fill: parent
        active: false
        z: 2

        sourceComponent: EmergencyDialerPage {
            appTheme: prefsPage.appTheme
            telephonyManager: prefsPage.telephonyManager
            voiceCallMgrWrapper: prefsPage.voiceCallMgrWrapper

            onClosed: emergencyLoader.active = false
        }
    }

    /// The three things the card asks for, with the headings the original
    /// gave each of them.
    readonly property var _pinSteps: ({
        "old":     { title: qsTr("Enter PIN"),
                     sub:   qsTr("Enter old PIN") },
        "new":     { title: qsTr("Enter new PIN"),
                     sub:   qsTr("Enter 4-8 numbers for new PIN") },
        "confirm": { title: qsTr("Confirm new PIN"),
                     sub:   qsTr("Enter 4-8 numbers for new PIN") }
    })

    property string _pinStep: "old"
    property string _pinTitle: ""
    property string _pinSubText: ""
    /// Set while the card is showing why the last attempt was turned down, so
    /// the next digit typed can put the step's own wording back.
    property bool _pinInError: false
    property string _pinOld: ""
    property string _pinNew: ""

    function _setPinStep(step) {
        _pinStep = step;
        _pinTitle = _pinSteps[step].title;
        _pinSubText = _pinSteps[step].sub;
        _pinInError = false;

        if (pinCardLoader.item)
            pinCardLoader.item.clear();
    }

    function _startPinChange() {
        _pinOld = "";
        _pinNew = "";
        _setPinStep("old");
        pinCardLoader.active = true;
    }

    function _endPinChange() {
        _pinOld = "";
        _pinNew = "";
        pinCardLoader.active = false;
    }

    function _clearPinError() {
        if (_pinInError)
            _setPinStep(_pinStep);
    }

    function _pinAccepted(entered) {
        // Done on an empty first step leaves the card. The original relied on
        // the back gesture for this, which a page inside our own card has no
        // way of receiving.
        if (entered.length === 0) {
            if (_pinStep === "old")
                _endPinChange();
            return;
        }

        switch (_pinStep) {
        case "old":
            _pinOld = entered;
            _setPinStep("new");
            break;
        case "new":
            _pinNew = entered;
            _setPinStep("confirm");
            break;
        case "confirm":
            supplementaryServices.changeSimPin(_pinOld, _pinNew, entered);
            break;
        }
    }

    Connections {
        /*
         * Switched by the target rather than by `enabled`: the Qt the device
         * runs has no such property on Connections, so setting it bound
         * nothing and left this listening the whole time -- which meant the
         * other card's handler ran on every completion too.
         */
        target: pinCardLoader.active ? prefsPage.supplementaryServices : null

        function onCompleted(success, message) {
            if (success) {
                prefsPage._endPinChange();
                return;
            }

            // Two PINs that did not match send the user back to the new PIN;
            // anything the SIM itself turned down starts the whole thing over.
            if (message === CallMessages.pinFailure["mismatch"]) {
                prefsPage._pinNew = "";
                prefsPage._setPinStep("new");
                prefsPage._pinSubText = qsTr("PIN doesn't match");
            }
            else {
                prefsPage._pinOld = "";
                prefsPage._pinNew = "";
                prefsPage._setPinStep("old");
                prefsPage._pinTitle = qsTr("PIN incorrect");
                prefsPage._pinSubText = message;
            }

            prefsPage._pinInError = true;
        }
    }
}
