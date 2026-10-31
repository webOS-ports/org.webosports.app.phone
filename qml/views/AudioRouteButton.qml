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

import "../services"

/**
 * The audio route control under the active call card.
 *
 * Drawn the way webOS 2.x's ActiveCall drew it: the "Speaker" toggle with a
 * glyph for the route in use (audioRouteImages) while the handset and the
 * speaker are all there is, and "Audio" with the drop-down glyphs
 * (audioRouteImagesPopup) once a Bluetooth headset is connected. Tapping
 * steps to the next route; 2.x opened a menu of them instead.
 */
CallActionButton {
    id: audioRouteButton

    property AudioRouteManager audioRouteManager

    readonly property bool _menu: audioRouteManager ? audioRouteManager.buttonIsMenu : false
    readonly property string _route: audioRouteManager ? audioRouteManager.currentRoute : "earpiece"

    /// The glyph for the route in use, by file name.
    readonly property string iconName: {
        if (_menu) {
            switch (_route) {
            case "bt_sco":        return "menu-popup-bluetooth.png";
            case "ihf":           return "menu-popup-bluetooth-speaker.png";
            case "wired_headset": return "menu-popup-bluetooth-headset.png";
            default:              return "menu-popup-bluetooth-internal.png";
            }
        }
        switch (_route) {
        case "bt_sco":        return "menu-icon-speaker-bluetooth.png";
        case "ihf":           return "menu-icon-speaker-external.png";
        case "wired_headset": return "menu-icon-headset.png";
        default:              return "menu-icon-speaker-internal.png";
        }
    }

    iconSource: appTheme ? appTheme.image(iconName) : ""
    // The drop-down glyphs are two 3:2 frames, normal over pressed.
    iconAspect: _menu ? 1.5 : 1
    iconFrameCount: _menu ? 2 : 0
    label: audioRouteManager ? audioRouteManager.buttonLabel : ""
    active: audioRouteManager ? audioRouteManager.buttonActive : false

    onClicked: {
        if (audioRouteManager)
            audioRouteManager.nextRoute();
    }
}
