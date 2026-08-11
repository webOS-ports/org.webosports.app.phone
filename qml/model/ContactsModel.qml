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

import LunaNext.Common 0.1

import LuneOS.Service 1.0
import LuneOS.Telephony 1.0

Db8Model {
    id: db8model

    kind: "com.palm.person:1"
    watch: true
    query: {
        "orderBy": "sortKey"
    }

    property string countryCode

    Component.onCompleted: {
        if(db8model.setTestDataFile) {
            db8model.setTestDataFile(Qt.resolvedUrl("../test/persons.json"));
        }
    }

    function getPhoneNumberTypeStr(phoneNumberType)
    {
        return LibPhoneNumber.getPhoneNumberTypeStr(phoneNumberType);
    }

    /// Phone numbers of a person, as a plain array regardless of whether the
    /// record came from db8 or from the test data file.
    function phoneNumbersOf(person)
    {
        if (!person || !person.phoneNumbers) return [];

        var list = person.phoneNumbers;
        var count = (typeof list.length !== 'undefined') ? list.length : list.count;
        var result = [];
        for (var i = 0; i < count; ++i)
            result.push(Array.isArray(list) ? list[i] : list.get(i));

        return result;
    }

    /**
     * Contacts the user is likely to mean while typing on the dialpad: those
     * with a number starting with the digits typed so far, plus -- for the
     * letters on the dialpad keys -- those whose name starts with the same
     * text. This is the type-ahead the legacy ContactLookup scene provided.
     */
    function matchByNumberPrefix(prefix, limit)
    {
        var digits = String(prefix).replace(/[^0-9+]/g, '');
        if (digits.length === 0) return [];

        var maximum = limit || 20;
        var matches = [];

        for (var i = 0; i < db8model.count && matches.length < maximum; ++i) {
            var person = db8model.get(i);
            var numbers = phoneNumbersOf(person);

            for (var j = 0; j < numbers.length; ++j) {
                var value = String(numbers[j].value || "").replace(/[^0-9+]/g, '');
                // Match on the start of the number, and also on the national
                // part so that typing a local number finds a stored +316... one.
                if (value.indexOf(digits) === 0 ||
                    value.replace(/^\+[0-9]{1,3}/, '').indexOf(digits.replace(/^0/, '')) === 0) {
                    matches.push({ person: person, phoneNumber: numbers[j] });
                    break;
                }
            }
        }

        return matches;
    }

    /// Contacts whose display name contains `text`, for the contact lookup list.
    function matchByName(text, limit)
    {
        var needle = String(text).toLowerCase().trim();
        if (needle.length === 0) return [];

        var maximum = limit || 50;
        var matches = [];

        for (var i = 0; i < db8model.count && matches.length < maximum; ++i) {
            var person = db8model.get(i);
            var haystack = [person.nickname,
                            person.name ? person.name.givenName : "",
                            person.name ? person.name.familyName : ""]
                               .join(" ").toLowerCase();

            if (haystack.indexOf(needle) >= 0)
                matches.push({ person: person, phoneNumber: null });
        }

        return matches;
    }

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

    function personByNormalizedPhoneNumber(normalizedPhoneNumber)
    {
        // in legacy phone app, this search was done by normalizing the phone
        // number _without_ the area, country or prefix codes.
        // only the extension and the national number are taken into account.

        var strippedNormalizedPhoneNumber = normalizedPhoneNumber.split("-", 2).join("-");

        console.log("Looking up contacts for normalized phone number: " + normalizedPhoneNumber);
        for( var i=0; i<db8model.count; ++i ) {
            var person = db8model.get(i);
            var nbPhoneNunmbers = (typeof person.phoneNumbers.length !== 'undefined') ? person.phoneNumbers.length : person.phoneNumbers.count
            for( var j=0; j<nbPhoneNunmbers; ++j ) {
                var personPhoneNumber = Array.isArray(person.phoneNumbers) ? person.phoneNumbers[j] : person.phoneNumbers.get(j);
                if( personPhoneNumber.normalizedValue.substr(0, strippedNormalizedPhoneNumber.length) === strippedNormalizedPhoneNumber ) {
                    console.log(" ... found " + person.nickname);
                    return { foundPerson: person, foundPhoneNumber: personPhoneNumber };
                }
            }
        }

        console.log(" ... no contact found.");
        return null;
    }

    function personByPhoneNumber(phoneNumber)
    {
        return personByNormalizedPhoneNumber(LibPhoneNumber.normalizePhoneNumber(phoneNumber, db8model.countryCode));
    }
}
