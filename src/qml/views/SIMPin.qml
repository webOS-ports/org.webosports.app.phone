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

Rectangle {
    id: simPin
    width: appTheme.appWidth
    height: appTheme.appHeight
    color: main.appTheme.backgroundColor
    z: 10
    visible: false


    Rectangle {
        id: header
        width: appTheme.appWidth
        color: main.appTheme.headerColor
        radius: 2
        height: 100
        ColumnLayout{
            anchors.fill:parent
            anchors.margins: 8
            spacing: 16

            Text {
                id: label
                text: "Enter PIN to unlock SIM. "  + ofono.retries().pin + " attempts remaining."
                font.pixelSize: 20
                color: main.appTheme.headerTip
                anchors.horizontalCenter:parent.horizontalCenter
            }

            RowLayout {
                height: parent.height
                anchors.left: parent.left
                anchors.right: parent.right

                Button {
                    text: "Cancel"
                    anchors.left: parent.left
                    anchors.leftMargin: 50
                    onClicked: simPin.visible = false
                }

                Text {
                    id: title
                    text: "SIM PIN"
                    font.pixelSize: 30
                    color: main.appTheme.headerTitle
                    anchors.horizontalCenter:parent.horizontalCenter
                }

                Button {
                    text: "Done"
                    anchors.right: parent.right
                    anchors.rightMargin: 50
                    onClicked: checkPin()

                    function checkPin(){
                        if(ofono.unlockPin("pin", pin.text)){
                            simPin.visible = false
                        } else {
                            pin.text = ""
                            if(ofono.retries().pin >0){
                               label.text = "Invalid PIN. Enter PIN to unlock SIM. " + ofono.retries().pin + " attempts remaining."
                            } else{
                                  label.text = "Invalid PIN. Max retries exceeded."
                            }


                        }
                    }
                }


            }


        }

    }

    NumberEntry {
        id:pin
        width:parent.width; height:90
        anchors.top: header.bottom
        anchors.topMargin: 50
        color:main.appTheme.foregroundColor

    }

    NumPad {
        id:keyboard
        anchors {
            horizontalCenter:parent.horizontalCenter
            top: pin.bottom
            bottom:parent.bottom
        }
        mode:'sim'
        entryTarget: pin
        width:parent.width - 50;height:childrenRect.height
        model: ListModel {
            ListElement {key:'1';sub:''}
            ListElement {key:'2';sub:'abc'}
            ListElement {key:'3';sub:'def'}
            ListElement {key:'4';sub:'ghi'}
            ListElement {key:'5';sub:'jkl'}
            ListElement {key:'6';sub:'mno'}
            ListElement {key:'7';sub:'pqrs'}
            ListElement {key:'8';sub:'tuv'}
            ListElement {key:'9';sub:'wxyz'}
            ListElement {key:''}
            ListElement {key:'0';sub:'';alt:''}
            ListElement {key:'';alt:''}
        }
    }


}
