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


Rectangle {
    id: root
    width: appTheme.appWidth
    height: appTheme.appHeight
    color: main.appTheme.backgroundColor
    z: 10

    visible: false

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
        console.log("Screen Width: " + Screen.width)
        console.log("Screen Height: " + Screen.height)
        console.log("Screen desktopAvailableHeight: " + Screen.desktopAvailableHeight)
        console.log("Screen desktopAvailableWidth: " + Screen.desktopAvailableWidth)
    }

    function close(){
        root.visible = false
        //if(root.dtmfKeypadDialog) {
        //    root.dtmfKeypadDialog.visible = false
        //    root.dtmfKeypadDialog.destroy()
        //}
        tLineId.text = ''

    }

   /* Component {
        id:numPadDialog

        Rectangle {
            y: 90
            //width:parent.width;height:parent.height
            width: parent.width
            height: 500
            color: main.appTheme.backgroundColor


            NumPad {
                id:dtmfpad
                anchors {
                    horizontalCenter:parent.horizontalCenter
                    //topMargin: 300
                    bottom:parent.bottom
                }
                mode:'dtmf'
                entryTarget: tLineId
                width:parent.width - 50;height:childrenRect.height
            }



        }
    }
    */


    ColumnLayout {
        width:parent.width -10
        anchors {
            horizontalCenter: parent.horizontalCenter
            fill: parent
        }

        ColumnLayout {

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: buttonRow.top
            }

            Text {
                id:tLineId
                Layout.fillWidth: true
                height:90
                color:main.appTheme.foregroundColor
                font.pixelSize: 40
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

           // Spacer
            //Item {width:parent.width;height:10}

            Image {
                id:iAvatar
                anchors{
                    top: tLineId.bottom
                    topMargin: 5
                    horizontalCenter:parent.horizontalCenter
                }

                width:500; height:500
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

            Text {
                id:tVoiceCallDuration
                anchors.horizontalCenter:parent.horizontalCenter
                color:main.appTheme.foregroundColor
                font.pixelSize:18
                text:manager.activeVoiceCall ? main.secondsToTimeString(manager.activeVoiceCall.duration) : '00:00:00'
            }

            // Spacer
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                MouseArea {
                    anchors.fill: parent
                }
            }

            Item {
                id: numPadDialog
                Layout.fillWidth: true
                Layout.fillHeight: true           

                //width:parent.width;height:parent.height
                //width: parent.width
                //height: 500
                visible: false
                //color: 'red' //main.appTheme.backgroundColor

                NumPad {
                    id:dtmfpad
                    anchors {
                        horizontalCenter:parent.horizontalCenter
                        //topMargin: 300
                        bottom: parent.bottom
                    }
                    mode:'dtmf'
                    entryTarget: tLineId
                    width:(main.height -300) * 1.25
                    height:childrenRect.height
                }



            }

            RowLayout {
                id:rVoiceCallTools
                anchors.horizontalCenter:parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                spacing: 10

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
                        //if(!root.dtmfKeypadDialog) {
                        //    root.dtmfKeypadDialog = numPadDialog.createObject(root);
                        //} else{
                        //    root.dtmfKeypadDialog.visible = false
                        //    root.dtmfKeypadDialog.destroy()
                        //}
                        if(numPadDialog.visible){
                            numPadDialog.visible = false
                        } else{
                             numPadDialog.visible = true
                        }

                        // TODO: toggle this
                        //root.dtmfKeypadDialog.visible ^= root.dtmfKeypadDialog.visible;

                    }
                }
            }



            // Spacer
            //Item {width:parent.width;height:5}

            /*
            Item {
                width:parent.width;height:childrenRect.height
                Text {
                    id:tVoiceCallStatus
                    anchors.right:parent.right
                    color:main.appTheme.foregroundColor
                    font.pixelSize:18
                    text:qsTr(manager.activeVoiceCall ? manager.activeVoiceCall.statusText : 'disconnected')
                }
            }
            */
        }


        // Spacer
        //Item {width:parent.width;height:100}
        RowLayout {
            id: buttonRow
            width:500
            anchors{
                bottom: parent.bottom
                horizontalCenter:parent.horizontalCenter
                margins: 30
            }
            spacing:200

            AcceptButton {
                width:200
                visible:true //root.state === 'incoming'
                onClicked: if(manager.activeVoiceCall) manager.activeVoiceCall.answer();
            }

            // Spacer
            //Item {width:parent.width;height:5}

            RejectButton {
                width:200
                onClicked: {
                    if(manager.activeVoiceCall) {
                        manager.activeVoiceCall.hangup();
                    } else {
                        root.close();
                    }
                }
            }
        }

    }

}
