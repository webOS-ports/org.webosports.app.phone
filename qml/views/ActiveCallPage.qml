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
import QtQuick.Layouts 1.0

import org.nemomobile.voicecall 1.0

import LuneOS.Service 1.0
import LuneOS.Telephony 1.0

import LunaNext.Common 0.1

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

    function open() { root.visible = true }
    function close() { root.visible = false }

    color: appTheme.backgroundColor
    gradient: null

    /**
     * The call card
     **/

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Units.gu(2), (parent.height - controlsRow.height - Units.gu(4) - height) / 2)

        width: Math.min(parent.width - Units.gu(4), Units.gu(40))
        height: cardColumn.height

        radius: Units.gu(1)
        color: appTheme.panelColor
        border.color: appTheme.panelBorderColor
        border.width: 1
        clip: true

        Column {
            id: cardColumn
            width: parent.width

            // One line per call. The avatar only appears for a single call --
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
                        color: appTheme.panelBorderColor
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

                        onClicked: root.selectedCall = modelData
                        onHangupRequested: modelData.hangup()
                        onJoinRequested: voiceCallMgrWrapper.merge()
                        onAddContactRequested: root._addToContacts(modelData.lineId)
                    }
                }
            }

            // The avatar well, shown only for a single call.
            Item {
                width: parent.width
                height: visible ? Units.gu(20) : 0
                visible: !root.multipleCalls && !flipable.flipped

                Rectangle {
                    anchors.fill: parent
                    gradient: appTheme.panelGradient
                }

                Image {
                    id: imageAvatar
                    anchors.centerIn: parent
                    width: Units.gu(14)
                    height: Units.gu(14)

                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    source: currentContact.avatarPath
                    visible: false
                }
                CornerShader {
                    anchors.fill: imageAvatar
                    source: imageAvatar
                    radius: Units.gu(1)
                }
                Rectangle {
                    anchors.fill: imageAvatar
                    color: 'transparent'
                    radius: Units.gu(1)
                    border.color: '#4a4a4a'
                    border.width: 1
                }
            }

            // The DTMF pad takes the avatar's place when the dialpad is on.
            Item {
                id: flipable

                property bool flipped: false

                width: parent.width
                height: flipped ? Units.gu(26) : 0
                visible: flipped
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: appTheme.panelDarkColor
                }

                Text {
                    id: tLineId
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    height: Units.gu(3)
                    verticalAlignment: Text.AlignVCenter
                    color: appTheme.primaryTextColor
                    font.pixelSize: FontUtils.sizeToPixels("medium")
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
            Rectangle {
                width: parent.width
                height: visible ? Units.gu(5) : 0
                visible: postDialPrompt.remainder.length > 0
                color: appTheme.panelFooterColor

                Text {
                    id: postDialPrompt
                    property string remainder: ""

                    anchors.centerIn: parent
                    color: appTheme.primaryTextColor
                    font.pixelSize: FontUtils.sizeToPixels("small")
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

            // With a single call the hangup button lives on the card's footer;
            // with several, each line carries its own and this ends them all.
            Item {
                width: parent.width
                height: Units.gu(6)

                Rectangle {
                    anchors.fill: parent
                    color: appTheme.panelFooterColor
                }

                SpriteIcon {
                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.multipleCalls
                                               ? "images/multicall-disconnect-button-full-all.png"
                                               : "images/multicall-disconnect-button.png")
                    frameCount: 3
                    frame: hangupAllArea.pressed ? 1 : 0
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
        usePrivateBus: true
    }
}
