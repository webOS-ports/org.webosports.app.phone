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

import LunaNext.Common 0.1

import "../qml/views"

/**
 * The device profile a run is pretending to be, and the look that follows.
 *
 * Settings.tabletUi is the whole basis on which the app picks a look, so a
 * profile that does not take is a run that tests one look twice. The mock lets
 * a test switch device, so this walks every profile it offers rather than
 * covering whichever one the run happened to start in.
 */
TestCase {
    name: "Profile"

    PhoneUiTheme  { id: phone }
    TabletUiTheme { id: tablet }

    property string _startingProfile

    function initTestCase() { _startingProfile = Settings.profileName; }
    function cleanupTestCase() { Settings.setProfile(_startingProfile); }

    function test_the_mock_offers_profiles() {
        verify(Object.keys(Settings.profiles).length > 1,
               "only one device profile; both looks cannot be covered");
        compare(Settings.setProfile("no-such-device"), false,
                "an unknown profile was accepted");
    }

    function test_every_profile_applies() {
        var names = Object.keys(Settings.profiles);
        for (var i = 0; i < names.length; ++i) {
            var name = names[i];
            verify(Settings.setProfile(name), "could not select " + name);
            compare(Settings.profileName, name);

            var wanted = Settings.profiles[name];
            compare(Settings.tabletUi, wanted.tabletUi, name + ": tabletUi did not take");
            compare(Settings.displayWidth, wanted.displayWidth, name + ": width did not take");
            compare(Settings.gridUnit, wanted.gridUnit, name + ": gridUnit did not take");
            verify(Settings.gridUnit > 0, name + ": Units.gu() would collapse to zero");
        }
    }

    /// Under every profile, the look the app would choose draws from its own
    /// artwork -- a handset never ends up on tablet art, or the other way.
    function test_the_look_follows_the_profile() {
        var names = Object.keys(Settings.profiles);
        for (var i = 0; i < names.length; ++i) {
            Settings.setProfile(names[i]);
            var look = Settings.tabletUi ? tablet : phone;
            var wanted = Settings.tabletUi ? "/tablet/" : "/phone/";
            verify(String(look.imageDir).indexOf(wanted) >= 0,
                   names[i] + ": would draw from " + look.imageDir);
        }
    }
}
