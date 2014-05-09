/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

