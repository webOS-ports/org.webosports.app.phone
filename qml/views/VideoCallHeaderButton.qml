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
 * sizes come from the theme: the tablet's .muteButton is a hundred and fifty
 * by eighty with the caption at fifty, the handset's a hundred by fifty-nine.
 */
Item {
    id: headerButton

    property UiTheme appTheme

    property url iconSource
    property string label: ""
    property bool dividerOnLeft: false
    /// Whether the button is lit: the artwork's last state, over the selected
    /// background (.videocall-button-on). Mute lights while the microphone is
    /// off, video while our camera is.
    property bool on: false
    /// Width of the strip's artwork: 36 for mute, 37 for video.
    property int stateWidth: 37

    /*
     * Where each state sits in the strip.
     *
     * mute_on_off and video_on_off hold three states apiece -- up, down and
     * lit -- but not on an even pitch: their artwork starts at one,
     * seventy-one and a hundred and thirty-seven. Dividing the file into
     * equal frames, which is all a sprite can do, lands between them: the
     * icon comes out stretched and shifts as the state changes. Taking the
     * three rectangles out of the source directly is exact. Both looks draw
     * strips laid out this way (the handset's are the Pre3's 1.5x ones from
     * shared/activecall/images).
     */
    readonly property var _stateTop: [1, 71, 137]
    readonly property int _stateHeight: 44
    readonly property int _state: buttonArea.pressed ? 1 : (on ? 2 : 0)

    signal clicked();

    width: appTheme ? appTheme.videoButtonWidth : Units.gu(15)
    readonly property real _artScale: appTheme ? appTheme.videoButtonArtScale : 1

    Image {
        anchors.fill: parent
        visible: buttonArea.pressed || headerButton.on
        source: appTheme.image("selected_button_bg.png")
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
        source: appTheme.image("button_divider.png")
        fillMode: Image.TileVertically
    }

    Image {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: headerButton.appTheme ? headerButton.appTheme.videoButtonIconTop : Units.gu(0.8)
        }
        // The clip, drawn at the size the stylesheet gives it: a pixel of
        // the artwork is a tenth of a grid unit in either look, as the rest
        // of the header is. Sizing from sourceSize instead would leave the
        // icon at nothing until the file had loaded.
        width: Units.gu(headerButton.stateWidth / 10 / headerButton._artScale)
        height: Units.gu(headerButton._stateHeight / 10 / headerButton._artScale)
        source: headerButton.iconSource
        sourceClipRect: Qt.rect(0, headerButton._stateTop[headerButton._state],
                                headerButton.stateWidth, headerButton._stateHeight)
        smooth: true
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: headerButton.appTheme ? headerButton.appTheme.videoButtonLabelTop : Units.gu(5)
        }
        color: '#666666'
        font.pixelSize: headerButton.appTheme ? headerButton.appTheme.videoButtonLabelSize : Units.gu(1.8)
        text: headerButton.label
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        onClicked: headerButton.clicked()
    }
}
