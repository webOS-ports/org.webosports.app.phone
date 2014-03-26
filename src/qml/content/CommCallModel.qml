import QtQuick 2.0

ListModel {

    ListElement{ isMissedCall: true; direction: "received"; startTime: "2014-03-12"; remoteUid: "1234567890"}
    ListElement{ isMissedCall: false; direction: "received"; startTime:"2014-03-10"; remoteUid: "235892382"}
    ListElement{ isMissedCall: false; direction: "received"; startTime: "2014-03-08"; remoteUid: "35892382"}
    ListElement{ isMissedCall: true; direction: "received"; startTime: "2014-02-12"; remoteUid: "435892382"}
    ListElement{ isMissedCall: true; direction: "received"; startTime: "2014-02-12"; remoteUid: "51235892382"}
    ListElement{ isMissedCall: false; direction: "received"; startTime: "2014-01-12"; remoteUid: "61235892382"}
    ListElement{ isMissedCall: true; direction: "received"; startTime: "2014-01-12"; remoteUid: "71235892382"}
    ListElement{ isMissedCall: true; direction: "received"; startTime: "2014-01-01"; remoteUid: "81235892382"}

}
