/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import LuneOS.Application 1.0
import LuneOS.Service 1.0

/*
  DB8 history definition:
  ///// for one call:
    "properties": {
        "from": {
            "type": "object",
            "description": "Address call is originating from. Will be an account on this device
                            for type == outgoing. An object with keys 'addr', 'service', 'normalizedAddr' (for cleanup service),
                            and also 'personId' and 'name' if the entry is associated with a person.
                            More person metadata may also be present. Valid values for 'service' are currently 'skype' or 'phone'."
        },
        "to": {
            "type": "array",
            "description": "Address call of recipient. Will be an account on this device for type != outgoing.
                            An array with a single object with keys 'addr', 'service', 'normalizedAddr' (for cleanup service),
                            and also 'personId' and 'name' if the entry is associated with a person. Valid values for 'service' are
                            currently 'skype' or 'phone'."
        },
        "timestamp": {
            "type": "integer",
            "description": "Start time of the phone call in ms utc timestamp."
        },
        "type": {
            "type": "string",
            "enum": ["incoming", "outgoing", "missed", "ignored"],
            "description": "Type of call. Enum values are DBModels.PhoneCall.TYPES"
        },
        "timestampInSecs": {
            "type": "integer",
            "description": "WORKAROUND NOV-93332. Value is timestamp / 1000. This is for the Bluetooth service that can't yet read large numbers (like ms timestamps)."
        },
        "duration": {
            "type": "integer",
            "description": "Call duration in ms. Empty for type=missed|ignored.",
            "optional": true
        },
        "groups": {
            "type": ["array", "null"],
            "description": "Group ids this call is a member of"
        }
    }
*/

Db8Model {
    id: db8model

    property string callGroupId: ""

    kind: "com.palm.phonecall:1"
    watch: false
    query: {
        "where": [
            { "prop": "groups", "op": "=", "val": callGroupId }
        ],
        "orderBy": "timestamp", "desc": true
    }

    Component.onCompleted: {
        if(db8model.setTestDataFile) {
            db8model.setTestDataFile(Qt.resolvedUrl("../test/phonecall.json"));
        }
    }
}

