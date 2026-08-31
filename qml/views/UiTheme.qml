/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

import LunaNext.Common 0.1

/**
 * What every view asks for its colours, metrics and artwork.
 *
 * The app wears one of two looks depending on the shape of the device it is
 * running on -- PhoneUiTheme or TabletUiTheme -- and this is the interface
 * both satisfy. A view holds a `UiTheme`, never one of the two, so nothing
 * below the theme has to know which is in force.
 *
 * Everything declared here is what the two have in common: the webOS phone
 * app kept the same chrome across the handset and the tablet, and the values
 * that survived both are the ones that belong here. What each look does
 * differently -- the list greys, the drawer, the row metrics, and the artwork
 * itself -- is set by the two themes and only by them.
 */
QtObject {
    id: uiTheme

    /**
     * Artwork
     *
     * The two looks are drawn from different artwork at different densities,
     * so no view names an image file directly: it asks the theme, which
     * answers out of its own directory.
     *
     *     source: appTheme.image("dialpad-bg.png")
     */
    property url imageDir: Qt.resolvedUrl("images/")

    function image(name) {
        return imageDir + name;
    }

    /**
     * Chrome
     **/

    /// The page behind everything. The same grey the list rows sit on -- the
    /// group box is told apart by its border alone, not by a fill of its own.
    property color backgroundColor: '#57595c'
    property color foregroundColor: '#ffffff'

    /// Panels that sit on the page: the call card, the dialpad, popups.
    property color panelColor: '#2d2c2c'
    /// The dark well inside a panel, behind an avatar or a call line.
    property color panelDarkColor: '#030303'
    /// The strip a panel's buttons sit on.
    property color panelFooterColor: '#242627'
    property color panelBorderColor: '#4a4a4a'

    /// Tab bar. The tab in use is the darker one: it reads as pressed in.
    property color tabBarColor: '#5a5d61'
    property color tabBarSelectedColor: '#424446'
    property color tabBarBorderColor: '#2c2e30'

    /**
     * Text
     **/

    property color primaryTextColor: '#ffffff'
    /// Secondary information: numbers under a name, timestamps, hints.
    property color secondaryTextColor: '#9a9a9a'
    /// The service a contact point or call belongs to, shown in caps.
    property color serviceTextColor: '#6f7070'
    property color disabledTextColor: '#5a5a5a'

    /**
     * Buttons
     **/

    property color buttonColor: '#2c2c2c'
    property color buttonPressedColor: '#3a3a3a'
    property color buttonBorderColor: '#151515'
    /// A toggled-on call control, e.g. speaker or mute.
    property color buttonActiveColor: '#3871a1'

    /// Place a call.
    property color callColor: '#60ab27'
    /// End or decline a call.
    property color hangupColor: '#d0341f'

    /// Destructive backdrop, revealed behind a swiped call log row.
    property color deleteColor: '#8b2020'

    /**
     * Lists
     *
     * Lists sit in a bordered group box, a mid grey with light text.
     *
     * These were read off the device twice and got it wrong both times: first
     * from a capture taken behind a dimming scrim, which made the list look
     * light-on-white, and then from the same capture again, which made it far
     * darker than it is. The values here are from an undimmed capture and are
     * corroborated -- the row separator's own alpha resolves to exactly the
     * pixels the device shows over this background.
     */
    property color listBackgroundColor: '#57595c'
    property color listAlternateColor: '#525457'
    property color listTextColor: '#ffffff'

    /**
     * Each list names its own second line, and each look gives it a different
     * grey. The selectors are .call-log .clv-drawerItem-displayLbl,
     * .contact-list .enyo-item and .drawerItem-favorites-displayLbl.
     */
    property color listSecondaryTextColor: '#cccccc'
    property color callLogDetailColor: '#9d9e9f'
    property color favoritesDetailColor: '#c5c5c6'
    /// A number inside an opened call group: .drawer-subItem-itemTextLbl.
    property color drawerNumberColor: '#cbcbcb'
    /// The name above a run of rows: .enyo-divider-caption.
    property color listSectionTextColor: '#8b8c8e'

    /**
     * The drawer a row opens. Favourites fills it flat; the call log lays a
     * nine-slice over it that darkens the top and bottom edges, so an open
     * drawer looks sunk into the row that opened it.
     */
    property color listSectionColor: '#3b3d3f'
    property url drawerBackgroundSource: image('call-log-drawer-sub-item-bg.png')

    /// A row the user is acting on: .enyo-addressing-item-selected.
    property color listSelectedColor: '#4a7298'

    /// The rule around a list: `2px solid #1f2121` with a six-pixel radius,
    /// set thirty pixels in from the edge of the page.
    property color listBorderColor: '#1f2121'
    property real listBorderWidth: 2
    property real listBorderRadius: Units.gu(0.6)
    property real listMargin: Units.gu(3)

    /**
     * The drawer a list row opens.
     *
     * A row of its own -- another number to call, "View Contact" -- is fifty
     * pixels tall. A past call is shorter, because it is a record rather than
     * something to act on. Both indent past the photo so their text lines up
     * with the name of the row that opened them, which is what the original's
     * `padding-left: 60px` on .drawer-subitem does.
     */
    property real drawerRowHeight: Units.gu(5)
    property real drawerCallRowHeight: Units.gu(3.6)
    property real drawerIndent: Units.gu(6)

    /// A list row carrying a photo and two lines of text.
    property real listRowHeight: Units.gu(7.4)
    property real callLogRowHeight: Units.gu(7.9)

    /**
     * Preferences
     *
     * The preference scenes are light where the rest of the app is dark, as
     * they are in webOS -- they belong to the settings world rather than to
     * the call. Groups are drawn with the framework's own nine-slices, whose
     * caption band is black at a quarter opacity: over this background that
     * resolves to exactly the grey the device shows.
     */
    property color prefsBackgroundColor: '#d8d8d8'
    property color prefsHeaderColor: '#e0e0e0'
    property color prefsFooterColor: '#b1b1b1'
    property color prefsTextColor: '#2a2a2a'
    property color prefsSecondaryTextColor: '#5a5a5a'
    property color prefsGroupLabelColor: '#ffffff'
    property color prefsRowDividerColor: '#00000040'
    /// The button that closes a preference scene.
    property color prefsDoneColor: '#62b246'

    /**
     * The SIM PIN card.
     *
     * The two looks disagree about this one more than about anything else:
     * one fills the screen, the other floats a panel in the middle of it. The
     * card reads these rather than hard-coding either.
     */
    /// True when the card is a panel centred on the screen rather than the
    /// whole of it.
    property bool pinCardIsPanel: false
    property real pinCardPanelWidth: Units.gu(40)
    property real pinCardPanelHeight: Units.gu(50)
    /// The run of dots standing in for the entered code.
    property color pinCardEntryColor: '#ffffff'
    property real pinCardEntrySize: Units.gu(3.2)
    property bool pinCardEntryBold: true
    property real pinCardTitleSize: Units.gu(2.6)
    property real pinCardSubTextSize: Units.gu(1.7)
    property real pinCardButtonHeight: Units.gu(6)
    /// True when the accepting button is the green affirmative one rather
    /// than the second of two matching pills.
    property bool pinCardAffirmativeDone: false

    /**
     * Gradients
     **/

    property Gradient mainGradient: Gradient {
        GradientStop { position: 0.0; color: '#2f3032' }
        GradientStop { position: 1.0; color: '#252628' }
    }

    /// The call card: charcoal at the top fading into black behind the avatar.
    property Gradient panelGradient: Gradient {
        GradientStop { position: 0.0; color: '#333233' }
        GradientStop { position: 0.55; color: '#151515' }
        GradientStop { position: 1.0; color: '#030303' }
    }

    property Gradient selectedGradient: Gradient {
        GradientStop { position: 0.0; color: '#2a2a2a' }
        GradientStop { position: 1.0; color: '#1b1b1b' }
    }
    property Gradient unSelectedGradient: Gradient {
        GradientStop { position: 0.0; color: '#3a3c3e' }
        GradientStop { position: 1.0; color: '#2b2d2f' }
    }

    /**
     * Retained for compatibility with the existing views.
     **/

    property color headerColor: '#4a4a4a'
    property color headerTitle: '#ffffff'
    property color headerTip: '#000000'
    property color subForegroundColor: '#8d8d8d'
    property color selectedTabColor: '#222324'
    property color selectedTabForground: '#ffffff'
    property color unselectedTabColor: '#333537'
    property color unselectedTabForground: '#9a9a9a'
    property color callActionBtnFgColor: '#2c2c2c'
    property color callActionBtnFgColorActive: '#3871a1'
}
