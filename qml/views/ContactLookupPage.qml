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

import QtQuick.Controls.LuneOS 2.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/ContactCallOptions.js" as ContactCallOptions

/**
 * Contact lookup: search contacts and pick how to reach them.
 *
 * Laid out like the webOS contact list -- a bordered group box holding a white
 * search pill and, under it, each contact's name on a dark band followed by one
 * row per way to call them, with the service in grey caps on the right.
 *
 * That shape is what makes Synergy legible: a contact's mobile number, their
 * WhatsApp and their Telegram sit side by side and the user picks one.
 *
 * Ports the legacy ContactLookup / AllContactLookup scenes.
 */
BasePage {
    id: contactLookupPage

    pageName: "ContactLookup"

    // A list page is a flat grey: the gradient belongs to the call card.
    gradient: null
    color: appTheme.backgroundColor

    property var imBuddyStatus

    /// The Video tab lists only contacts reachable by a video-capable account.
    property bool videoOnly: false

    /// The Phone tab offers the dialpad above the list.
    property bool showDialpadButton: false
    signal dialpadRequested();

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

            var name = PhoneNumberUtils.personDisplayName(match.person);
            result.push({ header: true, person: match.person,
                          name: name,
                          nameMarkup: _highlight(name, searchField.text.trim()),
                          favorite: match.person.favorite === true });

            options.forEach(function(option) {
                result.push({ header: false, person: match.person, option: option,
                              lastOfContact: false });
            });

            // The row before the next contact's name carries no divider.
            result[result.length - 1].lastOfContact = true;
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

    /// Underlines the part of `name` the search matched, in blue.
    function _highlight(name, needle) {
        var plain = _escape(name);
        if (needle.length === 0)
            return plain;

        var at = name.toLowerCase().indexOf(needle.toLowerCase());
        if (at < 0)
            return plain;

        return _escape(name.slice(0, at)) +
               "<font color=\"#5a9bd8\"><u>" + _escape(name.substr(at, needle.length)) + "</u></font>" +
               _escape(name.slice(at + needle.length));
    }

    function _escape(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
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

    Button {
        id: dialpadButton

        anchors {
            top: parent.top
            topMargin: Units.gu(0.8)
            horizontalCenter: parent.horizontalCenter
        }
        height: visible ? Units.gu(4) : 0
        width: Units.gu(24)
        visible: contactLookupPage.showDialpadButton

        text: qsTr("Dialpad")
        LuneOSButton.mainColor: '#2071bb'
        LuneOSButton.textColor: '#ffffff'
        onClicked: contactLookupPage.dialpadRequested()
    }

    // The search field and the list share one bordered group box, which is how
    // the reference frames them.
    Rectangle {
        id: groupBox

        anchors {
            top: dialpadButton.visible ? dialpadButton.bottom : parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: appTheme.listMargin
        }

        color: appTheme.listBackgroundColor
        radius: appTheme.listBorderRadius
        border.color: appTheme.listBorderColor
        border.width: appTheme.listBorderWidth
        clip: true

        SearchField {
            id: searchField

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Units.gu(0.8)
            }

            placeholderText: qsTr("Enter Name")
        }

        ListView {
            id: contactList

            anchors {
                top: searchField.bottom
                topMargin: Units.gu(0.8)
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
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
                    id: sectionRow

                    property var rowData

                    width: contactList.width
                    height: Units.gu(2.4)

                    Text {
                        id: sectionName

                        anchors {
                            left: parent.left
                            leftMargin: Units.gu(1.2)
                            bottom: parent.bottom
                            bottomMargin: Units.gu(0.3)
                        }
                        width: Math.min(implicitWidth, parent.width - Units.gu(4))
                        elide: Text.ElideRight
                        color: appTheme.listSectionTextColor
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        textFormat: Text.StyledText
                        text: sectionRow.rowData ? sectionRow.rowData.nameMarkup : ""
                    }

                    // A favourite is starred, as on the reference.
                    Text {
                        id: favouriteStar

                        anchors {
                            left: sectionName.right
                            leftMargin: Units.gu(0.5)
                            baseline: sectionName.baseline
                        }
                        visible: sectionRow.rowData ? sectionRow.rowData.favorite === true : false
                        color: appTheme.buttonActiveColor
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        text: "★"
                    }

                    // The rule that runs from the name out to the edge.
                    Rectangle {
                        anchors {
                            left: favouriteStar.visible ? favouriteStar.right : sectionName.right
                            leftMargin: Units.gu(1)
                            right: parent.right
                            rightMargin: Units.gu(1.2)
                            verticalCenter: sectionName.verticalCenter
                        }
                        height: 1
                        color: appTheme.listBorderColor
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
                    height: Units.gu(5.4)

                    Rectangle {
                        anchors.fill: parent
                        color: rowArea.pressed ? appTheme.listSelectedColor : 'transparent'
                    }

                    ListSeparator {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        drawn: !(row.rowData && row.rowData.lastOfContact)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Units.gu(2.4)
                        anchors.rightMargin: Units.gu(1.2)
                        spacing: Units.gu(1)

                        Text {
                            elide: Text.ElideRight
                            Layout.maximumWidth: parent.width * 0.55
                            color: appTheme.listSecondaryTextColor
                            font.pixelSize: FontUtils.sizeToPixels("medium")
                            text: row.option
                                      ? PhoneNumberUtils.formatForDisplay(row.option.value,
                                                                          contacts ? contacts.countryCode : "US",
                                                                          false)
                                      : ""
                        }

                        // Presence sits next to the address, as "(Busy)" does
                        // on the reference, rather than only dimming the row.
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: appTheme.disabledTextColor
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            text: {
                                if (!row.option || row.option.kind !== "im") return "";
                                if (!contactLookupPage.imBuddyStatus) return "";

                                return contactLookupPage.imBuddyStatus.isAvailable(row.option.type,
                                                                                   row.option.value)
                                           ? "" : qsTr("(Offline)");
                            }
                        }

                        // A video-capable row offers video, using the original
                        // app's own list icon.
                        Image {
                            Layout.preferredWidth: Units.gu(3.4)
                            Layout.preferredHeight: Units.gu(3.2)
                            fillMode: Image.PreserveAspectFit
                            source: Qt.resolvedUrl("images/Camera-Icon.png")
                            visible: !!row.option && row.option.supportsVideo
                            opacity: videoArea.pressed ? 0.6 : 1.0

                            MouseArea {
                                id: videoArea
                                anchors.fill: parent
                                anchors.margins: -Units.gu(0.8)
                                onClicked: contactLookupPage._dial(row.rowData.person, row.option, true)
                            }
                        }

                        // The service this row would call over, as on the original.
                        Text {
                            Layout.preferredWidth: Units.gu(9)
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
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
