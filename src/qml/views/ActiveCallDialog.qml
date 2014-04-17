import QtQuick 2.0

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
    }

    function close(){
        root.visible = false
        if(root.dtmfKeypadDialog) {
            root.dtmfKeypadDialog.visible = false
            root.dtmfKeypadDialog.destroy()
        }
        tLineId.text = ''

    }

    Component {
        id:numPadDialog

        Rectangle {
            y: 70
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


    Column {
        Column {
            width:root.width -10
            anchors.horizontalCenter: parent.horizontalCenter

            Item {width:parent.width;height:10}

            Text {
                id:tLineId
                width:parent.width; height:90
                color:main.appTheme.foregroundColor
                horizontalAlignment:Text.Center

                text:main.activeVoiceCallPerson
                     ? main.activeVoiceCallPerson.displayLabel
                     : (manager.activeVoiceCall ? manager.activeVoiceCall.lineId : '');

                onTextChanged: resizeText();

                Component.onCompleted: resizeText();

                function resizeText() {
                    if(paintedWidth < 0 || paintedHeight < 0) return;
                    while(paintedWidth > width)
                        if(--font.pixelSize <= 0) break;

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
            Item {width:parent.width;height:10}

            Image {
                id:iAvatar
                anchors.horizontalCenter:parent.horizontalCenter
                width:196;height:width
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
            Item {width:parent.width; height:300}

            Row {
                id:rVoiceCallTools
                anchors.horizontalCenter:parent.horizontalCenter
                spacing:5

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
                        if(!root.dtmfKeypadDialog) {
                            root.dtmfKeypadDialog = numPadDialog.createObject(root);
                        } else{
                            root.dtmfKeypadDialog.visible = false
                            root.dtmfKeypadDialog.destroy()
                        }

                        // TODO: toggle this
                        //root.dtmfKeypadDialog.visible ^= root.dtmfKeypadDialog.visible;

                    }
                }
            }

            // Spacer
            Item {width:parent.width;height:5}

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
        Item {width:parent.width;height:100}

        AcceptButton {
            visible:root.state === 'incoming'
            onClicked: if(manager.activeVoiceCall) manager.activeVoiceCall.answer();
        }

        // Spacer
        Item {width:parent.width;height:5}

        RejectButton {
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
