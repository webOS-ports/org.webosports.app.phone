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

import QtQuick 2.15
import QtQuick.Layouts 1.0

import org.nemomobile.voicecall 1.0

import LuneOS.Service 1.0
import LuneOS.Telephony 1.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/CallMessages.js" as CallMessages

/**
 * The in-call screen.
 *
 * Laid out like the webOS 3.x call card: a single centred panel holding one
 * line per call, and a row of controls underneath. A second call stacks into
 * the same card rather than replacing it, which is what makes swapping and
 * merging make sense visually.
 *
 * Beyond the single call the original QML app handled, this covers what the
 * legacy ActiveCall/MultilineCall scenes did -- hold, swap, conference, split,
 * audio routing, post-dial DTMF -- and shows which Synergy account each call is
 * on.
 */
BasePage {
    id: root

    pageName: "ActiveCall"

    property Item dtmfKeypadDialog
    property VoiceCallManager voiceCallManager: voiceCallMgrWrapper.manager

    /// Emitted when the user taps "Add call" and wants the dialpad back.
    signal addCallRequested();

    property bool voiceCallIsActive: voiceCall && voiceCall.status === VoiceCall.STATUS_ACTIVE

    // Every call in progress. With one call the card holds one line.
    readonly property var allCalls: voiceCallMgrWrapper ? voiceCallMgrWrapper.allCallsList : []
    readonly property bool multipleCalls: allCalls.length > 1

    // Which call the controls apply to. Follows the active call unless the user
    // taps another line.
    property var selectedCall: voiceCall

    onVoiceCallChanged: selectedCall = voiceCall

    readonly property string formattedAddress: selectedCall
        ? PhoneNumberUtils.formatForDisplay(selectedCall.lineId,
                                            contacts ? contacts.countryCode : "US", false)
        : ""

    /**
     * The network a Synergy call is going over, in caps. Blank for a cellular
     * call, and blank for a provider the transport registry does not know --
     * otherwise an unrecognised id gets tidied into a label and shown as if it
     * were the name of a service.
     */
    readonly property string serviceLabel: {
        if (!selectedCall || !callTransports) return "";

        var provider = selectedCall.providerId || "";
        if (provider.length === 0 || provider === callTransports.cellularTransport) return "";
        if (!callTransports.transportFor(provider)) return "";

        return callTransports.labelFor(provider).toUpperCase();
    }

    function open() { root.visible = true }
    function close() { root.visible = false }

    // The page behind the call: #25394a with backdrop-phone.png banded across
    // the top of it, which is what .single-call-simple is.
    color: '#25394a'
    gradient: null

    Image {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: sourceSize.height
        source: Qt.resolvedUrl("images/backdrop-phone.png")
        fillMode: Image.TileHorizontally
    }

    /**
     * The call card
     **/

    Item {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Units.gu(2), (parent.height - controlsRow.height - Units.gu(4) - height) / 2)

        width: Math.min(parent.width - Units.gu(4), Units.gu(40))
        height: cardColumn.height

        /*
         * The glass the call sits behind. One nine-slice covers what the
         * original splits between .single-call-header, .single-call-glass and
         * .glass-footer: the top sixty-one rows are the header, the bottom
         * twenty-two the footer, and the translucent black between them
         * stretches to however tall the card is.
         */
        BorderImage {
            anchors.fill: parent
            source: Qt.resolvedUrl("images/glass-panel.png")
            border { left: 22; right: 22; top: 61; bottom: 22 }
            horizontalTileMode: BorderImage.Stretch
            verticalTileMode: BorderImage.Stretch
        }

        Column {
            id: cardColumn
            width: parent.width

            // Who is on the line. Eighteen pixel name over a sixteen pixel
            // address over a fourteen pixel network label, all centred, as
            // .single-call-display-name / -address / -label have them.
            Item {
                width: parent.width
                height: visible ? nameColumn.height + Units.gu(1.6) : 0
                visible: !root.multipleCalls

                Column {
                    id: nameColumn

                    anchors {
                        top: parent.top
                        topMargin: Units.gu(0.8)
                        left: parent.left
                        right: parent.right
                        leftMargin: Units.gu(1.2)
                        rightMargin: Units.gu(1.2)
                    }
                    spacing: 0

                    Text {
                        id: displayName

                        // The name if the caller is known, else what they
                        // dialled from. A Contact that has not resolved yet
                        // reports no name rather than an empty one.
                        readonly property string contactName:
                            root.currentContact ? String(root.currentContact.displayLabel || "").trim() : ""

                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: '#ffffff'
                        font.pixelSize: Units.gu(1.8)
                        lineHeight: Units.gu(3.6)
                        lineHeightMode: Text.FixedHeight
                        text: contactName.length > 0 ? contactName : root.formattedAddress
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: '#ffffff'
                        font.pixelSize: Units.gu(1.6)
                        visible: displayName.contactName.length > 0 && text.length > 0
                        text: root.formattedAddress
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: '#999999'
                        font.pixelSize: Units.gu(1.4)
                        visible: text.length > 0
                        text: root.serviceLabel
                    }
                }
            }

            // One line per call. The photo only appears for a single call --
            // with two lines up there is no room, exactly as on the original.
            Repeater {
                model: root.allCalls

                delegate: Column {
                    required property var modelData
                    required property int index

                    width: cardColumn.width

                    // Hairline between stacked lines.
                    Rectangle {
                        width: parent.width
                        height: index > 0 ? 1 : 0
                        color: '#00000060'
                    }

                    CallLineDelegate {
                        width: cardColumn.width

                        voiceCall: modelData
                        contacts: root.contacts
                        appTheme: root.appTheme
                        callTransports: root.callTransports
                        selected: root.multipleCalls && root.selectedCall === modelData
                        showFooter: root.multipleCalls
                        canJoin: root.multipleCalls && voiceCallMgrWrapper.canMerge
                        visible: root.multipleCalls

                        onClicked: root.selectedCall = modelData
                        onHangupRequested: modelData.hangup()
                        onJoinRequested: voiceCallMgrWrapper.merge()
                        onAddContactRequested: root._addToContacts(modelData.lineId)
                    }
                }
            }

            // The contact's photo in its stamp frame, shown for a single call.
            Item {
                width: parent.width
                height: visible ? Units.gu(16.6) : 0
                visible: !root.multipleCalls && !flipable.flipped

                Item {
                    anchors.centerIn: parent
                    width: Units.gu(17)
                    height: Units.gu(14)

                    Image {
                        id: imageAvatar
                        anchors.fill: parent

                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        source: root.currentContact ? root.currentContact.avatarPath : Qt.resolvedUrl("images/contacts-unknown-icon-large.png")
                    }

                    // active-photo-overlay.png is three pixels proud of the
                    // photo on every side, which is how it frames it.
                    Image {
                        anchors.centerIn: parent
                        width: parent.width + Units.gu(0.6)
                        height: parent.height + Units.gu(0.6)
                        source: Qt.resolvedUrl("images/active-photo-overlay.png")
                    }
                }
            }

            // The DTMF pad takes the photo's place when the dialpad is on.
            Item {
                id: flipable

                property bool flipped: false

                width: parent.width
                height: flipped ? Units.gu(26) : 0
                visible: flipped
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: '#00000080'
                }

                Text {
                    id: tLineId
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    height: Units.gu(3)
                    verticalAlignment: Text.AlignVCenter
                    color: '#ffffff'
                    font.pixelSize: Units.gu(1.6)
                    text: root.selectedCall ? root.selectedCall.lineId : ""
                }

                NumPad {
                    anchors {
                        top: tLineId.bottom
                        bottom: parent.bottom
                        right: parent.right
                        left: parent.left
                    }
                    mode: 'dtmf'

                    // Send the tone down the line as well as echoing it, which
                    // the original page never did -- the pad looked live but
                    // was not.
                    onSendKey: (keycode) => {
                        var tone = String.fromCharCode(keycode);
                        tLineId.text += tone;
                        if (root.selectedCall)
                            root.selectedCall.sendDtmf(tone);
                    }
                }
            }

            // A post-dial string that stopped at a 'wait' needs the user to say go.
            Item {
                width: parent.width
                height: visible ? Units.gu(5) : 0
                visible: postDialPrompt.remainder.length > 0

                Text {
                    id: postDialPrompt
                    property string remainder: ""

                    anchors.centerIn: parent
                    color: '#ffffff'
                    font.pixelSize: Units.gu(1.6)
                    text: qsTr("Send %1").arg(remainder)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        voiceCallMgrWrapper.sendPendingPostDial(root.selectedCall);
                        postDialPrompt.remainder = "";
                    }
                }

                Connections {
                    target: voiceCallMgrWrapper
                    function onPostDialWaiting(voiceCall, remainder) {
                        postDialPrompt.remainder = remainder;
                    }
                }
            }

            // How long the call has been up, with MUTE called out in front of
            // it while the microphone is off -- LineState's prefix label.
            Item {
                width: parent.width
                height: Units.gu(4.5)

                Row {
                    anchors.centerIn: parent
                    spacing: Units.gu(0.5)

                    Text {
                        color: '#ffffff'
                        font.bold: true
                        font.pixelSize: Units.gu(1.6)
                        visible: voiceCallManager ? voiceCallManager.isMicrophoneMuted : false
                        text: qsTr("MUTE")
                    }

                    Text {
                        color: '#ffffff'
                        font.pixelSize: Units.gu(1.6)
                        text: root.selectedCall
                                  ? PhoneNumberUtils.formatDuration(root.selectedCall.duration / 1000)
                                  : ""
                    }
                }
            }

            // With a single call this ends it; with several, each line carries
            // its own hangup and this ends them all.
            Item {
                width: parent.width
                height: Units.gu(6.6)

                // Three states stacked in the one file, in the order the CSS
                // slices them: up, disabled, down.
                SpriteIcon {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Units.gu(0.6)
                        rightMargin: Units.gu(0.6)
                    }
                    height: Units.gu(6.6)

                    source: Qt.resolvedUrl("images/disconnect-button.png")
                    frameCount: 3
                    frame: hangupAllArea.pressed ? 2 : 0
                }

                MouseArea {
                    id: hangupAllArea
                    anchors.fill: parent
                    onClicked: {
                        if (root.multipleCalls)
                            voiceCallMgrWrapper.hangupAll();
                        else if (root.selectedCall)
                            root.selectedCall.hangup();

                        root.close();
                    }
                }
            }
        }
    }

    /**
     * The call controls
     **/

    Row {
        id: controlsRow

        anchors {
            top: card.bottom
            topMargin: Units.gu(1.5)
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Units.gu(0.6)

        // Cycles earpiece -> speaker -> headset -> bluetooth, showing which one
        // is in use. The legacy app used a popup menu for the same thing.
        CallActionButton {
            appTheme: root.appTheme
            visible: root.voiceCallIsActive
            iconSource: {
                if (!root.audioRouteManager)
                    return Qt.resolvedUrl("images/menu-icon-speaker.png");

                switch (root.audioRouteManager.currentRoute) {
                case root.audioRouteManager.routeBluetooth:
                    return Qt.resolvedUrl("images/menu-popup-bluetooth.png");
                case root.audioRouteManager.routeWiredHeadset:
                    return Qt.resolvedUrl("images/menu-icon-headset.png");
                default:
                    return Qt.resolvedUrl("images/menu-icon-speaker.png");
                }
            }
            label: qsTr("Speaker")
            active: root.audioRouteManager ? root.audioRouteManager.speakerOn : false
            onClicked: {
                if (root.audioRouteManager)
                    root.audioRouteManager.nextRoute();
            }
        }

        CallActionButton {
            appTheme: root.appTheme
            visible: root.voiceCallIsActive
            iconSource: Qt.resolvedUrl("images/menu-icon-mute.png")
            label: qsTr("Mute")
            active: voiceCallManager ? voiceCallManager.isMicrophoneMuted : false
            onClicked: voiceCallManager.setMuteMicrophone(!voiceCallManager.isMicrophoneMuted)
        }

        CallActionButton {
            appTheme: root.appTheme
            visible: root.voiceCallIsActive
            iconSource: Qt.resolvedUrl("images/menu-icon-dtmfpad.png")
            label: qsTr("Dialpad")
            active: flipable.flipped
            onClicked: flipable.flipped = !flipable.flipped
        }

        // Swap and split only appear once there is something to act on, which
        // is how the legacy AbstractCallButtons decided too. Merge lives on the
        // call line itself, as it does on the original card.
        CallActionButton {
            appTheme: root.appTheme
            visible: voiceCallMgrWrapper.canSwap
            iconSource: Qt.resolvedUrl("images/multicall-switch-button.png")
            label: qsTr("Swap")
            onClicked: voiceCallMgrWrapper.swap()
        }

        CallActionButton {
            appTheme: root.appTheme
            visible: voiceCallMgrWrapper.canSplit
            iconSource: Qt.resolvedUrl("images/multicall-resume-button.png")
            label: qsTr("Split")
            onClicked: voiceCallMgrWrapper.split(root.selectedCall)
        }

        CallActionButton {
            appTheme: root.appTheme
            visible: voiceCallMgrWrapper.canAddCall
            iconSource: Qt.resolvedUrl("images/menu-icon-addcall.png")
            label: qsTr("Add Call")
            onClicked: root.addCallRequested()
        }
    }

    function _addToContacts(address) {
        lunaService.call("luna://com.webos.applicationManager/launch",
                         JSON.stringify({ id: "com.palm.app.contacts",
                                          params: { newContact: { phoneNumbers: [ { value: address } ] } } }),
                         undefined,
                         function(error) { console.log("Could not open Contacts: " + error); });
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
    }
}
