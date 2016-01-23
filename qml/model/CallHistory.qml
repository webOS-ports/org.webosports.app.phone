/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
  ///// for a callgroup:
        "properties": {
            "type": {
                "type": "string",
                "enum": ["all","missed"],
                "description": "Type of grouping. 'all' contains every phonecall and 'missed' is only where phonecall.type = 'missed'"
            },
            "timestamp": {
                "type": "integer",
                "description": "Start time of the most recent phone call in ms timestamp."
            },
            "callcount": {
                "type": "integer",
                "description": "Cached value for performance. Number of calls associated with this group.",
            },
            "recentcall_address": {
                "type": "object",
                "description": "Cached value for performance. Object with 'service' and 'addr' keys. It's the 'remote'
                                address (phone number or IM) of the recipient most recent call associated with this group."
            },
            "recentcall_type": {
                "type": "string",
                "description": "Cached value for performance. Type of phone call of most recent call associated with this group."
            }
        }
*/

Db8Model {
    id: db8model

    property bool showOnlyMissed: false;

    kind: "com.palm.phonecallgroup:1"
    watch: true
    query: {
        "where": [
            { "prop": "type", "op": "=", "val": showOnlyMissed ? "missed" : "all" }
        ],
        "orderBy": "timestamp", "desc": true
    }

    Component.onCompleted: {
        if(db8model.setTestDataFile) {
            db8model.setTestDataFile(Qt.resolvedUrl("../test/phonecallgroup.json"));
        }
    }

    // Surveiller VoiceCallMgrWrapper
    //  onEndingCall --> ajouter l'appel
    //  Considérer voiceCall.startedAt, et faire une recherche dans les callGroups sur
    //    - soit les timestamps de la même journée et de la même personne
    //  --> si le résultat contient qqch on prend le plus récent (il ne devrait y en avoir qu'un !), sinon on en créé un nouveau
    function addEndedCall(endedVoiceCall) {
        // In all cases, a call item must be added
    }
}

