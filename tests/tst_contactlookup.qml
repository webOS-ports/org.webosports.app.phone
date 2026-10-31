/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

pragma ComponentBehavior: Bound

import QtQuick 2.0
import QtQml
import QtTest 1.2

import "../qml/model"
import "../qml/services"

/**
 * Who a number belongs to, with records shaped as the device hands them out.
 *
 * The device's Db8Model is C++: get() answers a QVariant, so a person's
 * phoneNumbers reach QML as a QVariantList - the engine's array-like, for
 * which Array.isArray() is false and which has no get(). The stand-in model
 * hands out plain JS arrays, which hid that. Here every record is sent once
 * through C++ and back - into a QVariantMap property, Drag.mimeData, and out
 * again - so the lookup sees the same shapes it sees on the phone.
 */
Item {
    id: root

    /// Holds one record as a QVariantMap. Each record gets its own: what is
    /// read back stays tied to the property, and would change with it.
    Component {
        id: variantHolder
        Item {}
    }

    /// A person as the device's model hands one out.
    function asOnDevice(row) {
        var holder = variantHolder.createObject(root);
        holder.Drag.mimeData = { "record": row };
        return holder.Drag.mimeData.record;
    }

    Component {
        id: deviceContactsComponent
        ContactsModel {
            id: deviceContacts
            function get(index) {
                return root.asOnDevice(deviceContacts._rows[index]);
            }
        }
    }

    Component {
        id: managerComponent
        NotificationManager {}
    }

    TestCase {
        name: "ContactLookup"

        property var contacts: null

        function initTestCase() {
            contacts = deviceContactsComponent.createObject(root);
            verify(contacts !== null, "the contacts model did not load");
            tryVerify(function() { return contacts.count > 0; }, 5000, "no test contacts");
        }

        function cleanupTestCase() {
            if (contacts)
                contacts.destroy();
        }

        /// The premise: what get() hands out here is what the device's is.
        function test_theRecordsAreShapedAsOnTheDevice() {
            var person = contacts.get(0);
            verify(person.phoneNumbers.length > 0);
            verify(!Array.isArray(person.phoneNumbers), "phoneNumbers is a JS array");
            compare(typeof person.phoneNumbers.get, "undefined");
        }

        function test_aNumberFindsItsPerson() {
            var match = contacts.personByPhoneNumber("+420505521234");
            verify(match !== null, "nobody found");
            compare(match.foundPerson.nickname, "Mary Spetzler");
            compare(match.foundPhoneNumber.value, "+420505521234");
        }

        /// Not only the first number of a person counts.
        function test_aSecondNumberFindsItsPersonToo() {
            var match = contacts.personByPhoneNumber("+46677221234");
            verify(match !== null, "nobody found");
            compare(match.foundPerson.nickname, "Claire Meyer");
        }

        function test_aStrangersNumberFindsNobody() {
            compare(contacts.personByPhoneNumber("+31201234567"), null);
        }

        /// A withheld caller has no number; it is not the first contact's call.
        function test_noNumberFindsNobody() {
            compare(contacts.personByNormalizedPhoneNumber(""), null);
        }

        function test_phoneNumbersOfIsAPlainArray() {
            var mary = contacts.personByPhoneNumber("+420505521234").foundPerson;
            var numbers = contacts.phoneNumbersOf(mary);
            verify(Array.isArray(numbers));
            compare(numbers.length, 2);
            compare(numbers[1].value, "+46699051234");
        }

        /// The dialpad's type-ahead walks the same lists.
        function test_typeAheadFindsByNumber() {
            var matches = contacts.matchByNumberPrefix("+4205055", 20);
            compare(matches.length, 1);
            compare(matches[0].person.nickname, "Mary Spetzler");
        }

        /// The missed call's notification is titled with the caller's name.
        function test_aMissedCallIsNamedForTheCaller() {
            var manager = createTemporaryObject(managerComponent, root, { contacts: contacts });
            verify(manager !== null, "the notification manager did not load");
            compare(manager._displayNameFor("+420505521234"), "Mary Spetzler");
            // No nickname: the given and family names.
            compare(manager._displayNameFor("+46661871234"), "Bob Willer");
            // Nobody: no name, and the notification shows the number.
            compare(manager._displayNameFor("+31201234567"), "");
        }
    }
}
