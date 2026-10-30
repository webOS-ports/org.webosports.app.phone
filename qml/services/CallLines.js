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

// The calls in progress as the call card shows them: in lines, as webOS 2.x's
// CallSynergizer kept them. A call on its own is a line; every call in the
// conference together is one line. ActiveCall then picked the layout from the
// lines: SingleLineSingleCall for one call, SingleConferenceCall for a
// conference and nothing else, MultiLineView for more than one line.

.pragma library

/**
 * Groups `calls` into lines, in the order the calls come. The conference
 * takes the place of its first member.
 *
 * Each line is { calls: [...], conference: bool, call: <the call the line
 * shows: its own, or the conference's first member - the members are held
 * and resumed together, so any of them tells the conference's state> }.
 */
function group(calls) {
    var lines = [];
    var conference = null;

    (calls || []).forEach(function(call) {
        if (!call)
            return;

        if (call.isMultiparty) {
            if (!conference) {
                conference = { calls: [], conference: true, call: call };
                lines.push(conference);
            }
            conference.calls.push(call);
            return;
        }

        lines.push({ calls: [call], conference: false, call: call });
    });

    return lines;
}

/// The line `call` is in, or null.
function lineOf(lines, call) {
    for (var i = 0; i < lines.length; ++i) {
        if (lines[i].calls.indexOf(call) >= 0)
            return lines[i];
    }
    return null;
}

/// How long the line has been up: its longest-running call.
function duration(line) {
    if (!line)
        return 0;
    return line.calls.reduce(function(longest, call) {
        return Math.max(longest, call.duration || 0);
    }, 0);
}
