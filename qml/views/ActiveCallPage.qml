/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import QtQuick.Layouts 1.0

import org.nemomobile.voicecall 1.0

import LuneOS.Telephony 1.0

import LunaNext.Common 0.1

BasePage {
    id: root

    pageName: "ActiveCall"

    property Item dtmfKeypadDialog
    property VoiceCallManager voiceCallManager: voiceCallMgrWrapper.manager

    property bool voiceCallIsActive: voiceCall && voiceCall.status === VoiceCall.STATUS_ACTIVE

    function open(){
        root.visible = true
    }

    function close(){
        root.visible = false
    }

    BorderImage {
        id: rootBackground

        source: "images/frame-background.png"
        border.left: 70; border.top: 70
        border.right: 70; border.bottom: 70

        anchors {
            bottom: tVoiceCallDuration.top
            bottomMargin: Units.gu(1)
            top: parent.top
            topMargin: Units.gu(1)
            left: parent.left
            leftMargin: Units.gu(1)
            right: parent.right
            rightMargin: Units.gu(1)
        }
    }


    Flipable {
        id: flipable
        height:Units.gu(38)

        anchors{
            top: rootBackground.top
            topMargin: Units.gu(2)
            bottom: disconnectBtn.top
            left: rootBackground.left
            leftMargin: 23
            right: rootBackground.right
            rightMargin: 23
        }

        property bool flipped: false

        transform: Rotation {
            id: rotation
            origin.x: flipable.width/2
            origin.y: flipable.height/2
            axis.x: 0; axis.y: 1; axis.z: 0
            angle: 0    // the default angle
        }

        states: State {
            name: "back"
            PropertyChanges { target: rotation; angle: 180 }
            when: flipable.flipped
        }

        transitions: Transition {
            NumberAnimation { target: rotation; property: "angle"; duration: 200 }
        }

        front: Item {
            width: parent.width
            height:parent.height

            Image {
                id:imageAvatar
                anchors {
                    top: parent.top
                    topMargin: Units.gu(3);
                    horizontalCenter: parent.horizontalCenter
                }

                width: Math.min(parent.width*0.6, parent.height*0.6)
                height:width

                asynchronous:true
                fillMode:Image.PreserveAspectFit
                smooth:true
                source: currentContact.avatarPath
            }
            CornerShader {
                radius: 35
                source: imageAvatar
                anchors.fill: imageAvatar
            }
            Image {
                id: avatarFrame
                anchors.centerIn: imageAvatar

                width: imageAvatar.width + Units.gu(2)
                height: width
                source: "images/contacts-icon-frame.png"
                fillMode:Image.Stretch
                asynchronous:true
                smooth:true
            }

            Text {
                id: lineIdText
                anchors {
                    top: imageAvatar.bottom
                    bottom: parent.bottom
                    topMargin: Units.gu(1)
                    bottomMargin: Units.gu(1)
                    left: parent.left
                    right: parent.right
                }

                font.pixelSize: Units.dp(30)
                fontSizeMode: Text.Fit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: appTheme.headerTitle
                text: currentContact.personId ? (currentContact.displayLabel +"\n" + currentContact.addr) :
                                                (currentContact.lineId + "\n"+ currentContact.geoLocation);
            }
        }

        back:  Item {
            id: numPadDialog
            width: parent.width
            height:parent.height

            Text {
                id:tLineId
                anchors{
                    top: parent.top
                    horizontalCenter:parent.horizontalCenter
                }

                color:appTheme.foregroundColor
                font.pixelSize: Units.dp(20)
                text:voiceCall ? voiceCall.lineId : ""
            }


            NumPad {
                id:dtmfpad
                anchors {
                    top: tLineId.bottom
                    bottom: parent.bottom
                    right: parent.right
                    left: parent.left
                }
                mode:'dtmf'

                onSendKey: tLineId.text += String.fromCharCode(keycode)
                // entryTarget: tLineId
                //width: Units.gu(50)
                //height:childrenRect.height
            }

        }


    }

    DisconnectButton {
        id: disconnectBtn

        anchors {
            bottom: rootBackground.bottom
            bottomMargin: 30
            left: rootBackground.left
            leftMargin: 23
            right: rootBackground.right
            rightMargin: 23
        }
        onClicked: {
           voiceCall.hangup()
           root.close();
        }
    }

    Text {
        id:tVoiceCallDuration
        anchors{
            bottom: rVoiceCallTools.top
            bottomMargin: Units.gu(1)
            horizontalCenter:parent.horizontalCenter
        }

        color:appTheme.foregroundColor
        font.pixelSize: Units.dp(20)
        text:voiceCall ? secondsToTimeString(voiceCall.duration/1000) : '00:00:00'

        function secondsToTimeString(seconds) {
            var h = Math.floor(seconds / 3600);
            var m = Math.floor((seconds - (h * 3600)) / 60);
            var s = Math.floor(seconds - h * 3600 - m * 60);
            if(h < 10) h = '0' + h;
            if(m < 10) m = '0' + m;
            if(s < 10) s = '0' + s;
            return '' + h + ':' + m + ':' + s;
        }
    }

    Row {
        id:rVoiceCallTools
        height: Units.gu(5)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        spacing: Units.gu(4)

        SpeakerButton {
            width: Units.gu(5)
            height: parent.height
            checkable: true
            visible:root.voiceCallIsActive
            onClicked: {
                voiceCallManager.setAudioMode(voiceCallManager.audioMode === 'ihf' ? 'earpiece' : 'ihf');
            }
        }

        MuteButton {
            visible:root.voiceCallIsActive
            onClicked: {
                btnActive = !btnActive
                if(root.state == 'incoming') { // TODO: Take in to account unmuting audio when call is answered.
                    voiceCallManager.setMuteSpeaker(true);
                } else {
                    voiceCallManager.setMuteMicrophone(voiceCallManager.isMicrophoneMuted ? false : true);
                }
            }
        }

        KeypadButton {
            visible:root.voiceCallIsActive
            onClicked: {
                btnActive = !btnActive
                console.log("Numpad Button tapped");
                flipable.flipped = !flipable.flipped;
            }
        }

        AddCallButton {
            visible:root.voiceCallIsActive
            onClicked: {
                console.log("Add Call not implemented yet !");

            }
        }


    }
}
