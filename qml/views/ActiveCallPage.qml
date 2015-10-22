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
import QtQuick.Window 2.1
import LunaNext.Common 0.1

Rectangle {
    id: root
    width: Settings.displayWidth
    height: Settings.displayHeight
    color: main.appTheme.backgroundColor

    property Item dtmfKeypadDialog

    state: voiceCallManager.activeVoiceCall ? voiceCallManager.activeVoiceCall.statusText : 'disconnected'


    states {
        State {name:'active'}
        State {name:'held'}
        State {name:'dialing'}
        State {name:'alerting'}
        State {name:'incoming'}
        State {name:'waiting'}
        State {name:'disconnected'}
    }

    function open(){
        root.visible = true
        tLineId.text = main.activeVoiceCallPerson ? main.activeVoiceCallPerson.displayLabel : (voiceCallManager.activeVoiceCall ? voiceCallManager.activeVoiceCall.lineId : '');
        console.log("Settings.displayWidth: " + Settings.displayWidth)
        console.log("Settings.displayHeight: " + Settings.displayHeight)
        console.log("Screen desktopAvailableHeight: " + Screen.desktopAvailableHeight)
        console.log("Screen desktopAvailableWidth: " + Screen.desktopAvailableWidth)
    }

    function close(){
        root.visible = false
        tLineId.text = ''
    }


    Rectangle {
        id: topStatusBar
        width: Settings.displayWidth
        anchors.left: parent.left
        anchors.right: parent.right
        color: main.appTheme.headerColor
        radius: 10
        height: Units.gu(5)

        Text {
            id:tLineId
            Layout.fillWidth: true
            height: Units.gu(5)
            color:main.appTheme.foregroundColor
            font.pixelSize: Units.dp(30)
            anchors{
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            horizontalAlignment:Text.Center

            text:main.activeVoiceCallPerson
                 ? main.activeVoiceCallPerson.displayLabel
                 : (voiceCallManager.activeVoiceCall ? voiceCallManager.activeVoiceCall.lineId : '');

            onTextChanged: resizeText();

            Component.onCompleted: resizeText();

            function resizeText() {
                if(paintedWidth < 0 || paintedHeight < 0) return;
                while(paintedWidth > width) {
                    //console.log("paintedWidth=" + paintedWidth + " width=" + width)
                    //console.log(font.pixelSize)
                    if(--font.pixelSize <= 0) break;
                }

                while(paintedWidth < width)
                    if(++font.pixelSize >= 38) break;
            }

            function insertChar(character) {

                if(text.length === 0 || (main.activeVoiceCallPerson && text === main.activeVoiceCallPerson.displayLabel)) {
                    text = character
                } else{
                    text = text + character;
                }

            }
        }

    }


    Text {
        id:tVoiceCallDuration
        anchors{
            top: topStatusBar.bottom
            topMargin: 5
            horizontalCenter:parent.horizontalCenter
        }

        color:main.appTheme.foregroundColor
        font.pixelSize: Units.dp(15)
        text:voiceCallManager.activeVoiceCall ? main.secondsToTimeString(voiceCallManager.activeVoiceCall.duration) : '00:00:00'
    }


    Flipable {
        id: flipable
        height:Units.gu(35)

        anchors{
            top: tVoiceCallDuration.bottom
            topMargin: 5
            horizontalCenter:parent.horizontalCenter
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

            width: Units.gu(35)
            height:Units.gu(35)
            asynchronous:true
            fillMode:Image.PreserveAspectFit
            smooth:true

            Rectangle {
                anchors.fill:parent
                border {color:main.appTheme.foregroundColor;width:2}
                radius:10
                color:'#00000000'
            }

            source: main.activeVoiceCallPerson
                    ? main.activeVoiceCallPerson.avatarPath
                    : 'images/generic-details-view-avatar.png';
        }

        back:  Item {
            id: numPadDialog
            anchors {
                horizontalCenter: parent.horizontalCenter
                fill: parent
            }

            NumPad {
                id:dtmfpad
                anchors {
                    bottom: parent.disconnectBtn
                    horizontalCenter:parent.horizontalCenter
                    topMargin: Units.gu(3)

                }
                mode:'dtmf'
                entryTarget: tLineId
                //width: Units.gu(50)
                //height:childrenRect.height
            }

        }


    }

    DisconnectButton {
        id: disconnectBtn
        height: 99
        anchors {
            top: flipable.bottom
            horizontalCenter:parent.horizontalCenter
            margins:Units.gu(2)
        }
        onClicked: {
           voiceCallManager.hangup()
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
            visible:root.state == 'active'
            onClicked: {
                voiceCallManager.setAudioMode(voiceCallManager.audioMode === 'ihf' ? 'earpiece' : 'ihf');
                btnActive = !btnActive
            }
        }

        MuteButton {
            visible:root.state == 'active'
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
            visible:root.state == 'active'
            onClicked: {
                btnActive = !btnActive
                console.log("Numpad Button tapped");
                flipable.flipped = !flipable.flipped;
            }
        }

        AddCallButton {
            visible:root.state == 'active'
            onClicked: {
                console.log("Add Call not implemented yet !");

            }
        }


    }
}
