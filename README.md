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
