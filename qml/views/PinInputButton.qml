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

        /*
         * A word, not a digit.
         *
         * These sit in the cells the PIN keypad leaves free, alongside digits
         * drawn at the key's own scale -- which lands within a pixel of
         * x-large, so a label set that way filled its cell: "Cancel" measured
         * 129 of the 146 pixels a key is wide, and "Emergency" 220 in a button
         * only 160 wide, so it ran out past both ends of it. This is the
         * largest step every label still fits inside, and it leaves the words
         * reading as the actions they are rather than as outsized keys.
         */
        font.pixelSize: FontUtils.sizeToPixels("large")
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
