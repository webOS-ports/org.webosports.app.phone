/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import QtQuick 2.15

import LunaNext.Common 0.1
import LuneOS.Components 1.0

import "../model"
import "../services"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * Who is in the conference, one row each, as webOS 2.x's SingleConferenceCall
 * listed them in the call card: the name, or the number for someone not in
 * Contacts, in a 48 pixel row (.conference-call-display-name). Tapping a row
 * opens a drawer under it with two buttons from conf-list-buttons.png - hang
 * up on that caller alone, or take them aside into a private call - and
 * closes whichever row was open before. Tapping it again closes it.
 */
Column {
    id: members

    property var calls: []
    property ContactsModel contacts
    property UiTheme appTheme

    /// The row whose drawer is open, by index; -1 for none.
    property int openIndex: -1

    signal hangupRequested(var call)
    signal privateRequested(var call)

    // A member leaving shifts the rows; close the drawer rather than leave it
    // open under someone else.
    onCallsChanged: openIndex = -1

    Repeater {
        model: members.calls

        delegate: Column {
            id: row

            required property var modelData
            required property int index

            readonly property bool open: members.openIndex === index

            width: members.width

            Contact {
                id: contact
                contactsModel: members.contacts
                lineId: row.modelData ? row.modelData.lineId : ""
            }

            // .conference-call-list-item: a hairline above and below each row.
            Rectangle {
                width: parent.width
                height: 1
                color: '#4b4b4b'
            }

            Item {
                width: parent.width
                height: Units.gu(4.8)

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: Units.gu(1)
                        rightMargin: Units.gu(1)
                    }
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: '#ffffff'
                    font.pixelSize: Units.gu(1.8)
                    text: contact.personId.length > 0
                          ? contact.displayLabel.trim()
                          : PhoneNumberUtils.formatForDisplay(row.modelData ? row.modelData.lineId : "",
                                                              members.contacts ? members.contacts.countryCode : "US",
                                                              false)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: members.openIndex = row.open ? -1 : row.index
                }
            }

            // The drawer: hang up, and private, side by side.
            Item {
                width: parent.width
                height: row.open ? Units.gu(5.6) : 0
                visible: row.open
                clip: true

                Row {
                    anchors.centerIn: parent
                    spacing: Units.gu(0.4)

                    // Frames, top to bottom: hang up up, disabled, down; then
                    // private up, disabled, down.
                    SpriteIcon {
                        objectName: "hangupButton"
                        width: Units.gu(15.5)
                        height: Units.gu(4.8)
                        source: members.appTheme ? members.appTheme.image("conf-list-buttons.png") : ""
                        frameCount: 6
                        frame: hangupArea.pressed ? 2 : 0

                        MouseArea {
                            id: hangupArea
                            anchors.fill: parent
                            onClicked: {
                                members.openIndex = -1;
                                members.hangupRequested(row.modelData);
                            }
                        }
                    }

                    SpriteIcon {
                        objectName: "privateButton"
                        width: Units.gu(15.5)
                        height: Units.gu(4.8)
                        source: members.appTheme ? members.appTheme.image("conf-list-buttons.png") : ""
                        frameCount: 6
                        frame: privateArea.pressed ? 5 : 3

                        MouseArea {
                            id: privateArea
                            anchors.fill: parent
                            onClicked: {
                                members.openIndex = -1;
                                members.privateRequested(row.modelData);
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: '#0b0b0b'
            }
        }
    }
}
