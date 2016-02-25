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

import LuneOS.Telephony 1.0

QtObject {
    id: contactObj

    property ContactsModel contactsModel;

    property string avatarPath: _genericAvatarPath
    property string displayLabel: (nickname === "") ? (givenName + " " + familyName) : nickname;

    property string addr: "";

    property string normalizedAddr: "";
    property string nickname: "";
    property string familyName: "";
    property string givenName: "";
    property string personId: "";

    readonly property string _genericAvatarPath: Qt.resolvedUrl('../views/images/contacts-unknown-icon-large.png')

    function buildFromVoiceCall(voiceCall)
    {
        contactObj.reset();

        var normalizedLineId = LibPhoneNumber.normalizePhoneNumber(voiceCall.lineId, contactsModel.countryCode);
        var person = contactsModel.personByNormalizedPhoneNumber(normalizedLineId);

        contactObj.addr = voiceCall.lineId;
        contactObj.normalizedAddr = normalizedLineId;
        if( person ) {
            contactObj.nickname = person.nickname;
            contactObj.familyName = person.name.familyName;
            contactObj.givenName = person.name.givenName;
            contactObj.personId = person._id;
            if(person.photos) {
                contactObj.avatarPath = person.photos.listPhotoPath;
            }
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
