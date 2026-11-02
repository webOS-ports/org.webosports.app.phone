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

import "../services"
import "../services/CallMessages.js" as CallMessages

/**
 * "Call dropped", from the legacy phonePopups/sources/DroppedCall.js. It was
 * up for twenty seconds, with the alert tone, and offered to redial. The QML
 * app had the wording, and said nothing.
 */
MessageAlert {
    id: droppedCallAlert

    property DialHandler dialHandler
    property CallAlertSounds alertSounds

    /// DroppedCall.kTimeoutMs.
    property int timeoutMs: 20000

    property string _number: ""

    function showDropped(lineId, displayName, reason) {
        // One at a time, as announceDisconnectAbnormal: all of a conference
        // going down is one alert and one tone, not one on top of the other.
        if (timeout.running)
            return;

        _number = lineId || "";

        var name = (displayName && displayName.length > 0) ? displayName : _number;
        var text = CallMessages.lookup(CallMessages.droppedCall, reason, CallMessages.droppedCallDefault);
        if (name.length > 0)
            text = name + "\n" + text;

        var icon = appTheme.image("popup-icon-dropped.png");
        if (_number.length > 0)
            showQuestion(CallMessages.droppedCallTitle, text, icon, qsTr("Redial"), droppedCallAlert._redial);
        else
            showMessage(CallMessages.droppedCallTitle, text, icon);

        if (alertSounds)
            alertSounds.playAlert();

        timeout.restart();
    }

    function _redial() {
        if (dialHandler && _number.length > 0)
            dialHandler.dial(_number);
    }

    onAccepted: timeout.stop()
    onDismissed: timeout.stop()

    Timer {
        id: timeout
        interval: droppedCallAlert.timeoutMs
        onTriggered: droppedCallAlert.hide()
    }
}
