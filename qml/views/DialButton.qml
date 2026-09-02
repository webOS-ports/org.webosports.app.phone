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

    background: ClippedImage {
        id: bgClippedImage

        source: appTheme.image("dial-button.png")

        wantedWidth: dialButtonRoot.width
        // Only a width is given, so ClippedImage works the height out from the
        // artwork's own proportions -- and it cannot read those off the image,
        // so the theme names them. Left unset they default to -1x-1, which
        // reads as square and stretched the handset upright.
        imageSize: appTheme.footerButtonImageSize
        patchGridSize: Qt.size(1, 3)
        patch: dialButtonRoot.pressed ? Qt.point(0,2): Qt.point(0,0)

        onHeightChanged: dialButtonRoot.height = bgClippedImage.height
    }
}
