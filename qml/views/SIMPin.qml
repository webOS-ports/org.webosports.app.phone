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
import QtQuick.Controls.Styles 1.1
import LunaNext.Common 0.1

Rectangle {
    id: simPin
    width: Settings.displayWidth
    height: Settings.displayHeight
    color: main.appTheme.backgroundColor

    Rectangle {
        id: header
        width: Settings.displayWidth
        anchors.left: parent.left
        anchors.right: parent.right
        color: main.appTheme.headerColor
        radius: 2
        height: Units.gu(10)
        ColumnLayout{
            anchors.fill:parent
            anchors.margins: 8
            spacing: Units.gu(2)

            Text {
                id: label
                text: "Enter PIN to unlock SIM. "  + telephonyManager.getPinRetries('pin') + " attempts remaining."
                font.pixelSize: Units.dp(12)
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
                    anchors.leftMargin: Units.gu(5)
                    width: Units.gu(10)
                    onClicked: stackView.pop()

                    style: CustomButtonStyle {}
                }

                Text {
                    id: title
                    text: "SIM PIN"
                    font.pixelSize: Units.dp(18)
                    color: main.appTheme.headerTitle
                    anchors.horizontalCenter:parent.horizontalCenter
                }

                Button {
                    text: "Done"
                    anchors.right: parent.right
                    anchors.rightMargin: Units.gu(3)
                    onClicked: checkPin()

                    function checkPin(){
                        if(telephonyManager.enterPin("pin", pin.text)){
                            stackView.pop()
                        } else {
                            pin.text = ""
                            console.log("telephonyManager.getPinRetries=" + telephonyManager.getPinRetries("pin"));
                            if(telephonyManager.getPinRetries("pin") > 0){
                                label.text = "Invalid PIN. Enter PIN to unlock SIM. " + telephonyManager.getPinRetries("pin") + " attempts remaining."
                            } else{
                                label.text = "Invalid PIN. Max retries exceeded."
                            }


                        }
                    }

                    style: CustomButtonStyle {}
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
            topMargin: Units.gu(3)
        }
        mode:'sim'
        entryTarget: pin
        // width:parent.width - 50;height:childrenRect.height
    }

}
