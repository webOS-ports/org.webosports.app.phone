/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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
import QtSensors 5.11
import LuneOS.System 1.0

import "OrientationFilter.js" as OrientationFilter

/*
 * Which way the phone is held, for a video call that sends our camera.
 *
 * Loaded by VideoCallPage only while we send, so the accelerometer runs no
 * longer than that. It is its own file because QtSensors is not everywhere
 * the page is (the desktop test runner has none): there the Loader just
 * comes up empty and the page keeps the phone upright.
 *
 * Quarter turns in the shell's convention (OrientationHelper.qml): 0 top up,
 * 1 left edge up, 2 upside down, 3 right edge up.
 */
Item {
    id: tilt

    /// The phone, by the shell's rule (OrientationFilter.js), settled.
    property int deviceTurns: 0
    /// Our screen: the shell turns it with the phone unless rotation is
    /// locked, and then it stays at the locked angle.
    readonly property int screenTurns: lockAngle >= 0 && lockAngle < 360
                                       ? Math.round(lockAngle / 90) & 3 : deviceTurns

    // The shell's rotationLock preference: the locked angle in degrees, or
    // 400 when the screen turns freely (LunaSysAPI/Preferences.qml).
    property int lockAngle: 400

    SystemPreferences {
        clientName: "org.webosports.app.phone"
        keys: ["rotationLock"]
        onUpdated: (response) => {
            if (response.rotationLock !== undefined)
                tilt.lockAngle = Number(response.rotationLock);
        }
    }

    Accelerometer {
        id: sensor
        active: true
        property int pending: -1
        onReadingChanged: {
            var current = tilt.deviceTurns * 90;
            var proposed = OrientationFilter.orientationFor(reading.x, reading.y, reading.z, current);
            if (proposed === current) {
                pending = -1;
                settle.stop();
            } else if (proposed !== pending) {
                pending = proposed;
                settle.restart();
            }
        }
    }

    // As the shell: a new orientation has to hold this long, so swinging the
    // phone through one on the way to another does not turn the picture twice.
    Timer {
        id: settle
        interval: 200
        onTriggered: {
            if (sensor.pending >= 0)
                tilt.deviceTurns = (sensor.pending / 90) & 3;
            sensor.pending = -1;
        }
    }
}
