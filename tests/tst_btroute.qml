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
import QtTest 1.2

import "../qml/services"

/**
 * Call audio on a hands-free Bluetooth headset, as the phone app sees it:
 * audiod's getStatus says whether one is connected (bluetoothCall) and
 * whether the call is on it (bluetoothCallActive); the route button offers
 * it and asks audiod's setCallMode for it by route.
 */
Item {
    id: root

    TestCase {
        name: "BluetoothRoute"

        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: routesComponent
            AudioRouteManager {}
        }

        function status(wrapper, fields) {
            var s = { returnValue: true, speakerMode: false, micMute: false,
                      headset: false, bluetoothAudio: false,
                      bluetoothCall: false, bluetoothCallActive: false };
            for (var k in fields)
                s[k] = fields[k];
            wrapper.__audioStatus({ payload: JSON.stringify(s) });
        }

        function make() {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            var routes = createTemporaryObject(routesComponent, root, { voiceCallManager: wrapper });
            verify(routes !== null, "the route manager did not load");
            return { wrapper: wrapper, routes: routes };
        }

        function test_noHeadsetNoBluetoothRoute() {
            var o = make();
            status(o.wrapper, {});
            compare(o.routes.bluetoothAvailable, false);
            compare(o.routes.availableRoutes, ["earpiece", "ihf"]);
            compare(o.routes.currentRoute, "earpiece");
        }

        function test_aConnectedHeadsetIsOffered() {
            var o = make();
            status(o.wrapper, { bluetoothCall: true });
            compare(o.routes.bluetoothAvailable, true);
            compare(o.routes.availableRoutes, ["earpiece", "ihf", "bt_sco"]);
            status(o.wrapper, { bluetoothCall: false });
            compare(o.routes.bluetoothAvailable, false);
        }

        function test_theCallOnTheHeadsetShowsAsBluetooth() {
            var o = make();
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true });
            compare(o.wrapper.audioMode, "bt_sco");
            compare(o.routes.currentRoute, "bt_sco");
            // The speaker picked over it wins the button.
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: false, speakerMode: true });
            compare(o.routes.currentRoute, "ihf");
            // Plugged in but on the headset: the headset.
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true, headset: true });
            compare(o.routes.currentRoute, "bt_sco");
        }

        function test_routesAreAskedForByName() {
            var o = make();
            compare(o.wrapper._callModeRequest("ihf"), { route: "speaker" });
            compare(o.wrapper._callModeRequest("bt_sco"), { route: "bluetooth" });
            compare(o.wrapper._callModeRequest("earpiece"), { route: "handset" });
            compare(o.wrapper._callModeRequest("wired_headset"), { route: "handset" });
            compare(o.wrapper._callModeRequest("default"), { route: "default" });
        }

        function test_theButtonCyclesThroughTheHeadset() {
            var o = make();
            var asked = [];
            o.routes.routeRequested.connect(function(route) { asked.push(route); });
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true });
            o.routes.nextRoute();
            status(o.wrapper, { bluetoothCall: true });
            o.routes.nextRoute();
            status(o.wrapper, { bluetoothCall: true, speakerMode: true });
            o.routes.nextRoute();
            compare(asked, ["earpiece", "ihf", "bt_sco"]);
        }

        function test_automaticChoicesAreLeftToAudiod() {
            var o = make();
            var asked = [];
            o.routes.routeRequested.connect(function(route) { asked.push(route); });
            status(o.wrapper, { bluetoothCall: true, headset: true });
            o.routes.applyDefaultRoute();
            o.routes.toggleSpeaker();                       // on
            status(o.wrapper, { bluetoothCall: true, headset: true, speakerMode: true });
            o.routes.toggleSpeaker();                       // off again
            compare(asked, ["default", "ihf", "default"]);
        }
    }
}
