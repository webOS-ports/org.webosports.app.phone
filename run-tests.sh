#!/bin/sh
#
# Runs the QML test cases under tests/ against the mocks in luneos-components.
#
# The cases that care about the shape of the device switch profile themselves
# through Settings.setProfile(), so one run covers both looks; there is nothing
# to pass in here. To try the app itself as a particular device instead:
#
#     qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
#         qml/main-desktop.qml -- --profile=tp
#
# Expects luneos-components checked out next to this repository, the same way
# phoneapp.qmlproject does. QMLTESTRUNNER may be set to pick a particular Qt's
# runner; COMPONENTS to point elsewhere for the mocks.

set -e

COMPONENTS=${COMPONENTS:-../luneos-components}
QMLTESTRUNNER=${QMLTESTRUNNER:-qmltestrunner}

if [ ! -d "$COMPONENTS/test/imports" ]; then
    echo "luneos-components not found at $COMPONENTS -- set COMPONENTS=<path>" >&2
    exit 1
fi

# The mock Db8Model reads its sample records with XMLHttpRequest, which Qt 6
# refuses for local files unless this is set.
QML_XHR_ALLOW_FILE_READ=1
export QML_XHR_ALLOW_FILE_READ
QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export QT_QPA_PLATFORM

exec "$QMLTESTRUNNER" -input tests \
    -import "$COMPONENTS/modules" \
    -import "$COMPONENTS/test/imports" \
    "$@"
