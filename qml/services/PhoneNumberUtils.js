/*
 * Copyright (C) 2026 WebOS Ports
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

// Phone number and duration formatting, ported from the legacy Enyo app's
// Utils.FormatPhoneNumber / Utils.getElaspedTime. The legacy version formatted
// against the MCC reported by the radio; here the region comes from the system
// preferences, which is what the rest of the app already uses.

.pragma library

.import LuneOS.Telephony 1.0 as Telephony

.import "CallMessages.js" as CallMessages

/**
 * Formats a number for display. `partial` keeps a half-typed number readable
 * while the user is still dialling, instead of refusing to format it.
 */
function formatForDisplay(number, countryCode, partial) {
    if (!number || number.length === 0)
        return "";

    var trimmed = String(number).trim();

    switch (trimmed.toLowerCase()) {
    case "":
    case "unknown":
    case "unknown caller":
        return CallMessages.unknownNumber;
    case "blocked":
    case "blocked caller":
        return CallMessages.blockedNumber;
    }

    // MMI and USSD strings are not phone numbers; show them exactly as typed.
    if (/[\*#]/.test(trimmed))
        return trimmed;

    // With Synergy this is also called on IM addresses, which may be usernames
    // rather than numbers. Anything that is not dialable is shown as-is --
    // otherwise the post-dial split below would cut "powell" at its 'p'.
    if (!/^[+0-9][0-9+\s().,;pw-]*$/i.test(trimmed))
        return trimmed;

    // Post-dial digits are not part of the number the formatter understands.
    var postDialIndex = trimmed.search(/[,;pw]/i);
    var postDial = "";
    if (postDialIndex >= 0) {
        postDial = trimmed.slice(postDialIndex);
        trimmed = trimmed.slice(0, postDialIndex);
    }

    // A number too short to be dialled would come back mangled.
    if (partial && trimmed.replace(/[^0-9]/g, '').length < 4)
        return trimmed + postDial;

    var formatted = Telephony.LibPhoneNumber.formatPhoneNumberForDisplay(trimmed, countryCode);
    return (formatted && formatted.length > 0 ? formatted : trimmed) + postDial;
}

function normalize(number, countryCode) {
    return Telephony.LibPhoneNumber.normalizePhoneNumber(number, countryCode);
}

function phoneNumberTypeLabel(type) {
    return Telephony.LibPhoneNumber.getPhoneNumberTypeStr(type);
}

/// "1:02:03" for anything an hour or longer, "02:03" below that.
function formatDuration(seconds) {
    var total = Math.max(0, Math.floor(seconds));
    var h = Math.floor(total / 3600);
    var m = Math.floor((total - h * 3600) / 60);
    var s = total - h * 3600 - m * 60;

    var mm = (m < 10 ? "0" : "") + m;
    var ss = (s < 10 ? "0" : "") + s;

    return (h > 0) ? (h + ":" + mm + ":" + ss) : (mm + ":" + ss);
}

/**
 * "46 sec", "1 min 1 sec", "1 hr 5 min 3 sec" -- the abbreviated-but-worded
 * style the call log uses next to each individual call, matching what the
 * legacy app got out of enyo.g11n.DurationFmt in its "long" style. Components
 * that are zero are left out; a call of no length has nothing to say.
 */
function formatDurationLong(seconds) {
    var total = Math.max(0, Math.round(seconds));
    if (total === 0)
        return "";

    var h = Math.floor(total / 3600);
    var m = Math.floor((total - h * 3600) / 60);
    var s = total - h * 3600 - m * 60;

    var parts = [];
    if (h > 0) parts.push(h + " " + qsTr("hr"));
    if (m > 0) parts.push(m + " " + qsTr("min"));
    if (s > 0 || parts.length === 0) parts.push(s + " " + qsTr("sec"));

    return parts.join(" ");
}

/**
 * The day a call log section stands for: "Today", "Yesterday", the weekday
 * within the last week, and a short numeric date beyond that -- which is what
 * com.palm.app.phone shows. The long locale date is far too wide for a header.
 */
function formatRelativeDay(date, locale) {
    var today = new Date();
    var startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    var dayMs = 86400000;
    var diffDays = Math.floor((startOfToday.getTime() - date.getTime()) / dayMs);

    if (diffDays <= 0) return qsTr("Today");
    if (diffDays === 1) return qsTr("Yesterday");
    if (diffDays < 7) return date.toLocaleDateString(locale, "dddd");

    // Locale.ShortFormat is not reachable from a .pragma library, so
    // ask for the numeric pattern directly.
    return date.toLocaleDateString(locale, "d/M/yy");
}

/// Display name for a com.palm.person record, mirroring the legacy
/// Utils.PersonDisplayName fallback chain.
function personDisplayName(person) {
    if (!person)
        return "";

    if (person.nickname && person.nickname.length > 0)
        return person.nickname;

    if (person.name) {
        var full = [person.name.givenName, person.name.middleName, person.name.familyName]
                       .filter(function(part) { return part && part.length > 0; })
                       .join(" ");
        if (full.length > 0)
            return full;
    }

    if (person.organization) {
        if (person.organization.name && person.organization.name.length > 0)
            return person.organization.name;
        if (person.organization.title && person.organization.title.length > 0)
            return person.organization.title;
    }

    var lists = ["emails", "ims", "phoneNumbers"];
    for (var i = 0; i < lists.length; ++i) {
        var list = person[lists[i]];
        var count = list ? (list.length !== undefined ? list.length : list.count) : 0;
        if (count > 0) {
            var entry = Array.isArray(list) ? list[0] : list.get(0);
            if (entry && entry.value) return entry.value;
        }
    }

    return qsTr("[No Name Available]");
}

/// The number to dial for a person: the one flagged primary, else the first.
function primaryPhoneNumber(person) {
    if (!person || !person.phoneNumbers)
        return "";

    var list = person.phoneNumbers;
    var count = (list.length !== undefined) ? list.length : list.count;

    for (var i = 0; i < count; ++i) {
        var entry = Array.isArray(list) ? list[i] : list.get(i);
        if (entry && entry.primary)
            return entry.value;
    }

    if (count > 0) {
        var first = Array.isArray(list) ? list[0] : list.get(0);
        if (first) return first.value;
    }

    return "";
}
