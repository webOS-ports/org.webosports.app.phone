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

import QtQuick 2.0
import QtQml

import LuneOS.Service 1.0

import "../services"
import "../services/CallMessages.js" as CallMessages

/**
 * The "Missed call / Call back" alert, ported from the legacy
 * phonePopups/sources/MissedCall.js. The QML app dropped missed calls into the
 * call log and told the user nothing.
 *
 * As there, the alert is up for a minute at most. If it goes without "Call
 * back" or "Dismiss" - the minute is up, the screen comes on after it, the
 * shell closes it, or another missed call takes its place - it is minimized:
 * 2.2.4 put it on the missed call dashboard, and minimized() asks for the
 * same here, the notification with the red missed call icon.
 */
MessageAlert {
    id: missedCallAlert

    property DialHandler dialHandler

    /// MissedCall.kTimeoutMs: how long the alert stays up.
    property int timeoutMs: 60000

    /// The alert went without being answered; the call is to be minimized.
    signal minimized(string lineId, string displayName, date missedAt)

    property string _missedNumber: ""
    property string _missedName: ""
    property date _missedAt
    /// Up and not yet answered with either button.
    property bool _pending: false

    function showMissedCall(lineId, displayName) {
        // Another missed call while one is still up: the first is minimized
        // rather than lost.
        _minimize();

        _missedNumber = lineId || "";

        var name = (displayName && displayName.length > 0) ? displayName : lineId;
        _missedName = name || "";
        _missedAt = new Date();
        var when = Qt.formatTime(_missedAt, Qt.locale().timeFormat(Locale.ShortFormat));

        // Wake the screen, as the legacy popup did, so the alert is actually seen.
        lunaService.call("luna://com.palm.display/control/setState",
                         JSON.stringify({ state: "on" }), undefined,
                         function(error) { console.log("Could not turn the display on: " + error); });

        showQuestion(CallMessages.missedCallTitle,
                     qsTr("%1 at %2").arg(name).arg(when),
                     appTheme.image("popup-icon-missed.png"),
                     qsTr("Call back"),
                     missedCallAlert._callBack);

        _pending = true;
        timeout.restart();
    }

    /// Takes the alert down and minimizes the call, unless it was answered.
    function _minimize() {
        if (!_pending)
            return;
        _pending = false;
        timeout.stop();
        hide();
        minimized(_missedNumber, _missedName, _missedAt);
    }

    function _answered() {
        _pending = false;
        timeout.stop();
    }

    onAccepted: _answered()
    onDismissed: _answered()
    // The shell closed it: Eos.Window lets the window go without its visible
    // turning false first.
    onWindowCloseRequested: _minimize()

    Timer {
        id: timeout
        interval: missedCallAlert.timeoutMs
        onTriggered: missedCallAlert._minimize()
    }

    /*
     * A timer does not run while the device sleeps, which is where a missed
     * call usually leaves it. 2.2.4 checked when the screen came back on, and
     * took down an alert older than the minute then.
     */
    function _displayStatus(message) {
        var status = JSON.parse(message.payload);
        if (status.event === "displayOn" && _pending
                && Date.now() - _missedAt.getTime() > timeoutMs)
            _minimize();
    }

    function _callBack() {
        if (dialHandler && _missedNumber.length > 0)
            dialHandler.dial(_missedNumber);
        _missedNumber = "";
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        Component.onCompleted: {
            lunaService.subscribe("luna://com.palm.display/control/status",
                                  JSON.stringify({ subscribe: true }),
                                  missedCallAlert._displayStatus,
                                  function(error) { console.log("No display status: " + error); });
        }
    }
}
