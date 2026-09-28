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
 * How the dialer divides the page it is given.
 *
 * The keypad filling the screen is sized by subtraction: the field and the
 * dial button take their natural heights and the keys get the remainder. That
 * works on a tall handset and falls apart on a square one -- on a Q25 the two
 * naturals came to half the page and the keys were left four times wider than
 * they were tall. The arithmetic that fixes it is invisible until someone
 * looks at the device, which is why it is pinned here.
 *
 * The page is driven directly rather than through PhoneTabView: this is about
 * the division of a height, and handing it one is the whole of the setup.
 */
TestCase {
    name: "DialerLayout"

    PhoneUiTheme { id: phoneTheme }

    Component {
        id: dialerComponent
        DialerPage {
            appTheme: phoneTheme
            fillsScreen: true
        }
    }

    property string _startingProfile

    function initTestCase() { _startingProfile = Settings.profileName; }
    function cleanupTestCase() { Settings.setProfile(_startingProfile); }

    /**
     * The dialer as the app would build it, at a given page height.
     *
     * How much height there is to divide is not the panel's: the status bar
     * and the gesture area are the compositor's, the tab bar is the app's, and
     * what is left over is what the keypad gets. On the Q25 that came to 512
     * of the panel's 720. Rather than hard-code the compositor's share, the
     * cases below walk a range of it, so the arithmetic is pinned for whatever
     * the shell ends up handing over.
     */
    function _dialer(profile, pageHeight) {
        verify(Settings.setProfile(profile), "could not select " + profile);
        var page = createTemporaryObject(dialerComponent, this,
                                         { width: Settings.displayWidth,
                                           height: pageHeight });
        verify(page !== null, profile + ": the dialer would not load");
        return page;
    }

    function _pageHeights(fractions) {
        var heights = [];
        for (var i = 0; i < fractions.length; ++i)
            heights.push(Math.round(Settings.displayHeight * fractions[i]) - Units.gu(6));
        return heights;
    }

    /// The point of the whole exercise: on a screen no taller than it is wide,
    /// the keys still get the bulk of whatever the shell leaves the app.
    function test_the_keys_keep_their_share_of_a_square_screen() {
        verify(Settings.setProfile("q25"), "could not select q25");

        // The whole panel, then the card the Q25's shell actually hands over,
        // then tighter still.
        var heights = _pageHeights([1.0, 0.845, 0.78]);
        for (var i = 0; i < heights.length; ++i) {
            var page = _dialer("q25", heights[i]);
            var where = "q25 at " + heights[i] + "px";

            // Half a pixel of slack: where the chrome is squeezed the keys get
            // exactly the share, and exactly is a hair under it in floating
            // point.
            verify(page.padKeysHeight >= page.height * page.keysMinimumShare - 0.5,
                   where + ": keys got " + page.padKeysHeight + " of " + page.height);

            // Four rows out of what is left, less the pad's own inset. This
            // only has to be enough to press with a thumb; at 291dpi five grid
            // units is about 7mm, where the 55px the Q25 used to get was under
            // five and read as a row of letterboxes.
            var keyHeight = (page.padKeysHeight - Units.gu(2)) / 4;
            verify(keyHeight >= Units.gu(5),
                   where + ": a key is only " + keyHeight + " tall ("
                         + Units.gu(5) + " wanted)");
        }
    }

    /// And a tall screen is left exactly as it was: the chrome is only ever
    /// squeezed when it would not otherwise fit.
    function test_a_tall_screen_keeps_the_natural_sizes() {
        var page = _dialer("gnex", Settings.displayHeight - Units.gu(6));

        compare(page.chromeScale, 1, "a tall screen should not be scaling anything");
        compare(page.entryHeight, Units.gu(7), "the field lost its natural height");
        compare(page.dialHeight, page.naturalDialHeight,
                "the dial button lost its natural height");
    }

    /// The dial button narrows to meet a height cap rather than being drawn
    /// the full width and squashed onto it -- that squashing is what stretched
    /// the handset glyph the last time this was got wrong.
    function test_the_dial_button_keeps_its_proportions() {
        var names = ["q25", "gnex"];
        for (var i = 0; i < names.length; ++i) {
            var page = _dialer(names[i], Settings.displayHeight - Units.gu(6));

            verify(page.dialHeight <= page.naturalDialHeight + 0.5,
                   names[i] + ": the button grew past its natural height");
            // The height it is allowed and the width it is drawn at stay in
            // the artwork's own ratio, whatever the cap did to them.
            fuzzyCompare(page.dialHeight / page.keypadWidth,
                         phoneTheme.footerButtonImageSize.height / 3
                             / phoneTheme.footerButtonImageSize.width,
                         0.005, names[i] + ": the button is no longer in proportion");
        }
    }

    /**
     * The keys and the button line up exactly, on every shape of screen.
     *
     * Not approximately: three key widths are what the grid actually measures,
     * and NumPad rounds each of them to a whole pixel, so a shared width that
     * is not a multiple of three leaves the button overhanging the keys.
     */
    function test_the_keys_and_the_dial_button_are_the_same_width() {
        var names = ["q25", "gnex"];
        for (var i = 0; i < names.length; ++i) {
            var page = _dialer(names[i], Settings.displayHeight - Units.gu(6));
            var pad = findChild(page, "numPad");
            var button = findChild(page, "dialButton");
            var entry = findChild(page, "numberEntry");

            verify(pad !== null, names[i] + ": no keypad to measure");
            verify(button !== null, names[i] + ": no dial button to measure");
            verify(entry !== null, names[i] + ": no number field to measure");

            // The field too: the column is one width from the top of it to the
            // bottom of the button, and a field wider than the pad it belongs
            // to reads as a mistake in exactly the way an oversized backdrop
            // did.
            compare(entry.width, page.keypadWidth,
                    names[i] + ": the number field is not the width of the keys");

            compare(pad.keysWidth * 3, page.keypadWidth,
                    names[i] + ": the grid does not fill the width it was given");
            compare(button.width, page.keypadWidth,
                    names[i] + ": the button is not the width of the keys");
            // And the backdrop they are drawn on. Three things stacked one
            // above another, and any one of them a different width from the
            // other two is the thing that catches the eye -- this has been
            // wrong in both directions already, once too wide and once too
            // narrow.
            compare(pad.width, page.keypadWidth,
                    names[i] + ": the pad's backdrop is not the width of its keys");
            verify(page.keypadWidth <= page.naturalKeypadWidth,
                   names[i] + ": the keys grew past the pad");
        }
    }
}
