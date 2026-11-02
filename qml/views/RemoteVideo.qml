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

    readonly property bool running: captureSession.nativeVideoSource !== null

    function _stop() {
        if (captureSession.nativeVideoSource) {
            captureSession.nativeVideoSource.stop();
            captureSession.nativeVideoSource = null;
        }
    }

    function _restart() {
        _stop();
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

    // The three change together; restart once for all of them.
    onShmPathChanged: Qt.callLater(_restart)
    onFrameWidthChanged: Qt.callLater(_restart)
    onFrameHeightChanged: Qt.callLater(_restart)
    Component.onCompleted: _restart()
    Component.onDestruction: _stop()

    CaptureSession {
        id: captureSession
        videoOutput: videoOut
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }
}
