/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import LunaNext.Compositor 0.1
import LuneOS.Application 1.0 as LuneOS

import org.nemomobile.voicecall 1.0

import LuneOS.Telephony 1.0

import "../services"
import "../model"
import "../services/IncomingCallsService.js" as IncomingCallsService

LuneOS.ApplicationWindow {
    id: incomingCallAlert

    property ContactsModel contacts;
    property VoiceCallMgrWrapper voiceCallManager
    property QtObject voiceCall;
    onVoiceCallChanged: lineIdText.updateText();

    property Contact voiceCallPerson: (voiceCall && contacts) ? contacts.personByPhoneNumber(voiceCall.lineId) : null

    width: Settings.displayWidth
    height: Units.gu(24)

    type: LuneOS.ApplicationWindow.PopupAlert
    color: "transparent"

    Text {
        id: lineIdText
        anchors {
            top: parent.top
            bottom: buttons.top
            margins: Units.gu(1)
            left: parent.left
            right: parent.right
        }

        font.pixelSize: Units.dp(30)
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "white"
        text: voiceCall ? voiceCall.lineId : ""

        function updateText() {
            if(voiceCallPerson && voiceCallPerson.personId) {
                lineIdText.text = voiceCallPerson.displayLabel +"\n" +
                                  voiceCallPerson.addr;
            }
            else if(voiceCall) {
                LibPhoneNumber.getNumberGeolocation(voiceCall.lineId, contacts.countryCode, lineIdText.setTextFromGeoLocation);
            }
        }

        function setTextFromGeoLocation(geoLocation) {
                if(geoLocation.parsed) {
                    var location = geoLocation.location || "Unknown";
                    var country = geoLocation.country || {};
                    var countryShortName = country.sn || "Unknown Country";
                    lineIdText.text = voiceCall.lineId + "\n"+
                                      location + ", " + countryShortName;
                }
        }
    }

    Row {
        id: buttons
        height: Units.gu(12)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        spacing: Units.gu(1)

        IncomingAcceptButton {
            anchors.verticalCenter: buttons.verticalCenter
            height: 210
            width: 210
            onClicked: {
                IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Accepted);
                voiceCall.answer();
                incomingCallAlert.hide();
            }
        }

        Item {
            anchors.verticalCenter: buttons.verticalCenter

            width: incomingCallAlert.width - 2*210 - Units.gu(1)
            height: buttons.height

            Image {
                id: imageAvatar
                anchors.fill: parent
                asynchronous:true
                fillMode:Image.PreserveAspectCrop
                smooth:true
                source: (voiceCallPerson && voiceCallPerson.avatarPath) ? voiceCallPerson.avatarPath : 'images/contacts-unknown-icon-large.png';
            }
            CornerShader {
                radius: 30
                sourceItem: imageAvatar
                anchors.fill: imageAvatar
            }
        }

        IncomingRejectButton {
            anchors.verticalCenter: buttons.verticalCenter
            height: 210
            width: 210
            onClicked: {
                IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Ignored);
                voiceCall.hangup();
                incomingCallAlert.hide();
            }
        }
    }
}
