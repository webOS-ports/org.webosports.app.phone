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
import "../model"

QtObject {
    property Contact john: Contact{displayLabel: "John Smith"}
    property Contact steve: Contact{displayLabel: "Steve Brown"}
    property Contact tom: Contact{displayLabel: "Tom Slater"}
    property Contact voiceMail: Contact{displayLabel: "Voicemail"}

    function personByPhoneNumber(remoteUid){
        console.log("Looking up Contact for remoteID: " + remoteUid)
        switch(remoteUid){
        case "1234567890":
            return john
        case "235892382":
            return steve
        case "81235892382":
            return tom
        case "443":
            return voiceMail
        default:
            return null
        }

    }

}
