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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1
import LuneOS.Components 1.0

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/ContactCallOptions.js" as ContactCallOptions

/**
 * Contact lookup: search contacts and pick how to reach them.
 *
 * Laid out like the webOS 3.x contact list on the TouchPad -- a light list, the
 * contact's name as a bold header, and one row per way to call them with the
 * service in grey caps on the right. That shape is what makes Synergy legible:
 * a contact's mobile number, their WhatsApp and their Telegram sit side by side
 * and the user picks one.
 *
 * Ports the legacy ContactLookup / AllContactLookup scenes.
 */
BasePage {
    id: contactLookupPage

    pageName: "ContactLookup"

    property var imBuddyStatus

    /// The Video tab lists only contacts reachable by a video-capable account.
    property bool videoOnly: false

    /// Pre-fills the search field, e.g. with what was typed on the dialpad.
    property string initialFilter: ""

    /// The user picked a contact but wants it on the dialpad rather than dialled.
    signal contactPicked(string name, string phoneNumber);

    // Numbers are searched digit-wise, names as substrings, so one field
    // handles both without the user choosing a mode.
    property var matches: {
        if (!contacts) return [];

        var text = searchField.text.trim();
        if (text.length === 0)
            return _allContacts();

        if (/^[0-9+][0-9+\s().-]*$/.test(text))
            return contacts.matchByNumberPrefix(text, 50);

        return contacts.matchByName(text, 50);
    }

    /**
     * Flattened to one entry per row: a header for each contact, then a row per
     * way to call them. Contacts with nothing callable are left out entirely.
     *
     * Rebuilt explicitly rather than bound: the list feeds a ListView whose
     * delegates read back from this page, and expressing it as a binding makes
     * QML see a cycle.
     */
    property var rows: []

    function _rebuildRows() {
        var result = [];

        matches.forEach(function(match) {
            var options = videoOnly
                ? ContactCallOptions.videoCallOptionsFor(match.person, contactLookupPage.callTransports)
                : ContactCallOptions.callOptionsFor(match.person, contactLookupPage.callTransports);

            if (options.length === 0)
                return;

            result.push({ header: true, person: match.person,
                          name: PhoneNumberUtils.personDisplayName(match.person) });

            options.forEach(function(option) {
                result.push({ header: false, person: match.person, option: option });
            });
        });

        rows = result;
    }

    onMatchesChanged: _rebuildRows()
    onVideoOnlyChanged: _rebuildRows()

    Connections {
        target: contactLookupPage.callTransports
        // A connector signing in or out changes what a contact can be called on.
        function onRevisionChanged() { contactLookupPage._rebuildRows(); }
    }

    function _allContacts() {
        var all = [];
        for (var i = 0; i < contacts.count && i < 200; ++i)
            all.push({ person: contacts.get(i), phoneNumber: null });
        return all;
    }

    Component.onCompleted: {
        searchField.text = initialFilter;
        searchField.forceActiveFocus();
        _rebuildRows();
    }

    TextField {
        id: searchField

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Units.gu(0.8)
        }
        height: Units.gu(4)

        placeholderText: qsTr("Enter name or number")
        color: appTheme.listTextColor
        placeholderTextColor: appTheme.listSecondaryTextColor
        font.pixelSize: FontUtils.sizeToPixels("medium")

        background: Rectangle {
            color: '#f4f4f4'
            radius: Units.gu(0.5)
            border.color: '#9a9a9a'
            border.width: 1
        }
    }

    // The list is light, in contrast with the dark chrome around it.
    Rectangle {
        anchors {
            top: searchField.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(0.8)
            topMargin: 0
        }
        color: appTheme.listBackgroundColor
        radius: Units.gu(0.5)
        clip: true

        ListView {
            id: contactList

            anchors.fill: parent
            clip: true
            model: contactLookupPage.rows

            delegate: Loader {
                required property var modelData

                width: contactList.width
                sourceComponent: modelData.header ? headerRow : optionRow

                // A Loader does not pass the delegate's context on, so hand the
                // row its data explicitly.
                onLoaded: item.rowData = modelData
            }

            Component {
                id: headerRow

                Item {
                    property var rowData

                    width: contactList.width
                    height: Units.gu(3.4)

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            bottomMargin: Units.gu(0.2)
                            leftMargin: Units.gu(1.2)
                            rightMargin: Units.gu(1.2)
                        }
                        elide: Text.ElideRight
                        color: appTheme.listSectionTextColor
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: parent.rowData ? parent.rowData.name : ""
                    }
                }
            }

            Component {
                id: optionRow

                Item {
                    id: row

                    property var rowData
                    readonly property var option: rowData ? rowData.option : null

                    width: contactList.width
                    height: Units.gu(4.6)

                    Rectangle {
                        anchors.fill: parent
                        color: rowArea.pressed ? '#cdcdcd' : 'transparent'
                    }

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1
                        color: appTheme.listDividerColor
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Units.gu(2.4)
                        anchors.rightMargin: Units.gu(1.2)
                        spacing: Units.gu(1)

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            // Dimmed when the connector says the buddy is offline.
                            color: (row.option && row.option.kind === "im" &&
                                    contactLookupPage.imBuddyStatus &&
                                    !contactLookupPage.imBuddyStatus.isAvailable(row.option.type,
                                                                                 row.option.value))
                                       ? '#9a9a9a' : appTheme.listSecondaryTextColor
                            font.pixelSize: FontUtils.sizeToPixels("medium")
                            text: row.option
                                      ? PhoneNumberUtils.formatForDisplay(row.option.value,
                                                                          contacts ? contacts.countryCode : "US",
                                                                          false)
                                      : ""
                        }

                        // The service this row would call over, as on the original.
                        Text {
                            color: appTheme.listSecondaryTextColor
                            font.capitalization: Font.AllUppercase
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            text: row.option ? (row.option.kind === "im" ? row.option.transportLabel
                                                                         : row.option.typeLabel)
                                             : ""
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        z: -1
                        onClicked: contactLookupPage._dial(row.rowData.person, row.option,
                                                           contactLookupPage.videoOnly)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - Units.gu(4)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: contactList.count === 0
                color: appTheme.listSecondaryTextColor
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: {
                    if (contactLookupPage.videoOnly)
                        return qsTr("No contacts can be called with video");
                    return searchField.text.length > 0 ? qsTr("No matching contacts")
                                                       : qsTr("No contacts yet");
                }
            }
        }
    }

    function _dial(person, option, video) {
        if (!option) return;

        contactPicked(PhoneNumberUtils.personDisplayName(person), option.value);

        if (dialHandler)
            dialHandler.dial(option.value, option.transport, video === true);
    }
}
