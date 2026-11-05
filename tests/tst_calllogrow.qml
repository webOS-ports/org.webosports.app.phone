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

// One call log row at handset width: whatever the name and the service line
// say, the count pill, the star and the video marker stay inside the text and
// never reach the call type or the time; a person without a photo gets the
// stand-in. A group is fed the way HistoryPage feeds it, appended to a
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

    ListView {
        id: list
        anchors.fill: parent
        model: groups
        delegate: CallGroupDelegate {
            width: list.width
            contacts: testContacts
            callTransports: testTransports
            appTheme: theme
        }
    }

    TestCase {
        name: "CallLogRow"
        when: windowShown

        function group(name, count, personId, service, addr) {
            return { groupId: "g-" + name, callcount: count, recentcall_type: "incoming",
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

        function test_long_name_keeps_the_count_off_the_call_type() {
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
            verify(leftOf(r, pill) >= rightOf(r, name), "the pill follows the name");
        }

        function test_long_service_line_keeps_the_video_marker_off_the_call_type() {
            var r = row(group("Herman van Hazendonk", 4, "p-nophoto", "com.palm.telegram",
                              "+316123456789012345678"));
            var video = part(r, "videoMarker"), icon = part(r, "callTypeIcon");
            var service = part(r, "serviceText");
            verify(video.visible, "video marker shows for a video-capable service");
            verify(rightOf(r, video) <= leftOf(r, icon),
                   "video marker ends at " + rightOf(r, video) + ", call type starts at " + leftOf(r, icon));
            verify(leftOf(r, video) >= rightOf(r, service), "the marker follows the service line");
        }

        function test_short_name_count_beside_it() {
            var r = row(group("Ann", 10, "p-photo", "com.palm.telegram", "+31612345678"));
            var pill = part(r, "countPill"), name = part(r, "nameText");
            verify(!name.truncated, "a short name is whole");
            verify(leftOf(r, pill) - rightOf(r, name) < Units.gu(2), "the count sits right after the name");
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
    }
}
