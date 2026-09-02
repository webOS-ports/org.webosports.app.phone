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
import "../services"
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
Item {
    id: callGroupDetailsId

    implicitHeight: drawerContent.height

    property ContactsModel contacts;

    property var callGroupRemotePerson;
    property var callGroupAddress;
    property string callGroupId;
    property DialHandler dialHandler;
    property CallTransports callTransports;
    property UiTheme appTheme: PhoneUiTheme {}

    readonly property string callService: (callGroupAddress && callGroupAddress.service)
                                              ? callGroupAddress.service : ""
    readonly property bool isSynergyCall: callService.length > 0 && callService !== "com.palm.telephony"

    readonly property string groupPhoneNumber: callGroupAddress ? (callGroupAddress.addr || "") : ""

    /**
     * How wide the column naming what each call went over has to be.
     *
     * A transport can be called anything -- "WHATSAPP" already overruns the
     * sixty pixels the original allowed, which is why the reference runs the
     * network name and the number into each other. Widen the column to the
     * longest name in this drawer instead, so the numbers still line up
     * underneath one another without anything being cut short.
     */
    property real prefixColumn: Units.gu(7)

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

    /*
     * The drawer is sunk into the row that opened it: call-log-drawer-sub-item-bg
     * darkens ten pixels at its top and bottom and is flat between, so it fits
     * a drawer of any depth. In the original this is the border of the two
     * .hidden-drawer-item halves, which between them cover the whole drawer.
     */
    BorderImage {
        anchors.fill: drawerContent
        source: appTheme.drawerBackgroundSource
        border { left: 10; right: 10; top: 10; bottom: 10 }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
    }

    Column {
        id: drawerContent

        width: parent.width

    // 1. Every call in the group.
    Repeater {
        id: modelRepeater

        width: parent.width
        model: CallGroupItems { callGroupId: callGroupDetailsId.callGroupId }

        delegate: Item {
            id: callphoneDelegate

            width: modelRepeater.width
            height: appTheme.drawerCallRowHeight

            property date _timestamp: new Date(model.timestamp)
            property var _remotePerson: (model.type !== "outgoing") ? model.from
                                                                    : (Array.isArray(model.to) ? model.to[0] : model.to.get(0))
            property string _service: callGroupDetailsId._prefixLabelFor(_remotePerson)
            property string _number: LibPhoneNumber.formatPhoneNumberForDisplay(_remotePerson.addr,
                                                                                contacts.countryCode)
            /// The account this particular call went over, so tapping it back
            /// reaches the same place -- a group can hold calls over several.
            property string _transport: (_remotePerson.service &&
                                         _remotePerson.service !== "com.palm.telephony")
                                            ? _remotePerson.service : ""

            Rectangle {
                anchors.fill: parent
                color: callArea.pressed ? appTheme.listSelectedColor : 'transparent'
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: appTheme.drawerIndent
                anchors.rightMargin: Units.gu(0.8)
                spacing: Units.gu(0.8)

                Text {
                    id: prefixLabel

                    Layout.preferredWidth: callGroupDetailsId.prefixColumn
                    color: appTheme.serviceTextColor
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: callphoneDelegate._service

                    onImplicitWidthChanged: callGroupDetailsId.prefixColumn =
                        Math.max(callGroupDetailsId.prefixColumn, implicitWidth)
                    Component.onCompleted: callGroupDetailsId.prefixColumn =
                        Math.max(callGroupDetailsId.prefixColumn, implicitWidth)
                }

                Text {
                    Layout.fillWidth: true
                    color: appTheme.drawerNumberColor
                    elide: Text.ElideRight
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: callphoneDelegate._number + " " +
                          callGroupDetailsId._durationText(model.duration)
                }

                // Grey here; the group's own row above carries the coloured one.
                ClippedImage {
                    Layout.preferredWidth: callGroupDetailsId.iconColumn
                    Layout.preferredHeight: callGroupDetailsId.iconColumn

                    source: appTheme.image("call-log-list-light-sprite.png")
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
                    color: appTheme.drawerNumberColor
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: Qt.formatTime(callphoneDelegate._timestamp,
                                        Qt.locale().timeFormat(Locale.ShortFormat))
                }

                // Keeps these columns lined up under the expand button above.
                Item { Layout.preferredWidth: callGroupDetailsId.trailingColumn }
            }

            // Calling a past call back places it over the account it used.
            MouseArea {
                id: callArea

                anchors.fill: parent
                enabled: !!callphoneDelegate._remotePerson.addr

                onClicked: {
                    if (callGroupDetailsId.dialHandler)
                        callGroupDetailsId.dialHandler.dial(callphoneDelegate._remotePerson.addr,
                                                            callphoneDelegate._transport, false);
                }
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
                                                      : 'transparent'
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
                                color: appTheme.listSecondaryTextColor
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
                                    source: appTheme.image("button-sprite.png")
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
        appTheme: callGroupDetailsId.appTheme
        width: parent.width
        drawn: callGroupDetailsId.groupPhoneNumber.length > 0
    }

    Item {
        width: parent.width
        height: appTheme.drawerRowHeight
        visible: callGroupDetailsId.groupPhoneNumber.length > 0

        Rectangle {
            anchors.fill: parent
            color: viewArea.pressed ? appTheme.listSelectedColor : 'transparent'
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
    }
}
