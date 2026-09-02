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

import "../services"
import "../services/CallMessages.js" as CallMessages

/**
 * "Unable to connect" -- the popup the legacy app showed whenever a call could
 * not be placed (phonePopups/sources/DialFail.js), plus the airplane-mode
 * variant that offered to turn the radio back on
 * (phonePopups/sources/AirplaneMode.js).
 *
 * The QML app failed silently: a call that the modem refused simply never
 * happened, with nothing on screen to say why.
 */
MessageAlert {
    id: dialFailAlert

    /// DialFail.js puts the error icon after the text, unlike the call popups.
    iconOnRight: true

    property DialHandler dialHandler
    property TelephonyManager telephonyManager

    property string _pendingNumber: ""

    /// Shows the failure for `number`, keyed by a CallMessages.dialFailure reason.
    function showDialFailure(number, reason) {
        console.log("DIALFAIL popup: number='" + number + "' reason='" + reason + "'");
        _pendingNumber = number || "";

        var text = CallMessages.lookup(CallMessages.dialFailure, reason,
                                       CallMessages.dialFailureDefault);

        // Airplane mode is the one failure the user can fix from here, so it
        // gets a button instead of just an explanation.
        if (reason === "airplanemodeon") {
            showQuestion(CallMessages.dialFailureTitle, text,
                         appTheme.image("flight-mode-icon.png"),
                         qsTr("Turn radio on"), dialFailAlert._enableRadioAndRedial);
            return;
        }

        showMessage(CallMessages.dialFailureTitle, text,
                    appTheme.image("popup-icon-error.png"));
    }

    function _enableRadioAndRedial() {
        if (!telephonyManager || !telephonyManager.setRadioOnline(true))
            return;

        // The dial handler waits for registration before redialling, so just
        // hand the number back to it.
        if (dialHandler && _pendingNumber.length > 0)
            redialTimer.restart();
    }

    Timer {
        id: redialTimer
        interval: 5000
        onTriggered: {
            if (dialFailAlert._pendingNumber.length > 0 && dialFailAlert.dialHandler)
                dialFailAlert.dialHandler.dial(dialFailAlert._pendingNumber);
            dialFailAlert._pendingNumber = "";
        }
    }
}
