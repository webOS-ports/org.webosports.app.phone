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
import LuneOS.Telephony 1.0

import "../services/IncomingCallsService.js" as IncomingCallsService

/*
  DB8 history definition:
  ///// for a callgroup:
        "properties": {
            "type": {
                "type": "string",
                "enum": ["all","missed"],
                "description": "Type of grouping. 'all' contains every phonecall and 'missed' is only where phonecall.type = 'missed'"
            },
            "groupId": {
                "type": "string",
                "description": "Unique identifier which can be built from a phone call description."
            },
            "timestamp": {
                "type": "integer",
                "description": "Start time of the most recent phone call in ms timestamp."
            },
            "timestamp_day": {
                    "type": "integer",
                    "description": "Start time of the most recent phone call in days timestamp. Its value is Math.floor(timestamp/86400000)."
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
    property ContactsModel personListModel;

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

    property Connections _personsDbConnections: Connections {
        target: personListModel
        function onModelReset() {
            _updatePersonsInHistory();
        }
    }

    function _updatePersonsInHistory() {
        // This method does two updates:
        //  - ensure that the recentcall_address.personId still exists for every item
        //  - associate recentcall_address with a personId when the contact can be found
        var mergeActions = [];
        var callGroup = null;
        var i = 0;
        // first phase: fill missing personId
        for(i=0; i<db8model.count; ++i) {
            callGroup = db8model.get(i);
            if(callGroup && callGroup.recentcall_address && !callGroup.recentcall_address.personId) {
                var correspondingPersonId = personListModel.personByNormalizedPhoneNumber(callGroup.recentcall_address.normalizedAddr);
                if(correspondingPersonId && correspondingPersonId.foundPerson) {
                    // this number is now associated to a person, so fill in the fields
                    callGroup.recentcall_address.personId = correspondingPersonId.foundPerson._id;
                    callGroup.recentcall_address.name = (correspondingPersonId.foundPerson.nickname === "") ? (correspondingPersonId.foundPerson.name.givenName + " " + correspondingPersonId.foundPerson.name.familyName) : correspondingPersonId.foundPerson.nickname;
                    callGroup.recentcall_address.personFamilyName = correspondingPersonId.foundPerson.name.familyName;
                    callGroup.recentcall_address.personGivenName = correspondingPersonId.foundPerson.name.givenName;
                    if(correspondingPersonId.foundPhoneNumber) {
                        callGroup.recentcall_address.personAddressType = correspondingPersonId.foundPhoneNumber.type;
                    }
                    mergeActions.push({ "_id": callGroup._id, "recentcall_address": callGroup.recentcall_address });
                }
            }
        }
        // second phase: cleanup
        for(i=0; i<db8model.count; ++i) {
            callGroup = db8model.get(i);
            if(callGroup && callGroup.recentcall_address && callGroup.recentcall_address.personId) {
                if(!personListModel.personById(callGroup.recentcall_address.personId))
                {
                    // register a new action to cleanup this one
                    callGroup.recentcall_address.personId = null;
                    mergeActions.push({ "_id": callGroup._id, "recentcall_address": callGroup.recentcall_address });
                }
            }
        }
        // do the merge
        if(mergeActions.length>0) {
            __queryDB("merge", { objects: mergeActions }, function(result) {});
        }
    }

    function _buildCallGroupID(endedVoiceCall, person, startTime)
    {
        // We are looking for a group that is within the same day as endedVoiceCall, and corresponding to the same call.
        // But it's actually possible to build the id of that callgroup by hand:

        var callGroupID = "";

        // "com.palm.app.phone 1003.callgroup__ID_++IgDPYVSrGrr9+W_10/30/2013_all",
        // "com.palm.app.phone 1003.callgroup__PHONE_-00868448---_8/27/2013_all"
        //  <app identifier><.callgroup><_><_PHONE_ or _ID_><normalizedAddr or personId><_><dd/mm/yyyy><_><all or missed>

        var appId = Qt.application.name + " pid.callgroup";
        callGroupID += appId + "_";

        // we now need to know if the voicecall can be related to an existing personId in the db
        if( !person ) {
            callGroupID += "_PHONE_" + LibPhoneNumber.normalizePhoneNumber(endedVoiceCall.lineId, personListModel.countryCode) + "_";
        }
        else {
            callGroupID += "_ID_" + person._id + "_";
        }

        callGroupID += Qt.formatDate(startTime, "d/M/yyyy") + "_";

        return callGroupID;
    }

    // Surveiller VoiceCallMgrWrapper
    //  onEndingCall --> ajouter l'appel
    //  Considérer voiceCall.startedAt, et faire une recherche dans les callGroups sur
    //    - soit les timestamps de la même journée et de la même personne
    //  --> si le résultat contient qqch on prend le plus récent (il ne devrait y en avoir qu'un !), sinon on en créé un nouveau
    function addEndedCall(endedVoiceCall)
    {
        console.log("Call History: adding " + endedVoiceCall.lineId + " to history");
        var personMatchingNumber = personListModel.personByPhoneNumber(endedVoiceCall.lineId);
        var foundPerson = personMatchingNumber ? personMatchingNumber.foundPerson: null;
        var foundPhoneNumber = personMatchingNumber ? personMatchingNumber.foundPhoneNumber: null;

        var startTime = new Date();
        startTime.setSeconds(startTime.getSeconds() - endedVoiceCall.duration);

        // get the group ID of that call
        var callGroupID = _buildCallGroupID(endedVoiceCall, foundPerson, startTime);

        var actionForCall = IncomingCallsService.getActionForCall(endedVoiceCall.handlerId);

        var newCallItem = {
            _kind: "com.palm.phonecall:1",
            duration: endedVoiceCall.duration,
            groups: [ callGroupID+"all" ],
            timestamp: startTime.getTime(),
            timestampInSecs: Math.floor(startTime.getTime()/1000),
            to: []
        };
        if( actionForCall===IncomingCallsService.Missed ) newCallItem.groups.push(callGroupID+"missed");

        var normalizedLineId = LibPhoneNumber.normalizePhoneNumber(endedVoiceCall.lineId, personListModel.countryCode);

        var personDetails = {
            addr: endedVoiceCall.lineId,
            normalizedAddr: normalizedLineId,
            service: "com.palm.telephony"
        };
        if( foundPerson ) {
            personDetails.name = (foundPerson.nickname === "") ? (foundPerson.name.givenName + " " + foundPerson.name.familyName) : foundPerson.nickname;
            personDetails.personFamilyName = foundPerson.name.familyName;
            personDetails.personGivenName = foundPerson.name.givenName;
            personDetails.personId = foundPerson._id;
        }
        if( foundPhoneNumber ) {
            personDetails.personAddressType = foundPhoneNumber.type;
        }

        if( endedVoiceCall.isIncoming ) {
            newCallItem.from = personDetails;
            newCallItem.to.push({ addr: "", service: "com.palm.telephony" });

            if(actionForCall===IncomingCallsService.Missed) {
                newCallItem.type = "missed";
            }
            else if(actionForCall===IncomingCallsService.Ignored) {
                newCallItem.type = "ignored";
            }
            else {
                newCallItem.type = "incoming";
            }
        }
        else {
            newCallItem.from = { addr: "", service: "com.palm.telephony" };
            newCallItem.to.push(personDetails);
            newCallItem.type = "outgoing";
        }

        // In all cases, a call item must be added
        __queryDB('put', { objects: [ newCallItem ] }, function(result) {});

        function findResult_all(message) {
            var existingCallGroup = {
                callcount: 0
            }
            var action = "put";
            var result = JSON.parse(message.payload);
            if( result && result.results && result.results.length===1 ) {
                existingCallGroup = result.results[0];
                action = "merge";
            }
            __addOrUpdate(action, existingCallGroup, "all");
        }
        function findResult_missed(message) {
            var existingCallGroup = {
                callcount: 0
            }
            var action = "put";
            var result = JSON.parse(message.payload);
            if( result && result.results && result.results.length===1 ) {
                existingCallGroup = result.results[0];
                action = "merge";
            }
            __addOrUpdate(action, existingCallGroup, "merge");
        }

        // Also, the callgroup must be either created or updated
        function __addOrUpdate(action, existingCallGroup, callGroupType) {
            existingCallGroup.groupId = callGroupID + callGroupType;
            existingCallGroup._kind = 'com.palm.phonecallgroup:1';
            existingCallGroup.callcount++;
            existingCallGroup.recentcall_address = personDetails;
            existingCallGroup.recentcall_type = newCallItem.type;
            existingCallGroup.timestamp = newCallItem.timestamp;
            existingCallGroup.timestamp_day = Math.floor(newCallItem.timestamp/86400000);
            existingCallGroup.type = callGroupType;

            __queryDB(action, { objects: [ existingCallGroup ] }, function(result) {});
        }

        // add it to the database
        __queryDB('find', {query:
                      {from:"com.palm.phonecallgroup:1",
                       where: [ { prop: "groupId", op: "=", val: callGroupID+"all" } ],
                       limit:1}}, findResult_all);

        // if the called was missed add also the corresponding group to the database
        if( newCallItem.type === "missed" ) {
            __queryDB('find', {query:
                          {from:"com.palm.phonecallgroup:1",
                           where: [ { prop: "groupId", op: "=", val: callGroupID+"missed" } ],
                           limit:1}}, findResult_missed);
        }
    }


    property QtObject __ls2service: LunaService {
        id: __lunaNextLS2Service
        name: "org.webosports.app.phone"
    }
    function __handleDBError(message) {
        console.log("Could not fulfill DB operation : " + message)
    }
    function __queryDB(action, params, handleResultFct) {
        __lunaNextLS2Service.call("luna://com.palm.db/" + action, JSON.stringify(params),
                  handleResultFct, __handleDBError)
    }

}

