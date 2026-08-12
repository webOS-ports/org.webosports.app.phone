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

/**
 * Blanks the screen while the phone is held to the ear.
 *
 * Ported from the legacy source/proxInterface.js: the proximity sensor is only
 * enabled while a call is up *and* its audio is on the earpiece, so putting a
 * speakerphone call on the table does not black the screen out.
 */
Item {
    id: proximityManager

    property var voiceCallManager
    property var audioRouteManager

    readonly property bool shouldEnable: !!voiceCallManager &&
                                         (!!voiceCallManager.activeVoiceCall ||
                                          voiceCallManager.callCount > 0) &&
                                         (!audioRouteManager ||
                                          audioRouteManager.currentRoute === audioRouteManager.routeEarpiece)

    property bool _enabled: false
    /// What subscribe() handed back. cancel() lives on that, not on the
    /// LunaService itself, which has no such method -- releasing the sensor
    /// used to throw instead.
    property var _subscription: null

    onShouldEnableChanged: shouldEnable ? _enable() : _disable()

    function _enable() {
        if (_enabled) return;

        console.log("Enabling the proximity sensor for the call in progress");
        _subscription = proximitySubscription.subscribe(
                            JSON.stringify({ proximityEnabled: true, client: "phoneapp" }));
        _enabled = true;
    }

    function _disable() {
        if (!_enabled) return;

        console.log("Disabling the proximity sensor");
        if (_subscription) {
            _subscription.cancel();
            _subscription = null;
        }
        _enabled = false;
    }

    // The subscription is what keeps the sensor on: com.palm.display turns it
    // back off as soon as the last subscriber goes away, so cancelling is how
    // the sensor is released.
    LunaService {
        id: proximitySubscription
        name: "org.webosports.app.phone"
        usePrivateBus: true
        service: "luna://com.palm.display"
        method: "control/setProperty"

        onResponse: function (message) {
            console.log("Proximity sensor: " + message.payload);
        }
    }

    Component.onDestruction: _disable()
}
