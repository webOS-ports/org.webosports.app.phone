import QtQuick 2.0

/**
 * Mock implementation of Ofono
 *
 * https://github.com/intgr/ofono/blob/master/doc/sim-api.txt
 */
QtObject{

    property bool present: true
    property string subscriberIdentity: "1234-5678-9012-3456"
    property string mobileCountryCode: "UK"
    property string mobileNetworkCode: "Vodaphone"
    property string pinRequired: "none"
    property int pinRetry: 3

    function changePin(type, oldPin, newPin){

    }

    function enterPin(type, pin) {

    }

    function resetPin(type, puk, newpin){

    }

    function lockPin(type, pin){

    }

    function unlockPin(type, pin){
        if(type === "pin" && pin === "111"){
            console.log("SIM PIN Unlocked")
            pinRetry = 3
            return true
        }else{
            console.log("Invalid PIN")
            --pinRetry
            return false
        }
    }

    function retries(){
        return {pin: pinRetry}
    }


}

