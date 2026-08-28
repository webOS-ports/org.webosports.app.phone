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
import QtQuick.Layouts 1.2

import LunaNext.Common 0.1
import LuneOS.Components 1.0
import org.nemomobile.voicecall 1.0

import "../model"
import "../services"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/CallMessages.js" as CallMessages

/**
 * One call line inside the active call card.
 *
 * Laid out like the webOS 3.x call card on the TouchPad: the caller's name,
 * then their address with the service it is on in grey caps beside it, then
 * the call's state or its duration, then a footer split between a red hangup
 * and a merge/swap arrow. Two of these stack inside the same card when a second
 * call arrives, which is exactly what the original does.
 */
Item {
    id: callLine

    property var voiceCall
    property ContactsModel contacts
    property PhoneUiTheme appTheme
    property CallTransports callTransports
    property bool selected: false
    /// Shows the merge/swap arrow; the card decides when that is meaningful.
    property bool canJoin: false
    /// With a single call the card carries the hangup button, so the line does
    /// not repeat it. Only stacked lines need their own.
    property bool showFooter: false

    signal clicked();
    signal hangupRequested();
    signal joinRequested();
    signal addContactRequested();

    property Contact lineContact: Contact {
        contactsModel: callLine.contacts
        lineId: callLine.voiceCall ? callLine.voiceCall.lineId : ""
    }

    readonly property bool isKnownContact: lineContact.personId.length > 0

    readonly property string displayName: {
        if (!voiceCall) return "";
        if (voiceCall.isMultiparty) return CallMessages.conferenceCall;
        if (isKnownContact) return lineContact.displayLabel;
        if (voiceCall.displayName && voiceCall.displayName.length > 0) return voiceCall.displayName;

        return qsTr("Unknown Caller");
    }

    readonly property string displayAddress: {
        if (!voiceCall) return "";
        return PhoneNumberUtils.formatForDisplay(voiceCall.lineId,
                                                 contacts ? contacts.countryCode : "US", false);
    }

    /// "TELEGRAM", "SIGNAL", ... Cellular stays unlabelled, as on the original.
    readonly property string serviceLabel: {
        if (!voiceCall || !callTransports) return "";

        var provider = voiceCall.providerId || "";
        if (provider.length === 0 || provider === callTransports.cellularTransport)
            return "";

        return callTransports.labelFor(provider).toUpperCase();
    }

    readonly property string stateText: {
        if (!voiceCall) return "";

        switch (voiceCall.status) {
        case VoiceCall.STATUS_ACTIVE:
            return PhoneNumberUtils.formatDuration(voiceCall.duration / 1000);
        case VoiceCall.STATUS_HELD:       return CallMessages.callStateHold;
        case VoiceCall.STATUS_DIALING:
        case VoiceCall.STATUS_ALERTING:   return qsTr("Connecting");
        case VoiceCall.STATUS_INCOMING:   return CallMessages.callStateIncoming;
        case VoiceCall.STATUS_WAITING:    return CallMessages.callStateWaiting;
        case VoiceCall.STATUS_DISCONNECTED: return CallMessages.callStateEnded;
        default: return "";
        }
    }

    height: body.height + (showFooter ? footer.height : 0)

    // A held call is dimmed so which one is live reads at a glance.
    opacity: (voiceCall && voiceCall.status === VoiceCall.STATUS_HELD) ? 0.55 : 1.0

    Rectangle {
        id: body

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: detailsColumn.height + Units.gu(2)
        color: callLine.selected ? '#1b1b1b' : appTheme.panelDarkColor

        ColumnLayout {
            id: detailsColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: Units.gu(1)
                leftMargin: Units.gu(1.5)
                rightMargin: Units.gu(1.5)
            }
            spacing: Units.gu(0.3)

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: appTheme.primaryTextColor
                font.pixelSize: FontUtils.sizeToPixels("large")
                text: callLine.displayName
            }

            // Address and service, centred together as one line.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Units.gu(0.8)

                Text {
                    color: appTheme.primaryTextColor
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    text: callLine.displayAddress
                }
                Text {
                    color: appTheme.serviceTextColor
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    text: callLine.serviceLabel
                    visible: callLine.serviceLabel.length > 0
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: Units.gu(0.5)
                horizontalAlignment: Text.AlignHCenter
                color: appTheme.primaryTextColor
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: callLine.stateText
            }
        }

        // Offer to save a caller who is not in Contacts, as the original does.
        SpriteIcon {
            anchors {
                top: parent.top
                right: parent.right
                margins: Units.gu(1)
            }
            width: Units.gu(2.6)
            height: Units.gu(2.6)
            source: Qt.resolvedUrl("images/menu-icon-addcontact.png")
            frame: addContactArea.pressed ? 1 : 0
            visible: !callLine.isKnownContact && callLine.voiceCall &&
                     callLine.voiceCall.lineId.length > 0

            MouseArea {
                id: addContactArea
                anchors.fill: parent
                onClicked: callLine.addContactRequested()
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: callLine.clicked()
        }
    }

    // Hangup on the left, join/swap on the right, split by a hairline.
    Item {
        id: footer

        anchors { top: body.bottom; left: parent.left; right: parent.right }
        height: Units.gu(5)
        visible: callLine.showFooter

        Rectangle {
            anchors.fill: parent
            color: appTheme.panelFooterColor
        }

        Row {
            anchors.fill: parent

            Item {
                width: callLine.canJoin ? parent.width / 2 : parent.width
                height: parent.height

                SpriteIcon {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("images/multicall-disconnect-button.png")
                    frameCount: 3
                    frame: hangupArea.pressed ? 1 : 0
                }

                MouseArea {
                    id: hangupArea
                    anchors.fill: parent
                    onClicked: callLine.hangupRequested()
                }
            }

            Rectangle {
                width: callLine.canJoin ? 1 : 0
                height: parent.height
                color: appTheme.buttonBorderColor
            }

            Item {
                width: callLine.canJoin ? (parent.width / 2 - 1) : 0
                height: parent.height
                visible: callLine.canJoin

                SpriteIcon {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("images/multicall-merge-button.png")
                    frameCount: 3
                    frame: joinArea.pressed ? 1 : 0
                }

                MouseArea {
                    id: joinArea
                    anchors.fill: parent
                    onClicked: callLine.joinRequested()
                }
            }
        }
    }
}
