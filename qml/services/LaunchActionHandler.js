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

// Handles the 'action' launch parameter that lets other applications -- the
// bluetooth handsfree profile, the system manager, the messaging app -- drive
// call control. Ported from the legacy source/LaunchActionHandler.js.
//
//   luna-send -n 1 luna://com.webos.applicationManager/launch \
//     '{"id":"org.webosports.app.phone","params":{"action":"dial","address":"4157773456"}}'
//
// Supported actions: dial, answer, reject, swap, merge, extract, dtmf,
// activecall, voicemail, calllog, favorites, dialpad.

.pragma library

/**
 * Runs the action described by `params`.
 *
 * `services` supplies the collaborators:
 *   dialHandler        DialHandler
 *   voiceCallManager   VoiceCallMgrWrapper
 *   ui                 { showDialpad(), showCallLog(), showFavorites(),
 *                        showActiveCall(force), showVoicemail() }
 *
 * Returns true when the action was recognised.
 */
function handle(params, services) {
    if (!params || !params.action)
        return false;

    var handler = _handlers[String(params.action).toLowerCase()];
    if (!handler) {
        console.log("Unknown launch action: " + params.action);
        return false;
    }

    console.log("Handling launch action: " + params.action);
    handler(params, services);
    return true;
}

/// True when the action should be carried out without bringing the app forward.
function isBackgroundAction(action) {
    return ["answer", "reject", "swap", "merge", "extract", "dtmf"].indexOf(
                String(action || "").toLowerCase()) >= 0;
}

var _handlers = {
    "dial": function(params, services) {
        if (!params.address) return;
        services.dialHandler.dial(params.address);
    },

    "voicemail": function(params, services) {
        services.dialHandler.dialVoicemail();
    },

    "answer": function(params, services) {
        services.voiceCallManager.answer();
    },

    // 'reject' doubles as 'hang up' when nothing is ringing.
    "reject": function(params, services) {
        services.voiceCallManager.reject();
    },

    "hangup": function(params, services) {
        services.voiceCallManager.reject();
    },

    "swap": function(params, services) {
        services.voiceCallManager.swap();
    },

    "merge": function(params, services) {
        services.voiceCallManager.merge();
    },

    "extract": function(params, services) {
        if (params.id !== undefined)
            services.voiceCallManager.privateChat(parseInt(params.id, 10));
        else
            services.voiceCallManager.split();
    },

    "dtmf": function(params, services) {
        if (params.tone)
            services.voiceCallManager.sendDtmf(String(params.tone));
    },

    "activecall": function(params, services) {
        services.ui.showActiveCall(true);
    },

    "dialpad": function(params, services) {
        services.ui.showDialpad();
    },

    "calllog": function(params, services) {
        services.ui.showCallLog();
    },

    "favorites": function(params, services) {
        services.ui.showFavorites();
    }
};
