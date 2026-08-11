/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

import QtQuick 2.6

import LunaNext.Common 0.1

/**
 * Desktop entry point.
 *
 * On a device the phone app has no window of its own until something asks for
 * one -- the launcher, an incoming call, a dial request. On the desktop there
 * is nothing to ask, so this stands in for the system manager: it loads
 * main.qml, then sends the relaunch that brings the phone window up.
 *
 * Everything underneath runs against the mocks in
 * luneos-components/test/imports, so there is a modem, a set of Synergy
 * accounts and a contact list without a device attached.
 */
Item {
    id: mainDesktop

    width: Settings.displayWidth
    height: Settings.displayHeight

    Rectangle {
        anchors.fill: parent
        color: "black"

        Column {
            anchors.centerIn: parent
            spacing: Units.gu(1)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#666666"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: qsTr("Phone app running against mock services")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#444444"
                font.pixelSize: FontUtils.sizeToPixels("small")
                text: qsTr("Close the phone window to get back here")
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                margins: Units.gu(2)
            }
            color: "#aa3333"
            font.pixelSize: FontUtils.sizeToPixels("large")
            text: qsTr("Quit")

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Units.gu(2)
                onClicked: Qt.quit();
            }
        }
    }

    /**
     * Stands in for the host application object the device provides.
     *
     * `launchParameters` is what the app reads on startup, so this is where to
     * put a launch action to test one -- for example
     * '{"action":"dial","address":"+31612345678"}' to come up dialling, or
     * '{"action":"calllog"}' to open on the call log.
     */
    property QtObject application: QtObject {
        property string launchParameters: "{}"
        property bool launchedAtBoot: false

        signal relaunched(string parameters);
    }

    Timer {
        id: relaunchMainAppTimer
        interval: 500
        running: false
        repeat: false
        // An empty relaunch is how the app is told to show its window, which is
        // what tapping the launcher icon does on a device.
        onTriggered: application.relaunched("{}");
    }

    Component.onCompleted: {
        var main = Qt.createComponent(Qt.resolvedUrl("main.qml"));

        if (main.status === Component.Error) {
            // Error Handling
            console.error("Error loading main.qml: ", main.errorString());
        }
        else {
            main.createObject(mainDesktop);
        }

        relaunchMainAppTimer.start();
    }
}
