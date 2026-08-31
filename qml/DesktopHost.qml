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

import LunaNext.Common 0.1

/**
 * Desktop host.
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
 *
 * The entry points beside this one are what Qt Creator runs -- one per shape
 * of device, since its QML run configuration has nowhere to pass an argument.
 */
Window {
    id: desktopHost

    /**
     * The device to pretend to be, named as in the mock's own table:
     * "desktop", "tp", "n5", "n7", "a500", "gnex", "n4". Empty leaves whatever
     * the command line asked for, or the mock's default.
     *
     * It has to be applied before main.qml exists: the app reads
     * Settings.tabletUi to choose its look, and the mock's values are plain
     * variables, so a binding made beforehand would keep the old one.
     */
    property string profile: ""

    /**
     * Reads the profile from `.desktop-profile` at the top of the checkout --
     * a single word such as `tp`. Returns "" when there is no such file.
     *
     * This exists because Qt Creator greys out its Main QML file setting when
     * a .qmlproject names a `mainFile`: it always runs the same entry point,
     * and its QML run configuration has nowhere to pass an argument either.
     * Rather than have anyone edit a tracked file to see the other look, the
     * choice lives in an ignored file beside the project.
     *
     * Read synchronously: the answer is needed before main.qml is built.
     */
    function profileFromFile() {
        try {
            var req = new XMLHttpRequest();
            req.open("GET", Qt.resolvedUrl("../.desktop-profile"), false);
            req.send();
            if (req.status === 200 || req.status === 0)
                return String(req.responseText).trim();
        } catch (e) {
            // No such file, or reading it is not allowed. Either way there is
            // nothing to honour and the caller's own choice stands.
        }
        return "";
    }

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
        /*
         * Only the mock offers these; the real Settings has no such functions,
         * and this host never runs on a device anyway.
         *
         * An explicit --profile wins over the entry point's own choice: it is
         * the more specific ask, and silently ignoring a flag someone typed
         * is worse than either answer.
         */
        if (typeof Settings.setProfile === "function" && !Settings.commandLineProfile()) {
            // The ignored file outranks the entry point, being the more
            // deliberate ask; the command line outranks both, and the mock has
            // already applied that itself.
            var wanted = desktopHost.profileFromFile() || desktopHost.profile;
            if (wanted.length > 0 && !Settings.setProfile(wanted))
                console.warn("No such device profile: " + wanted);
        }
        /*
         * Said out loud on every run: which look is in force is otherwise
         * invisible until something looks wrong, and Qt Creator runs whatever
         * its Main QML file points at -- which is easy to have pointing
         * somewhere other than you think.
         */
        console.log("Running as " + (Settings.tabletUi ? "a tablet" : "a handset")
                    + ", " + Settings.displayWidth + "x" + Settings.displayHeight);
        if (!Settings.tabletUi)
            console.log("For the tablet look: echo tp > .desktop-profile"
                        + " at the top of the checkout, then run again.");

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
            // On a device the system draws the app menu; here nothing does,
            // so the app has to put one up itself.
            main.createObject(desktopHost, { runningOnDesktop: true });
        }

        relaunchMainAppTimer.start();
    }
}
