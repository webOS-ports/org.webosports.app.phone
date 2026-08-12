/*
 * Copyright (C) 2026 WebOS Ports
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import QtQuick 2.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0

/**
 * One of the two buttons at the ends of a video call's header: an icon over a
 * caption, a divider down one side, and a lit background while pressed. The
 * sizes are .muteButton's -- a hundred and fifty by eighty, caption at fifty.
 */
Item {
    id: headerButton

    property url iconSource
    property string label: ""
    property bool dividerOnLeft: false
    /// Whether what the button controls is currently on, which the artwork
    /// shows as its last state.
    property bool on: false

    /*
     * Where each state sits in the strip.
     *
     * mute_on_off and video_on_off hold three states apiece, but not on an
     * even pitch -- their artwork starts at one, seventy-one and a hundred
     * and thirty-seven. Dividing the file into equal frames, which is all a
     * sprite can do, lands between them: the icon comes out stretched and
     * shifts as the state changes. Taking the three rectangles out of the
     * source directly is exact.
     */
    readonly property var _stateTop: [1, 71, 137]
    /// Wider than either strip, so the clip takes the whole width of one.
    readonly property int _stateWidth: 64
    readonly property int _stateHeight: 44

    signal clicked();

    width: Units.gu(15)

    Image {
        anchors.fill: parent
        visible: buttonArea.pressed
        source: Qt.resolvedUrl("images/selected_button_bg.png")
        fillMode: Image.TileHorizontally
    }

    Image {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: headerButton.dividerOnLeft ? parent.left : undefined
            right: headerButton.dividerOnLeft ? undefined : parent.right
        }
        width: 2
        source: Qt.resolvedUrl("images/button_divider.png")
        fillMode: Image.TileVertically
    }

    Image {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Units.gu(0.8)
        }
        // Sized by the clip, and drawn at the size the artwork is -- which is
        // what the original does, offsetting the strip inside the button
        // rather than scaling it. Deriving the width from sourceSize instead
        // would leave the icon at nothing until the file had loaded.
        source: headerButton.iconSource
        sourceClipRect: Qt.rect(0, headerButton._stateTop[headerButton.on ? 2 : 0],
                                headerButton._stateWidth, headerButton._stateHeight)
        smooth: true
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Units.gu(5)
        }
        color: '#666666'
        font.pixelSize: Units.gu(1.8)
        text: headerButton.label
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        onClicked: headerButton.clicked()
    }
}
