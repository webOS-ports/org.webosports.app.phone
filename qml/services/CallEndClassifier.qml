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

/**
 * What an ended call was: dropped, failed or nothing to tell the user about.
 *
 * Legacy told these apart by the modem's disconnect cause. Here it is oFono's
 * DisconnectReason for the call: "local" when we hung up, "remote" when the
 * other side or the network ended it in the ordinary way, "network" for the
 * rest (binder_voicecall_map_cause). voicecall-manager passes none of it on,
 * so it comes from CallEndReasons, by line, by its own way over the bus:
 * either before or after the call's end does. Each end waits for its reason
 * for a moment, and a reason that finds no call waits for its call as long.
 *
 * - A connected call counts as dropped on "network" only. Not knowing the
 *   reason is never a drop: a false alarm after every ordinary hangup is
 *   worse than a drop that goes unannounced.
 * - A call that never connected failed, unless we ended it ourselves: that
 *   is someone changing their mind while it rang out. It counts as failed
 *   when the reason does not come, as all of these did before there was one.
 */
Item {
    id: classifier

    /// False when there will be no reasons: nothing then waits for one.
    property bool reasonsAvailable: true
    property int waitMs: 1000

    signal dropped(var call, string reason)
    signal failed(var call)

    property var _ended: []
    property var _reasons: []

    /// `connected`: the call was up, not just dialled or ringing out.
    function callEnded(call, connected) {
        var entry = { call: call, connected: connected, at: Date.now() };

        if (!reasonsAvailable) {
            _decide(entry, "");
            return;
        }

        for (var i = 0; i < _reasons.length; i++) {
            if (_reasons[i].lineId === call.lineId) {
                var reason = _reasons[i].reason;
                _reasons.splice(i, 1);
                _decide(entry, reason);
                return;
            }
        }

        _ended.push(entry);
        expiry.restart();
    }

    function reasonReported(lineId, reason) {
        for (var i = 0; i < _ended.length; i++) {
            if (_ended[i].call.lineId === lineId) {
                _decide(_ended.splice(i, 1)[0], reason);
                return;
            }
        }

        _reasons.push({ lineId: lineId, reason: reason, at: Date.now() });
        expiry.restart();
    }

    function _decide(entry, reason) {
        if (entry.connected) {
            if (reason === "network")
                dropped(entry.call, "networkfailure");
        } else if (reason !== "local") {
            failed(entry.call);
        }
    }

    function _expire() {
        var oldest = Date.now() - waitMs + 1;

        _reasons = _reasons.filter(function(entry) { return entry.at > oldest; });

        var left = [];
        var late = [];
        _ended.forEach(function(entry) { (entry.at > oldest ? left : late).push(entry); });
        _ended = left;
        late.forEach(function(entry) { classifier._decide(entry, ""); });

        if (_ended.length > 0 || _reasons.length > 0)
            expiry.restart();
    }

    Timer {
        id: expiry
        interval: classifier.waitMs
        onTriggered: classifier._expire()
    }
}
