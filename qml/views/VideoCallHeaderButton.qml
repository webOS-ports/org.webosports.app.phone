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
    /// shows as its last frame.
    property bool on: false

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

    SpriteIcon {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Units.gu(1.2)
        }
        width: Units.gu(3.6)
        height: Units.gu(3.6)

        source: headerButton.iconSource
        frameCount: 4
        frame: headerButton.on ? 3 : 0
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
