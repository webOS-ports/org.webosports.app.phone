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

import org.nemomobile.voicecall 1.0

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils
import "../services/CallMessages.js" as CallMessages

/**
 * A call with video on it.
 *
 * Laid out as videocall-tablet.css has it: a scene of #1a1a1a under
 * scenetall.png, an eighty-nine pixel header carrying the caller's name over
 * the running time with a button at each end, the far side's picture filling
 * what is left, and this side's inset into the corner of it.
 *
 * The far side's picture comes from the connector's call engine
 * (luneos-rtc-engine), which decodes it and publishes the frames where the
 * call's videoURI says; RemoteVideo renders them. This side's inset is only
 * there while the call sends our camera.
 */
BasePage {
    id: videoCallPage

    pageName: "VideoCall"

    /// Where a decoded stream would be shown, once there is one to show.
    readonly property alias remoteVideoArea: remoteVideo
    readonly property alias localVideoArea: localVideo

    signal closed();

    /// Whether the far side's picture is showing yet. Not read-only only so
    /// that a test, which has no decoder, can stand in for the first frame.
    property bool hasRemotePicture: !!remotePicture.item && remotePicture.item.hasPicture === true

    /// The far side's camera is on. When it goes off (<video state=6>) the
    /// decoder keeps its last frame; showing that would freeze the far side
    /// on screen, so the picture is hidden until the camera is back.
    readonly property bool farCameraOn: !!voiceCall && voiceCall.incomingVideoState === "streaming"

    /**
     * The call's state, where VideoCall.js puts it under the name: "Starting
     * Video..." until the call is up, then the running time. The far side's
     * picture can take seconds to follow the call coming up, so it says so
     * until the first frame too.
     */
    readonly property string stateText: {
        if (!voiceCall)
            return "";
        switch (voiceCall.status) {
        case VoiceCall.STATUS_ACTIVE:
            // As VideoCall.js lineChanged: an active call shows its time.
            // "Starting Video..." is for dialing only; holding it until the far
            // side's picture came kept it up for a whole call with a far side
            // that has no camera.
            return PhoneNumberUtils.formatDuration(voiceCall.duration / 1000);
        case VoiceCall.STATUS_HELD:
            return CallMessages.callStateHold;
        case VoiceCall.STATUS_DISCONNECTED:
            return CallMessages.callStateEnding;
        default:
            return CallMessages.videoStateStarting;
        }
    }

    gradient: null
    color: '#1a1a1a'

    Image {
        anchors.fill: parent
        source: appTheme.image("scenetall.png")
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

        Loader {
            id: remotePicture
            objectName: "remotePicture"
            anchors.fill: parent
            visible: videoCallPage.farCameraOn
            active: !!videoCallPage.voiceCall && String(videoCallPage.voiceCall.videoURI || "").length > 0
            source: "RemoteVideo.qml"
            onLoaded: {
                item.shmPath = Qt.binding(function() {
                    return videoCallPage.voiceCall ? String(videoCallPage.voiceCall.videoURI || "") : "";
                });
                item.frameWidth = Qt.binding(function() {
                    return videoCallPage.voiceCall ? (videoCallPage.voiceCall.videoWidth || 0) : 0;
                });
                item.frameHeight = Qt.binding(function() {
                    return videoCallPage.voiceCall ? (videoCallPage.voiceCall.videoHeight || 0) : 0;
                });
                item.quarterTurns = Qt.binding(function() {
                    return videoCallPage.voiceCall ? (videoCallPage.voiceCall.incomingVideoOrientation || 0) : 0;
                });
            }
        }

        Text {
            objectName: "noVideoLabel"
            anchors.centerIn: parent
            visible: !videoCallPage.hasRemotePicture || !videoCallPage.farCameraOn
            color: '#4a4a4a'
            font.pixelSize: Units.gu(1.8)
            text: qsTr("No video")
        }

        /*
         * This side, in its own frame, where each look's stylesheet puts
         * .videoPip: the handset's at the foot of the picture, the tablet's at
         * its top, both to the left. Here it can be dragged anywhere over the
         * far side's picture, and is kept inside it however the window is
         * resized.
         */
        BorderImage {
            id: pip
            objectName: "pip"

            // Only while we send our own picture.
            readonly property bool sending: !!videoCallPage.voiceCall && videoCallPage.voiceCall.outgoingVideo === true
            visible: sending

            /// Our picture shows taller than wide: the frame stands up with it,
            /// rather than showing a narrow picture in a wide frame. That is a
            /// wide sensor's picture turned a quarter (a phone held upright), or
            /// one that comes upright already, as Teams' does (240x320, no
            /// turn). Without a size, the turn alone decides.
            readonly property bool sideways: {
                var c = videoCallPage.voiceCall;
                if (!c)
                    return false;
                var turned = ((c.videoPreviewOrientation | 0) & 1) === 1;
                var w = c.videoPreviewWidth | 0, h = c.videoPreviewHeight | 0;
                if (w <= 0 || h <= 0)
                    return turned;
                return turned ? w > h : h > w;
            }
            readonly property real frameLong: appTheme.videoPipWidth + 2 * appTheme.videoPipPadding
            readonly property real frameShort: appTheme.videoPipHeight + 2 * appTheme.videoPipPadding

            width: sideways ? frameShort : frameLong
            height: sideways ? frameLong : frameShort

            // Where the stylesheet has it, until dragged.
            x: appTheme.videoPipLeft
            y: appTheme.videoPipAtFoot
               ? Math.max(0, hangup.y - remoteVideo.y - appTheme.videoPipTop - height)
               : appTheme.videoPipTop

            source: appTheme.image("dropshadowboarder_PIP.png")
            border { left: 7; right: 7; top: 7; bottom: 7 }

            /// Dragged away from where the stylesheet puts it; from then on it
            /// stays where it was put, kept inside the picture.
            property bool moved: false

            function keepInside() {
                if (!moved)
                    return;
                var nx = Math.max(0, Math.min(x, remoteVideo.width - width));
                var ny = Math.max(0, Math.min(y, remoteVideo.height - height));
                if (nx !== x)
                    x = nx;
                if (ny !== y)
                    y = ny;
            }

            onWidthChanged: keepInside()
            onHeightChanged: keepInside()
            Connections {
                target: remoteVideo
                function onWidthChanged() { pip.keepInside(); }
                function onHeightChanged() { pip.keepInside(); }
            }

            Rectangle {
                id: localVideo
                anchors.fill: parent
                anchors.margins: appTheme.videoPipPadding
                color: '#0d0d0d'
                clip: true

                /*
                 * Our own camera, as the engine publishes it while we send.
                 * Read only while the inset shows: a reader nobody looks at
                 * would still take its frames off the GUI thread, which the
                 * far side's picture shares.
                 */
                Loader {
                    id: ownPicture
                    objectName: "ownPicture"
                    anchors.fill: parent
                    active: pip.sending && videoCallPage.visible
                            && String(videoCallPage.voiceCall.videoPreviewURI || "").length > 0
                    source: "RemoteVideo.qml"
                    onLoaded: {
                        item.shmPath = Qt.binding(function() {
                            return videoCallPage.voiceCall ? String(videoCallPage.voiceCall.videoPreviewURI || "") : "";
                        });
                        item.frameWidth = Qt.binding(function() {
                            return videoCallPage.voiceCall ? (videoCallPage.voiceCall.videoPreviewWidth || 0) : 0;
                        });
                        item.frameHeight = Qt.binding(function() {
                            return videoCallPage.voiceCall ? (videoCallPage.voiceCall.videoPreviewHeight || 0) : 0;
                        });
                        item.quarterTurns = Qt.binding(function() {
                            return videoCallPage.voiceCall ? (videoCallPage.voiceCall.videoPreviewOrientation || 0) : 0;
                        });
                        item.mirrored = Qt.binding(function() {
                            return !!videoCallPage.voiceCall && videoCallPage.voiceCall.videoPreviewMirrored === true;
                        });
                    }
                }
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
                drag.onActiveChanged: if (drag.active) pip.moved = true

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
        height: videoCallPage.appTheme.videoHeaderHeight

        // One row of the artwork, stretched to the header's height: tiled both
        // ways it repeated down the header in bands wherever the header is
        // taller than the file.
        Image {
            objectName: "headerArt"
            anchors.fill: parent
            source: appTheme.image(appTheme.videoHeaderImage)
            fillMode: Image.TileHorizontally
        }

        Column {
            objectName: "headerTitle"
            anchors.centerIn: parent
            // Between the two buttons, with a little air either side.
            width: parent.width - 2 * videoCallPage.appTheme.videoButtonWidth - Units.gu(1)
            spacing: Units.gu(0.2)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: 'white'
                font.bold: true
                font.pixelSize: appTheme.videoTitleSize
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

            Text {
                objectName: "headerState"
                width: parent.width
                visible: appTheme.videoStateInHeader
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: 'white'
                font.pixelSize: appTheme.videoStateSize
                text: videoCallPage.stateText
            }
        }

        // Our camera on or off; the far side's picture stays. Only on a device
        // that can send video at all.
        VideoCallHeaderButton {
            appTheme: videoCallPage.appTheme
            id: videoButton
            objectName: "videoButton"

            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            visible: !!videoCallPage.voiceCallMgrWrapper
                     && videoCallPage.voiceCallMgrWrapper.videoSendCapable === true

            iconSource: appTheme.image("video_on_off.png")
            stateWidth: 37
            label: qsTr("Video")
            dividerOnLeft: false
            // Lit while our camera is off, as mute is while the microphone
            // is: VideoCall.js sets the button's state when outgoingVideo is
            // not true, and the lit artwork is the camera struck through.
            on: videoCallPage.voiceCall ? videoCallPage.voiceCall.outgoingVideo !== true : false

            onClicked: {
                if (videoCallPage.voiceCall && videoCallPage.voiceCall.changeMedia)
                    videoCallPage.voiceCall.changeMedia(undefined, !videoCallPage.voiceCall.outgoingVideo);
            }
        }

        VideoCallHeaderButton {
            appTheme: videoCallPage.appTheme
            id: audioButton

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }

            iconSource: appTheme.image("mute_on_off.png")
            stateWidth: 36
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
     * reads just above the button that ends the call. The handset keeps it
     * in the header.
     */
    Text {
        objectName: "footerState"
        visible: !appTheme.videoStateInHeader
        anchors {
            bottom: hangup.top
            bottomMargin: Units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        color: 'white'
        font.bold: true
        font.pixelSize: appTheme.videoStateSize
        text: videoCallPage.stateText
    }

    // Ends the call, standing clear of the foot of the screen as the original
    // has it, at the size each look's stylesheet gives it.
    SpriteIcon {
        id: hangup
        objectName: "hangup"

        anchors {
            bottom: parent.bottom
            bottomMargin: appTheme.videoHangupMargin
            horizontalCenter: parent.horizontalCenter
        }
        width: appTheme.videoHangupWidth
        height: appTheme.videoHangupHeight

        // Up, down and disabled, stacked in the one file.
        source: appTheme.image("hangup_dartfish.png")
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
