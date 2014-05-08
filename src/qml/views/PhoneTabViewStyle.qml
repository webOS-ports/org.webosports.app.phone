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
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0

TabViewStyle {
    frameOverlap: 1
    tab: Rectangle {
        color: styleData.selected ? main.appTheme.backgroundColor : main.appTheme.unselectedTabColor
        border.color:  main.appTheme.backgroundColor
        implicitWidth: tabView.width/5
        implicitHeight: 50
        radius: 2
        ColumnLayout{
            anchors.fill: parent

            Image{
                id: icon
                width: 32
                height: 32
                source: tabView.getIcon(styleData.title)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                  id: text
                  anchors.top: icon.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: styleData.title
                  color: styleData.selected ? main.appTheme.foregroundColor : main.appTheme.foregroundColor
                 }
        }


    }
    frame: Rectangle { color: main.appTheme.backgroundColor }}
