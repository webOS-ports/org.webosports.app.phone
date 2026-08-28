/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

// This service library will remember what action has been taken for
// a given incoming voicecall's id

.pragma library

var Accepted="accepted";
var Ignored="ignored";
var Missed="missed";

var __callsActions = {};

// Which way each call went, by handler id. Kept separately from the actions
// because it is observed rather than chosen by the user.
var __callDirections = {};

// possible values for 'action' are:
//  Accepted: the call has been answered
//  Ignored: the call has been rejected
//  Missed: the call rang out without either
//
// Only ask about an incoming call. An id that was never registered answers
// Missed, which is the right answer for an incoming call that ended without
// the user doing anything, and the wrong one for every outgoing call.

function setActionForCall(handlerId, action) {
    __callsActions[handlerId] = action;
}

function getActionForCall(handlerId) {
    if(typeof __callsActions[handlerId] === 'undefined') return Missed;
    return __callsActions[handlerId];
}

/**
 * Remembers which way a call went, taken from a state only one direction can
 * reach: dialling or alerting means we placed it, ringing or waiting means it
 * came to us.
 */
function setIncomingForCall(handlerId, incoming) {
    __callDirections[handlerId] = !!incoming;
}

/**
 * Which way the call went. `fallback` is used for a call that never reached
 * such a state -- one that failed before it could ring, say.
 */
function wasIncoming(handlerId, fallback) {
    if (typeof __callDirections[handlerId] === 'undefined')
        return !!fallback;

    return __callDirections[handlerId];
}
