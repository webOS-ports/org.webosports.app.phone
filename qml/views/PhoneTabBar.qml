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
 * The phone app's tab bar.
 *
 * Matches the webOS 3.x one on the TouchPad: it sits at the top of the app,
 * spans the full width, and each tab is an icon above a small uppercase label.
 * The selected tab is darker than the bar rather than lighter, with a vertical
 * hairline between tabs.
 *
 * The QML app previously used a bottom bar of bare icons, which is why it never
 * looked like the rest of the platform.
 */
Item {
    id: phoneTabBar

    property PhoneUiTheme appTheme: PhoneUiTheme {}

    /// [{ icon: url, label: string }]
    property var tabs: []
    property int currentIndex: 0

    signal tabSelected(int index);

    height: Units.gu(6)

    Rectangle {
        anchors.fill: parent
        color: appTheme.tabBarColor
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: phoneTabBar.tabs

            delegate: Item {
                required property var modelData
                required property int index

                width: phoneTabBar.width / Math.max(1, phoneTabBar.tabs.length)
                height: phoneTabBar.height

                readonly property bool selected: index === phoneTabBar.currentIndex

                Rectangle {
                    anchors.fill: parent
                    color: parent.selected ? appTheme.tabBarSelectedColor
                                           : (tabArea.pressed ? appTheme.tabBarSelectedColor
                                                              : 'transparent')
                }

                // Divider on the trailing edge, skipped after the last tab.
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: appTheme.tabBarBorderColor
                    visible: index < phoneTabBar.tabs.length - 1
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Units.gu(0.3)

                    SpriteIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Units.gu(2.6)
                        height: Units.gu(2.6)
                        source: modelData.icon
                        opacity: parent.parent.selected ? 1.0 : 0.65
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: parent.parent.selected ? appTheme.primaryTextColor
                                                      : appTheme.secondaryTextColor
                        font.pixelSize: FontUtils.sizeToPixels("x-small")
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                        text: modelData.label
                    }
                }

                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    onClicked: phoneTabBar.tabSelected(index)
                }
            }
        }
    }

    // Bottom edge, so the bar reads as chrome sitting above the content.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: appTheme.tabBarBorderColor
    }
}
