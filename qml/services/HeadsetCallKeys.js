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

// What the wired headset's button does to the calls, as on Android
// (Telecom's CallsManager.onMediaButton): a press answers a ringing call,
// and with none ringing ends the one in progress; a long press rejects a
// ringing call. Android mutes the microphone on a long press with no call
// ringing; that is left out here, the long press doing nothing then.
//
// mediacontroller sends the button to the Phone app while it holds
// registerCallKeys: "playPause" for a press (the shell counts presses and
// sends a single one as that) and "hold" for a long press.

.pragma library

//! What keyEvent asks for: "answer", "hangup", "reject" or "".
//! ringing: a call is ringing (incoming, or waiting behind one in
//! progress); inProgress: there is a call to end.
function actionFor(keyEvent, ringing, inProgress) {
    if (keyEvent === "playPause") {
        if (ringing)
            return "answer";
        return inProgress ? "hangup" : "";
    }
    if (keyEvent === "hold")
        return ringing ? "reject" : "";
    return "";
}
