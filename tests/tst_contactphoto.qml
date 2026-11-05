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

import QtQuick 2.0
import QtTest 1.2

import "../qml/model"

/**
 * The picture a call shows for a contact.
 *
 * On the device every person carries a photos record, and one without a
 * photo has it with every path empty. Taking listPhotoPath from that put an
 * empty source on the call screen: a blank frame, not the unknown-caller
 * stand-in (sargo, 2026-11-04, a Telegram call from a contact with no photo).
 */
Item {
    id: root

    property var found: null

    Component {
        id: contactsComponent
        ContactsModel {
            function personByNormalizedPhoneNumber(normalizedPhoneNumber) {
                return root.found;
            }
        }
    }

    Component {
        id: contactComponent
        Contact {}
    }

    function person(photos) {
        return { foundPerson: { _id: "p1", nickname: "", photos: photos,
                                name: { givenName: "Ann", familyName: "Example" } },
                 foundPhoneNumber: null };
    }

    function emptyPhotos() {
        return { accountId: "", bigPhotoId: "", bigPhotoPath: "", contactId: "",
                 listPhotoPath: "", listPhotoSource: "", squarePhotoId: "", squarePhotoPath: "" };
    }

    TestCase {
        name: "ContactPhoto"

        function contactFor(found) {
            root.found = found;
            var contacts = createTemporaryObject(contactsComponent, root);
            verify(contacts !== null, "the contacts model did not load");
            var contact = createTemporaryObject(contactComponent, root, { contactsModel: contacts });
            verify(contact !== null, "the contact did not load");
            contact.lineId = "+31201234567";
            return contact;
        }

        function test_aPersonWithoutAPhotoKeepsTheStandIn() {
            var contact = contactFor(root.person(root.emptyPhotos()));
            compare(contact.personId, "p1", "the person was not matched");
            compare(contact.avatarPath, contact._genericAvatarPath);
            verify(!contact.hasPhoto);
        }

        function test_aPersonsPhotoIsShown() {
            var photos = root.emptyPhotos();
            photos.listPhotoPath = "/var/file-cache/contactphoto/x/example.jpg";
            var contact = contactFor(root.person(photos));
            compare(contact.avatarPath, "/var/file-cache/contactphoto/x/example.jpg");
            verify(contact.hasPhoto);
        }

        function test_aPersonWithNoPhotosRecordKeepsTheStandIn() {
            var contact = contactFor(root.person(undefined));
            compare(contact.avatarPath, contact._genericAvatarPath);
        }

        function test_aStrangerKeepsTheStandIn() {
            var contact = contactFor(null);
            compare(contact.personId, "");
            compare(contact.avatarPath, contact._genericAvatarPath);
        }
    }
}
