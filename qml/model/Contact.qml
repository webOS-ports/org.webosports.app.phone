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

import LunaNext.Common 0.1

import LuneOS.Telephony 1.0

QtObject {
    id: contactObj

    property ContactsModel contactsModel;
    property string lineId: "";

    property string avatarPath: _genericAvatarPath
    property string displayLabel: (nickname === "") ? (givenName + " " + familyName) : nickname;

    property string addr: "";

    property string normalizedAddr: "";
    property string nickname: "";
    property string familyName: "";
    property string givenName: "";
    property string personId: "";

    property string geoLocation: "Unknown"

    /*
     * The stand-in for a contact with no photo.
     *
     * A model has no theme to ask, so this is the one place outside the views
     * that has to work out which artwork set is in force for itself. The rule
     * is the same one main.qml picks the theme with.
     */
    readonly property string _genericAvatarPath:
        Qt.resolvedUrl(Settings.tabletUi ? '../views/images/tablet/contacts-unknown-icon-large.png'
                                         : '../views/images/phone/contacts-unknown-icon-large.png')

    onLineIdChanged: buildFromLineId()
    function buildFromLineId()
    {
        contactObj.reset();
        if(contactObj.lineId.length === 0) return;

        var normalizedLineId = LibPhoneNumber.normalizePhoneNumber(contactObj.lineId, contactsModel.countryCode);
        var person = contactsModel.personByNormalizedPhoneNumber(normalizedLineId);

        contactObj.addr = contactObj.lineId;
        contactObj.normalizedAddr = normalizedLineId;
        if( person && person.foundPerson ) {
            contactObj.nickname = person.foundPerson.nickname;
            contactObj.familyName = person.foundPerson.name.familyName;
            contactObj.givenName = person.foundPerson.name.givenName;
            contactObj.personId = person.foundPerson._id;
            if(person.foundPerson.photos) {
                contactObj.avatarPath = person.foundPerson.photos.listPhotoPath;
            }
        }

        LibPhoneNumber.getNumberGeolocation(contactObj.lineId, contactsModel.countryCode, contactObj.setTextFromGeoLocation);
    }

    function setTextFromGeoLocation(geoLocation) {
        if(geoLocation.parsed) {
            var location = geoLocation.location || "Unknown";
            var country = geoLocation.country || {};
            var countryShortName = country.sn || "Unknown Country";

            contactObj.geoLocation = location + ", " + countryShortName;
        }
    }

    function reset()
    {
        contactObj.avatarPath = contactObj._genericAvatarPath;
        contactObj.addr = "";
        contactObj.normalizedAddr = "";
        contactObj.nickname = "";
        contactObj.familyName = "";
        contactObj.givenName = "";
        contactObj.personId = "";
    }
}
