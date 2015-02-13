import QtQuick 2.0
import QtQuick.Window 2.0
import "."

Window {
    property int type
    property bool loadingAnimationDisabled: false
    property bool keepAlive: false
    property int windowId: 0
    property int parentWindowId: 0
}
