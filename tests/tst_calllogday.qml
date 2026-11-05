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

import "../qml/services/PhoneNumberUtils.js" as PhoneNumberUtils

// The call log's day headers go by the local date. The times are built in
// local time, so the cases hold in any zone; they only catch a UTC day east
// of UTC (run-tests.sh is run with TZ=Europe/Amsterdam for that).
TestCase {
    name: "CallLogDay"

    function day(y, m, d, h, min) {
        return PhoneNumberUtils.localDayNumber(new Date(y, m - 1, d, h, min).getTime());
    }

    function label(y, m, d, h, min, now) {
        return PhoneNumberUtils.formatRelativeDay(day(y, m, d, h, min), Qt.locale("en_US"), now);
    }

    property double now: new Date(2026, 10, 5, 8, 31).getTime()   // 5 Nov 2026 08:31 local

    function test_same_local_date_same_day() {
        compare(day(2026, 11, 5, 0, 30), day(2026, 11, 5, 23, 59), "just after midnight and late evening");
        compare(day(2026, 11, 5, 0, 30) - day(2026, 11, 4, 23, 30), 1, "either side of midnight");
    }

    function test_today() {
        compare(label(2026, 11, 5, 7, 51, now), "Today");
        compare(label(2026, 11, 5, 0, 30, now), "Today", "a call just after midnight");
    }

    function test_yesterday() {
        compare(label(2026, 11, 4, 22, 41, now), "Yesterday", "late yesterday evening");
        compare(label(2026, 11, 4, 0, 10, now), "Yesterday", "just after midnight yesterday");
        compare(label(2026, 11, 4, 23, 59, new Date(2026, 10, 5, 0, 1).getTime()), "Yesterday",
                "a minute after midnight, the call two minutes before");
    }

    function test_weekday_and_date() {
        compare(label(2026, 11, 2, 12, 0, now), "Monday", "three days back");
        compare(label(2026, 10, 30, 9, 0, now), "Friday", "six days back");
        compare(label(2026, 10, 29, 9, 0, now), "29/10/26", "a week back");
    }
}
