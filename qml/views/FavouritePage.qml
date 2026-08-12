/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import LuneOS.Components 1.0
import LuneOS.Service 1.0

import "../model"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/ContactCallOptions.js" as ContactCallOptions

/**
 * Favourite contacts.
 *
 * Laid out like the reference: a bordered group box, one row per favourite
 * showing the photo, the name and the default way to reach them, and a chevron
 * that opens the rest. Opened, each way to call is its own row with the service
 * on the right and a button to message instead, followed by View Contact.
 * "+ Add Favorite" closes the list.
 */
BasePage {
    id: favouritePage

    pageName: "Favourite"

    property alias favoritesModel: favouriteList.model

    /// Which favourite is open, by person id; only one at a time.
    property string expandedId: ""

    Rectangle {
        id: groupBox

        anchors.fill: parent
        anchors.margins: Units.gu(0.8)

        color: appTheme.listBackgroundColor
        radius: Units.gu(0.8)
        border.color: appTheme.listBorderColor
        border.width: 1
        clip: true

        ListView {
            id: favouriteList

            anchors.fill: parent
            clip: true

            delegate: Column {
                id: favouriteEntry

                width: favouriteList.width

                readonly property bool expanded: favouritePage.expandedId === model._id
                readonly property var callOptions:
                    ContactCallOptions.callOptionsFor(model, favouritePage.callTransports)
                readonly property var defaultOption:
                    ContactCallOptions.defaultCallOption(model, favouritePage.callTransports)

                // The collapsed row: photo, name, and the way a tap would call.
                Item {
                    width: parent.width
                    height: Units.gu(6)

                    Rectangle {
                        anchors.fill: parent
                        color: rowArea.pressed ? appTheme.listSelectedColor : 'transparent'
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Units.gu(0.8)
                        anchors.rightMargin: Units.gu(0.8)
                        spacing: Units.gu(1)

                        Item {
                            Layout.preferredWidth: Units.gu(4.4)
                            Layout.preferredHeight: Units.gu(4.4)

                            Image {
                                id: avatar
                                anchors.fill: parent
                                source: (model.photos && model.photos.listPhotoPath)
                                            ? model.photos.listPhotoPath
                                            : Qt.resolvedUrl("images/list-avatar-default.png")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }
                            CornerShader {
                                anchors.fill: avatar
                                source: avatar
                                radius: Units.gu(0.4)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                color: appTheme.listTextColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("medium")
                                text: PhoneNumberUtils.personDisplayName(model)
                            }
                            Text {
                                Layout.fillWidth: true
                                color: appTheme.listSecondaryTextColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                // "MOBILE +31 6 2148 9831": the service, then the
                                // number, as the reference shows it. A count of
                                // ways to call would tell the user nothing here.
                                text: {
                                    var option = favouriteEntry.defaultOption;
                                    if (!option)
                                        return qsTr("TAP TO ADD NUMBER");

                                    var label = (option.kind === "im") ? option.transportLabel
                                                                       : option.typeLabel;
                                    return label.toUpperCase() + " " +
                                           PhoneNumberUtils.formatForDisplay(option.value,
                                                                             contacts ? contacts.countryCode : "US",
                                                                             false);
                                }
                            }
                        }

                        // The expand button, from the original app's artwork.
                        Item {
                            Layout.preferredWidth: Units.gu(3.4)
                            Layout.preferredHeight: Units.gu(3.4)

                            ClippedImage {
                                anchors.centerIn: parent
                                source: Qt.resolvedUrl(favouriteEntry.expanded
                                                           ? "images/favorites-icon-drawer-open.png"
                                                           : "images/expand-button.png")
                                wantedWidth: Units.gu(3.4)
                                wantedHeight: Units.gu(3.4)
                                imageSize: favouriteEntry.expanded ? Qt.size(36, 72) : Qt.size(50, 100)
                                patchGridSize: Qt.size(1, 2)
                                patch: expandArea.pressed ? Qt.point(0, 1) : Qt.point(0, 0)
                            }

                            MouseArea {
                                id: expandArea
                                anchors.fill: parent
                                onClicked: favouritePage.expandedId =
                                               favouriteEntry.expanded ? "" : model._id
                            }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            if (favouriteEntry.defaultOption && dialHandler)
                                dialHandler.dial(favouriteEntry.defaultOption.value,
                                                 favouriteEntry.defaultOption.transport, false);
                        }
                    }
                }

                // Opened: every way to call, each with a button to message instead.
                Repeater {
                    model: favouriteEntry.expanded ? favouriteEntry.callOptions : []

                    delegate: Column {
                        required property var modelData

                        width: favouriteEntry.width

                        ListSeparator { width: parent.width }

                    Item {
                        width: parent.width
                        height: appTheme.drawerRowHeight

                        Rectangle {
                            anchors.fill: parent
                            color: optionArea.pressed ? appTheme.listSelectedColor
                                                      : appTheme.listSectionColor
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: appTheme.drawerIndent
                            anchors.rightMargin: Units.gu(0.8)
                            spacing: Units.gu(1)

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: appTheme.listTextColor
                                font.pixelSize: FontUtils.sizeToPixels("medium")
                                text: PhoneNumberUtils.formatForDisplay(modelData.value,
                                                                        contacts ? contacts.countryCode : "US",
                                                                        false)
                            }

                            Text {
                                color: appTheme.serviceTextColor
                                font.capitalization: Font.AllUppercase
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: modelData.kind === "im" ? modelData.transportLabel
                                                              : modelData.typeLabel
                            }

                            // Video, where the account behind this row can carry it.
                            Image {
                                Layout.preferredWidth: Units.gu(3.4)
                                Layout.preferredHeight: Units.gu(3.2)
                                fillMode: Image.PreserveAspectFit
                                source: Qt.resolvedUrl("images/Camera-Icon.png")
                                visible: modelData.supportsVideo

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -Units.gu(0.8)
                                    onClicked: {
                                        if (dialHandler)
                                            dialHandler.dial(modelData.value, modelData.transport, true);
                                    }
                                }
                            }

                            // Message rather than call, over the same service.
                            // The teal bubble is the original's own button art.
                            Item {
                                Layout.preferredWidth: Units.gu(3.4)
                                Layout.preferredHeight: Units.gu(3.4)

                                ClippedImage {
                                    anchors.centerIn: parent
                                    source: Qt.resolvedUrl("images/button-sprite.png")
                                    wantedWidth: Units.gu(3.4)
                                    wantedHeight: Units.gu(3.4)
                                    imageSize: Qt.size(184, 246)
                                    patchGridSize: Qt.size(3, 4)
                                    patch: messageArea.pressed ? Qt.point(2, 1) : Qt.point(2, 0)
                                }

                                MouseArea {
                                    id: messageArea
                                    anchors.fill: parent
                                    onClicked: favouritePage._sendMessage(modelData)
                                }
                            }
                        }

                        MouseArea {
                            id: optionArea
                            anchors.fill: parent
                            z: -1
                            onClicked: {
                                if (dialHandler)
                                    dialHandler.dial(modelData.value, modelData.transport, false);
                            }
                        }
                    }
                    }
                }

                // Opening a favourite also offers their contact card.
                ListSeparator {
                    width: parent.width
                    drawn: favouriteEntry.expanded
                }

                Item {
                    width: parent.width
                    height: favouriteEntry.expanded ? appTheme.drawerRowHeight : 0
                    visible: favouriteEntry.expanded

                    Rectangle {
                        anchors.fill: parent
                        color: viewArea.pressed ? appTheme.listSelectedColor
                                                : appTheme.listSectionColor
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: appTheme.drawerIndent
                            verticalCenter: parent.verticalCenter
                        }
                        color: appTheme.listTextColor
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                        text: qsTr("View Contact")
                    }

                    MouseArea {
                        id: viewArea
                        anchors.fill: parent
                        onClicked: favouritePage._viewContact(model._id)
                    }
                }

                // Closes the entry off, drawer and all.
                ListSeparator {
                    width: parent.width
                }
            }

            // Closes the list, as on the reference.
            footer: Item {
                width: favouriteList.width
                height: Units.gu(5.5)

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    color: addArea.pressed ? appTheme.primaryTextColor
                                           : appTheme.listSecondaryTextColor
                    font.italic: true
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    text: qsTr("+ Add Favorite")
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    onClicked: favouritePage._addFavourite()
                }
            }
        }
    }

    function _sendMessage(option) {
        var compose = { messageText: "", personId: "", address: option.value };
        if (option.kind === "im" && callTransports) {
            var transport = callTransports.transportFor(option.transport);
            if (transport && transport.serviceName)
                compose.serviceName = transport.serviceName;
        }

        _launch("com.palm.app.messaging", { compose: compose });
    }

    function _viewContact(personId) {
        _launch("com.palm.app.contacts", { personId: personId });
    }

    function _addFavourite() {
        _launch("com.palm.app.contacts", { });
    }

    function _launch(appId, params) {
        lunaService.call("luna://com.webos.applicationManager/launch",
                         JSON.stringify({ id: appId, params: params }), undefined,
                         function(error) { console.log("Could not launch " + appId + ": " + error); });
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
}
