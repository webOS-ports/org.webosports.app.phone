import QtQuick 2.0
import LunaNext.Common 0.1

MouseArea {
    id: button

    property string text: ""
    property bool emergency: false

    property bool _highlighted: pressed && containsMouse

    visible: text != ""

    Text {
        anchors.centerIn: parent
        text: button.text
        font.pixelSize: FontUtils.sizeToPixels("x-large")
        font.bold: button.emergency
        color: {
            if (button.emergency)
                return button.highlighted ? "black" : "red";
            return button.highlighted ? "black" : "white";
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: _highlighted || pressTimer.running ? "white": "transparent"
    }

    onPressed: {
        pressTimer.start();
    }

    onCanceled: {
        pressTimer.stop();
    }

    Timer {
        id: pressTimer
        interval: 45
    }
}
