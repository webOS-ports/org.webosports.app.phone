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

import LunaNext.Common 0.1

/**
 * The handset look.
 *
 * Sampled from the phone app as it ships on the Pre3 -- webOS 2.2.4,
 * `nova-cust-image-mantaray`. The two looks agree on the chrome: #25394a,
 * #132232 and #071116 are the same in both stylesheets, which is why they sit
 * in UiTheme. Where the handset differs is in how it greys a list, how it
 * fills an opened drawer, and -- most visibly -- in the artwork, which it
 * draws from the 1.5x set the Pre3 ships rather than the tablet's 1x.
 *
 * Values not set here are ones no difference has been found for. That is a
 * statement about the evidence, not a guarantee they are identical: the
 * sampling covered base.css, dialer.css, activecall.css, dialpad.css and the
 * phoneApp and phoneprefs stylesheets, not every rule in the app.
 */
UiTheme {
    imageDir: Qt.resolvedUrl("images/phone/")

    /// The handset's dial and disconnect buttons are drawn 480 wide, the
    /// width of the Pre3 screen, where the tablet draws them 612.
    footerButtonImageSize: Qt.size(480, 297)

    /// The handset draws the 1.5x pill, 76 wide, so its caps are 37 and not
    /// the 25 the stylesheet names for the 1x one.
    pinMenuButtonCapWidth: 37

    /**
     * The page behind everything.
     *
     * The handset is blue where the tablet is grey. shared/base.css gives
     * .phone-background as `#25394a url(backdrop-phone.png) left top repeat-x`
     * -- a flat blue with a vertical gradient laid over it -- and the stops
     * below are read off that backdrop at 1.5x, which is the artwork the Pre3
     * draws. It matters more than it sounds: the dialpad is a translucent
     * black scrim over translucent keys, so what shows through the pad is this
     * and nothing else.
     */
    backgroundColor: '#25394a'

    mainGradient: Gradient {
        GradientStop { position: 0.00; color: '#4e7495' }
        GradientStop { position: 0.15; color: '#466885' }
        GradientStop { position: 0.50; color: '#38546b' }
        GradientStop { position: 0.75; color: '#2f465a' }
        GradientStop { position: 1.00; color: '#233443' }
    }

    /**
     * Lists
     *
     * One grey does for every secondary line here, where the tablet gives
     * each list its own: .call-history-subitem is #AAAAAA on the Pre3 against
     * the TouchPad's #6f7070, and neither the favourites nor the call log
     * label overrides it.
     */
    /**
     * Lists are not filled on the handset.
     *
     * .call-log and .enyo-item carry no background rule at all in 2.2.4, so
     * the blue page shows through them the way it shows through the dialpad;
     * the TouchPad fills both (#323232), which is where the greys in UiTheme
     * come from. Leaving those greys in place put opaque slabs over the blue.
     */
    listBackgroundColor: 'transparent'
    listAlternateColor: 'transparent'

    serviceTextColor: '#aaaaaa'
    /*
     * #aaaaaa is .call-history-subitem, which is the service line and only
     * that. The call log's own second line, .call-log .clv-drawerItem-displayLbl,
     * sets no colour on the handset and inherits .enyo-item's #ccc -- it was
     * given the subitem grey here by mistake.
     */
    callLogDetailColor: '#cccccc'
    favoritesDetailColor: '#cccccc'
    drawerNumberColor: '#cccccc'
    /// .enyo-divider-caption keeps the framework's own #ccc.
    listSectionTextColor: '#cccccc'

    /**
     * An opened drawer is blue on the handset. .drawer-subitem fills with
     * #25394a -- the same blue the rest of webOS uses behind a selection --
     * where the TouchPad had gone flat grey.
     */
    listSectionColor: '#25394a'

    /*
     * listSelectedColor is deliberately not overridden.
     *
     * It was, to 'transparent', on the strength of the Pre3's
     * `.contact-list .enyo-addressing-item-selected { background: none }`.
     * That reading was wrong twice over: the same rule carries a
     * focus-gradient border-image, so the row is still marked, just with
     * artwork rather than a fill; and the unscoped framework rule is
     * `background: lightblue` in both eras, so this was never a difference
     * between them. Meanwhile the QML uses this for press feedback on every
     * list, so blanking it left a tap showing nothing at all.
     */

    /**
     * The SIM PIN card.
     *
     * Fills the card, sky backdrop and all, with the entry drawn large and
     * white and a pair of matching pills along the foot. Kept from PinCode as
     * it runs on the Pre3, whose stylesheet gives the heading twenty-six
     * pixels, the step line seventeen, the dots thirty-two and bold, and the
     * buttons sixty.
     */
    pinCardIsPanel: false
    pinCardEntryColor: '#ffffff'
    pinCardEntrySize: Units.gu(3.2)
    pinCardEntryBold: true
    pinCardTitleSize: Units.gu(2.6)
    pinCardSubTextSize: Units.gu(1.7)
    pinCardButtonHeight: Units.gu(6)
    pinCardAffirmativeDone: false
}
