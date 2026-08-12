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
import QtQuick.Window 2.3

/**
 * Desktop entry point.
 *
 * On a device the phone app has no window of its own until something asks for
 * one -- the launcher, an incoming call, a dial request. On the desktop there
 * is nothing to ask, so this stands in for the system manager: it loads
 * main.qml and sends the relaunch that brings the phone window up.
 *
 * This host is itself a window, but never a visible one. Showing it would put a
 * second, pointless window on screen next to the phone -- the app's own windows
 * are the only ones worth looking at.
 *
 * Everything underneath runs against the mocks in
 * luneos-components/test/imports, so there is a modem, a set of Synergy
 * accounts and a contact list without a device attached.
 */
Window {
    id: mainDesktop

    // Never shown: it exists only to own the app and drive the relaunch.
    visible: false
    width: 1
    height: 1
    title: "LuneOS phone app (mock host)"

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
        onTriggered: {
            // An empty relaunch is how the app is told to show its window,
            // which is what tapping the launcher icon does on a device.
            application.relaunched("{}");

            // Safe to restore now that the phone window is up: closing it ends
            // the session, the way closing the card does.
            Qt.application.quitOnLastWindowClosed = true;
        }
    }

    Component.onCompleted: {
        // Nothing is on screen until the relaunch above, and with this host
        // invisible that would otherwise count as "the last window closed" and
        // quit before the app ever appears.
        Qt.application.quitOnLastWindowClosed = false;

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
