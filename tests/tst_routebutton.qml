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
import QtTest 1.2

import "../qml/services"
import "../qml/views"

/**
 * The audio route button under the call card, per route, fed audiod's
 * getStatus the way the wrapper hears it.
 *
 * As webOS 2.x drew it: with no Bluetooth headset it is the "Speaker"
 * toggle, lit on the speaker, with the handset, speaker or headphone glyph;
 * with one it is "Audio", unlit, with the drop-down glyph of the route in
 * use. Those glyphs are two 3:2 frames; drawn as a square one-frame icon
 * both frames showed at once, under "Speaker", while the call was on the
 * headset.
 *
 * Every glyph sits in the same square box as the neighbouring buttons'
 * icons, centred the same way, and a drop-down glyph shows only its left
 * square there, without the caret, as the Enyo app of 2.2.4 and 3.0.5 drew
 * it in its 32x32 .enyo-button-icon.
 */
Item {
    id: root
    width: 480
    height: 800

    PhoneUiTheme  { id: phone }
    TabletUiTheme { id: tablet }

    TestCase {
        name: "AudioRouteButton"
        when: windowShown

        Component {
            id: wrapperComponent
            VoiceCallMgrWrapper {}
        }
        Component {
            id: routesComponent
            AudioRouteManager {}
        }
        Component {
            id: buttonComponent
            AudioRouteButton {}
        }
        Component {
            id: neighbourComponent
            CallActionButton { label: "Mute"; x: 200 }
        }

        function status(wrapper, fields) {
            var s = { returnValue: true, speakerMode: false, micMute: false,
                      headset: false, bluetoothAudio: false,
                      bluetoothCall: false, bluetoothCallActive: false };
            for (var k in fields)
                s[k] = fields[k];
            wrapper.__audioStatus({ payload: JSON.stringify(s) });
        }

        function make(theme) {
            var wrapper = createTemporaryObject(wrapperComponent, root);
            verify(wrapper !== null, "the wrapper did not load");
            var routes = createTemporaryObject(routesComponent, root, { voiceCallManager: wrapper });
            verify(routes !== null, "the route manager did not load");
            var button = createTemporaryObject(buttonComponent, root,
                                               { appTheme: theme || phone, audioRouteManager: routes });
            verify(button !== null, "the button did not load");
            var icon = findChild(button, "icon");
            verify(icon !== null, "the button has no icon");
            var box = findChild(button, "iconBox");
            verify(box !== null, "the button has no icon box");
            var mute = createTemporaryObject(neighbourComponent, root,
                                             { appTheme: theme || phone,
                                               iconSource: (theme || phone).image("menu-icon-mute.png") });
            verify(mute !== null, "the neighbour did not load");
            return { wrapper: wrapper, routes: routes, button: button, icon: icon, box: box,
                     neighbourBox: findChild(mute, "iconBox") };
        }

        /// The glyph, the label, whether it is lit, and that what is drawn is
        /// one frame of the strip: a loaded image, as many frames as the
        /// strip holds, and an icon box of the frame's own shape.
        function checkButton(o, glyph, label, lit, frames) {
            compare(o.button.iconName, glyph);
            compare(String(o.button.iconSource), String(o.button.appTheme.image(glyph)));
            compare(o.button.label, label);
            compare(o.button.active, lit);
            var image = o.icon.children[0];
            tryCompare(image, "status", Image.Ready);
            compare(o.icon._frames, frames, glyph + " is drawn as " + o.icon._frames + " frame(s)");
            var frameW = image.sourceSize.width;
            var frameH = image.sourceSize.height / frames;
            fuzzyCompare(o.icon.width / o.icon.height, frameW / frameH, 0.01,
                         glyph + " is squashed into a box of the wrong shape");

            // The neighbours' box: the same square, centred the same way,
            // and the glyph drawn from its left edge and clipped to it.
            compare(o.box.width, o.neighbourBox.width, "the icon box is wider than Mute's");
            compare(o.box.height, o.neighbourBox.height, "the icon box is taller than Mute's");
            compare(o.box.width, o.box.height, "the icon box is not square");
            verify(o.box.clip, "a wide glyph is not clipped to the box");
            compare(o.icon.x, 0);
            compare(o.icon.y, 0);
            compare(o.icon.height, o.box.height);
            var c = o.box.mapToItem(o.button, o.box.width / 2, o.box.height / 2);
            var n = o.neighbourBox.mapToItem(o.neighbourBox.parent.parent.parent,
                                             o.neighbourBox.width / 2, o.neighbourBox.height / 2);
            fuzzyCompare(c.x, o.button.width / 2, 0.5, "the icon is off the button's centre");
            fuzzyCompare(c.y, n.y, 0.5, "the icon sits higher or lower than Mute's");
        }

        function test_earpiece_data() {
            return [ { tag: "phone", theme: phone }, { tag: "tablet", theme: tablet } ];
        }
        function test_earpiece(data) {
            var o = make(data.theme);
            status(o.wrapper, {});
            checkButton(o, "menu-icon-speaker-internal.png", "Speaker", false, 2);
        }

        function test_speaker_data() { return test_earpiece_data(); }
        function test_speaker(data) {
            var o = make(data.theme);
            status(o.wrapper, { speakerMode: true });
            checkButton(o, "menu-icon-speaker-external.png", "Speaker", true, 2);
        }

        function test_wiredHeadset_data() { return test_earpiece_data(); }
        function test_wiredHeadset(data) {
            var o = make(data.theme);
            status(o.wrapper, { headset: true });
            checkButton(o, "menu-icon-headset.png", "Speaker", false, 2);
        }

        /// What audiod reported at 05:21 on the mindphone: the call on the
        /// Nuraphone.
        function test_bluetooth_data() { return test_earpiece_data(); }
        function test_bluetooth(data) {
            var o = make(data.theme);
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true,
                                bluetoothAudio: true, bluetoothAudioName: "nuraphone 943" });
            checkButton(o, "menu-popup-bluetooth.png", "Audio", false, 2);
        }

        /// With a headset connected the button stays the menu whichever route
        /// the call is on, and shows that route.
        function test_headsetConnectedOtherRoutes_data() {
            return [
                { tag: "earpiece", fields: {},                   glyph: "menu-popup-bluetooth-internal.png" },
                { tag: "speaker",  fields: { speakerMode: true }, glyph: "menu-popup-bluetooth-speaker.png" },
                { tag: "wired",    fields: { headset: true },     glyph: "menu-popup-bluetooth-headset.png" }
            ];
        }
        function test_headsetConnectedOtherRoutes(data) {
            var o = make(phone);
            var fields = { bluetoothCall: true };
            for (var k in data.fields)
                fields[k] = data.fields[k];
            status(o.wrapper, fields);
            checkButton(o, data.glyph, "Audio", false, 2);
        }

        /// The headset going takes the menu with it.
        function test_headsetGoneBackToTheToggle() {
            var o = make(phone);
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true });
            compare(o.button.label, "Audio");
            status(o.wrapper, {});
            checkButton(o, "menu-icon-speaker-internal.png", "Speaker", false, 2);
        }

        function test_tappingStepsToTheNextRoute() {
            var o = make(phone);
            var asked = [];
            o.routes.routeRequested.connect(function(route) { asked.push(route); });
            status(o.wrapper, { bluetoothCall: true, bluetoothCallActive: true });
            mouseClick(o.button);
            compare(asked, ["earpiece"]);
        }
    }
}
