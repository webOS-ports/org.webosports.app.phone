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

import QtQuick 2.6
import QtMultimedia

import LuneOS.Foreign 1.0

/**
 * The far side's picture of a video call.
 *
 * The connector's call engine (luneos-rtc-engine) decodes the stream and
 * publishes the frames on a gst-shm socket; this renders them as a plain
 * VideoOutput, composited like any other item (docs/QML.md of
 * luneos-rtc-engine). Loaded through a Loader by VideoCallPage, so the page
 * still works where LuneOS.Foreign or Qt Multimedia is missing.
 */
Item {
    id: remoteVideo

    /// The engine's shm socket; empty when nothing is decoded.
    property string shmPath: ""
    /// Its frame size. gst-shm carries no caps, so these have to match.
    property int frameWidth: 0
    property int frameHeight: 0
    /// How far the far side's phone is turned, in quarter turns; the picture
    /// is turned back by as much.
    property int quarterTurns: 0
    /// Show the picture mirrored, as the front camera's self-view is.
    property bool mirrored: false

    readonly property bool running: captureSession.nativeVideoSource !== null
    /// Whether a frame has arrived since the source was opened; the source
    /// can be open long before the far side's first picture.
    property bool hasPicture: false

    // Stops the reader before Qt tears the source down: Qt's teardown of a
    // source that still has frames coming can crash on a streaming thread
    // (camera turned off in a video call on sargo, 2026-11-04;
    // RtcVideoFactory.stopShmSource in luneos-rtc-engine). An older
    // LuneOS.Foreign without it is stopped as before.
    function _stopSource(session) {
        var source = session.nativeVideoSource;
        if (!source)
            return;
        if (typeof RtcVideoFactory.stopShmSource === "function")
            RtcVideoFactory.stopShmSource(source);
        source.stop();
        session.nativeVideoSource = null;
    }

    function _stop() {
        _stopSource(captureSession);
    }

    function _restart() {
        _stop();
        hasPicture = false;
        if (shmPath.length === 0 || frameWidth <= 0 || frameHeight <= 0)
            return;
        if (!RtcVideoFactory.available()) {
            console.log("RemoteVideo: no GStreamer video source in Qt Multimedia");
            return;
        }
        var source = RtcVideoFactory.createShmSource(shmPath, frameWidth, frameHeight);
        if (!source) {
            console.log("RemoteVideo: could not open " + shmPath);
            return;
        }
        captureSession.nativeVideoSource = source;
        source.start();
    }

    // The three change together; restart once for all of them. A Timer rather
    // than Qt.callLater: it dies with this item, so a restart queued while the
    // page goes away never runs on a destroyed item.
    Timer {
        id: restartTimer
        interval: 0
        onTriggered: remoteVideo._restart()
    }
    onShmPathChanged: restartTimer.restart()
    onFrameWidthChanged: restartTimer.restart()
    onFrameHeightChanged: restartTimer.restart()
    Component.onCompleted: _restart()
    Component.onDestruction: _stop()

    CaptureSession {
        id: captureSession
        videoOutput: videoOut
    }

    VideoOutput {
        id: videoOut

        readonly property bool sideways: (remoteVideo.quarterTurns & 1) === 1

        // Turned on its side, the output swaps width and height so the turned
        // picture still fits the area.
        anchors.centerIn: parent
        width: sideways ? parent.height : parent.width
        height: sideways ? parent.width : parent.height
        rotation: -90 * (remoteVideo.quarterTurns & 3)
        transform: Scale {
            origin.x: videoOut.width / 2
            xScale: remoteVideo.mirrored ? -1 : 1
        }
        fillMode: VideoOutput.PreserveAspectFit
    }

    // Only listens until the first frame; every frame after it would be a
    // call into QML for nothing.
    Connections {
        target: videoOut.videoSink
        enabled: !remoteVideo.hasPicture
        function onVideoFrameChanged() { remoteVideo.hasPicture = true; }
    }
}
