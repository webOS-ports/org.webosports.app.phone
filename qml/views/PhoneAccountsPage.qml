/*
 * Copyright (C) 2026 WebOS Ports
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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1
import LuneOS.Service 1.0

/**
 * "Your phone accounts": which services this device can place calls over.
 *
 * Ports the legacy firstLaunch/ConnectPhone scene, generalised. It is shown on
 * its own when no calling account exists at all -- with no SIM and no connector
 * there is nothing the dialpad could do -- and is reachable from the
 * preferences the rest of the time.
 */
BasePage {
    id: accountsPage

    pageName: "PhoneAccounts"


    signal closed();

    Text {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1.5)
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: 'white'
        font.bold: true
        font.pixelSize: FontUtils.sizeToPixels("large")
        text: qsTr("Your phone accounts")
    }

    Text {
        id: subheader

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(1.5)
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: 'grey'
        font.pixelSize: FontUtils.sizeToPixels("small")
        text: accountsPage.callTransports && accountsPage.callTransports.callableTransportIds().length > 0
                  ? qsTr("Calls can be placed over any of these.")
                  : qsTr("Add an account that can place calls, or insert a SIM card.")
    }

    ListView {
        id: accountList

        anchors {
            top: subheader.bottom
            bottom: addButton.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        clip: true
        spacing: Units.gu(1)

        model: accountsPage.callTransports ? accountsPage.callTransports.callableTransportIds() : []

        delegate: Rectangle {
            required property var modelData

            width: accountList.width
            height: Units.gu(7)
            radius: Units.gu(1)
            color: appTheme.panelColor

            property var transport: accountsPage.callTransports.transportFor(modelData)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Units.gu(1)
                spacing: Units.gu(1)

                Image {
                    Layout.preferredWidth: Units.gu(4)
                    Layout.preferredHeight: Units.gu(4)
                    fillMode: Image.PreserveAspectFit
                    source: (parent.parent.transport && parent.parent.transport.icon)
                                ? parent.parent.transport.icon
                                : Qt.resolvedUrl("images/menu-icon-dial.png")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        color: 'white'
                        elide: Text.ElideRight
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                        text: accountsPage.callTransports.labelFor(modelData)
                    }
                    Text {
                        Layout.fillWidth: true
                        color: 'grey'
                        elide: Text.ElideRight
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: {
                            var transport = accountsPage.callTransports.transportFor(modelData);
                            if (transport && transport.alias && transport.alias.length > 0)
                                return transport.alias;

                            return accountsPage.callTransports.isAvailable(modelData)
                                       ? qsTr("Ready") : qsTr("Not available");
                        }
                    }
                }

                Text {
                    color: accountsPage.callTransports.supportsVideo(modelData) ? 'white' : 'transparent'
                    font.pixelSize: FontUtils.sizeToPixels("x-small")
                    text: qsTr("Video")
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: accountList.count === 0
            color: 'white'
            wrapMode: Text.Wrap
            width: parent.width - Units.gu(4)
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: FontUtils.sizeToPixels("medium")
            text: qsTr("No calling accounts yet")
        }
    }

    Button {
        id: addButton

        anchors {
            bottom: doneButton.top
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        height: Units.gu(5)
        text: qsTr("Add an account")

        onClicked: lunaService.call("luna://com.webos.applicationManager/launch",
                                    JSON.stringify({ id: "com.palm.app.accounts" }), undefined,
                                    function(error) { console.log("Could not open Accounts: " + error); })
    }

    Button {
        id: doneButton

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(1)
        }
        height: Units.gu(5)
        text: qsTr("Done")

        onClicked: accountsPage.closed()
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
}
