#!/bin/sh
#
# Runs the QML test cases under tests/ against the mocks in luneos-components,
# then screens/tst_screens.qml once per device in PROFILES.
#
# The cases under tests/ that care about the shape of the device switch
# profile themselves through Settings.setProfile(), so one run covers both
# looks. The screens test cannot: Units and FontUtils read the grid unit once,
# as they load, and qmltestrunner takes no --profile. So each device runs
# against a copy of LunaNext.Common whose default profile is that device. Its
# pictures go to build/test-output/screens/<profile>-<screen>.png.
#
#     PROFILES="q25 radon" ./run-tests.sh      # the screens on two devices
#     PROFILES= ./run-tests.sh -functions      # only tests/
#
# To try the app itself as a particular device instead:
#
#     qml -I ../luneos-components/modules -I ../luneos-components/test/imports \
#         qml/main-desktop.qml -- --profile=tp
#
# Expects luneos-components checked out next to this repository, the same way
# phoneapp.qmlproject does. QMLTESTRUNNER may be set to pick a particular Qt's
# runner; COMPONENTS to point elsewhere for the mocks. Further arguments go to
# every qmltestrunner.

set -e

COMPONENTS=${COMPONENTS:-../luneos-components}
QMLTESTRUNNER=${QMLTESTRUNNER:-qmltestrunner}
PROFILES=${PROFILES-mindphone q25 tp radon}

if [ ! -d "$COMPONENTS/test/imports" ]; then
    echo "luneos-components not found at $COMPONENTS -- set COMPONENTS=<path>" >&2
    exit 1
fi
COMPONENTS=$(cd "$COMPONENTS" && pwd)

# The mock Db8Model reads its sample records with XMLHttpRequest, which Qt 6
# refuses for local files unless this is set.
QML_XHR_ALLOW_FILE_READ=1
export QML_XHR_ALLOW_FILE_READ
QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export QT_QPA_PLATFORM

status=0
"$QMLTESTRUNNER" -input tests \
    -import "$COMPONENTS/modules" \
    -import "$COMPONENTS/test/imports" \
    -import tests/imports \
    "$@" || status=1

[ -n "$PROFILES" ] || exit $status
# The screens are drawn through OpenGL, as on a device. Offscreen, Qt Quick
# otherwise falls back to its software renderer, which leaves out every
# shader effect - the rounded photos (CornerShader) among them - so the
# pictures showed empty frames the device never does. QT_QUICK_BACKEND=software
# puts the software renderer back where there is no OpenGL.
QT_QUICK_BACKEND=${QT_QUICK_BACKEND-rhi}
QSG_RHI_BACKEND=${QSG_RHI_BACKEND-opengl}
export QT_QUICK_BACKEND QSG_RHI_BACKEND
COMMON=$(mktemp -d)
trap 'rm -rf "$COMMON"' EXIT
mkdir -p build/test-output/screens
for profile in $PROFILES; do
    common=$COMMON/$profile/LunaNext/Common
    mkdir -p "$common"
    cp "$COMPONENTS"/test/imports/LunaNext/Common/* "$common/"
    sed -i "s/^var defaultProfile = .*/var defaultProfile = \"$profile\";/" "$common/SettingsStub.js"
    if ! grep -q "^var defaultProfile = \"$profile\";" "$common/SettingsStub.js"; then
        echo "could not select profile $profile in SettingsStub.js" >&2
        status=1
        continue
    fi
    echo "--- screens ($profile)"
    # The last -import is looked in first, so the copy goes after the rest.
    "$QMLTESTRUNNER" -input screens/tst_screens.qml \
        -import "$COMPONENTS/modules" \
        -import "$COMPONENTS/test/imports" \
        -import tests/imports \
        -import "$COMMON/$profile" \
        "$@" || status=1
done
exit $status
