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

// The menus, switches and fields here are the platform's, so they have to
// be drawn by the platform's style rather than whatever Controls defaults to.
import QtQuick.Controls.LuneOS 2.0
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1
import LuneOS.Forms 1.0
import LuneOS.System 1.0

import "../services"

/**
 * "Your phone accounts": which services this device can place calls over.
 *
 * Ports the legacy firstLaunch/ConnectPhone scene, generalised. It is shown on
 * its own when no calling account exists at all -- with no SIM and no connector
 * there is nothing the dialpad could do -- and is reachable from the
 * preferences the rest of the time. In the look of the settings apps, like
 * the preferences.
 */
AppPage {
    id: accountsPage

    // What PhoneTabView hands the page
    property UiTheme appTheme
    property CallTransports callTransports

    signal closed();

    // Done sits at the foot, as in every webOS preferences scene
    footer: DoneBar { onClicked: accountsPage.closed() }

    header: AppHeader {
        height: Units.gu(7.5)
        title: qsTr("Phone Accounts")
        icon: Qt.resolvedUrl("../../icon.png")
        compact: width < Units.gu(50)
    }

    readonly property var _transportIds: callTransports ? callTransports.callableTransportIds() : []

    SettingsPageContent {
        ExplanationText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: accountsPage._transportIds.length > 0
                      ? qsTr("Calls can be placed over any of these.")
                      : qsTr("Add an account that can place calls, or insert a SIM card.")
        }

        FormGroup {
            title: qsTr("Accounts")

            Repeater {
                model: accountsPage._transportIds

                delegate: Item {
                    required property var modelData
                    readonly property var transport:
                        accountsPage.callTransports.transportFor(modelData)

                    width: parent ? parent.width : 0
                    height: Units.gu(6.5)

                    RowLayout {
                        anchors.fill: parent
                        spacing: Units.gu(1)

                        Image {
                            Layout.preferredWidth: Units.gu(3.4)
                            Layout.preferredHeight: Units.gu(3.4)
                            fillMode: Image.PreserveAspectFit
                            visible: !!source && String(source).length > 0
                            source: (transport && transport.icon) ? transport.icon : ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("16pt")
                                text: accountsPage.callTransports.labelFor(modelData)
                            }
                            Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: Colors.secondaryText
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: {
                                    if (transport && transport.alias && transport.alias.length > 0)
                                        return transport.alias;

                                    return accountsPage.callTransports.isAvailable(modelData)
                                               ? qsTr("Ready") : qsTr("Not available");
                                }
                            }
                        }

                        Label {
                            color: Colors.secondaryText
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            visible: accountsPage.callTransports.supportsVideo(modelData)
                            text: qsTr("Video")
                        }
                    }
                }
            }

            LabelAndValue {
                visible: accountsPage._transportIds.length === 0
                label: qsTr("No calling accounts yet")
            }
        }

        Button {
            width: parent.width
            text: qsTr("Add an account")

            onClicked: launcher.launch("com.palm.app.accounts", null, undefined,
                                       function(error) { console.log("Could not open Accounts: " + error); })
        }
    }

    AppLauncher {
        id: launcher
        clientName: "org.webosports.app.phone"
    }
}
