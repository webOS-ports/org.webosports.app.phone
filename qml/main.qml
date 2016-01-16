/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import "views"
import "services"
import "model"
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0

import LunaNext.Common 0.1
import LuneOS.Service 1.0
import LuneOS.Application 1.0

Item {
    id: root

    width: Settings.displayWidth
    height: Settings.displayHeight

    Component.onCompleted: {
        var launchParams = "{\"mode\":\"first-use\"}";
        if (typeof application !== "undefined")
            launchParams = application.launchParameters;

        console.log("Parsing Launch Params: " + launchParams);
        var params = JSON.parse(launchParams);

        if (params.mode && params.mode === "first-use") {
            simPinWindow.type = typeof application === "undefined" ? 0 : ApplicationWindow.Pin;
            // PIN window will now open automatically when the PIN is required
            return;
        }

        if (!params.launchedAtBoot)
            phoneWindow.show();
    }

    Item {
        id: dummyApp
        signal relaunched
    }

    Connections {
        target: typeof application !== "undefined" ? application : dummyApp
        onRelaunched: {
            console.log("DEBUG: Relaunched with parameters: " + parameters);

            // If we're launched at boot time we're not yet visible so bring our window
            // to the foreground
            if (!phoneWindow.visible)
                phoneWindow.show();
        }
    }

    TelephonyManager {
        id: telephonyManager
    }

    VoiceCallMgr {
        id: voiceCallManager
        onIncomingCallChanged: {
            if (!voiceCallManager.incomingCall) {
                incomingCallAlert.hide();
                return;
            }

            incomingCallAlert.show();
        }
    }

    IncomingCallAlert {
        id: incomingCallAlert
        visible: false
        voiceCallManager: voiceCallManager
    }

    PhoneWindow {
        id: phoneWindow
        simPinWindow: simPinWindow
        voiceCallManager: voiceCallManager
    }

    SimPinWindow {
        id: simPinWindow
        visible: false
    }

    function openSIMLockedPage() {
        simPinWindow.show();
    }
}
