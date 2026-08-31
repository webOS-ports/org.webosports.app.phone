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

import QtQuick 2.6

/**
 * Desktop entry point -- the handset look.
 *
 * Open this file in Qt Creator and press Run. For the tablet look, run
 * main-desktop-tablet.qml beside it: Qt Creator's QML run configuration has
 * nowhere to pass an argument, so the shape of the device is chosen by which
 * file you run.
 *
 * Outside Qt Creator either look can come from one entry point instead:
 *
 *     qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
 *         qml/main-desktop.qml -- --profile=tp
 */
DesktopHost {
    // Left to the mock's default, which the command line can still override.
    profile: ""
}
