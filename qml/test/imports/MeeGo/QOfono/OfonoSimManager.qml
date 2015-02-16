import QtQuick 2.0
import "."

Item {
    id: ofonoSimManager

    property string modemPath
    property int pinRequired: 1
    property int pinRetries: 3
    property string subscriberIdentity: ""
    property bool present: true

    signal enterPinComplete(int error, string errorString)
    signal resetPinComplete(int error, string errorString)

    function minimumPinLength(pinType) {
        return 4;
    }

    function maximumPinLength(pinType) {
        return 4;
    }

    function isPukType(pinType) {
        return false;
    }

    function enterPin(pinType, pin) {
        enterPinComplete(0, "");
    }

    function resetPin(pinType, puk, pin) {
        resetPinComplete(0, "");
    }
}
