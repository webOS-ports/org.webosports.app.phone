import QtQuick 2.0

import org.nemomobile.voicecall 1.0

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
    property Contact voiceCallPerson: Contact { contactsModel: contacts }

    onVoiceCallChanged: updateVoiceCallPerson();

    function updateVoiceCallPerson() {
        if( voiceCall ) {
            voiceCallPerson.buildFromVoiceCall(voiceCall);
        }
        else {
            // reset contact
            voiceCallPerson.reset();
        }
    }
}
