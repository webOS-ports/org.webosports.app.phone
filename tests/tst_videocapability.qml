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

import org.nemomobile.voicecall 1.0

import "../qml/views"
import "../qml/services"
import "fakes"

/**
 * Whether this phone can send video is asked of the call engine once, the
 * first time video comes up on a call -- whoever started it. It was only asked
 * when the far side started video, so after a restart a video call we started
 * ourselves had no camera button on its screen.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "VideoCapability"
        when: windowShown

        PhoneUiTheme { id: theme }
        Component { id: networkComponent; FakeCallNetwork {} }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }
        Component { id: windowComponent; PhoneWindow {} }
        Component {
            id: callComponent
            QtObject {
                property bool showsVideo: true
                property string lineId: "+10000000000"
                property string displayName: "A"
                property int status: VoiceCall.STATUS_ACTIVE
                function acceptVideo(sendOwn) {}
                function refuseVideo() {}
            }
        }

        property var wrapper: null
        property var phone: null
        property int queries: 0
        property var pendingAnswer: null

        function init() {
            queries = 0;
            pendingAnswer = null;
            var network = createTemporaryObject(networkComponent, root);
            wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            phone = createTemporaryObject(windowComponent, root,
                                          { voiceCallMgrWrapper: wrapper, phoneUiAppTheme: theme });
            verify(phone !== null, "the phone window did not load");
            // The engine answers when the test says so.
            phone.videoCapabilityQuery = function(answer) {
                queries++;
                pendingAnswer = answer;
            };
        }

        function test_videoWeStartedAsksTheEngine() {
            var call = createTemporaryObject(callComponent, root);
            wrapper.callVideoChanged(call);
            compare(queries, 1, "a video call we started never asked");
            pendingAnswer(true);
            verify(wrapper.videoSendCapable, "the answer was not kept");
        }

        function test_askedOnceForEveryone() {
            var call = createTemporaryObject(callComponent, root);
            wrapper.callVideoChanged(call);
            wrapper.videoRequested(call);
            wrapper.videoRequested(call);
            compare(queries, 1, "asked more than once while the answer was coming");
            pendingAnswer(true);
            wrapper.callVideoChanged(call);
            wrapper.videoRequested(call);
            compare(queries, 1, "asked again after the answer");
        }

        // The far side's question waits for the answer, then is put.
        function test_theFarSidesQuestionWaitsForTheAnswer() {
            var call = createTemporaryObject(callComponent, root);
            var alert = findByName(phone, "videoRequestAlert");
            verify(alert !== null, "no video request alert");
            wrapper.videoRequested(call);
            compare(queries, 1);
            verify(alert.voiceCall === null, "the question went out before the answer");
            pendingAnswer(true);
            verify(alert.voiceCall === call, "the question was not put after the answer");
        }

        function findByName(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            var kids = item.data || [];
            for (var i = 0; i < kids.length; ++i) {
                var found = findByName(kids[i], name);
                if (found)
                    return found;
            }
            return null;
        }

        function test_noEngineMeansNoCameraAndNoRetry() {
            var call = createTemporaryObject(callComponent, root);
            wrapper.callVideoChanged(call);
            pendingAnswer(false);
            verify(!wrapper.videoSendCapable);
            wrapper.callVideoChanged(call);
            compare(queries, 1, "asked again after a no");
        }

        // A call that stops showing video is no reason to ask.
        function test_aCallLeavingVideoDoesNotAsk() {
            var call = createTemporaryObject(callComponent, root, { showsVideo: false });
            wrapper.callVideoChanged(call);
            compare(queries, 0);
        }
    }
}
