/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import "views"
import "services"
import "model"

import "services/LaunchActionHandler.js" as LaunchActionHandler

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

    /// Set by the desktop host. A device has a system app menu of its own and
    /// wants none of ours.
    property bool runningOnDesktop: false

    width: Settings.displayWidth
    height: Settings.displayHeight
    windowType: "_WEBOS_WINDOW_TYPE_NONE" // make sure this window will never appear in the card shell

    // The collaborators LaunchActionHandler needs to carry out an action.
    readonly property var launchServices: ({
        dialHandler: dialHandlerId,
        voiceCallManager: voiceCallMgrWrapperId,
        ui: {
            showDialpad: function() { phoneWindow.showDialpad(); },
            showCallLog: function() { phoneWindow.showCallLog(); },
            showFavorites: function() { phoneWindow.showFavorites(); },
            showActiveCall: function(force) { phoneWindow.showActiveCall(force); },
            showVoicemail: function() { dialHandlerId.dialVoicemail(); }
        }
    })

    /**
     * Acts on the launch parameters. Beyond opening the app, these let other
     * applications drive the phone -- the bluetooth handsfree profile answering
     * a call, the system manager raising the in-call screen, the messaging app
     * dialling a number. The legacy app supported this through
     * source/LaunchActionHandler.js; the QML app ignored every parameter but
     * `mode` and `launchedAtBoot`.
     */
    function handleLaunchParams(params) {
        if (!params)
            return;

        /*
         * The status bar's menu does not draw anything itself: it relaunches
         * the app with this command and leaves the app to put its own menu up.
         * On a device that is the only way in, since the app draws no menu
         * button of its own there.
         */
        // The command may arrive on its own or still wrapped in the launch
        // request the shell sent, depending on what the runner hands over.
        var command = params["palm-command"] ||
                      (params.params ? params.params["palm-command"] : undefined);

        if (command === "open-app-menu") {
            console.log("Opening the app menu for the status bar");
            phoneWindow.openAppMenu();
            return;
        }

        if (params.mode && params.mode === "first-use") {
            // PIN window will now open automatically when the PIN is required
            return;
        }

        if (params.action) {
            var handled = LaunchActionHandler.handle(params, root.launchServices);

            // Call control asked for by another app must not steal the screen.
            if (handled && LaunchActionHandler.isBackgroundAction(params.action))
                return;
            if (handled)
                return;
        }

        // A bare address is the old way of asking for a call.
        if (params.address) {
            dialHandlerId.dial(params.address);
            return;
        }

        if (!params.launchedAtBoot)
            phoneWindow.show();
    }

    Component.onCompleted: {
        // with qml-runner, launchParams are set later on
        if(typeof root.params === "undefined") {
            var launchParams = {"mode": "first-use"};
            if (typeof application !== "undefined")
                launchParams = JSON.parse(application.launchParameters);

            console.log("Parsing Launch Params: " + JSON.stringify(launchParams));
            handleLaunchParams(launchParams);
        }
    }

    onLaunchParamsChanged: {
        console.log("DEBUG: Relaunched with parameters: " + launchParams);
        handleLaunchParams(params);
    }

    Connections {
        target: typeof application !== "undefined" ? application : null
        function onRelaunched(parameters) {
            console.log("DEBUG: Relaunched with parameters: " + parameters);

            var params = {};
            try {
                params = JSON.parse(parameters);
            } catch (error) {
                console.log("Could not parse relaunch parameters: " + error);
            }

            var hasCommand = params["palm-command"] ||
                             (params.params && params.params["palm-command"]);

            if (params.action || params.address || hasCommand) {
                root.handleLaunchParams(params);
                return;
            }

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

        callTransports: callTransportsId

        onEndingCall: (voiceCall) => { callHistoryModelId.addEndedCall(voiceCall); }
    }

    RingManager {
        voiceCallManager: voiceCallMgrWrapperId
    }

    /* Synergy: which accounts can place calls, and over what */
    CallTransports {
        id: callTransportsId
    }

    ImBuddyStatus {
        id: imBuddyStatusId
    }

    DialProxy {
        id: dialProxyId
        callTransports: callTransportsId
        telephonyManager: telephonyManagerId
    }

    /* telephony services */
    SupplementaryServices {
        id: supplementaryServicesId
        modemPath: telephonyManagerId.getModemPath()
    }

    DialingShortcuts {
        id: dialingShortcutsId
    }

    DialHandler {
        id: dialHandlerId

        voiceCallMgrWrapper: voiceCallMgrWrapperId
        telephonyManager: telephonyManagerId
        supplementaryServices: supplementaryServicesId
        dialingShortcuts: dialingShortcutsId
        dialProxy: dialProxyId
        callTransports: callTransportsId

        // More than one calling account and no stored preference: ask.
        onTransportChoiceRequired: (callData) => phoneWindow.askPreferredService(callData)
    }

    AudioRouteManager {
        id: audioRouteManagerId
        voiceCallManager: voiceCallMgrWrapperId
    }

    ProximityManager {
        voiceCallManager: voiceCallMgrWrapperId
        audioRouteManager: audioRouteManagerId
    }

    NotificationManager {
        voiceCallManager: voiceCallMgrWrapperId
        telephonyManager: telephonyManagerId
        contacts: personListModelId

        onMissedCall: (lineId, displayName) => missedCallAlertId.showMissedCall(lineId, displayName)
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

    /*
     * views
     *
     * The app has two looks, one for each shape of device, and this is the
     * only place that chooses between them. Settings.tabletUi is what the
     * shell itself reads to tell a tablet from a handset, so the app follows
     * that rather than measuring its own window -- a phone app on a big
     * screen is still a phone app. Everything below takes a UiTheme and never
     * names either of the two.
     *
     * Only the look in force is ever built. The two are components rather
     * than objects, and the loader turns one of them into the single theme
     * the app then wears for its lifetime; the other stays a recipe.
     *
     * A loaded object arrives one pass later than a declared one: the loader
     * builds its item when it completes, which is after the bindings below
     * have run once. Anything that reads the theme that early has to tolerate
     * finding nothing there yet -- it is asked again as soon as it lands.
     */
    readonly property UiTheme phoneUiTheme: uiThemeLoaderId.item

    Loader {
        id: uiThemeLoaderId
        sourceComponent: Settings.tabletUi ? tabletUiThemeComponent
                                           : phoneUiThemeComponent
    }

    Component {
        id: phoneUiThemeComponent
        PhoneUiTheme {}
    }

    Component {
        id: tabletUiThemeComponent
        TabletUiTheme {}
    }

    IncomingCallAlert {
        id: incomingCallAlertWindowId
        contacts: personListModelId
        voiceCallManager: voiceCallMgrWrapperId
        appTheme: phoneUiTheme
        visible: false
    }

    MissedCallAlert {
        id: missedCallAlertId
        appTheme: phoneUiTheme
        dialHandler: dialHandlerId
        visible: false
    }

    SimPinWindow {
        id: simPinWindowId
        appTheme: root.phoneUiTheme
        telephonyManager: telephonyManagerId
        voiceCallMgrWrapper: voiceCallMgrWrapperId
        visible: false
    }

    PhoneWindow {
        id: phoneWindow
        runningOnDesktop: root.runningOnDesktop
        simPinWindow: simPinWindowId
        incomingCallAlertWindow: incomingCallAlertWindowId
        contacts: personListModelId
        voiceCallMgrWrapper: voiceCallMgrWrapperId
        telephonyManager: telephonyManagerId
        historyModel: callHistoryModelId
        favoritesModel: favoritesModelId
        phoneUiAppTheme: phoneUiTheme
        dialHandler: dialHandlerId
        supplementaryServices: supplementaryServicesId
        audioRouteManager: audioRouteManagerId
        dialingShortcuts: dialingShortcutsId
        callTransports: callTransportsId
        imBuddyStatus: imBuddyStatusId
    }

    IncomingUSSDAlert {
        id: incomingUSSDAlertId
        telephonyManager: telephonyManagerId
        visible: false
    }
}
