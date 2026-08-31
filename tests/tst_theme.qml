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

import "../qml/views"

/**
 * The two looks, and the artwork each of them draws from.
 *
 * Most of what these check is the kind of thing that goes wrong silently: an
 * asset present in one set and not the other resolves to a URL that simply
 * does not load, and nothing says so except a missing picture on a device.
 */
TestCase {
    id: testCase
    name: "Theme"

    PhoneUiTheme  { id: phone }
    TabletUiTheme { id: tablet }
    UiTheme       { id: base }

    /// Every image the views ask a theme for, gathered from the source.
    readonly property var assets: [
        "backdrop-firstuse.png", "button-ignore-answer.png", "button-sprite.png",
        "buttons-numpad.png", "buttons-numpad-pressed.png",
        "call-log-drawer-sub-item-bg.png", "call-log-list-separator.png",
        "call-log-list-sprite.png", "contacts-unknown-icon-large.png",
        "dashboard-unread.png", "dial-button.png", "dialer-entry-bg.png",
        "dialpad-backspace.png", "dialpad-bg.png", "disconnect-button.png",
        "expand-button.png", "favorites-star-blue.png", "group-labeled.png",
        "group-unlabeled.png", "list-avatar-default.png",
        "pin-menu-button.png", "pin-menu-button-pressed.png",
        "popup-icon-error.png", "search-button.png"
    ]

    function test_each_look_has_its_own_artwork() {
        verify(String(phone.imageDir).length > 0, "the phone look names no directory");
        verify(String(tablet.imageDir).length > 0, "the tablet look names no directory");
        verify(phone.imageDir !== tablet.imageDir,
               "both looks draw from the same directory, so the split does nothing");
    }

    /**
     * The base declares the interface; it is not a look in its own right, and
     * nothing should ever be drawn out of its directory. This is what went
     * wrong once already: a path that resolved against the base landed in the
     * old flat images/ directory, which no longer holds anything.
     */
    function test_neither_look_falls_back_to_the_base_directory() {
        compare(phone.imageDir === base.imageDir, false,
                "the phone look never overrode imageDir");
        compare(tablet.imageDir === base.imageDir, false,
                "the tablet look never overrode imageDir");
    }

    function test_image_resolves_under_the_looks_own_directory() {
        var name = "dial-button.png";
        compare(String(phone.image(name)), String(phone.imageDir) + name);
        compare(String(tablet.image(name)), String(tablet.imageDir) + name);
    }

    /**
     * Both sets must answer for every asset. A name present in one and missing
     * from the other is invisible until the look that lacks it is the one in
     * force.
     */
    function test_both_sets_answer_for_every_asset() {
        for (var i = 0; i < assets.length; ++i) {
            var name = assets[i];
            probe.source = phone.image(name);
            verify(probe.status !== Image.Error, "the phone set has no " + name);
            probe.source = tablet.image(name);
            verify(probe.status !== Image.Error, "the tablet set has no " + name);
        }
    }

    /// The PIN card reads its shape from the theme; the two must disagree,
    /// or the tablet is being shown the handset's full-bleed card.
    function test_the_looks_disagree_about_the_pin_card() {
        compare(phone.pinCardIsPanel, false);
        compare(tablet.pinCardIsPanel, true);
        verify(phone.pinCardEntrySize !== tablet.pinCardEntrySize);
        verify(String(phone.pinCardEntryColor) !== String(tablet.pinCardEntryColor));
    }

    Image {
        id: probe
        visible: false
        asynchronous: false
        cache: false
    }
}
