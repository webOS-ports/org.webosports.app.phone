/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtQuick.Layouts 1.2
import QtQml

import LunaNext.Common 0.1
import LuneOS.Components 1.0
import LuneOS.Service 1.0
import LuneOS.Telephony 1.0

import "../model"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * The opened call group: first every call in it, then the contact's other
 * numbers, then their card -- the order com.palm.app.phone uses.
 *
 * The individual calls carry the grey call-type icon; only the group's own row
 * above uses the coloured one. Their icon and time line up with the columns of
 * that row, so the drawer reads as a continuation of it.
 *
 * A past call is a shorter row than one the user can act on, and the two kinds
 * are told apart by rule as well as by height: only the actionable rows are
 * separated from one another.
 */
Column {
    id: callGroupDetailsId

    property ContactsModel contacts;

    property var callGroupRemotePerson;
    property var callGroupAddress;
    property string callGroupId;
    property var dialHandler;
    property var callTransports;
    property PhoneUiTheme appTheme: PhoneUiTheme {}

    readonly property string callService: (callGroupAddress && callGroupAddress.service)
                                              ? callGroupAddress.service : ""
    readonly property bool isSynergyCall: callService.length > 0 && callService !== "com.palm.telephony"

    readonly property string groupPhoneNumber: callGroupAddress ? (callGroupAddress.addr || "") : ""

    // The trailing columns of the group's own row, so the icons and times in
    // here sit under the ones up there.
    readonly property real iconColumn: Units.gu(2.2)
    readonly property real timeColumn: Units.gu(5)
    readonly property real trailingColumn: Units.gu(3.4)

    /// "(19 sec)", as the original writes it. Nothing at all for a call that
    /// was never answered, rather than an empty pair of brackets.
    function _durationText(milliseconds) {
        var spoken = PhoneNumberUtils.formatDurationLong(Math.round(milliseconds / 1000));
        return spoken.length > 0 ? "(" + spoken + ")" : "";
    }

    /**
     * What a call went over: the network's name for a Synergy call, and for a
     * cellular one the type of the number it reached -- MOBILE, HOME, WORK --
     * which is what com.palm.app.phone puts in this column.
     */
    function _prefixLabelFor(address) {
        if (!address)
            return "";

        var service = address.service;
        if (service && service !== "com.palm.telephony")
            return callTransports ? callTransports.labelFor(service).toUpperCase() : "";

        if (!address.personAddressType)
            return "";

        return contacts.getPhoneNumberTypeStr(address.personAddressType).toUpperCase();
    }

    // 1. Every call in the group.
    Repeater {
        id: modelRepeater

        width: parent.width
        model: CallGroupItems { callGroupId: callGroupDetailsId.callGroupId }

        delegate: Item {
            id: callphoneDelegate

            width: modelRepeater.width
            height: appTheme.drawerCallRowHeight

            Rectangle {
                anchors.fill: parent
                color: appTheme.listSectionColor
            }

            property date _timestamp: new Date(model.timestamp)
            property var _remotePerson: (model.type !== "outgoing") ? model.from
                                                                    : (Array.isArray(model.to) ? model.to[0] : model.to.get(0))
            property string _service: callGroupDetailsId._prefixLabelFor(_remotePerson)
            property string _number: LibPhoneNumber.formatPhoneNumberForDisplay(_remotePerson.addr,
                                                                                contacts.countryCode)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: appTheme.drawerIndent
                anchors.rightMargin: Units.gu(0.8)
                spacing: Units.gu(0.8)

                Text {
                    Layout.preferredWidth: Units.gu(7)
                    color: appTheme.serviceTextColor
                    elide: Text.ElideRight
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: callphoneDelegate._service
                }

                Text {
                    Layout.fillWidth: true
                    color: appTheme.listSecondaryTextColor
                    elide: Text.ElideRight
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: callphoneDelegate._number + " " +
                          callGroupDetailsId._durationText(model.duration)
                }

                // Grey here; the group's own row above carries the coloured one.
                ClippedImage {
                    Layout.preferredWidth: callGroupDetailsId.iconColumn
                    Layout.preferredHeight: callGroupDetailsId.iconColumn

                    source: Qt.resolvedUrl('images/call-log-list-light-sprite.png')
                    wantedWidth: callGroupDetailsId.iconColumn
                    wantedHeight: callGroupDetailsId.iconColumn
                    imageSize: Qt.size(22, 91)
                    patchGridSize: Qt.size(1, 4)
                    patch: (model.type === "missed") ? Qt.point(0,0) :
                           (model.type === "incoming") ? Qt.point(0,1) :
                           (model.type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
                }

                Text {
                    Layout.preferredWidth: callGroupDetailsId.timeColumn
                    horizontalAlignment: Text.AlignRight
                    color: appTheme.listSecondaryTextColor
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: Qt.formatTime(callphoneDelegate._timestamp,
                                        Qt.locale().timeFormat(Locale.ShortFormat))
                }

                // Keeps these columns lined up under the expand button above.
                Item { Layout.preferredWidth: callGroupDetailsId.trailingColumn }
            }
        }
    }

    // 2. The contact's numbers, each of which can be called or messaged.
    Loader {
        active: callGroupRemotePerson !== null
        width: parent.width

        sourceComponent: Component {
            Column {
                width: parent.width

                Repeater {
                    width: parent.width
                    model: callGroupRemotePerson.phoneNumbers

                    delegate: Column {
                        width: parent.width

                        property string _phoneNumberValue: model.value ? model.value : modelData.value
                        property string _phoneNumberType: model.type ? model.type : modelData.type

                        ListSeparator { width: parent.width }

                    Item {
                        width: parent.width
                        height: appTheme.drawerRowHeight

                        Rectangle {
                            anchors.fill: parent
                            color: numberArea.pressed ? appTheme.listSelectedColor
                                                      : appTheme.listSectionColor
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: appTheme.drawerIndent
                            anchors.rightMargin: Units.gu(0.8)
                            spacing: Units.gu(0.8)

                            Text {
                                Layout.fillWidth: true
                                color: appTheme.listTextColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("medium")
                                text: LibPhoneNumber.formatPhoneNumberForDisplay(_phoneNumberValue,
                                                                                 contacts.countryCode)
                            }

                            Text {
                                color: appTheme.serviceTextColor
                                font.capitalization: Font.AllUppercase
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: contacts.getPhoneNumberTypeStr(_phoneNumberType)
                            }

                            // The teal bubble from the original's button sprite.
                            Item {
                                Layout.preferredWidth: Units.gu(3.4)
                                Layout.preferredHeight: Units.gu(3.4)

                                ClippedImage {
                                    anchors.centerIn: parent
                                    source: Qt.resolvedUrl('images/button-sprite.png')
                                    wantedWidth: Units.gu(3.4)
                                    wantedHeight: Units.gu(3.4)
                                    imageSize: Qt.size(184, 246)
                                    patchGridSize: Qt.size(3, 4)
                                    patch: smsButtonMouseArea.pressed ? Qt.point(2,1) : Qt.point(2,0)
                                }

                                MouseArea {
                                    id: smsButtonMouseArea
                                    anchors.fill: parent
                                    onClicked: callGroupDetailsId.sendMessage(_phoneNumberValue, "")
                                }
                            }
                        }

                        MouseArea {
                            id: numberArea
                            anchors.fill: parent
                            z: -1
                            onClicked: {
                                if (callGroupDetailsId.dialHandler)
                                    callGroupDetailsId.dialHandler.dial(_phoneNumberValue, "", false);
                            }
                        }
                    }
                    }
                }
            }
        }
    }

    // 3. The contact card, last.
    ListSeparator {
        width: parent.width
        drawn: callGroupDetailsId.groupPhoneNumber.length > 0
    }

    Item {
        width: parent.width
        height: appTheme.drawerRowHeight
        visible: callGroupDetailsId.groupPhoneNumber.length > 0

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
            text: callGroupDetailsId.callGroupRemotePerson ? qsTr("View Contact")
                                                           : qsTr("Add to Contacts")
        }

        MouseArea {
            id: viewArea
            anchors.fill: parent
            onClicked: {
                if (callGroupDetailsId.callGroupRemotePerson)
                    callGroupDetailsId.viewContact(callGroupDetailsId.callGroupRemotePerson._id);
                else
                    callGroupDetailsId.addToContacts(callGroupDetailsId.groupPhoneNumber);
            }
        }
    }

    /// Opens the messaging app on a conversation with this address. A Synergy
    /// address opens the conversation on its own service rather than as an SMS.
    function sendMessage(address, service) {
        var compose = { messageText: "", personId: "", address: address };
        if (service && service.length > 0 && callTransports) {
            var transport = callTransports.transportFor(service);
            if (transport && transport.serviceName)
                compose.serviceName = transport.serviceName;
        }

        _launch("com.palm.app.messaging", { compose: compose });
    }

    function viewContact(personId) {
        _launch("com.palm.app.contacts", { personId: personId });
    }

    function addToContacts(phoneNumber) {
        _launch("com.palm.app.contacts", { newContact: { phoneNumbers: [ { value: phoneNumber, type: "type_mobile" } ] } });
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
