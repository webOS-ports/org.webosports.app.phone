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

/**
 * Shows one frame of a vertical sprite strip.
 *
 * Every icon inherited from the webOS phone app is a strip of states stacked
 * top to bottom -- normal, pressed, and sometimes disabled. Drawing the file
 * directly renders the whole strip squashed into the icon's box, which is what
 * the tab bar and the call buttons were doing.
 *
 * Frames are assumed square unless `frameCount` says otherwise, which covers
 * every icon in this app: the 32x64 and 48x96 icons are two square states, and
 * the wide 160x192 call buttons declare their three explicitly.
 */
Item {
    id: spriteIcon

    property url source
    /// 0 for the normal state, 1 for pressed, 2 for disabled where present.
    property int frame: 0
    /// Frames in the strip. Left at 0, it is derived from the image's aspect.
    property int frameCount: 0

    readonly property int _frames: {
        if (frameCount > 0)
            return frameCount;

        if (image.sourceSize.width <= 0 || image.sourceSize.height <= 0)
            return 1;

        return Math.max(1, Math.round(image.sourceSize.height / image.sourceSize.width));
    }

    readonly property int _frame: Math.max(0, Math.min(frame, _frames - 1))

    clip: true

    Image {
        id: image

        source: spriteIcon.source
        // Scale the whole strip so that exactly one frame fills this item, then
        // slide it up to the frame we want.
        width: spriteIcon.width
        height: spriteIcon.height * spriteIcon._frames
        y: -spriteIcon.height * spriteIcon._frame

        fillMode: Image.Stretch
        smooth: true
        asynchronous: true
    }
}
