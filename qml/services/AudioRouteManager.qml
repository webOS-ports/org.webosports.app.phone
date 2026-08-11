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

import LuneOS.Service 1.0

import "CallMessages.js" as CallMessages

/**
 * In-call audio routing.
 *
 * Ports three pieces of the legacy app that were separate there: the audio
 * route picker from ActiveCall.js, wiredHeadsetInterface.js, and the Touchstone
 * behaviour from puckInterface.js -- docking the device during a call switched
 * to the back speaker, undocking switched back.
 */
Item {
    id: audioRouteManager

    property var voiceCallManager

    readonly property string routeEarpiece: "earpiece"
    readonly property string routeSpeaker: "ihf"
    readonly property string routeBluetooth: "bt_sco"
    readonly property string routeWiredHeadset: "wired_headset"

    /// The route currently in use, as reported by the voicecall manager.
    readonly property string currentRoute: voiceCallManager ? voiceCallManager.audioMode : routeEarpiece

    property bool bluetoothAvailable: false
    property bool wiredHeadsetConnected: false
    property bool onCharger: false
    property bool onInductiveCharger: false

    readonly property bool speakerOn: currentRoute === routeSpeaker

    /// Routes the user can pick from right now, most-preferred first.
    readonly property var availableRoutes: {
        var routes = [routeEarpiece, routeSpeaker];
        if (wiredHeadsetConnected) routes.push(routeWiredHeadset);
        if (bluetoothAvailable) routes.push(routeBluetooth);
        return routes;
    }

    function routeLabel(route) {
        switch (route) {
        case routeSpeaker:      return CallMessages.audioRouteSpeaker;
        case routeBluetooth:    return CallMessages.audioRouteBluetooth;
        case routeWiredHeadset: return CallMessages.audioRouteWiredHeadset;
        default:                return CallMessages.audioRouteEarpiece;
        }
    }

    function setRoute(route) {
        if (!voiceCallManager) return;

        console.log("Switching call audio to " + route);
        voiceCallManager.setAudioMode(route);
    }

    /// Speaker on/off, the single button the active call screen exposes.
    function toggleSpeaker() {
        setRoute(speakerOn ? _defaultRoute() : routeSpeaker);
    }

    /// Steps through the available routes, for the audio-route button.
    function nextRoute() {
        var routes = availableRoutes;
        var index = routes.indexOf(currentRoute);
        setRoute(routes[(index + 1) % routes.length]);
    }

    function _defaultRoute() {
        if (wiredHeadsetConnected) return routeWiredHeadset;
        if (bluetoothAvailable) return routeBluetooth;
        return routeEarpiece;
    }

    /// Called when a call starts, to pick a sensible route without the user
    /// having to touch anything.
    function applyDefaultRoute() {
        setRoute(onInductiveCharger ? routeSpeaker : _defaultRoute());
    }

    // Docking on a Touchstone during a call switches to the back speaker, as on
    // the original hardware; undocking puts it back on the earpiece.
    onOnInductiveChargerChanged: {
        if (!voiceCallManager || !voiceCallManager.activeVoiceCall)
            return;

        setRoute(onInductiveCharger ? routeSpeaker : _defaultRoute());
    }

    onWiredHeadsetConnectedChanged: {
        if (!voiceCallManager || !voiceCallManager.activeVoiceCall)
            return;

        // Plugging a headset in takes the call; unplugging must never silently
        // hand the call to the loudspeaker.
        setRoute(wiredHeadsetConnected ? routeWiredHeadset : routeEarpiece);
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    Component.onCompleted: {
        lunaService.subscribe("luna://com.palm.bluetooth/hfg/monitorstatus",
                              JSON.stringify({ subscribe: true }),
                              function(message) {
                                  var response = JSON.parse(message.payload);
                                  bluetoothAvailable = (response.connected === true) ||
                                                       (response.status === "connected");
                              },
                              function(error) {
                                  console.log("No bluetooth handsfree status: " + error);
                                  bluetoothAvailable = false;
                              });

        lunaService.subscribe("luna://com.palm.keys/audio/status",
                              JSON.stringify({ subscribe: true }),
                              function(message) {
                                  var response = JSON.parse(message.payload);
                                  wiredHeadsetConnected = (response.headset === true) ||
                                                          (response.headsetMic === true);
                              },
                              function(error) {
                                  console.log("No wired headset status: " + error);
                                  wiredHeadsetConnected = false;
                              });

        lunaService.subscribe("luna://com.palm.power/com/palm/power/chargerStatus",
                              JSON.stringify({ subscribe: true }),
                              function(message) {
                                  var response = JSON.parse(message.payload);
                                  onCharger = (response.connected === true);
                                  if (response.type === "inductive")
                                      onInductiveCharger = (response.connected === true);
                              },
                              function(error) {
                                  console.log("No charger status: " + error);
                              });
    }
}
