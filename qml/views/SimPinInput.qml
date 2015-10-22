import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import MeeGo.QOfono 0.2
import "../services/PinTypes.js" as PinTypes
import LunaNext.Common 0.1

Item {
    id: simPinInput

    property OfonoSimManager simManager
    property int requestedPinType: 0
    property bool retrying: false
    property alias pin: pinEntry.text

    signal pinEntered
    signal canceled

    function clear() {
        pin = "";
    }

    function requestNewPin() {
        _enteringNewPin = true;
        title.text = "Enter new PIN";
        clear();
    }

    property bool _enteringNewPin: false
    property string _currentPinType: _enteringNewPin && simManager.isPukType(requestedPinType) ?
                                        simManager.pukToPin(requestedPinType) : requestedPinType
    property int _minimumPinLength: simManager.minimumPinLength(_currentPinType)
    property int _maximumPinLength: simManager.maximumPinLength(_currentPinType)
    property int _pinRetries: (simPinInput.requestedPinType !== PinTypes.NoPin) ?
                                  simManager.pinRetries[simPinInput.requestedPinType] : 0

    property string _newPin

    ColumnLayout{
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Units.gu(2)
        height: Units.gu(8)

        Label {
            id: title
            font.pixelSize: FontUtils.sizeToPixels("large")
            color: phoneUiAppTheme.headerTitle
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                switch (requestedPinType) {
                case PinTypes.SimPin:
                    return retrying ? "Incorrect PIN code" : "Enter PIN code";
                case PinTypes.SimPuk:
                    return retrying ? "Incorrect PUK code" : "Enter PUK code";
                default:
                    break;
                }

                return "";
            }
        }

        Label {
            id: warning
            color: phoneUiAppTheme.headerTitle
            font.pixelSize: FontUtils.sizeToPixels("medium")
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (_enteringNewPin)
                    return "";

                switch (requestedPinType) {
                case PinTypes.SimPin:
                    if (isNaN(_pinRetries) || _pinRetries === 0)
                        return "";
                    return _pinRetries === 1 ? "Only 1 attempt left. If this goes wrong your SIM will locked and you will need a PUK code to unlock." :
                                           "" + _pinRetries + "attempts left";
                case PinTypes.SimPuk:
                    if (_pinRetries === 0)
                        return "";
                    return _pinRetries === 1 ? "Only 1 attempt left. If this goes wrong your SIM card will be permanently blocked." :
                                    "" + _pinRetries + "attempts left. Ask your network service provider for the PUK code";
                default:
                    break;
                }

                return "";
            }
        }
    }

    NumberEntry {
        id: pinEntry

        width:parent.width
        height: Units.gu(6)
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        textColor: phoneUiAppTheme.foregroundColor
        echoMode: TextInput.Password
        isPhoneNumber: false
    }

    NumPad {
        id: keyboard

        anchors {
            left: parent.left
            right: parent.right
            top: pinEntry.bottom
            bottom: cancelButton.bottom
            topMargin: Units.gu(2)
        }

        mode:'sim'

        onKeyPressed: {
            if (pinEntry.text.length === _maximumPinLength)
                return;
            pinEntry.insert(label);
        }
    }

    PinInputButton {
        id: cancelButton

        width: parent.width / 3
        height: Units.gu(5)

        text: "Cancel"

        anchors.left: parent.left
        anchors.leftMargin: Units.gu(2)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: height / 3
        anchors.topMargin: height / 4

        onClicked: {
            simPinInput.canceled();
        }
    }

    PinInputButton {
        id: okButton

        width: parent.width / 3
        height: Units.gu(5)

        text: "Enter"

        anchors.right: parent.right
        anchors.rightMargin: Units.gu(2)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: height / 3
        anchors.topMargin: height / 4

        onClicked: {
            if (pinEntry.text.length < simManager.minimumPinLength(requestedPinType) &&
                pinEntry.text.length > simManager.maximumPinLength(requestedPinType))
                return;

            if (_enteringNewPin) {
                if (_newPin === "") {
                    title.text = "Enter new PIN again";
                    warning.text = "";
                    _newPin = pin;
                    clear();
                }
                else {
                    if (_newPin === pin) {
                        simPinInput.pinEntered();
                        _newPin = "";
                    }
                    else {
                        title.text = "Enter new PIN";
                        warning.title = "PIN doesn't match";
                        _newPin = "";
                        clear();
                    }
                }
            }
            else {
                simPinInput.pinEntered();
            }
        }
    }
}
