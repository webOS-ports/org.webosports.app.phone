/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

import QtQuick 2.0
import "views"
import "services"
import "model"

import Eos.Window 0.1

import LunaNext.Common 0.1
import LuneOS.Service 1.0

WebOSWindow {
    id: root

    visible: false
    onVisibleChanged: {
        if (root.visible) {
            root.visible = false;
            root.launchParamsChanged();
        }
    }

    width: Settings.displayWidth
    height: Settings.displayHeight
    windowType: "_WEBOS_WINDOW_TYPE_NONE" // make sure this window will never appear in the card shell

    Component.onCompleted: {
        // with qml-runner, launchParams are set later on
        if(typeof root.params === "undefined") {
            var launchParams = {"mode": "first-use"};
            if (typeof application !== "undefined")
                launchParams = JSON.parse(application.launchParameters);

            console.log("Parsing Launch Params: " + JSON.stringify(launchParams));
            var params = launchParams;

            if (params.mode && params.mode === "first-use") {
                // PIN window will now open automatically when the PIN is required
                return;
            }

            if (!params.launchedAtBoot)
                phoneWindow.show();
        }
    }

    onLaunchParamsChanged: {
        console.log("DEBUG: Relaunched with parameters: " + launchParams);

        if (params.mode && params.mode === "first-use") {
            // PIN window will now open automatically when the PIN is required
            return;
        }

        if (!params.launchedAtBoot)
            phoneWindow.show();
    }

    Connections {
        target: typeof application !== "undefined" ? application : null
        function onRelaunched(parameters) {
            console.log("DEBUG: Relaunched with parameters: " + parameters);

            // If we're launched at boot time we're not yet visible so bring our window
            // to the foreground
            phoneWindow.show();
        }
    }


    TelephonyManager {
        id: telephonyManagerId
    }

    VoiceCallMgrWrapper {
        id: voiceCallMgrWrapperId

        onEndingCall: (voiceCall) => { callHistoryModelId.addEndedCall(voiceCall); }
    }

    RingManager {
        voiceCallManager: voiceCallMgrWrapperId
    }

    /* models */
    ContactsModel {
        id: personListModelId
        countryCode: voiceCallMgrWrapperId.countryCode
    }
    CallHistory {
        id: callHistoryModelId
        personListModel: personListModelId
    }
    FavoritesModel {
        id: favoritesModelId
    }

    /* views */
    PhoneUiTheme {
        id: phoneUiTheme
    }

    IncomingCallAlert {
        id: incomingCallAlertWindowId
        contacts: personListModelId
        voiceCallManager: voiceCallMgrWrapperId
        appTheme: phoneUiTheme
        visible: false
    }

    SimPinWindow {
        id: simPinWindowId
        visible: false
    }

    PhoneWindow {
        id: phoneWindow
        simPinWindow: simPinWindowId
        incomingCallAlertWindow: incomingCallAlertWindowId
        contacts: personListModelId
        voiceCallMgrWrapper: voiceCallMgrWrapperId
        telephonyManager: telephonyManagerId
        historyModel: callHistoryModelId
        favoritesModel: favoritesModelId
        phoneUiAppTheme: phoneUiTheme
    }

    IncomingUSSDAlert {
        telephonyManager: telephonyManagerId
        visible: false
    }
}
