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
 */
MessageAlert {
    id: missedCallAlert

    property UiTheme appTheme: PhoneUiTheme {}

    property DialHandler dialHandler

    property string _missedNumber: ""

    function showMissedCall(lineId, displayName) {
        _missedNumber = lineId || "";

        var name = (displayName && displayName.length > 0) ? displayName : lineId;
        var when = Qt.formatTime(new Date(), Qt.locale().timeFormat(Locale.ShortFormat));

        // Wake the screen, as the legacy popup did, so the alert is actually seen.
        lunaService.call("luna://com.palm.display/control/setState",
                         JSON.stringify({ state: "on" }), undefined,
                         function(error) { console.log("Could not turn the display on: " + error); });

        showQuestion(CallMessages.missedCallTitle,
                     qsTr("%1 at %2").arg(name).arg(when),
                     appTheme.image("popup-icon-missed.png"),
                     qsTr("Call back"),
                     missedCallAlert._callBack);
    }

    function _callBack() {
        if (dialHandler && _missedNumber.length > 0)
            dialHandler.dial(_missedNumber);
        _missedNumber = "";
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
    }
}
