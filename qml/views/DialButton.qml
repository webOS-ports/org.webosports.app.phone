/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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
import QtQuick.Controls 2.0

import LuneOS.Components 1.0

Button {
    id: dialButtonRoot

    property UiTheme appTheme

    /// The sprite is the three states of the button stacked, so one state is
    /// a third of the artwork's height. How tall the button comes out for a
    /// given width follows from that, and only this file knows how the sprite
    /// is cut -- a page that has to fit the button into the height it has left
    /// asks here rather than repeating the division.
    readonly property int patchRows: 3
    readonly property real heightPerWidth:
        appTheme ? (appTheme.footerButtonImageSize.height / patchRows) /
                   appTheme.footerButtonImageSize.width
                 : 0

    /**
     * Sizing.
     *
     * Left entirely alone unless a caller sets both of these: the button is
     * anchored across its parent in most places, and declaring a width here
     * unconditionally would take that away from them.
     *
     * Where they are set, preferredWidth is the width to draw at and
     * maximumHeight the most height there is to give it. The proportions are
     * the artwork's and are not negotiable -- a button drawn wider than its
     * height allows would stretch the handset glyph -- so exceeding the cap
     * narrows the button instead.
     */
    property real preferredWidth: 0
    property real maximumHeight: 0

    // Through a Binding rather than a `width:` of its own, so that a caller
    // who sets neither keeps whatever its anchors were giving it.
    Binding {
        target: dialButtonRoot
        property: "width"
        value: Math.min(dialButtonRoot.preferredWidth,
                        dialButtonRoot.maximumHeight / dialButtonRoot.heightPerWidth)
        when: dialButtonRoot.preferredWidth > 0 && dialButtonRoot.maximumHeight > 0
              && dialButtonRoot.heightPerWidth > 0
        restoreMode: Binding.RestoreBindingOrValue
    }

    background: ClippedImage {
        id: bgClippedImage

        source: appTheme.image("dial-button.png")

        wantedWidth: dialButtonRoot.width
        // Only a width is given, so ClippedImage works the height out from the
        // artwork's own proportions -- and it cannot read those off the image,
        // so the theme names them. Left unset they default to -1x-1, which
        // reads as square and stretched the handset upright.
        imageSize: appTheme.footerButtonImageSize
        patchGridSize: Qt.size(1, dialButtonRoot.patchRows)
        patch: dialButtonRoot.pressed ? Qt.point(0,2): Qt.point(0,0)

        onHeightChanged: dialButtonRoot.height = bgClippedImage.height
    }
}
