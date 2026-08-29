/*
 * Copyright (C) 2026 LuneOS project
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

import QtQuick 2.6
import QtMultimedia

import LunaNext.Common 0.1
import LuneOS.Service 1.0
import LuneOS.Foreign 1.0

/**
 * Video area for a call, driven by luneos-rtc-engine. The engine
 * decodes the incoming stream, publishes the frames over gst-shm, and
 * this overlay renders them as a regular QML VideoOutput - composited
 * like any other item, so the card behaves normally in the shell.
 * Meanwhile the engine streams the local camera out as
 * hardware-encoded H.264.
 *
 * Until the messaging call engines feed the engine's sockets, loopback
 * mode shows the local camera as a self-view demo.
 */
Rectangle {
    id: videoCallOverlay

    property bool active: false
    property int cameraNumber: 0
    property int videoRotation: 90
    property bool loopbackDemo: true
    property string engineStatus: "idle"

    readonly property string shmPath: "/tmp/rtc-video"
    readonly property int streamWidth: 1280
    readonly property int streamHeight: 720
    // frame dimensions after the engine's render rotation
    readonly property bool dimensionsSwapped: videoRotation === 90 || videoRotation === 270
    readonly property int frameWidth: dimensionsSwapped ? streamHeight : streamWidth
    readonly property int frameHeight: dimensionsSwapped ? streamWidth : streamHeight

    visible: active
    color: "black"

    function open(params) {
        if (params) {
            if (params.camera !== undefined) cameraNumber = params.camera;
            if (params.rotation !== undefined) videoRotation = params.rotation;
            if (params.loopback !== undefined) loopbackDemo = params.loopback;
        }
        active = true;
        startEngine();
    }

    function close() {
        if (!active)
            return;
        stopEngine();
        active = false;
    }

    function startEngine() {
        engineStatus = "starting";
        rtcService.call("luna://org.webosports.rtcengine/start",
            JSON.stringify({
                camera: cameraNumber,
                rotation: videoRotation,
                shmPath: shmPath,
                width: streamWidth,
                height: streamHeight,
                loopback: loopbackDemo
            }),
            function(message) {
                var response = JSON.parse(message.payload);
                if (response.returnValue) {
                    engineStatus = "running";
                    attachVideoSource();
                } else {
                    engineStatus = "error: " + response.errorText;
                }
            },
            function(message) {
                engineStatus = "error: " + message.payload;
            });
    }

    function attachVideoSource() {
        if (captureSession.nativeVideoSource)
            captureSession.nativeVideoSource.stop();
        var source = RtcVideoFactory.createShmSource(shmPath, frameWidth, frameHeight);
        if (source) {
            captureSession.nativeVideoSource = source;
            source.start();
        } else {
            engineStatus = "error: no video source";
        }
    }

    function stopEngine() {
        if (captureSession.nativeVideoSource) {
            captureSession.nativeVideoSource.stop();
            captureSession.nativeVideoSource = null;
        }
        rtcService.call("luna://org.webosports.rtcengine/stop", "{}",
                        undefined, undefined);
        engineStatus = "idle";
    }

    LunaService {
        id: rtcService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    CaptureSession {
        id: captureSession
        videoOutput: videoOut
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    Text {
        anchors.centerIn: parent
        visible: videoCallOverlay.engineStatus !== "running"
        color: "white"
        font.pixelSize: FontUtils.sizeToPixels("medium")
        text: videoCallOverlay.engineStatus
    }

    Rectangle {
        id: endVideoButton
        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(3)
            horizontalCenter: parent.horizontalCenter
        }
        width: Units.gu(12)
        height: Units.gu(4)
        radius: height / 2
        color: "#c03a2b"

        Text {
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("small")
            text: "End video"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: videoCallOverlay.close()
        }
    }
}
