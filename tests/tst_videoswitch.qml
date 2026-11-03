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
 * Turning a voice call into a video call, as 2.2.4's GlassCallHeader
 * changeToVideoButton and AbstractCall.changeToVideoCall have it:
 *
 * - the button shows on a single messaging call whose account declares a
 *   video format, and not on a cellular call or one that already shows video;
 * - it works once the call is up, and greys out after the tap;
 * - the tap sends one changeMedia with both directions on, and the far side's
 *   picture needs no further question.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "VideoSwitch"
        when: windowShown

        PhoneUiTheme { id: theme }

        Component { id: transportComponent; SynergyTransport { transportId: "com.palm.whatsapp" } }
        Component {
            id: pageComponent
            ActiveCallPage { width: 480; height: 800 }
        }
        Component { id: networkComponent; FakeCallNetwork {} }
        Component { id: wrapperComponent; VoiceCallMgrWrapper {} }
        Component { id: transportsComponent; CallTransports {} }
        // A cellular call has no switchToVideo at all.
        Component {
            id: cellularCallComponent
            QtObject {
                property string lineId: "+10000000000"
                property int status: VoiceCall.STATUS_ACTIVE
                property string providerId: "com.palm.telephony"
            }
        }

        SignalSpy { id: controlSpy; signalName: "callControlRequested" }

        property var transport: null

        function init() {
            controlSpy.clear();
            controlSpy.target = null;
            transport = createTemporaryObject(transportComponent, root);
        }

        // A WhatsApp voice call in the given state, as the connector reports it.
        function whatsappCall(state) {
            var payload = { returnValue: true, allowVideoCalls: true, videoURI: "",
                            lines: [{ state: state, calls: [{ id: "c1", address: "+10000000000" }],
                                      incomingVideo: false, outgoingVideo: false,
                                      incomingVideoState: "unavailable" }] };
            transport._onLines(payload.lines, payload);
            var call = transport._findCall("c1");
            verify(call !== null, "the call was not announced");
            controlSpy.target = call;
            return call;
        }

        // The registry with WhatsApp in it, with or without a video format.
        function registry(videoFormat) {
            var t = createTemporaryObject(transportsComponent, root);
            t.transports["com.palm.whatsapp"] = {
                templateId: "com.palm.whatsapp", serviceName: "type_whatsapp",
                implementation: "luna://com.palm.whatsapp.call/", videoFormat: videoFormat
            };
            t.revision++;
            return t;
        }

        function page(call, transports) {
            var network = createTemporaryObject(networkComponent, root);
            var wrapper = createTemporaryObject(wrapperComponent, root, { manager: network });
            var p = createTemporaryObject(pageComponent, root, {
                appTheme: theme,
                voiceCallMgrWrapper: wrapper,
                callTransports: transports || registry("both")
            });
            p.selectedCall = call;
            return p;
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

        function changeMediaCalls() {
            var out = [];
            for (var i = 0; i < controlSpy.count; ++i)
                if (controlSpy.signalArguments[i][0] === "changeMedia")
                    out.push(controlSpy.signalArguments[i][1]);
            return out;
        }

        function test_aWhatsappVoiceCallOffersVideo() {
            var p = page(whatsappCall("active"));
            verify(p.videoSwitchShown);
            verify(p.videoSwitchEnabled);
            verify(findByName(p, "videoSwitchButton").visible, "the header button is hidden");
        }

        function test_theTapAsksForVideoBothWays() {
            var call = whatsappCall("active");
            var p = page(call);
            mouseClick(findByName(p, "videoSwitchArea"));
            compare(changeMediaCalls(), [{ id: "c1", incomingVideo: true, outgoingVideo: true }]);
            // The far side's picture is authorised: it shows without asking.
            compare(call.videoAuthorization, "granted");
        }

        function test_theButtonGreysOutAfterTheTap() {
            var call = whatsappCall("active");
            var p = page(call);
            var area = findByName(p, "videoSwitchArea");
            mouseClick(area);
            verify(p.videoSwitchShown, "still shown, as legacy's");
            verify(!p.videoSwitchEnabled, "still enabled after the tap");
            mouseClick(area);
            call.switchToVideo();
            compare(changeMediaCalls().length, 1, "asked more than once");
        }

        function test_notBeforeTheCallIsUp() {
            var p = page(whatsappCall("dialing"));
            verify(p.videoSwitchShown);
            verify(!p.videoSwitchEnabled);
            mouseClick(findByName(p, "videoSwitchArea"));
            compare(changeMediaCalls().length, 0);
        }

        function test_notForAnAccountWithoutVideo() {
            var p = page(whatsappCall("active"), registry("none"));
            verify(!p.videoSwitchShown);
            verify(!findByName(p, "videoSwitchButton").visible);
        }

        // The account registry fills in after start-up, in place.
        function test_showsOnceTheAccountsHaveLoaded() {
            var transports = createTemporaryObject(transportsComponent, root);
            // The mocks' sample accounts may already list WhatsApp.
            delete transports.transports["com.palm.whatsapp"];
            transports.revision++;
            var p = page(whatsappCall("active"), transports);
            verify(!p.videoSwitchShown, "shown with no accounts known");
            transports.transports["com.palm.whatsapp"] = {
                templateId: "com.palm.whatsapp", serviceName: "type_whatsapp",
                implementation: "luna://com.palm.whatsapp.call/", videoFormat: "both"
            };
            transports.revision++;
            verify(p.videoSwitchShown, "not shown once WhatsApp's account loaded");
        }

        function test_notForACellularCall() {
            var p = page(createTemporaryObject(cellularCallComponent, root));
            verify(!p.videoSwitchShown);
        }

        // The connector's report of our camera, as a line update.
        function reportOutgoing(on) {
            var line = { state: "active", calls: [{ id: "c1", address: "+10000000000" }],
                         incomingVideo: false, outgoingVideo: on, incomingVideoState: "unavailable" };
            transport._onLines([line], { returnValue: true, allowVideoCalls: true, videoURI: "" });
        }

        // Switched to video, camera turned off again: back to a voice call, and the
        // switch works again (it stayed greyed out, so the camera could not come back).
        function test_offeredAgainOnceTheCameraIsOff() {
            var call = whatsappCall("active");
            var p = page(call);
            var area = findByName(p, "videoSwitchArea");
            mouseClick(area);
            reportOutgoing(true);
            verify(!p.videoSwitchEnabled, "enabled while our camera is on");
            reportOutgoing(false);
            verify(p.videoSwitchEnabled, "still disabled with the camera off again");
            mouseClick(area);
            compare(changeMediaCalls().length, 2, "the second switch did not ask");
        }

        // Before the connector reports the camera on, the tap is still pending.
        function test_staysDisabledUntilTheCameraIsReported() {
            var call = whatsappCall("active");
            var p = page(call);
            mouseClick(findByName(p, "videoSwitchArea"));
            reportOutgoing(false);
            verify(!p.videoSwitchEnabled, "re-enabled before the camera was ever on");
        }

        function test_goneOnceTheCallShowsVideo() {
            var call = whatsappCall("active");
            var p = page(call);
            call.switchToVideo();
            call.videoURI = "/tmp/wa-rtc-video";
            verify(call.showsVideo, "the call does not show video");
            verify(!p.videoSwitchShown);
        }
    }
}
