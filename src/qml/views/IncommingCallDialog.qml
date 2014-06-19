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
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Window 2.1
import LunaNext.Common 0.1

Rectangle {
    id: incommingCallDialog
    width: Settings.displayWidth
    height: Units.gu(20)
    color: main.appTheme.backgroundColor
    radius: 10

    anchors {
        bottom: parent.bottom
        horizontalCenter:parent.horizontalCenter
    }

    Row {
        height: Units.gu(10)
        anchors {
            bottom: parent.bottom
            horizontalCenter:parent.horizontalCenter
        }

        spacing: Units.gu(2)

        IncommingAcceptButton {
            height: 105
            width: 105
            onClicked: {
                main.accept();
            }

        }

        Column{
            Image {
                        id:iAvatar
                        anchors {
                            horizontalCenter:parent.horizontalCenter
                        }

                        width: Units.gu(5)
                        height:Units.gu(5)
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
                id: title
                font.pixelSize: Units.dp(20)
                color: main.appTheme.headerTitle
                text:main.activeVoiceCallPerson
                     ? main.activeVoiceCallPerson.displayLabel
                     : (manager.activeVoiceCall ? manager.activeVoiceCall.lineId : 'unknown number');

            }
        }



        IncommingRejectButton {
            height: 105
            width: 105
            onClicked: {
                main.reject();
            }
        }


    }



}
