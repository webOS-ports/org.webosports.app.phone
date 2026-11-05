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

/**
 * This side's inset on a video call (.videoPip in videocall.css and
 * videocall-tablet.css):
 *
 * - each look sizes and places it as its stylesheet does: the handset's
 *   143 by 103 at the foot of the picture, the tablet's 202 by 154 at the top;
 * - it stands up when our picture is turned on its side;
 * - our camera's picture is read only while the inset shows, so a hidden
 *   inset costs the far side's picture nothing.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "SelfView"
        when: windowShown

        PhoneUiTheme { id: theme }
        TabletUiTheme { id: tabletTheme }

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
                property int videoPreviewOrientation: 0
                property bool videoPreviewMirrored: true
                function changeMedia(incoming, outgoing) {}
                function hangup() {}
            }
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

        function page(callProps, pageTheme) {
            var call = createTemporaryObject(fakeCallComponent, root, callProps || {});
            return createTemporaryObject(pageComponent, root,
                                         { appTheme: pageTheme || theme, voiceCall: call,
                                           width: root.width, height: root.height });
        }

        function frameOf(t) {
            return { w: t.videoPipWidth + 2 * t.videoPipPadding,
                     h: t.videoPipHeight + 2 * t.videoPipPadding };
        }

        function test_theHandsetInsetIsItsStylesheetsAt1x() {
            var p = page({}, theme);
            var pip = findByName(p, "pip");
            var f = frameOf(theme);
            compare(pip.width, f.w);
            compare(pip.height, f.h);
            verify(theme.videoPipWidth < tabletTheme.videoPipWidth, "the handset's is smaller than the tablet's");
            compare(pip.x, theme.videoPipLeft);
        }

        function test_theHandsetInsetSitsAtTheFootClearOfTheHangup() {
            var p = page({}, theme);
            var pip = findByName(p, "pip");
            var hangup = findByName(p, "hangup");
            var area = p.remoteVideoArea;
            var bottom = area.y + pip.y + pip.height;
            fuzzyCompare(bottom, hangup.y - theme.videoPipTop, 0.5);
            verify(pip.y > area.height / 2, "the handset's inset is at the top");
        }

        function test_theTabletInsetSitsAtTheTop() {
            var p = page({}, tabletTheme);
            var pip = findByName(p, "pip");
            var f = frameOf(tabletTheme);
            compare(pip.width, f.w);
            compare(pip.height, f.h);
            compare(pip.x, tabletTheme.videoPipLeft);
            compare(pip.y, tabletTheme.videoPipTop);
        }

        function test_thePictureSitsInsideTheShadow() {
            var p = page({}, theme);
            var pip = findByName(p, "pip");
            var inner = p.localVideoArea;
            fuzzyCompare(inner.width, pip.width - 2 * theme.videoPipPadding, 0.01);
            fuzzyCompare(inner.height, pip.height - 2 * theme.videoPipPadding, 0.01);
        }

        // The sensor is wider than tall; held upright, the picture is turned a
        // quarter and the frame turns with it.
        function test_theInsetStandsUpWithOurPicture() {
            var p = page({ videoPreviewOrientation: 1 }, theme);
            var pip = findByName(p, "pip");
            var f = frameOf(theme);
            compare(pip.width, f.h);
            compare(pip.height, f.w);
            p.voiceCall.videoPreviewOrientation = 2;
            compare(pip.width, f.w, "upside down is still wide");
            p.voiceCall.videoPreviewOrientation = 3;
            compare(pip.width, f.h);
        }

        function test_aTurnedInsetStaysClearOfTheHangup() {
            var p = page({ videoPreviewOrientation: 1 }, theme);
            var pip = findByName(p, "pip");
            var hangup = findByName(p, "hangup");
            verify(p.remoteVideoArea.y + pip.y + pip.height <= hangup.y);
        }

        function test_aDraggedInsetStaysWhereItWasPut() {
            var p = page({}, tabletTheme);
            var pip = findByName(p, "pip");
            pip.moved = true;
            pip.x = 100;
            pip.y = 200;
            p.voiceCall.videoPreviewOrientation = 1;
            compare(pip.x, 100);
            compare(pip.y, 200);
        }

        function test_theInsetIsKeptInsideThePicture() {
            var p = page({}, tabletTheme);
            var pip = findByName(p, "pip");
            pip.moved = true;
            p.voiceCall.videoPreviewOrientation = 1;   // standing up: narrow
            pip.x = p.remoteVideoArea.width - pip.width;
            p.voiceCall.videoPreviewOrientation = 0;   // wide again at the edge: pulled in
            verify(pip.x + pip.width <= p.remoteVideoArea.width + 0.01,
                   "the inset sticks out past the picture");
            p.width = 300;
            verify(pip.x + pip.width <= p.remoteVideoArea.width + 0.01);
        }

        function test_draggingTheInsetMovesItForGood() {
            var p = page({}, tabletTheme);
            var pip = findByName(p, "pip");
            mousePress(pip, 10, 10);
            mouseMove(pip, 60, 90);
            mouseMove(pip, 110, 170);
            mouseRelease(pip, 110, 170);
            verify(pip.moved, "a drag does not count as moved");
            verify(pip.y > tabletTheme.videoPipTop + 50, "the drag did not move it");
            var y = pip.y;
            p.voiceCall.videoPreviewOrientation = 1;
            compare(pip.y, y, "it went back to where the stylesheet puts it");
        }

        // --- our camera's picture, read only while it is shown

        function test_ourPictureIsReadWhileWeSend() {
            var p = page({}, theme);
            var loader = findByName(p, "ownPicture");
            verify(loader.active);
            p.voiceCall.outgoingVideo = false;
            verify(!findByName(p, "pip").visible);
            verify(!loader.active, "our picture is still read with the inset hidden");
            p.voiceCall.outgoingVideo = true;
            verify(loader.active);
        }

        function test_ourPictureIsNotReadWithThePageHidden() {
            var p = page({}, theme);
            var loader = findByName(p, "ownPicture");
            verify(loader.active);
            p.visible = false;
            verify(!loader.active, "our picture is read behind another page");
            p.visible = true;
            verify(loader.active);
        }

        function test_nothingIsReadWithoutAPreview() {
            var p = page({ videoPreviewURI: "" }, theme);
            verify(!findByName(p, "ownPicture").active);
        }
    }
}
