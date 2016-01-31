import QtQuick 2.0

import org.nemomobile.voicecall 1.0

import LuneOS.Telephony 1.0

import "../services"
import "../model"

Rectangle {
    gradient: appTheme ? appTheme.mainGradient : undefined
    radius: 10

    property string pageName: "Base"

    property PhoneUiTheme appTheme;
    property ContactsModel contacts;

    property VoiceCallMgrWrapper voiceCallManager;
    property QtObject voiceCall;
    property Contact voiceCallPerson: Contact {}

    onVoiceCallChanged: updateVoiceCallPerson();

    function updateVoiceCallPerson() {
        if( voiceCall ) {
            var normalizedLineId = LibPhoneNumber.normalizePhoneNumber(voiceCall.lineId, contacts.countryCode);
            var person = contacts.personByNormalizedPhoneNumber(normalizedLineId);

            voiceCallPerson.avatarPath = Qt.resolvedUrl('images/generic-details-view-avatar.png');
            voiceCallPerson.addr = voiceCall.lineId;
            voiceCallPerson.normalizedAddr = normalizedLineId;
            if( person ) {
                voiceCallPerson.nickname = person.nickname;
                voiceCallPerson.familyName = person.name.familyName;
                voiceCallPerson.givenName = person.name.givenName;
                voiceCallPerson.personId = person._id;
                if(person.photos) {
                    voiceCallPerson.avatarPath = person.photos.listPhotoPath;
                }
            }
        }
        else {
            // reset contact
            voiceCallPerson.avatarPath = "";
            voiceCallPerson.addr = "";
            voiceCallPerson.normalizedAddr = "";
            voiceCallPerson.nickname = "";
            voiceCallPerson.familyName = "";
            voiceCallPerson.givenName = "";
            voiceCallPerson.personId = "";
        }
    }
}
