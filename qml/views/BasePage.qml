import QtQuick 2.0

import org.nemomobile.voicecall 1.0

import "../services"
import "../model"

Rectangle {
    color: appTheme ? appTheme.backgroundColor : "black"
    radius: 10

    property string pageName: "Base"

    property PhoneUiTheme appTheme;

    property VoiceCallMgrWrapper voiceCallManager;
    property QtObject voiceCall;
    property Contact voiceCallPerson;
}
