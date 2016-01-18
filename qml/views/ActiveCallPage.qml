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

import LunaNext.Common 0.1

BasePage {
    id: root

    pageName: "ActiveCall"

    property Item dtmfKeypadDialog

    property bool voiceCallIsActive: voiceCall && voiceCall.status === VoiceCall.STATUS_ACTIVE

    function open(){
        root.visible = true
        tLineId.text = voiceCallPerson ? voiceCallPerson.displayLabel : (voiceCall ? voiceCall.lineId : '');
    }

    function close(){
        root.visible = false
        tLineId.text = ''
    }


    Rectangle {
        id: topStatusBar
        anchors {
            left: parent.left
            leftMargin: Units.gu(1)
            right: parent.right
            rightMargin: Units.gu(1)
        }
        height: Units.gu(5)
        color: appTheme.headerColor
        radius: 10

        Text {
            id:tLineId
            anchors.fill: parent
            anchors.margins: Units.gu(0.5)
            color:appTheme.foregroundColor
            font.pixelSize: height * 0.8

            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft

            text:voiceCallPerson ? voiceCallPerson.displayLabel : (voiceCall ? voiceCall.lineId : '');
        }

    }


    Text {
        id:tVoiceCallDuration
        anchors{
            top: topStatusBar.bottom
            topMargin: Units.gu(1)
            horizontalCenter:parent.horizontalCenter
        }

        color:appTheme.foregroundColor
        font.pixelSize: Units.dp(15)
        text:voiceCall ? secondsToTimeString(voiceCall.duration) : '00:00:00'

        function secondsToTimeString(seconds) {
            var h = Math.floor(seconds / 3600);
            var m = Math.floor((seconds - (h * 3600)) / 60);
            var s = seconds - h * 3600 - m * 60;
            if(h < 10) h = '0' + h;
            if(m < 10) m = '0' + m;
            if(s < 10) s = '0' + s;
            return '' + h + ':' + m + ':' + s;
        }
    }


    Flipable {
        id: flipable
        height:Units.gu(38)

        anchors{
            top: tVoiceCallDuration.bottom
            topMargin: Units.gu(1)
            bottom: disconnectBtn.top
            left: parent.left
            leftMargin: Units.gu(2)
            right: parent.right
            rightMargin: Units.gu(2)
        }

        property bool flipped: false

        transform: Rotation {
            id: rotation
            origin.x: flipable.width/2
            origin.y: flipable.height/2
            axis.x: 1; axis.y: 0; axis.z: 0     // set axis.y to 1 to rotate around y-axis
            angle: 0    // the default angle
        }

        states: State {
            name: "back"
            PropertyChanges { target: rotation; angle: 180 }
            when: flipable.flipped
        }

        transitions: Transition {
            NumberAnimation { target: rotation; property: "angle"; duration: 10 }
        }

        front:  Image {
            id:iAvatar
            anchors {
                horizontalCenter:parent.horizontalCenter
            }

            width: parent.width
            height:parent.height
            asynchronous:true
            fillMode:Image.PreserveAspectFit
            smooth:true

            Rectangle {
                anchors.fill:parent
                border {color:appTheme.foregroundColor;width:2}
                radius:10
                z: -1
                color:"black"
            }

            source: voiceCallPerson ? voiceCallPerson.avatarPath : 'images/generic-details-view-avatar.png';
        }

        back:  Item {
            id: numPadDialog
            width: parent.width
            height:parent.height

            NumPad {
                id:dtmfpad
                anchors {
                    fill: parent
                }
                mode:'dtmf'

                onKeyPressed: tLineId.text += label
                // entryTarget: tLineId
                //width: Units.gu(50)
                //height:childrenRect.height
            }

        }


    }

    DisconnectButton {
        id: disconnectBtn

        anchors {
            bottom: rVoiceCallTools.top
            bottomMargin: Units.gu(2)
            left: flipable.left
            right: flipable.right
        }
        onClicked: {
           voiceCall.hangup()
           root.close();
        }
    }

    Row {
        id:rVoiceCallTools
        height: Units.gu(7)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        spacing: Units.gu(4)

        SpeakerButton {
            visible:root.voiceCallIsActive
            onClicked: {
                voiceCallManager.setAudioMode(voiceCallManager.audioMode === 'ihf' ? 'earpiece' : 'ihf');
                btnActive = !btnActive
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
