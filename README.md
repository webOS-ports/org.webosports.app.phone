org.webosports.app.phone
========================

Summary
-------
Phone application for the webOS ports project.

Description
-----------
The phone application is completely written in Qt/QML to give the best performance for the
user experience. Having a stable and fast phone application is crucial for the system as
this is one of the main usage aspects and needs to work reliable.

Running on the desktop
======================

The app can be run on a development machine, against mock services, without a
device. Open `phoneapp.qmlproject` in Qt Creator and press Run.

The app wears one of two looks depending on the shape of the device -- the
handset one or the tablet one -- and there is an entry point for each:

* `qml/main-desktop.qml`        the handset look
* `qml/main-desktop-tablet.qml` the tablet look

Qt Creator always runs the project's `mainFile`, and greys out **Projects >
Run > Main QML file** because the .qmlproject names one -- so neither picking
the entry point in the editor nor changing that setting will switch looks.
Its QML run configuration has nowhere to pass an argument either.

So put the profile in `.desktop-profile` at the top of the checkout instead,
and press Run as usual:

    echo tp > .desktop-profile     # the tablet look
    rm .desktop-profile            # back to the handset

The file is gitignored, holds one word, and is read before the app is built.
Anything unrecognised is reported and ignored. Running one of the entry points
directly still works too, as does `--profile=` on the command line, which
outranks the file:

    qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
        qml/main-desktop.qml -- --profile=tp

Every run says which look it came up in:

    qml: Running as a tablet, 1024x768

It expects `luneos-components` checked out next to this repository:

    <parent>/org.webosports.app.phone
    <parent>/luneos-components

The mocks live in `luneos-components/test/imports` and stand in for the modem
(QOfono), the calling backend (nemo voicecall), the luna bus and db8. The sample
records they serve are the JSON files in `qml/test`:

* `persons.json`          contacts, including the IM addresses Synergy calls over
* `phonecallgroup.json`   call log groups
* `phonecall.json`        the individual calls in those groups
* `accounts.json`         the calling accounts (cellular plus WhatsApp/Telegram/Signal)
* `callcapabilities.json` what each of those accounts reports at runtime
* `imbuddystatus.json`    buddy presence

Edit those to change what the app comes up with -- removing the entries in
`accounts.json`, for instance, leaves only cellular and makes the "which
service?" chooser go away.

The mock SIM starts unlocked. To exercise the PIN screens, set `pinRequired` in
`luneos-components/test/imports/QOfono/OfonoSimManager.qml` to `SimPin` (the
mock accepts `1234`) or `SimPuk` (`12345678`). Dialling `*100#` returns a
balance; any other USSD code opens an interactive menu.

To start the app on something other than the dialler, put a launch action in
`launchParameters` in `qml/main-desktop.qml`, e.g.
`{"action":"dial","address":"+31612345678"}`.

Requirements beyond Qt itself: the `Qt5Compat.GraphicalEffects` QML module
(Debian/Ubuntu: `qml6-module-qt5compat-graphicaleffects`), which the app uses
for the rounded avatars.

Note that `QML_XHR_ALLOW_FILE_READ=1` must be set for the mock data to load --
the qmlproject sets it, but if you run `qml` by hand you need it too:

    qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
        qml/main-desktop.qml

The app wears one of two looks depending on the shape of the device -- the
handset one or the tablet one -- and the mock can pretend to be either. Pass
`--profile` after a `--` to pick which; the names are the keys of `profiles` in
`luneos-components/test/imports/LunaNext/Common/SettingsStub.js` (`desktop`,
`tp`, `n5`, `n7`, `a500`, `gnex`, `n4`), and anything unrecognised falls back to
`desktop`:

    qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
        qml/main-desktop.qml -- --profile=tp


Tests
=====

The QML test cases live in `tests/` and run against the same mocks:

    ./run-tests.sh

`QMLTESTRUNNER` picks a particular Qt's runner and `COMPONENTS` points
elsewhere for the mocks; anything else on the command line is passed through to
qmltestrunner, so `./run-tests.sh -functions` lists what there is.

The cases that care about the shape of the device switch profile themselves
through `Settings.setProfile()`, so a single run covers both looks -- there is
no profile to pass in here.


How to Build on Linux
=====================

## Dependencies

Below are the tools and libraries (and their minimum version) required to build the app:

* cmake (version required by openwebos/cmake-modules-webos)
* gcc 4.6.3
* glib-2.0 2.32.1
* make (any version)
* pkg-config 0.26
* qtbase 5.2
* qtquick2 5.2
* libofono-qt

## Building

Once you have downloaded the source, enter the following to build it (after
changing into the directory under which it was downloaded):

    $ mkdir BUILD
    $ cd BUILD
    $ cmake ..
    $ make
    $ sudo make install

The directory under which the files are installed defaults to `/usr/local/webos`.
You can install them elsewhere by supplying a value for `WEBOS_INSTALL_ROOT`
when invoking `cmake`. For example:

    $ cmake -D WEBOS_INSTALL_ROOT:PATH=$HOME/projects/openwebos ..
    $ make
    $ make install

will install the files in subdirectories of `$HOME/projects/openwebos`.

Specifying `WEBOS_INSTALL_ROOT` also causes `pkg-config` to look in that tree
first before searching the standard locations. You can specify additional
directories to be searched prior to this one by setting the `PKG_CONFIG_PATH`
environment variable.

If not specified, `WEBOS_INSTALL_ROOT` defaults to `/usr/local/webos`.

To configure for a debug build, enter:

    $ cmake -D CMAKE_BUILD_TYPE:STRING=Debug ..

To see a list of the make targets that `cmake` has generated, enter:

    $ make help

## Uninstalling

From the directory where you originally ran `make install`, enter:

 $ [sudo] make uninstall

You will need to use `sudo` if you did not specify `WEBOS_INSTALL_ROOT`.

# Contributing

If you want to contribute you can just start with cloning the repository and make your
contributions. We're using a pull-request based development and utilizing github for the
management of those. All developers must provide their contributions as pull-request and
github and at least one of the core developers needs to approve the pull-request before it
can be merged.

Please refer to http://www.webos-ports.org/wiki/Communications for information about how to
contact the developers of this project.

# Copyright and License Information

Copyright (c) 2014 Roshan <roshan@mobileteck.com>
Copyright (c) 2014 Simon Busch <morphis@gravedo.de>

This library is free software; you can redistribute it and/or modify it under
the terms of version 3 of the GNU General Public License as published
by the Free Software Foundation.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

The files

data/icon.png (origin https://github.com/openwebos/image-assets)

are licensed under the the following terms:

Copyright (c) 2009-2014 LG Electronics, Inc.

Unless otherwise specified or set forth in the NOTICE file, all content,
including all source code files and documentation files in this repository are:
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this content except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
