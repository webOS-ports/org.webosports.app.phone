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
 * The tablet look.
 *
 * Sampled from the phone app as it ships on the TouchPad -- webOS 3.0.5,
 * `nova-cust-image-topaz`. This is the look the QML app has worn since it was
 * matched to the reference, so the values it shares with the handset are the
 * ones left in UiTheme; what is set here is what the TouchPad does that the
 * Pre3 does not.
 *
 * Its artwork is the 1x set, which is the density the tablet is drawn at.
 */
UiTheme {
    imageDir: Qt.resolvedUrl("images/tablet/")

    /**
     * Lists
     *
     * The tablet greys its secondary lines by role: the call log's is the
     * dimmest of them, the contact list sits between, and favourites is nearly
     * as bright as the name above it. The handset uses one grey for all three.
     */
    serviceTextColor: '#6f7070'
    callLogDetailColor: '#9d9e9f'
    favoritesDetailColor: '#c5c5c6'
    drawerNumberColor: '#cbcbcb'
    listSectionTextColor: '#8b8c8e'

    /// An opened drawer is grey here and blue on the handset:
    /// .drawer-subitem is #3B3D3F on the TouchPad.
    listSectionColor: '#3b3d3f'
    /// .enyo-addressing-item-selected fills with a blue wash.
    listSelectedColor: '#4a7298'

    /// .call-history-subitem sets its own height on the tablet.
    drawerCallRowHeight: Units.gu(3.6)

    /**
     * The SIM PIN card.
     *
     * A panel four hundred by five hundred, centred on the screen, rather
     * than the whole of it: PinCode wraps itself in .unlock-pin-screen at
     * exactly that size. The entry is small and grey instead of large and
     * white, and the accepting button is the green affirmative one, with a
     * dark button beside it -- not the pair of matching pills the handset
     * puts along the foot of the screen.
     */
    pinCardIsPanel: true
    pinCardPanelWidth: Units.gu(40)
    pinCardPanelHeight: Units.gu(50)
    pinCardEntryColor: '#969696'
    pinCardEntrySize: Units.gu(1.8)
    pinCardEntryBold: false
    pinCardTitleSize: Units.gu(2.6)
    pinCardSubTextSize: Units.gu(1.8)
    pinCardButtonHeight: Units.gu(5)
    pinCardAffirmativeDone: true
}
