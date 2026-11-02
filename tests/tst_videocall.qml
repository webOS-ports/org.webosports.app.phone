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

import "../qml/views"
import "../qml/services"

/**
 * Video on a messaging call, as 2.2.4's ActiveCall.updateWithCallState and
 * phonePopups VideoRequest have it:
 *
 * - the far side starting to send asks the user once ("Switch to video?");
 * - accepting asks the connector to decode it (changeMedia incomingVideo),
 *   refusing turns both directions off, and neither is asked again;
 * - video we send ourselves, or a line that auto-accepts, needs no question;
 * - the call screen shows video only once granted and the connector says
 *   where the decoded picture is (videoURI).
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "VideoCall"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.whatsapp" } }
        Component { id: pageComponent; VideoCallPage {} }
        Component { id: alertComponent; MessageAlert {} }
        Component {
            id: fakeCallComponent
            QtObject {
                property string lineId: "+10000000000"
                property int duration: 0
                property bool outgoingVideo: false
                property string videoURI: ""
                property int videoWidth: 0
                property int videoHeight: 0
                property var lastChange: null
                function changeMedia(incoming, outgoing) { lastChange = [incoming, outgoing]; }
                function hangup() {}
            }
        }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }

        SignalSpy { id: requestedSpy; signalName: "videoRequested" }
        SignalSpy { id: controlSpy; signalName: "callControlRequested" }
        SignalSpy { id: showsSpy; signalName: "showsVideoChanged" }

        property var transport: null

        function init() {
            requestedSpy.target = null;
            controlSpy.target = null;
            showsSpy.target = null;
            requestedSpy.clear();
            controlSpy.clear();
            showsSpy.clear();
            transport = createTemporaryObject(transportComponent, root);
            // Watch a call from the moment it is announced: it may ask straight away.
            transport.callAdded.connect(function(call) {
                requestedSpy.target = call;
                controlSpy.target = call;
                showsSpy.target = call;
            });
        }

        function line(state, video, extra) {
            var l = { state: state, calls: [{ id: "c1", address: "+10000000000" }],
                      incomingVideo: false, outgoingVideo: false,
                      incomingVideoState: "unavailable" };
            for (var k in video) l[k] = video[k];
            for (var e in (extra || {})) l[e] = extra[e];
            return l;
        }

        // Pushes one callState update; returns the call.
        function push(state, video, payloadExtra) {
            var payload = { returnValue: true, allowVideoCalls: true, videoURI: "" };
            for (var k in (payloadExtra || {})) payload[k] = payloadExtra[k];
            var l = line(state, video);
            payload.lines = [l];
            transport._onLines(payload.lines, payload);
            return transport._findCall("c1");
        }

        function changeMediaCalls() {
            var out = [];
            for (var i = 0; i < controlSpy.count; ++i) {
                if (controlSpy.signalArguments[i][0] === "changeMedia")
                    out.push(controlSpy.signalArguments[i][1]);
            }
            return out;
        }

        // --- what the line says

        function test_anOfferedVideoCallIsAVideoCallButShowsNoVideoYet() {
            var call = push("incoming", { incomingVideoState: "available" });
            verify(call.isVideo);
            compare(call.incomingVideoState, "available");
            verify(!call.showsVideo);
            compare(requestedSpy.count, 0, "nothing is asked while it only rings");
        }

        function test_aVoiceCallIsNotAVideoCall() {
            var call = push("active", {});
            verify(!call.isVideo);
            compare(requestedSpy.count, 0);
        }

        // --- asking

        function test_theFarSideStreamingAsksOnce() {
            push("incoming", { incomingVideoState: "available" });
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            compare(requestedSpy.count, 1);
            push("active", { incomingVideoState: "streaming", incomingVideo: true });
            push("active", { incomingVideoState: "streaming", incomingVideo: true });
            compare(requestedSpy.count, 1, "the question is put once");
            compare(changeMediaCalls().length, 0, "nothing is decoded before the user says so");
            verify(!call.showsVideo);
        }

        function test_aCallThatTurnsUpStreamingAsksAfterItIsAnnounced() {
            var order = [];
            transport.callAdded.connect(function(call) {
                order.push("added");
                call.videoRequested.connect(function() { order.push("requested"); });
            });
            push("active", { incomingVideoState: "streaming", incomingVideo: true });
            compare(order, ["added", "requested"]);
        }

        function test_acceptingAsksForTheFarSidesPictureOnly() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            call.acceptVideo(false);
            compare(call.videoAuthorization, "granted");
            var sent = changeMediaCalls();
            compare(sent.length, 1);
            compare(sent[0].id, "c1");
            compare(sent[0].incomingVideo, true);
            verify(!("outgoingVideo" in sent[0]), "no camera to send: leave it alone");
        }

        function test_acceptingOnADeviceWithACameraSendsOursToo() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            call.acceptVideo(true);
            var sent = changeMediaCalls();
            compare(sent[0].incomingVideo, true);
            compare(sent[0].outgoingVideo, true);
        }

        function test_acceptedVideoShowsOnceThePictureIsPublished() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            call.acceptVideo(false);
            verify(!call.showsVideo, "nothing decoded yet");
            push("active", { incomingVideoState: "streaming", incomingVideo: true },
                 { videoURI: "/tmp/wa-rtc-video", videoWidth: 480, videoHeight: 640 });
            verify(call.showsVideo);
            compare(call.videoURI, "/tmp/wa-rtc-video");
            compare(call.videoWidth, 480);
            compare(call.videoHeight, 640);
            compare(showsSpy.count, 1);
            compare(changeMediaCalls().length, 1, "accepting is not repeated by later updates");
        }

        function test_thePictureGoingAwayLeavesVideo() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            call.acceptVideo(false);
            push("active", { incomingVideoState: "streaming", incomingVideo: true },
                 { videoURI: "/tmp/wa-rtc-video", videoWidth: 480, videoHeight: 640 });
            push("active", { incomingVideoState: "available" });
            verify(!call.showsVideo);
            compare(call.videoURI, "");
            compare(call.videoWidth, 0);
            compare(showsSpy.count, 2);
        }

        function test_refusingTurnsBothOffAndIsNotAskedAgain() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true });
            call.refuseVideo();
            var sent = changeMediaCalls();
            compare(sent.length, 1);
            compare(sent[0].incomingVideo, false);
            compare(sent[0].outgoingVideo, false);
            push("active", { incomingVideoState: "streaming", incomingVideo: true },
                 { videoURI: "/tmp/wa-rtc-video", videoWidth: 480, videoHeight: 640 });
            compare(requestedSpy.count, 1);
            verify(!call.showsVideo, "a refused call never shows video");
        }

        // --- no question

        function test_ourOwnVideoNeedsNoQuestion() {
            var call = push("active", { outgoingVideo: true, incomingVideoState: "streaming",
                                        incomingVideo: true });
            compare(requestedSpy.count, 0);
            compare(call.videoAuthorization, "granted");
            var sent = changeMediaCalls();
            compare(sent.length, 1, "the far side's picture is asked for at once");
            compare(sent[0].incomingVideo, true);
        }

        function test_anAutoAcceptingLineNeedsNoQuestion() {
            transport._onLines([line("active", { incomingVideoState: "streaming", incomingVideo: true },
                                     { autoAcceptVideoCalls: true })],
                               { returnValue: true, videoURI: "" });
            var call = transport._findCall("c1");
            compare(call.videoAuthorization, "granted");
        }

        function test_aLineThatForbidsVideoNeverAsks() {
            var call = push("active", { incomingVideoState: "streaming", incomingVideo: true },
                            { allowVideoCalls: false });
            compare(requestedSpy.count, 0);
            call.acceptVideo(false);
            push("active", { incomingVideoState: "streaming", incomingVideo: true },
                 { allowVideoCalls: false, videoURI: "/tmp/wa-rtc-video", videoWidth: 480,
                   videoHeight: 640 });
            verify(!call.showsVideo);
        }

        function test_aGrantedCallAsksForANewStreamAgain() {
            var call = push("active", { outgoingVideo: true, incomingVideoState: "streaming",
                                        incomingVideo: true });
            push("active", { outgoingVideo: true, incomingVideoState: "available" });
            push("active", { outgoingVideo: true, incomingVideoState: "streaming", incomingVideo: true });
            compare(changeMediaCalls().length, 2, "the far side stopped and started again");
        }

        // --- changeMedia's shape

        function test_changeMediaLeavesOutWhatIsNotChanged() {
            var call = push("active", {});
            call.changeMedia(undefined, false);
            var sent = changeMediaCalls();
            compare(sent.length, 1);
            verify(!("incomingVideo" in sent[0]));
            compare(sent[0].outgoingVideo, false);
        }

        // --- the call screen

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

        function test_thePageHidesOurInsetAndCameraButtonWithoutACamera() {
            var call = createTemporaryObject(fakeCallComponent, root);
            var wrapper = createTemporaryObject(wrapperComponent, root);
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCall: call,
                                               voiceCallMgrWrapper: wrapper });
            verify(!findByName(page, "pip").visible);
            verify(!findByName(page, "videoButton").visible);
            verify(!findByName(page, "remotePicture").active);
            verify(findByName(page, "noVideoLabel").visible);

            wrapper.videoSendCapable = true;
            call.outgoingVideo = true;
            verify(findByName(page, "pip").visible);
            verify(findByName(page, "videoButton").visible);
        }

        function test_theCameraButtonTogglesOurVideoOnly() {
            var call = createTemporaryObject(fakeCallComponent, root, { outgoingVideo: true });
            var wrapper = createTemporaryObject(wrapperComponent, root, { videoSendCapable: true });
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCall: call,
                                               voiceCallMgrWrapper: wrapper });
            findByName(page, "videoButton").clicked();
            compare(call.lastChange, [undefined, false]);
        }

        function test_thePageLoadsThePictureWhenThereIsOne() {
            var call = createTemporaryObject(fakeCallComponent, root);
            var page = createTemporaryObject(pageComponent, root,
                                             { appTheme: theme, voiceCall: call });
            var loader = findByName(page, "remotePicture");
            verify(!loader.active);
            call.videoURI = "/tmp/wa-rtc-video";
            verify(loader.active);
            call.videoURI = "";
            verify(!loader.active);
        }

        // --- the question itself

        function findByText(item, text) {
            if (!item)
                return null;
            if (item.text === text && item.clicked !== undefined)
                return item;
            var kids = item.children || [];
            for (var i = 0; i < kids.length; ++i) {
                var found = findByText(kids[i], text);
                if (found)
                    return found;
            }
            return null;
        }

        function test_theQuestionRunsTheMatchingAnswer() {
            var alert = createTemporaryObject(alertComponent, root, { appTheme: theme });
            var answered = [];
            alert.showQuestion("Switch to video?", "A wants to start a video call.", "",
                               "Accept", function() { answered.push("accept"); },
                               "Reject", function() { answered.push("reject"); });
            compare(alert.cancelLabel, "Reject");
            findByText(alert.contentItem, "Reject").clicked();
            compare(answered, ["reject"]);
            alert.showQuestion("Switch to video?", "A wants to start a video call.", "",
                               "Accept", function() { answered.push("accept"); },
                               "Reject", function() { answered.push("reject"); });
            findByText(alert.contentItem, "Accept").clicked();
            compare(answered, ["reject", "accept"]);
        }

        function test_anOrdinaryQuestionStillDismisses() {
            var alert = createTemporaryObject(alertComponent, root, { appTheme: theme });
            var ran = false;
            alert.showQuestion("Missed call", "", "", "Call back", function() {});
            compare(alert.cancelLabel, "Dismiss");
            alert.showQuestion("t", "m", "", "Ok", function() {}, "No", function() { ran = true; });
            alert.showMessage("t", "m", "");
            compare(alert.declineAction, null, "a plain message forgets the last decline");
            verify(!ran);
        }
    }
}
