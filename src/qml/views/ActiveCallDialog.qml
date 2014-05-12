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

    state: manager.activeVoiceCall ? manager.activeVoiceCall.statusText : 'disconnected'


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
        tLineId.text = main.activeVoiceCallPerson ? main.activeVoiceCallPerson.displayLabel : (manager.activeVoiceCall ? manager.activeVoiceCall.lineId : '');
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
                 : (manager.activeVoiceCall ? manager.activeVoiceCall.lineId : '');

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
        text:manager.activeVoiceCall ? main.secondsToTimeString(manager.activeVoiceCall.duration) : '00:00:00'
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

            width: Units.gu(30)
            height:Units.gu(30)
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
                    : 'images/icon-m-telephony-contact-avatar.svg';
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
            if(manager.activeVoiceCall) {
                manager.activeVoiceCall.hangup();
            } else {
                root.close();
            }
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

        //                SpeakerButton {
        //                    visible:root.state == 'active'
        //                    onClicked: {
        //                        manager.setAudioMode(manager.audioMode === 'ihf' ? 'earpiece' : 'ihf');
        //                    }
        //                }

        //                MuteButton {
        //                    visible:root.state == 'active'
        //                    onClicked: {
        //                        if(root.state == 'incoming') { // TODO: Take in to account unmuting audio when call is answered.
        //                            manager.setMuteSpeaker(true);
        //                        } else {
        //                            manager.setMuteMicrophone(manager.isMicrophoneMuted ? false : true);
        //                        }
        //                    }
        //                }


        CallDialogToolButton {
            visible:root.state == 'active'
            iconSource:'images/icon-m-telephony-volume.svg'
            onClicked: {
                manager.setAudioMode(manager.audioMode === 'ihf' ? 'earpiece' : 'ihf');
            }
        }

        CallDialogToolButton {
            visible:root.state == 'incoming' || root.state == 'active'
            iconSource:'images/icon-m-telephony-volume-off.svg'
            onClicked: {
                if(root.state == 'incoming') { // TODO: Take in to account unmuting audio when call is answered.
                    manager.setMuteSpeaker(true);
                } else {
                    manager.setMuteMicrophone(manager.isMicrophoneMuted ? false : true);
                }
            }
        }

        CallDialogToolButton {
            visible:root.state == 'active'
            iconSource:'images/icon-m-telephony-pause.svg'
            onClicked: manager.activeVoiceCall.hold();
        }

        CallDialogToolButton {
            visible:root.state == 'active'
            iconSource:'images/icon-m-telephony-numpad.svg'
            onClicked: {
                console.log("Numpad Button tapped")
                flipable.flipped = !flipable.flipped
            }
        }
    }

    //        RowLayout {
    //            id: buttonRow
    //            width: Units.gu(30)
    //            anchors{
    //                bottom: parent.bottom
    //                horizontalCenter:parent.horizontalCenter
    //                margins: Units.gu(2)
    //            }
    //            spacing:Units.gu(12)

    //            AcceptButton {
    //                width: Units.gu(12)
    //                visible:true //root.state === 'incoming'
    //                onClicked: if(manager.activeVoiceCall) manager.activeVoiceCall.answer();
    //            }

    //            // Spacer
    //            //Item {width:parent.width;height:5}

    //            DisconnectButton {
    //                //width: Units.gu(12)
    //                onClicked: {
    //                    if(manager.activeVoiceCall) {
    //                        manager.activeVoiceCall.hangup();
    //                    } else {
    //                        root.close();
    //                    }
    //                }
    //            }
    //        }

    // }

}
