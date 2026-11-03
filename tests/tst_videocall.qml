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
        TabletUiTheme { id: tabletTheme }

        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.whatsapp" } }
        Component { id: pageComponent; VideoCallPage {} }
        Component { id: alertComponent; MessageAlert {} }
        Component {
            id: fakeCallComponent
            QtObject {
                property string lineId: "+10000000000"
                property int status: VoiceCall.STATUS_ACTIVE
                property int duration: 0
                property bool outgoingVideo: false
                property string incomingVideoState: "unavailable"
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

        function videoPage(callProps, pageTheme) {
            var call = createTemporaryObject(fakeCallComponent, root, callProps || {});
            var wrapper = createTemporaryObject(wrapperComponent, root, { videoSendCapable: true });
            return createTemporaryObject(pageComponent, root,
                                         { appTheme: pageTheme || theme, voiceCall: call,
                                           voiceCallMgrWrapper: wrapper });
        }

        // VideoCall.js lights the camera button when outgoingVideo is not true,
        // and its lit artwork is the camera struck through: it is lit while
        // our camera is off, as mute is while the microphone is.
        function test_theCameraButtonIsLitWhileOurCameraIsOff() {
            var page = videoPage({ outgoingVideo: true });
            var button = findByName(page, "videoButton");
            verify(!button.on);
            compare(button._state, 0);
            page.voiceCall.outgoingVideo = false;
            verify(button.on);
            compare(button._state, 2);
        }

        // As legacy: an active call shows its time, picture or not. The far side
        // may never send one (a phone without a camera).
        function test_anActiveCallShowsItsTimeBeforeThePictureComes() {
            var page = videoPage({ videoURI: "/tmp/wa-rtc-video", videoWidth: 480,
                                   videoHeight: 640, duration: 65000 });
            compare(page.stateText, "01:05");
            page.hasRemotePicture = true;
            compare(page.stateText, "01:05");
        }

        // The far side turns its camera off (<video state=6>): the decoder keeps
        // its last frame, which must not stay on screen as if the far side froze.
        function test_theFarSidesCameraOffHidesItsLastFrame() {
            var page = videoPage({ videoURI: "/tmp/wa-rtc-video", videoWidth: 480, videoHeight: 640,
                                   incomingVideoState: "streaming" });
            page.hasRemotePicture = true;
            var picture = findByName(page, "remotePicture");
            var label = findByName(page, "noVideoLabel");
            verify(picture.visible, "the picture is hidden while the far camera is on");
            verify(!label.visible);
            page.voiceCall.incomingVideoState = "available";
            verify(!picture.visible, "the last frame stays up with the far camera off");
            verify(label.visible, "nothing says there is no video");
            page.voiceCall.incomingVideoState = "streaming";
            verify(picture.visible, "the picture does not come back with the camera");
        }

        function test_aCallWithoutVideoShowsItsTimeAtOnce() {
            var page = videoPage({ duration: 65000 });
            compare(page.stateText, "01:05");
        }

        function test_theStateFollowsTheCall() {
            var page = videoPage({ status: VoiceCall.STATUS_DIALING });
            compare(page.stateText, "Starting Video...");
            page.voiceCall.status = VoiceCall.STATUS_HELD;
            compare(page.stateText, "On hold");
            page.voiceCall.status = VoiceCall.STATUS_DISCONNECTED;
            compare(page.stateText, "Ending");
        }

        // videocall.css keeps the state under the name; videocall-tablet.css
        // drops it to just above the hangup button.
        function test_eachLookPutsTheStateWhereItsStylesheetDoes() {
            var phone = videoPage({}, theme);
            verify(findByName(phone, "headerState").visible);
            verify(!findByName(phone, "footerState").visible);
            var tablet = videoPage({}, tabletTheme);
            verify(!findByName(tablet, "headerState").visible);
            verify(findByName(tablet, "footerState").visible);
        }

        function test_eachLookSizesItsHangup() {
            var phone = findByName(videoPage({}, theme), "hangup");
            var tablet = findByName(videoPage({}, tabletTheme), "hangup");
            compare(phone.width, theme.videoHangupWidth);
            compare(tablet.width, tabletTheme.videoHangupWidth);
            verify(phone.width > tablet.width, "the handset's is 172 to the tablet's 116");
        }

        // The handset's header is videocall.css at its own 1x: at the Pre3's
        // 1.5x the buttons left the name a quarter of a 1080 wide screen.
        function test_theHandsetHeaderIsTheStylesheetAt1x() {
            var page = videoPage({}, theme);
            var button = findByName(page, "videoButton");
            compare(button.width, theme.videoButtonWidth);
            verify(theme.videoButtonWidth < tabletTheme.videoButtonWidth, "the handset's buttons are the tablet's");
            verify(theme.videoHeaderHeight < tabletTheme.videoHeaderHeight, "the handset's header is the tablet's");
            compare(findByName(page, "headerArt").height, theme.videoHeaderHeight);
            // The name has the room between the two buttons, less a little air.
            var title = findByName(page, "headerTitle");
            var between = page.width - 2 * button.width;
            verify(title.width <= between, "the name runs under the buttons");
            verify(title.width > between - button.width / 2, "the name has far less than the room between the buttons");
        }

        // Tiled both ways, an artwork shorter than the header repeated down it.
        function test_theHeaderArtworkIsStretchedDownNotRepeated() {
            var art = findByName(videoPage({}, theme), "headerArt");
            compare(art.fillMode, Image.TileHorizontally);
            verify(String(art.source).indexOf("header_catfish.png") >= 0);
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
