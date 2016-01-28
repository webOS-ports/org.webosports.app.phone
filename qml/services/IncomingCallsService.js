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

// possible values for 'action' are:
//  Accepted: the call has been answered
//  Ignored: the call has been rejected
//  Missed: the call was not missed

function setActionForCall(handlerId, action) {
    __callsActions[handlerId] = action;
}

function getActionForCall(handlerId) {
    if(typeof __callsActions[handlerId] === 'undefined') return Missed;
    return __callsActions[handlerId];
}
