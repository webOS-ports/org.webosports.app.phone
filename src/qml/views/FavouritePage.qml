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
import LunaNext.Common 0.1
import "../model"

Rectangle {
    anchors.fill: parent
    color: main.appTheme.backgroundColor

    ListView {
        id:favouriteList
        anchors {margins:5;horizontalCenter:parent.horizontalCenter}
        anchors.fill: parent
        spacing:10
        clip:true
        model: Favouites{}

        delegate: Item {
            width:parent.width
            height:Units.gu(10)
            anchors { margins: 20}
            
            MouseArea {
                anchors.fill: parent
                onClicked:main.dial(model.remoteUid);
            }


            Rectangle {
                anchors.fill:parent
                border {color:main.appTheme.foregroundColor;width: 1.5}
                radius:20
                color:'#00000000'
            }

            Row {
                anchors {left:parent.left; leftMargin:10; verticalCenter:parent.verticalCenter}
                spacing:10

            Column {
                    Text {
                        color:model.isMissedCall ? 'red' : 'white'
                        font.pixelSize:Units.dp(20)
                        text: model.name
                    }
                    Text {
                        color:'grey'
                        font.pixelSize:Units.dp(15)
                        text: model.remoteUid
                    }
                }
            }

            Row {
                anchors {
                    right:parent.right
                    rightMargin:10
                    verticalCenter:parent.verticalCenter
                }
                spacing:10
                Button {
                    width:Units.gu(5);height:Units.gu(5)
                    iconSource:'images/generic-details-view-avatar.png'
                }
            }
        }

        Rectangle {
            visible: favouriteList.count === 0
            Text {
                color: "white"
                font.pixelSize:Units.dp(20)
                text: "No favourites yet"
            }
        }
    }


}

