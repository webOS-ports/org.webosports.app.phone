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
import LuneOS.Service 1.0
import LuneOS.Application 1.0

Db8Model {
    id: db8model

    kind: "com.palm.person:1"
    watch: true
    query: {
        "orderBy": "sortKey"
    }

    Component.onCompleted: {
        if(db8model.setTestDataFile) {
            db8model.setTestDataFile(Qt.resolvedUrl("../test/persons.json"));
        }
    }

    function normalizePhoneNumber(phoneNumber)
    {

        return phoneNumber;
    }

    // this service is synchronous, which can be handy
    function personById(personId)
    {
        console.log("Looking up contacts for personId: " + personId);
        for( var i=0; i<db8model.count; ++i ) {
            var person = db8model.get(i);
            if( person._id === personId ) return person;
        }
        console.log(" ... no contact found.");
        return null;
    }

    // this service is synchronous, which can be handy
    function personByPhoneNumber(phoneNumber)
    {
        console.log("Looking up contacts for phone number: " + phoneNumber);
        for( var i=0; i<db8model.count; ++i ) {
            var person = db8model.get(i);
            for( var j=0; j<person.phoneNumbers.count; ++j ) {
                var personPhoneNumber = person.phoneNumbers.get(j);
                if( personPhoneNumber.value === phoneNumber ) {
                    console.log(" ... found " + person.nickname);
                    return person;
                }
            }
        }

        console.log(" ... no contact found.");
        return null;
    }
}
