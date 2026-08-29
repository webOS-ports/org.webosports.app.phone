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

import LunaNext.Common 0.1
import LuneOS.Service 1.0
import LuneOS.Foreign 1.0

/**
 * Video area for a call, driven by luneos-rtc-engine. The remote video
 * region of this item is exported through wl_webos_foreign; the engine
 * decodes the incoming stream straight into it (compositor punch-through)
 * while it streams the local camera out as hardware-encoded H.264.
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
        if (!active || !remoteVideo.exported) {
            engineStatus = remoteVideo.exported ? "idle" : "waiting for window";
            return;
        }
        engineStatus = "starting";
        rtcService.call("luna://org.webosports.rtcengine/start",
            JSON.stringify({
                camera: cameraNumber,
                rotation: videoRotation,
                windowId: remoteVideo.windowId,
                loopback: loopbackDemo
            }),
            function(message) {
                var response = JSON.parse(message.payload);
                engineStatus = response.returnValue ? "running"
                                                    : ("error: " + response.errorText);
            },
            function(message) {
                engineStatus = "error: " + message.payload;
            });
    }

    function stopEngine() {
        rtcService.call("luna://org.webosports.rtcengine/stop", "{}",
                        undefined, undefined);
        engineStatus = "idle";
    }

    LunaService {
        id: rtcService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    ForeignExportedRegion {
        id: remoteVideo
        anchors.fill: parent
        onWindowIdChanged: {
            if (videoCallOverlay.active && exported &&
                    videoCallOverlay.engineStatus !== "running")
                videoCallOverlay.startEngine();
        }
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
