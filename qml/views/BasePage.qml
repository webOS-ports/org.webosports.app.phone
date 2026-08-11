import QtQuick 2.0

import "../services"
import "../model"

Rectangle {
    id: basePageId
    gradient: appTheme ? appTheme.mainGradient : undefined
    radius: 10

    property string pageName: "Base"

    property PhoneUiTheme appTheme;
    property QtObject voiceCall;

    property ContactsModel contacts
    property Contact currentContact
    property VoiceCallMgrWrapper voiceCallMgrWrapper
    property TelephonyManager telephonyManager

    // Services every page may need. Declared here so PhoneWindow can hand them
    // to any page it pushes without each page repeating the plumbing.
    property var dialHandler
    property var audioRouteManager
    property var supplementaryServices
    property var callTransports
}
