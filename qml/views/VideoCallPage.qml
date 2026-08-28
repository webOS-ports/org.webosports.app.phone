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
 */

import QtQuick 2.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * A call with video on it.
 *
 * Laid out as videocall-tablet.css has it: a scene of #1a1a1a under
 * scenetall.png, an eighty-nine pixel header carrying the caller's name over
 * the running time with a button at each end, the far side's picture filling
 * what is left, and this side's inset into the corner of it.
 *
 * There is no video here yet -- nothing in the stack produces a stream to
 * show. The places both pictures go are laid out and labelled, so that when
 * something does, it has somewhere to be put.
 */
BasePage {
    id: videoCallPage

    pageName: "VideoCall"

    /// Where a decoded stream would be shown, once there is one to show.
    readonly property alias remoteVideoArea: remoteVideo
    readonly property alias localVideoArea: localVideo

    signal closed();

    gradient: null
    color: '#1a1a1a'

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("images/scenetall.png")
        fillMode: Image.TileHorizontally
    }

    // The far side. Black until there is a stream for it.
    Rectangle {
        id: remoteVideo

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: 'black'

        Text {
            anchors.centerIn: parent
            color: '#4a4a4a'
            font.pixelSize: Units.gu(1.8)
            text: qsTr("No video")
        }

        /*
         * This side, in its own frame. The original pins it to the corner;
         * here it can be dragged anywhere over the far side's picture, and is
         * kept inside it however the window is resized.
         */
        BorderImage {
            id: pip

            width: Units.gu(20.2)
            height: Units.gu(15.4)

            x: Units.gu(0.6)
            y: Units.gu(1.6)

            source: Qt.resolvedUrl("images/dropshadowboarder_PIP.png")
            border { left: 7; right: 7; top: 7; bottom: 7 }

            function keepInside() {
                x = Math.max(0, Math.min(x, remoteVideo.width - width));
                y = Math.max(0, Math.min(y, remoteVideo.height - height));
            }

            Connections {
                target: remoteVideo
                function onWidthChanged() { pip.keepInside(); }
                function onHeightChanged() { pip.keepInside(); }
            }

            Rectangle {
                id: localVideo
                anchors.fill: parent
                anchors.margins: 7
                color: '#0d0d0d'
            }

            MouseArea {
                anchors.fill: parent

                drag.target: pip
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: Math.max(0, remoteVideo.width - pip.width)
                drag.maximumY: Math.max(0, remoteVideo.height - pip.height)
                drag.threshold: 0

                cursorShape: Qt.OpenHandCursor
            }
        }
    }

    /**
     * The header
     **/

    Item {
        id: header

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Units.gu(8.9)

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("images/vidHeader.png")
            fillMode: Image.Tile
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Units.gu(32)
            spacing: Units.gu(0.2)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: 'white'
                font.bold: true
                font.pixelSize: Units.gu(2.4)
                text: {
                    var name = videoCallPage.currentContact
                                   ? String(videoCallPage.currentContact.displayLabel || "").trim() : "";
                    if (name.length > 0)
                        return name;

                    return videoCallPage.voiceCall
                               ? PhoneNumberUtils.formatForDisplay(videoCallPage.voiceCall.lineId,
                                                                   videoCallPage.contacts
                                                                       ? videoCallPage.contacts.countryCode : "US",
                                                                   false)
                               : "";
                }
            }

        }

        // Turning the camera off leaves the call up as a voice one.
        VideoCallHeaderButton {
            id: videoButton

            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }

            iconSource: Qt.resolvedUrl("images/video_on_off.png")
            label: qsTr("Video")
            dividerOnLeft: false
            on: videoCallPage.voiceCall ? videoCallPage.voiceCall.isVideo === true : false

            onClicked: {
                if (videoCallPage.voiceCall && videoCallPage.voiceCall.isVideo !== undefined)
                    videoCallPage.voiceCall.isVideo = !videoCallPage.voiceCall.isVideo;
            }
        }

        VideoCallHeaderButton {
            id: audioButton

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }

            iconSource: Qt.resolvedUrl("images/mute_on_off.png")
            label: qsTr("Audio")
            dividerOnLeft: true
            on: videoCallPage.voiceCallMgrWrapper
                    ? videoCallPage.voiceCallMgrWrapper.isMicrophoneMuted : false

            onClicked: {
                if (videoCallPage.voiceCallMgrWrapper)
                    videoCallPage.voiceCallMgrWrapper.setMuteMicrophone(
                        !videoCallPage.voiceCallMgrWrapper.isMicrophoneMuted);
            }
        }
    }

    /*
     * How long the call has been up. The header owns this label, but the
     * tablet stylesheet drops it six hundred pixels down the screen, so it
     * reads just above the button that ends the call.
     */
    Text {
        anchors {
            bottom: hangup.top
            bottomMargin: Units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        color: 'white'
        font.bold: true
        font.pixelSize: Units.gu(1.4)
        text: videoCallPage.voiceCall
                  ? PhoneNumberUtils.formatDuration(videoCallPage.voiceCall.duration / 1000)
                  : ""
    }

    // Ends the call, standing clear of the foot of the screen as the original
    // has it.
    SpriteIcon {
        id: hangup

        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(1.5)
            horizontalCenter: parent.horizontalCenter
        }
        width: Units.gu(11.6)
        height: Units.gu(3.7)

        // Up, down and disabled, stacked in the one file.
        source: Qt.resolvedUrl("images/hangup_dartfish.png")
        frameCount: 3
        frame: hangupArea.pressed ? 1 : 0

        MouseArea {
            id: hangupArea
            anchors.fill: parent
            onClicked: {
                if (videoCallPage.voiceCall)
                    videoCallPage.voiceCall.hangup();

                videoCallPage.closed();
            }
        }
    }
}
