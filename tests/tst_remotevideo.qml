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

import QtQuick 2.0
import QtTest 1.2

import LuneOS.Foreign 1.0

import "../qml/views"

/**
 * Stopping a call picture: the engine's reader is stopped (stopShmSource)
 * before Qt tears the source down, which crashed the Phone app on a
 * streaming thread when it was the other way round with frames still coming
 * (our camera turned off in a video call, sargo 2026-11-04).
 */
Item {
    id: root
    width: 200
    height: 200

    TestCase {
        name: "RemoteVideo"
        when: windowShown

        Component { id: videoComponent; RemoteVideo {} }
        Component {
            id: sourceComponent
            QtObject {
                function stop() { RtcVideoFactory.log.push("stop"); }
            }
        }
        Component { id: sessionComponent; QtObject { property var nativeVideoSource: null } }

        property var defaultStop

        function initTestCase() { defaultStop = RtcVideoFactory.stopShmSource; }
        function init() {
            RtcVideoFactory.log = [];
            RtcVideoFactory.stopShmSource = defaultStop;
        }

        function test_theReaderIsStoppedBeforeTheSource() {
            var video = createTemporaryObject(videoComponent, root);
            var session = createTemporaryObject(sessionComponent, root);
            session.nativeVideoSource = createTemporaryObject(sourceComponent, root);
            video._stopSource(session);
            compare(RtcVideoFactory.log, ["stopShmSource", "stop"]);
            compare(session.nativeVideoSource, null);
        }

        function test_nothingToStop() {
            var video = createTemporaryObject(videoComponent, root);
            var session = createTemporaryObject(sessionComponent, root);
            video._stopSource(session);
            compare(RtcVideoFactory.log, []);
        }

        function test_anOlderFactoryStillStopsTheSource() {
            RtcVideoFactory.stopShmSource = undefined;
            var video = createTemporaryObject(videoComponent, root);
            var session = createTemporaryObject(sessionComponent, root);
            session.nativeVideoSource = createTemporaryObject(sourceComponent, root);
            video._stopSource(session);
            compare(RtcVideoFactory.log, ["stop"]);
            compare(session.nativeVideoSource, null);
        }
    }
}
