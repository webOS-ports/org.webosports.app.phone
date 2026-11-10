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

/*
 * A video call follows the phone as it turns: the connector is told which way
 * the phone is held, so it can turn the picture it sends, and our own inset
 * turns with the screen. The test runner has no sensor; the turns are set on
 * the page as DeviceTilt.qml would.
 */

import QtQuick 2.0
import QtTest 1.2

import org.nemomobile.voicecall 1.0

import "../qml/views"
import "../qml/services"

Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "VideoRotation"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: pageComponent; VideoCallPage {} }
        Component {
            id: fakeCallComponent
            QtObject {
                property string lineId: "+10000000000"
                property int status: VoiceCall.STATUS_ACTIVE
                property int duration: 0
                property bool outgoingVideo: true
                property string incomingVideoState: "streaming"
                property string videoURI: ""
                property int videoWidth: 0
                property int videoHeight: 0
                property string videoPreviewURI: "/tmp/wa-rtc-preview"
                property int videoPreviewWidth: 320
                property int videoPreviewHeight: 240
                property int videoPreviewOrientation: 1
                property bool videoPreviewMirrored: true
                property var told: []
                function setDeviceOrientation(turns) { told = told.concat([turns]); }
                function changeMedia(incoming, outgoing) {}
                function hangup() {}
            }
        }
        Component { id: synergyCallComponent; SynergyCall {} }
        SignalSpy { id: controlSpy; signalName: "callControlRequested" }

        function page(callProps) {
            var call = createTemporaryObject(fakeCallComponent, root, callProps || {});
            return createTemporaryObject(pageComponent, root,
                                         { appTheme: theme, voiceCall: call,
                                           width: root.width, height: root.height });
        }

        function test_theConnectorHearsOfEveryTurnWhileWeSend() {
            var p = page();
            p.deviceTurns = 1;
            p.deviceTurns = 3;
            p.deviceTurns = 0;
            compare(p.voiceCall.told.slice(-3), [1, 3, 0]);
        }

        function test_nothingIsSaidWhileOurCameraIsOff() {
            var p = page({ outgoingVideo: false });
            p.deviceTurns = 1;
            compare(p.voiceCall.told.length, 0);
        }

        // Held sideways when the camera comes on: the connector starts from that.
        function test_ourCameraComingOnSaysWhichWayThePhoneIsHeld() {
            var p = page({ outgoingVideo: false });
            p.deviceTurns = 3;
            p.voiceCall.outgoingVideo = true;
            compare(p.voiceCall.told, [3]);
        }

        // A cellular call has no picture to turn and no such method.
        function test_aCallWithoutTheMethodIsLeftAlone() {
            var call = Qt.createQmlObject(
                'import QtQuick 2.0; import org.nemomobile.voicecall 1.0; QtObject {'
                + ' property int status: VoiceCall.STATUS_ACTIVE; property int duration: 0;'
                + ' property bool outgoingVideo: true; property string videoURI: "" }', root);
            var p = createTemporaryObject(pageComponent, root,
                                          { appTheme: theme, voiceCall: call,
                                            width: root.width, height: root.height });
            p.deviceTurns = 2;
            compare(p.deviceTurns, 2, "turning without the method is no error");
            call.destroy();
        }

        // The front camera's inset, shown mirrored, turns on by the screen's turn.
        function test_theMirroredInsetTurnsWithTheScreen() {
            var p = page();
            compare(p.previewTurns, 1, "upright: as the connector says");
            p.screenTurns = 1;
            compare(p.previewTurns, 2);
            p.screenTurns = 3;
            compare(p.previewTurns, 0);
        }

        // The back camera's inset turns the other way.
        function test_theBackCamerasInsetTurnsAgainstTheScreen() {
            var p = page({ videoPreviewMirrored: false });
            p.screenTurns = 1;
            compare(p.previewTurns, 0);
        }

        // Rotation locked: the screen stays put while the phone turns, so the
        // inset keeps its turn while the connector still hears of the phone's.
        function test_aLockedScreenKeepsTheInsetsTurn() {
            var p = page();
            p.screenTurns = 0;
            p.deviceTurns = 1;
            compare(p.previewTurns, 1);
            compare(p.voiceCall.told.slice(-1), [1]);
        }

        // The inset's frame stands up or lies down with the turned picture.
        function test_theInsetFrameFollowsTheTurn() {
            var p = page();
            var pip = findByName(p, "pip");
            var upright = { w: pip.width, h: pip.height };
            p.screenTurns = 1;
            compare(pip.width, upright.h);
            compare(pip.height, upright.w);
        }

        // What reaches the connector: changeMedia with the orientation alone.
        function test_aSynergyCallSendsTheOrientationAlone() {
            var call = createTemporaryObject(synergyCallComponent, root,
                                             { transport: "com.palm.telegram", callId: "tg-1" });
            controlSpy.clear();
            controlSpy.target = call;
            call.setDeviceOrientation(3);
            compare(controlSpy.count, 1);
            compare(controlSpy.signalArguments[0][0], "changeMedia");
            var params = controlSpy.signalArguments[0][1];
            compare(params.id, "tg-1");
            compare(params.deviceOrientation, 3);
            verify(params.incomingVideo === undefined && params.outgoingVideo === undefined,
                   "no video direction changes");
        }

        function findByName(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            var kids = item.children || [];
            for (var i = 0; i < kids.length; ++i) {
                var found = findByName(kids[i], name);
                if (found)
                    return found;
            }
            return null;
        }
    }
}
