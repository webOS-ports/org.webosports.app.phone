import QtQuick 2.0
import QtQuick.Controls 2.2

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

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
 *
 * In the look of the settings apps: the light header with Done on the right,
 * and groups of LuneOS.Forms rows. A preference scene belongs to the settings
 * world rather than to the call, so it does not take the call card's colours.
 */
AppPage {
    id: prefsPage

    // What PhoneTabView hands the page
    property UiTheme appTheme
    property TelephonyManager telephonyManager
    // The SIM PIN card offers an emergency dialpad, which places the call
    property VoiceCallMgrWrapper voiceCallMgrWrapper
    property SupplementaryServices supplementaryServices
    property DialingShortcuts dialingShortcuts

    signal closed();

    // A phone number needs less room than the label beside it does on a
    // narrow screen (the Q25's square)
    readonly property real numberFieldWidth: Math.min(Units.gu(24), width * 0.38)

    // Done sits at the foot, as in every webOS preferences scene
    footer: DoneBar { onClicked: prefsPage.closed() }

    header: AppHeader {
        height: Units.gu(7.5)
        title: qsTr("Phone Preferences")
        icon: Qt.resolvedUrl("../../icon.png")
        compact: width < Units.gu(50)
    }

    SettingsPageContent {
        // ---- Call forwarding -----------------------------------------------

        FormGroup {
            title: qsTr("Call Forwarding")

            LabelAndTextField {
                label: qsTr("Always forward to")
                placeholderText: qsTr("Off")
                inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                fieldWidth: prefsPage.numberFieldWidth
                text: supplementaryServices ? supplementaryServices.callForwardingUnconditional : ""
                onCommitted: (text) => supplementaryServices.callForwardingUnconditional = text
            }
            LabelAndTextField {
                label: qsTr("When busy")
                placeholderText: qsTr("Off")
                inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                fieldWidth: prefsPage.numberFieldWidth
                text: supplementaryServices ? supplementaryServices.callForwardingBusy : ""
                onCommitted: (text) => supplementaryServices.callForwardingBusy = text
            }
            LabelAndTextField {
                label: qsTr("When unanswered")
                placeholderText: qsTr("Off")
                inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                fieldWidth: prefsPage.numberFieldWidth
                text: supplementaryServices ? supplementaryServices.callForwardingNoReply : ""
                onCommitted: (text) => supplementaryServices.callForwardingNoReply = text
            }
            LabelAndTextField {
                label: qsTr("When unreachable")
                placeholderText: qsTr("Off")
                inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                fieldWidth: prefsPage.numberFieldWidth
                text: supplementaryServices ? supplementaryServices.callForwardingNotReachable : ""
                onCommitted: (text) => supplementaryServices.callForwardingNotReachable = text
            }
        }
        Button {
            width: parent.width
            text: qsTr("Turn all forwarding off")
            onClicked: supplementaryServices.disableAllForwarding()
        }

        // ---- Calls ---------------------------------------------------------

        FormGroup {
            title: qsTr("Calls")

            LabelAndSwitch {
                label: qsTr("Call waiting")
                checked: !!supplementaryServices && supplementaryServices.callWaiting === "enabled"
                // Only changes the user made, never the ones that came back
                // from the modem, so a setting is not written straight back
                onToggled: supplementaryServices.callWaiting = checked ? "enabled" : "disabled"
            }
            LabelAndSwitch {
                label: qsTr("Hide my caller ID")
                checked: !!supplementaryServices && supplementaryServices.hideCallerId === "enabled"
                onToggled: supplementaryServices.hideCallerId = checked ? "enabled" : "disabled"
            }
            LabelAndTextField {
                label: qsTr("Voicemail number")
                placeholderText: qsTr("Not set")
                inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                fieldWidth: prefsPage.numberFieldWidth
                text: telephonyManager ? telephonyManager.voicemailNumber : ""
                onCommitted: (text) => telephonyManager.messageWaitingObject.voicemailMailboxNumber = text
            }
        }

        // ---- Call barring --------------------------------------------------

        FormGroup {
            title: qsTr("Call Barring")

            LabelAndValue {
                label: qsTr("Outgoing calls")
                value: (supplementaryServices && supplementaryServices.barringOutgoing.length > 0)
                           ? supplementaryServices.barringOutgoing : qsTr("Not barred")
            }
            LabelAndValue {
                label: qsTr("Incoming calls")
                value: (supplementaryServices && supplementaryServices.barringIncoming.length > 0)
                           ? supplementaryServices.barringIncoming : qsTr("Not barred")
            }
        }
        Button {
            width: parent.width
            text: qsTr("Turn all barring off")
            onClicked: prefsPage._startBarring()
        }

        // ---- Dialing shortcuts ---------------------------------------------

        FormGroup {
            title: qsTr("Dialing Shortcuts")
            visible: !!prefsPage.dialingShortcuts

            Repeater {
                model: prefsPage.dialingShortcuts ? prefsPage.dialingShortcuts.supportedLengths : []

                delegate: LabelAndTextField {
                    required property var modelData

                    label: qsTr("%1-digit numbers").arg(modelData)
                    placeholderText: qsTr("None")
                    inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
                    fieldWidth: prefsPage.numberFieldWidth
                    text: prefsPage.dialingShortcuts.prefixFor(modelData)
                    onCommitted: (text) => prefsPage.dialingShortcuts.setPrefix(modelData, text)
                }
            }
        }

        ExplanationText {
            width: parent.width
            visible: !!prefsPage.dialingShortcuts
            text: qsTr("The prefix is put in front of a number dialled with that many digits.")
        }

        // ---- SIM -----------------------------------------------------------

        FormGroup {
            title: qsTr("SIM")

            LabelAndValue {
                label: qsTr("Network")
                value: telephonyManager ? (telephonyManager.networkName || qsTr("No service")) : ""
            }
            LabelAndValue {
                label: qsTr("Signal")
                value: telephonyManager ? (telephonyManager.signalStrength + "%") : ""
            }
        }
        Button {
            width: parent.width
            text: qsTr("Change SIM Card PIN")
            onClicked: prefsPage._startPinChange()
        }
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

        // Over the header too: a Page puts what it holds below the header
        parent: prefsPage
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

        parent: prefsPage
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

        parent: prefsPage
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
