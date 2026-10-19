import QtQuick 2.0
import QtQuick.Controls 2.2

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
import LunaNext.Common 0.1
import LuneOS.Forms 1.0
import LuneOS.System 1.0

import "../services"
import "../services/CallMessages.js" as CallMessages
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * Phone preferences, laid out as the legacy shared/phoneprefs scene was:
 * PHONE NUMBER, CALLS, DOMESTIC and INTERNATIONAL CALLS, VOICEMAIL NUMBER,
 * DIALING SHORTCUTS and SECURITY, in that order, with the same controls.
 * Left out is what has nothing behind it on LuneOS: contact matches while
 * typing, International Dialing, DTMF length, PRL, world phone, restricted
 * dialing, TTY/HAC and the network settings. Call barring, which the legacy
 * scene reached only through MMI codes, keeps a group at the end.
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
    property CallTransports callTransports

    signal closed();

    // Done sits at the foot, as in every webOS preferences scene
    footer: DoneBar { onClicked: prefsPage.closed() }

    header: AppHeader {
        height: Units.gu(7.5)
        title: qsTr("Phone Preferences")
        icon: Qt.resolvedUrl("../../icon.png")
        compact: width < Units.gu(50)
    }

    // Why the network's settings are not there: "Reading from network" with
    // a spinner while oFono asks, or what stops it from asking at all
    component StatusRow: Item {
        property alias text: statusLabel.text
        property bool busy: false
        width: parent ? parent.width : implicitWidth
        height: Units.gu(6)
        Label {
            id: statusLabel
            anchors.left: parent.left
            anchors.right: spinner.left
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: Colors.secondaryText
            font.pixelSize: FontUtils.sizeToPixels("16pt")
        }
        BusyIndicator {
            id: spinner
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Units.gu(3.5)
            height: width
            visible: parent.busy
            running: parent.visible && parent.busy
        }
    }

    // Without a SIM, or with the radio off, oFono never reads these from the
    // network: say so instead of waiting for ever
    readonly property bool _noSim: !telephonyManager || !telephonyManager.present
    readonly property bool _offline: !_noSim && !telephonyManager.radioOnline
    readonly property string _unavailableText: _noSim ? qsTr("No SIM card")
                                             : _offline ? qsTr("No network connection") : ""

    // A row that does something when tapped ("Lock SIM Card", "+ Add a number")
    component ActionRow: ItemDelegate {
        width: parent ? parent.width : implicitWidth
        height: Units.gu(6)
        leftPadding: 0
        font.pixelSize: FontUtils.sizeToPixels("16pt")
    }

    // A whole-row number field (the forwarding and voicemail numbers), which
    // reports a change once the user is done with it
    component NumberRow: Item {
        id: numberRow
        property alias text: numberField.text
        property alias placeholderText: numberField.placeholderText
        property bool _changed: false
        signal committed(string text)
        function focusField() { numberField.forceActiveFocus(); }

        width: parent ? parent.width : implicitWidth
        height: Units.gu(6)
        FormTextField {
            id: numberField
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Units.gu(5)
            font.pixelSize: FontUtils.sizeToPixels("16pt")
            inputMethodHints: Qt.ImhDialableCharactersOnly | Qt.ImhNoPredictiveText
            onTextEdited: numberRow._changed = true
            onEditingFinished: {
                if (!numberRow._changed)
                    return;
                numberRow._changed = false;
                numberRow.committed(text);
            }
        }
    }

    property bool _forwardOpen: false
    readonly property bool _forwarding: !!supplementaryServices
                                        && supplementaryServices.callForwardingUnconditional.length > 0
    readonly property bool _forwardingShown: _forwardOpen || _forwarding
    readonly property bool _callerIdShown: !!supplementaryServices && supplementaryServices.hideCallerId !== "enabled"
    readonly property bool _callWaitingShown: !!supplementaryServices && supplementaryServices.callWaiting === "enabled"

    // Puts a switch back on its binding when the network turned a change
    // down (the user's tap had moved it off the binding's value)
    function _rebind(row, shown) {
        row.checked = Qt.binding(shown);
    }

    Connections {
        target: prefsPage.supplementaryServices
        function onForwardingSet(success) {
            if (!success) {
                prefsPage._forwardOpen = false;
                prefsPage._rebind(forwardingSwitch, () => prefsPage._forwardingShown);
                errorDialog.show(qsTr("Call forwarding could not be set. You need a network connection to your wireless service provider to change it."));
            }
        }
        function onCallerIdSet(success) {
            if (!success) {
                prefsPage._rebind(callerIdSwitch, () => prefsPage._callerIdShown);
                errorDialog.show(qsTr("Caller ID could not be set."));
            }
        }
        function onCallWaitingSet(success) {
            if (!success) {
                prefsPage._rebind(callWaitingSwitch, () => prefsPage._callWaitingShown);
                errorDialog.show(qsTr("Call waiting could not be set."));
            }
        }
    }

    // The preferred service for domestic and international calls, which
    // DialProxy follows
    SystemPreferences {
        id: servicePrefs
        clientName: "org.webosports.app.phone"
        keys: ["phonePreferredDomesticPhoneService", "phonePreferredIntlPhoneService"]
    }

    readonly property var _serviceValues: {
        var values = [];
        if (callTransports) {
            if (callTransports.hasCellular)
                values.push(callTransports.cellularTransport);
            values = values.concat(callTransports.voipTransportIds());
        }
        values.push("none");
        return values;
    }
    readonly property var _serviceLabels: _serviceValues.map(function(id) {
        if (id === "none")
            return qsTr("Always Ask");
        if (callTransports && id === callTransports.cellularTransport)
            return (telephonyManager && telephonyManager.networkName) ? telephonyManager.networkName
                                                                       : qsTr("Carrier Wireless");
        return callTransports ? callTransports.labelFor(id) : id;
    })

    readonly property string _phoneNumber: {
        var numbers = telephonyManager ? telephonyManager.subscriberNumbers : [];
        if (!numbers || numbers.length === 0)
            return "";
        return PhoneNumberUtils.formatForDisplay(numbers[0],
                                                 voiceCallMgrWrapper ? voiceCallMgrWrapper.countryCode : undefined);
    }

    SettingsPageContent {
        // ---- Phone number --------------------------------------------------

        FormGroup {
            title: qsTr("Phone Number")
            visible: prefsPage._phoneNumber.length > 0

            LabelAndValue {
                label: prefsPage._phoneNumber
            }
        }

        // ---- Calls ---------------------------------------------------------

        FormGroup {
            title: qsTr("Calls")

            StatusRow {
                visible: prefsPage._unavailableText.length > 0
                text: prefsPage._unavailableText
            }
            StatusRow {
                visible: prefsPage._unavailableText.length === 0
                         && (!prefsPage.supplementaryServices || !prefsPage.supplementaryServices.forwardingReady)
                text: qsTr("Reading from network")
                busy: true
            }
            LabelAndSwitch {
                id: forwardingSwitch
                visible: prefsPage._unavailableText.length === 0
                         && !!prefsPage.supplementaryServices && prefsPage.supplementaryServices.forwardingReady
                label: qsTr("Call Forwarding")
                checked: prefsPage._forwardingShown
                onToggled: {
                    if (checked) {
                        // On shows where the number goes; it is set once
                        // there is one
                        prefsPage._forwardOpen = true;
                        if (forwardNumber.text.length > 0)
                            prefsPage.supplementaryServices.callForwardingUnconditional = forwardNumber.text;
                        else
                            forwardNumber.focusField();
                    } else {
                        prefsPage._forwardOpen = false;
                        if (prefsPage._forwarding)
                            prefsPage.supplementaryServices.callForwardingUnconditional = "";
                    }
                }
            }
            NumberRow {
                id: forwardNumber
                visible: forwardingSwitch.visible && forwardingSwitch.checked
                placeholderText: qsTr("Enter Number")
                text: prefsPage.supplementaryServices ? prefsPage.supplementaryServices.callForwardingUnconditional : ""
                onCommitted: (number) => {
                    if (number.length > 0)
                        prefsPage.supplementaryServices.callForwardingUnconditional = number;
                }
            }

            StatusRow {
                visible: prefsPage._unavailableText.length === 0
                         && (!prefsPage.supplementaryServices || !prefsPage.supplementaryServices.callSettingsReady)
                text: qsTr("Reading from network")
                busy: true
            }
            LabelAndSwitch {
                id: callerIdSwitch
                visible: prefsPage._unavailableText.length === 0
                         && !!prefsPage.supplementaryServices && prefsPage.supplementaryServices.callSettingsReady
                label: qsTr("Show My Caller ID")
                // "default" leaves it to the network, which shows it
                checked: prefsPage._callerIdShown
                onToggled: prefsPage.supplementaryServices.hideCallerId = checked ? "disabled" : "enabled"
            }
            LabelAndSwitch {
                id: callWaitingSwitch
                visible: callerIdSwitch.visible
                label: qsTr("Call Waiting")
                checked: prefsPage._callWaitingShown
                onToggled: prefsPage.supplementaryServices.callWaiting = checked ? "enabled" : "disabled"
            }
        }

        // ---- Domestic and international calls ------------------------------
        // Only once there is a choice: a calling account besides the SIM

        FormGroup {
            title: qsTr("Domestic Calls")
            visible: !!prefsPage.callTransports && prefsPage.callTransports.hasVoipAccount

            LabelAndSelector {
                label: qsTr("Use")
                values: prefsPage._serviceValues
                model: prefsPage._serviceLabels
                value: servicePrefs.value("phonePreferredDomesticPhoneService", "none")
                onChosen: (v) => servicePrefs.set("phonePreferredDomesticPhoneService", v)
            }
        }

        FormGroup {
            title: qsTr("International Calls")
            visible: !!prefsPage.callTransports && prefsPage.callTransports.hasVoipAccount

            LabelAndSelector {
                label: qsTr("Use")
                values: prefsPage._serviceValues
                model: prefsPage._serviceLabels
                value: servicePrefs.value("phonePreferredIntlPhoneService", "none")
                onChosen: (v) => servicePrefs.set("phonePreferredIntlPhoneService", v)
            }
        }

        // ---- Voicemail number ----------------------------------------------

        FormGroup {
            title: qsTr("Voicemail Number")

            NumberRow {
                // The number is the SIM's: with none there is nothing to wait for
                enabled: prefsPage._unavailableText.length === 0
                placeholderText: prefsPage._unavailableText.length > 0 ? prefsPage._unavailableText
                               : (telephonyManager && !telephonyManager.messageWaitingObject.ready)
                                 ? qsTr("Waiting for network") : qsTr("Enter Number")
                text: telephonyManager ? telephonyManager.voicemailNumber : ""
                onCommitted: (number) => telephonyManager.messageWaitingObject.voicemailMailboxNumber = number
            }
        }

        // ---- Dialing shortcuts ---------------------------------------------

        FormGroup {
            title: qsTr("Dialing Shortcuts")
            visible: !!prefsPage.dialingShortcuts

            Repeater {
                model: prefsPage.dialingShortcuts
                       ? prefsPage.dialingShortcuts.supportedLengths.filter(function(length) {
                             return prefsPage.dialingShortcuts.prefixFor(length).length > 0;
                         })
                       : []

                // Swipe it aside to delete it, as the legacy list did
                delegate: SwipeDelegate {
                    id: shortcutRow
                    required property var modelData

                    width: parent ? parent.width : implicitWidth
                    height: Units.gu(6)
                    leftPadding: 0
                    rightPadding: 0

                    contentItem: Item {
                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: FontUtils.sizeToPixels("16pt")
                            text: prefsPage.dialingShortcuts.prefixFor(shortcutRow.modelData)
                                  + "-" + "X".repeat(shortcutRow.modelData)
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: FontUtils.sizeToPixels("16pt")
                            color: "#1f75bf"
                            text: (shortcutRow.modelData === 1 ? qsTr("1 digit") : qsTr("%1 digits").arg(shortcutRow.modelData))
                        }
                    }

                    // The style draws the red confirm behind the row
                    LuneOSSwipeDelegate.confirmText: qsTr("Delete")
                    LuneOSSwipeDelegate.onConfirmed: prefsPage.dialingShortcuts.setPrefix(shortcutRow.modelData, "")
                    background: Item { }
                }
            }

            ActionRow {
                text: qsTr("+ Add a number")
                onClicked: shortcutEditorLoader.active = true
            }
        }

        // ---- Security ------------------------------------------------------

        FormGroup {
            title: qsTr("Security")

            ActionRow {
                text: !prefsPage.telephonyManager ? ""
                      : prefsPage.telephonyManager.pukRequired ? qsTr("PUK Required")
                      : prefsPage.telephonyManager.simPinLocked ? qsTr("Unlock SIM Card")
                      : qsTr("Lock SIM Card")
                enabled: !!prefsPage.telephonyManager && prefsPage.telephonyManager.present
                         && !prefsPage.telephonyManager.pukRequired
                onClicked: prefsPage._startSimLock()
            }
            ActionRow {
                visible: !!prefsPage.telephonyManager && prefsPage.telephonyManager.simPinLocked
                         && !prefsPage.telephonyManager.pukRequired
                text: qsTr("Change SIM Card PIN")
                onClicked: prefsPage._startPinChange()
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
    }

    Dialog {
        id: errorDialog
        function show(message) {
            errorText.text = message;
            open();
        }
        modal: true
        title: qsTr("Phone Preferences")
        standardButtons: Dialog.Ok
        Label {
            id: errorText
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    /*
     * Adding a dialing shortcut: the legacy scene's own page. WHEN I DIAL a
     * number of so many digits, USE THIS DIALING PREFIX; Done stays off until
     * there is a prefix.
     */
    Loader {
        id: shortcutEditorLoader

        parent: prefsPage
        anchors.fill: parent
        active: false
        z: 1

        sourceComponent: AppPage {
            id: shortcutEditor

            header: AppHeader {
                height: Units.gu(7.5)
                title: qsTr("Dialing Shortcuts")
                icon: Qt.resolvedUrl("../../icon.png")
                compact: width < Units.gu(50)
            }
            footer: DoneBar {
                enabled: prefixField.text.length > 0
                onClicked: {
                    prefsPage.dialingShortcuts.setPrefix(lengthSelector.value, prefixField.text);
                    shortcutEditorLoader.active = false;
                }
            }

            // The back gesture leaves without adding anything
            Keys.onReleased: (event) => {
                if (event.key === Qt.Key_Escape) {
                    shortcutEditorLoader.active = false;
                    event.accepted = true;
                }
            }
            Component.onCompleted: forceActiveFocus()

            SettingsPageContent {
                FormGroup {
                    title: qsTr("When I Dial")
                    LabelAndSelector {
                        id: lengthSelector
                        label: qsTr("Number length")
                        values: prefsPage.dialingShortcuts.supportedLengths
                        model: values.map(function(length) { return (length === 1 ? qsTr("1 digit") : qsTr("%1 digits").arg(length)); })
                        value: values[0]
                    }
                }
                FormGroup {
                    title: qsTr("Use This Dialing Prefix")
                    NumberRow {
                        id: prefixField
                        placeholderText: qsTr("Enter Number")
                    }
                }
                ExplanationText {
                    width: parent.width
                    text: qsTr("These shortcuts are digits added to the beginning of the number you are attempting to call. Example: (510) 123-xxxx")
                }
            }
        }
    }

    /*
     * Locking and unlocking the SIM: SecurityScene's "Lock SIM Card" asked for
     * the PIN on the same card the PIN change uses.
     */
    Loader {
        id: simLockLoader

        parent: prefsPage
        anchors.fill: parent
        active: false
        z: 1

        sourceComponent: SimPinCard {
            appTheme: prefsPage.appTheme

            title: prefsPage._simLockTitle
            subText: prefsPage._simLockSubText
            maximumLength: 8

            onAccepted: prefsPage._simLockAccepted(pin)
            onCanceled: simLockLoader.active = false
            onEmergencyCallRequested: emergencyLoader.active = true
            onKeyed: prefsPage._clearSimLockError()
        }
    }

    property string _simLockTitle: ""
    property string _simLockSubText: ""
    property bool _simLockInError: false
    property bool _simLocking: false

    function _resetSimLock() {
        _simLockTitle = qsTr("Enter PIN");
        _simLockSubText = _simLocking ? qsTr("Enter PIN to lock the SIM card")
                                      : qsTr("Enter PIN to unlock the SIM card");
        _simLockInError = false;
        if (simLockLoader.item)
            simLockLoader.item.clear();
    }

    function _startSimLock() {
        _simLocking = !telephonyManager.simPinLocked;
        _resetSimLock();
        simLockLoader.active = true;
    }

    function _clearSimLockError() {
        if (_simLockInError)
            _resetSimLock();
    }

    function _simLockAccepted(entered) {
        if (entered.length === 0) {
            simLockLoader.active = false;
            return;
        }
        if (_simLocking)
            supplementaryServices.lockSimPin(entered);
        else
            supplementaryServices.unlockSimPin(entered);
    }

    Connections {
        target: simLockLoader.active ? prefsPage.supplementaryServices : null

        function onCompleted(success, message) {
            if (success) {
                simLockLoader.active = false;
                return;
            }
            prefsPage._resetSimLock();
            prefsPage._simLockTitle = qsTr("PIN incorrect");
            prefsPage._simLockSubText = message;
            prefsPage._simLockInError = true;
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
