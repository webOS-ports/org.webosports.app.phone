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

import "../qml/services"

/**
 * Our own camera shows as soon as we send, not only once the far side's
 * picture is there. A Teams video call we place sends from the first
 * seconds, while the far side may take a while to turn its camera on; the
 * self-view used to stay empty until then, because the preview's location was
 * read only next to the far side's.
 */
TestCase {
    name: "SelfViewFirst"

    Component { id: transportComponent; SynergyTransport { transportId: "com.palm.teams" } }

    property var transport: null

    function init() {
        transport = createTemporaryObject(transportComponent, this);
    }

    function report(sending, farPicture, preview) {
        var payload = { returnValue: true, allowVideoCalls: true,
                        lines: [{ state: "active", calls: [{ id: "c1", address: "jan.1982" }],
                                  incomingVideo: farPicture, outgoingVideo: sending,
                                  incomingVideoState: farPicture ? "streaming" : "available" }] };
        if (farPicture) {
            payload.videoURI = "/tmp/teams-video.1";
            payload.videoWidth = 640;
            payload.videoHeight = 480;
        }
        if (preview) {
            payload.videoPreviewURI = "/tmp/teams-preview.0";
            payload.videoPreviewWidth = 320;
            payload.videoPreviewHeight = 240;
            payload.videoPreviewOrientation = 1;
            payload.videoPreviewMirrored = true;
        }
        transport._onLines(payload.lines, payload);
        var call = transport._findCall("c1");
        verify(call !== null, "the call was not announced");
        return call;
    }

    function test_selfViewBeforeTheFarPicture() {
        var call = report(true, false, true);
        compare(call.videoURI, "", "no far picture yet");
        compare(call.videoPreviewURI, "/tmp/teams-preview.0");
        compare(call.videoPreviewWidth, 320);
        compare(call.videoPreviewHeight, 240);
        compare(call.videoPreviewOrientation, 1);
        compare(call.videoPreviewMirrored, true);
    }

    function test_selfViewStaysWhenTheFarPictureComes() {
        report(true, false, true);
        var call = report(true, true, true);
        compare(call.videoURI, "/tmp/teams-video.1");
        compare(call.videoPreviewURI, "/tmp/teams-preview.0");
    }

    function test_selfViewGoesWhenThePreviewIsNoLongerReported() {
        report(true, true, true);
        var call = report(false, true, false);
        compare(call.videoPreviewURI, "");
        compare(call.videoPreviewWidth, 0);
        compare(call.videoPreviewMirrored, false);
        compare(call.videoURI, "/tmp/teams-video.1", "the far picture stays");
    }
}
