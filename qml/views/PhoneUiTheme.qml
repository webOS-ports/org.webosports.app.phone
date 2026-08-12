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

/**
 * The phone app's palette, matched to the webOS 3.x phone app as it runs on the
 * TouchPad.
 *
 * The QML app had drifted to a blue gradient of its own; every value here was
 * instead sampled from the real thing, so the two look like the same
 * application. The charcoal chrome, the black call card, the blue active
 * button and the green/red call buttons are all measured, not guessed.
 */
QtObject {
    /**
     * Chrome
     **/

    /// The page behind everything.
    property color backgroundColor: '#2a2b2d'
    property color foregroundColor: '#ffffff'

    /// Panels that sit on the page: the call card, the dialpad, popups.
    property color panelColor: '#2d2c2c'
    /// The dark well inside a panel, behind an avatar or a call line.
    property color panelDarkColor: '#030303'
    /// The strip a panel's buttons sit on.
    property color panelFooterColor: '#242627'
    property color panelBorderColor: '#4a4a4a'

    /// Tab bar.
    property color tabBarColor: '#333537'
    property color tabBarSelectedColor: '#222324'
    property color tabBarBorderColor: '#1a1a1a'

    /**
     * Text
     **/

    property color primaryTextColor: '#ffffff'
    /// Secondary information: numbers under a name, timestamps, hints.
    property color secondaryTextColor: '#9a9a9a'
    /// The service a contact point or call belongs to, shown in caps.
    property color serviceTextColor: '#8d8d8d'
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
     **/

    /**
     * Lists sit in a bordered group box and are the same charcoal family as
     * the chrome, with light text -- an earlier reading of a screenshot taken
     * behind a dimming scrim made them look like a light-on-white list.
     */
    property color listBackgroundColor: '#3a3c3e'
    property color listAlternateColor: '#343638'
    property color listDividerColor: '#2a2c2e'
    property color listBorderColor: '#1e2021'
    property color listTextColor: '#ffffff'
    property color listSecondaryTextColor: '#c8c8c8'
    property color listSectionTextColor: '#ffffff'
    /// The band a contact's name sits on, above its rows.
    property color listSectionColor: '#1c1d1e'
    /// A row the user is acting on.
    property color listSelectedColor: '#4a7298'

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
