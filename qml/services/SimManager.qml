/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import LunaNext.Common 0.1
import LuneOS.Service 1.0

Item {
    id: simManager

    // Possible values: none, pin, puk
    property string pinRequired: "none"

    onPinRequiredChanged: console.log("pinRequired: " + pinRequired)

    function isPinRequired() {
        return pinRequired !== "none";
    }

    Timer {
        id: resubscriberSimStatusTimer
        running: false
        interval: 2000
        onTriggered: {
            simStatusQuery.subscribe(JSON.stringify({"subscribe":true}));
        }
    }

    LunaService {
        id: simStatusQuery
        usePrivateBus: true
        service: "luna://com.palm.telephony"
        method: "simStatusQuery"

        onInitialized: {
            simStatusQuery.subscribe(JSON.stringify({"subscribe":true}));
        }

        onResponse: function (message) {
            var response = JSON.parse(message.payload);

            console.log("response: " + message.payload);

            if (!response.returnValue) {
                resubscriberSimStatusTimer.start();
                return;
            }

            switch (response.extended.state) {
            case "pinrequired":
                pinRequired = "pin";
                break;
            case "pukrequired":
                pinRequired = "puk";
                break;
            case "simready":
                pinRequired = "none";
                break;
            default:
                break;
            }
        }
    }
}
