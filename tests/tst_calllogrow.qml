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

import LunaNext.Common 0.1

import "../qml/views"
import "../qml/model"
import "../qml/services"

// One call log row at handset width: the name, the service and the number on
// lines of their own, the count over the video marker and the call type over
// the time in columns that stand at the same place whatever the text says; a
// person without a photo gets the stand-in. A group is fed the way HistoryPage feeds it, appended to a
// ListModel with its recentcall_address inside.
Item {
    id: root
    width: Units.gu(45)
    height: Units.gu(30)

    PhoneUiTheme { id: theme }

    ContactsModel {
        id: testContacts
        countryCode: "NL"
        property var people: ({
            "p-nophoto": { _id: "p-nophoto", favorite: true, photos: { listPhotoPath: "", squarePhotoPath: "" } },
            "p-photo":   { _id: "p-photo", favorite: false, photos: { listPhotoPath: "file:///nonexistent/photo.png" } }
        })
        function personById(id) { return people[id] || null; }
    }

    CallTransports {
        id: testTransports
        function labelFor(id) { return id === "com.palm.telegram" ? "Telegram" : id; }
        function supportsVideo(id) { return id === "com.palm.telegram"; }
    }

    ListModel { id: groups }

    // Records what the row asks to dial instead of dialling.
    DialHandler {
        id: fakeDial
        property var dialled: null
        function dial(address, transport, video) {
            dialled = { address: address, transport: transport, video: video === true };
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        model: groups
        delegate: CallGroupDelegate {
            width: list.width
            contacts: testContacts
            callTransports: testTransports
            dialHandler: fakeDial
            appTheme: theme
        }
    }

    TestCase {
        name: "CallLogRow"
        when: windowShown

        // Every row gets an id of its own: one that repeats the last test's
        // would find that test's row while it is still being taken down.
        property int serial: 0

        function group(name, count, personId, service, addr) {
            return { groupId: "g-" + (++serial), callcount: count, recentcall_type: "incoming",
                     timestamp: new Date(2026, 10, 5, 7, 51).getTime(),
                     recentcall_address: { name: name, personId: personId, addr: addr, service: service } };
        }

        function row(g) {
            groups.clear();
            groups.append(g);
            // The row for this group, not the previous one on its way out.
            tryVerify(function() {
                var it = list.itemAtIndex(0);
                return it !== null && it.callGroupId === g.groupId && findChild(it, "countPill") !== null;
            });
            var r = list.itemAtIndex(0);
            waitForRendering(r);
            return r;
        }

        function part(r, name) {
            var p = findChild(r, name);
            verify(p !== null, name + " exists");
            return p;
        }

        function rightOf(r, item) { return item.mapToItem(r, item.width, 0).x; }
        function leftOf(r, item) { return item.mapToItem(r, 0, 0).x; }

        function test_long_name_keeps_off_the_count_and_the_call_type() {
            var r = row(group("Herman van Hazendonk with a very long surname", 13, "p-nophoto",
                              "com.palm.telegram", "+31612345678"));
            var pill = part(r, "countPill"), star = part(r, "favoriteStar");
            var icon = part(r, "callTypeIcon"), name = part(r, "nameText");
            verify(pill.visible && pill.width > 0, "the count shows");
            verify(name.truncated, "the name is elided");
            verify(rightOf(r, pill) <= leftOf(r, icon),
                   "pill ends at " + rightOf(r, pill) + ", call type starts at " + leftOf(r, icon));
            verify(rightOf(r, star) <= leftOf(r, icon),
                   "star ends at " + rightOf(r, star) + ", call type starts at " + leftOf(r, icon));
            verify(leftOf(r, pill) >= rightOf(r, name), "the name stops before the count");
            verify(rightOf(r, star) <= leftOf(r, pill), "the star stops before the count");
        }

        function centreX(r, item) { return item.mapToItem(r, item.width / 2, 0).x; }
        function topOf(r, item) { return item.mapToItem(r, 0, 0).y; }
        function bottomOf(r, item) { return item.mapToItem(r, 0, item.height).y; }

        function test_service_and_number_on_lines_of_their_own() {
            var r = row(group("Herman van Hazendonk", 4, "p-nophoto", "com.palm.telegram",
                              "+316123456789012345678"));
            var service = part(r, "serviceText"), number = part(r, "numberText");
            var video = part(r, "videoMarker"), icon = part(r, "callTypeIcon");
            compare(service.text, "TELEGRAM");
            verify(number.visible && number.text.length > 0, "the number has a line");
            verify(topOf(r, number) >= bottomOf(r, service), "the number is under the service");
            verify(rightOf(r, number) <= leftOf(r, video), "a long number stops before the video marker");
            verify(rightOf(r, video) <= leftOf(r, icon),
                   "video marker ends at " + rightOf(r, video) + ", call type starts at " + leftOf(r, icon));
        }

        function test_number_the_name_already_shows_is_not_repeated() {
            var r = row(group("jan.1982", 3, "", "com.palm.telegram", "jan.1982"));
            verify(!part(r, "numberText").visible, "no number line under a username");
            verify(part(r, "serviceText").visible, "the service still shows");
        }

        // The count and the marker stand in one column beside the call type,
        // the count on the name's line and the marker under it across the two
        // lines below, at the same place whatever the name is.
        function badges(name, count) {
            var r = row(group(name, count, "p-nophoto", "com.palm.telegram", "+31612345678"));
            var pill = part(r, "countPill"), video = part(r, "videoMarker");
            var nameT = part(r, "nameText"), service = part(r, "serviceText");
            var number = part(r, "numberText"), icon = part(r, "callTypeIcon");
            verify(pill.visible && video.visible, "both show");
            fuzzyCompare(centreX(r, pill), centreX(r, video), 1, "count over marker");
            verify(rightOf(r, pill) <= leftOf(r, icon), "the count stops before the call type");
            verify(topOf(r, pill) < bottomOf(r, nameT) && bottomOf(r, pill) > topOf(r, nameT),
                   "the count is on the name's line");
            verify(topOf(r, video) < bottomOf(r, service) && bottomOf(r, video) > topOf(r, number),
                   "the marker spans the service and the number lines");
            verify(video.height > service.height, "the marker is bigger than a line of text");
            return { pill: centreX(r, pill), video: centreX(r, video) };
        }

        function test_count_and_video_marker_line_up_row_to_row() {
            var a = badges("Ann", 4);
            var b = badges("Herman van Hazendonk with a very long surname", 13);
            fuzzyCompare(a.pill, b.pill, 1, "the count stands at the same place");
            fuzzyCompare(a.video, b.video, 1, "the marker stands at the same place");
        }

        function test_time_under_the_call_type() {
            var r = row(group("Ann", 4, "p-photo", "com.palm.telegram", "+31612345678"));
            var icon = part(r, "callTypeIcon"), time = part(r, "timeText");
            var nameT = part(r, "nameText"), service = part(r, "serviceText");
            verify(topOf(r, time) >= bottomOf(r, icon), "the time is under the call type");
            fuzzyCompare(centreX(r, time), centreX(r, icon), 1, "one column");
            verify(topOf(r, icon) < bottomOf(r, nameT) && bottomOf(r, icon) > topOf(r, nameT),
                   "the call type is on the name's line");
            fuzzyCompare(topOf(r, time), topOf(r, service), 1, "the time is on the service line");
        }

        function test_short_name_whole() {
            verify(!part(row(group("Ann", 10, "p-photo", "com.palm.telegram", "+31612345678")),
                         "nameText").truncated, "a short name is whole");
        }

        function test_person_without_photo_gets_the_stand_in() {
            var r = row(group("Herman van Hazendonk", 1, "p-nophoto", "com.palm.telegram", "+31612345678"));
            var photo = part(r, "avatarPhoto");
            verify(String(photo.source).indexOf("list-avatar-default.png") >= 0, "stand-in: " + photo.source);
        }

        function test_person_with_photo_keeps_it() {
            var r = row(group("Ann", 1, "p-photo", "com.palm.telegram", "+31612345678"));
            compare(String(part(r, "avatarPhoto").source), "file:///nonexistent/photo.png");
        }

        // The camera on a row is a video call back; the rest of the row a call without.
        function test_camera_calls_back_with_video() {
            var r = row(group("Ann", 1, "p-nophoto", "com.palm.telegram", "ann.1982"));
            var cam = part(r, "videoMarker");
            verify(cam.visible, "the account can do video");
            fakeDial.dialled = null;
            var c = cam.mapToItem(r, cam.width / 2, cam.height / 2);
            mouseClick(r, c.x, c.y);
            verify(fakeDial.dialled !== null, "the camera dials");
            compare(fakeDial.dialled.address, "ann.1982");
            compare(fakeDial.dialled.transport, "com.palm.telegram");
            compare(fakeDial.dialled.video, true);

            fakeDial.dialled = null;
            var name = part(r, "nameText");
            var n = name.mapToItem(r, Units.gu(1), name.height / 2);
            mouseClick(r, n.x, n.y);
            verify(fakeDial.dialled !== null, "the name dials");
            compare(fakeDial.dialled.video, false);
        }

        // Without video on the account there is no camera, and no video call.
        function test_no_camera_no_video_call() {
            var r = row(group("Bob", 1, "p-nophoto", "com.palm.skype", "bob.1"));
            verify(!part(r, "videoMarker").visible);
            fakeDial.dialled = null;
            var name = part(r, "nameText");
            var n = name.mapToItem(r, Units.gu(1), name.height / 2);
            mouseClick(r, n.x, n.y);
            verify(fakeDial.dialled !== null);
            compare(fakeDial.dialled.video, false);
        }
    }
}
