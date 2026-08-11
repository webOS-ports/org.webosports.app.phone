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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1
import LuneOS.Service 1.0

import "../model"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/ContactCallOptions.js" as ContactCallOptions

/**
 * Favourite contacts.
 *
 * The original page showed only `name.familyName` and no photo, so a contact
 * with just a given name or an organisation showed up blank, and a contact with
 * several numbers could only ever be reached on one of them. This follows the
 * legacy Favorites scene instead: full display name, photo, and a row per
 * number once the entry is opened.
 */
BasePage {
    id: favouritePage

    pageName: "Favourite"

    property alias favoritesModel: favouriteList.model

    ListView {
        id: favouriteList

        anchors.fill: parent
        anchors.margins: Units.gu(0.5)
        spacing: Units.gu(1)
        clip: true

        delegate: Column {
            id: favouriteEntry

            width: favouriteList.width

            // Every way to reach this favourite, across all calling accounts.
            property var callOptions: ContactCallOptions.callOptionsFor(model, favouritePage.callTransports)
            property var defaultOption: ContactCallOptions.defaultCallOption(model, favouritePage.callTransports)
            property bool expanded: false

            Rectangle {
                width: parent.width
                height: Units.gu(9)
                radius: Units.gu(2)
                color: appTheme.panelColor
                border {
                    color: appTheme.headerColor
                    width: 1.5
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Units.gu(1)
                    spacing: Units.gu(1)

                    Item {
                        Layout.preferredWidth: Units.gu(6)
                        Layout.preferredHeight: Units.gu(6)

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
                            radius: Units.gu(1)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            color: "white"
                            elide: Text.ElideRight
                            font.pixelSize: FontUtils.sizeToPixels("medium")
                            text: PhoneNumberUtils.personDisplayName(model)
                        }
                        Text {
                            Layout.fillWidth: true
                            color: 'grey'
                            elide: Text.ElideRight
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            text: {
                                var options = favouriteEntry.callOptions;
                                if (options.length === 0)
                                    return qsTr("No way to call this contact");
                                if (options.length > 1)
                                    return qsTr("%1 ways to call").arg(options.length);

                                return favouritePage._optionLabel(options[0]);
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // One way to reach them calls straight away; several
                        // open the list so the user picks, as the legacy page did.
                        if (favouriteEntry.callOptions.length > 1)
                            favouriteEntry.expanded = !favouriteEntry.expanded;
                        else if (favouriteEntry.defaultOption && dialHandler)
                            dialHandler.dial(favouriteEntry.defaultOption.value,
                                             favouriteEntry.defaultOption.transport, false);
                    }
                }
            }

            Repeater {
                model: favouriteEntry.expanded ? favouriteEntry.callOptions : []

                delegate: Item {
                    required property var modelData

                    width: favouriteEntry.width
                    height: Units.gu(4.5)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (dialHandler)
                                dialHandler.dial(modelData.value, modelData.transport, false);
                        }
                    }

                    RowLayout {
                    anchors.fill: parent
                    spacing: Units.gu(1)

                    Item { Layout.preferredWidth: Units.gu(7) }

                    Text {
                        Layout.fillWidth: true
                        color: 'white'
                        elide: Text.ElideRight
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: PhoneNumberUtils.formatForDisplay(modelData.value,
                                                                contacts ? contacts.countryCode : "US",
                                                                false)
                    }
                    Text {
                        color: 'grey'
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: modelData.kind === "im" ? modelData.transportLabel : modelData.typeLabel
                    }

                    // Video, where the account behind this option supports it.
                    Image {
                        Layout.rightMargin: Units.gu(2)
                        Layout.preferredWidth: Units.gu(3)
                        Layout.preferredHeight: Units.gu(3)
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl("images/menu-icon-video.png")
                        visible: modelData.supportsVideo

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (dialHandler)
                                    dialHandler.dial(modelData.value, modelData.transport, true);
                            }
                        }
                    }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: favouriteList.count === 0
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            text: qsTr("No favourites yet")
        }
    }

    function _optionLabel(option) {
        var address = PhoneNumberUtils.formatForDisplay(option.value,
                                                        contacts ? contacts.countryCode : "US", false);
        return option.kind === "im" ? (option.transportLabel + " · " + address) : address;
    }
}
