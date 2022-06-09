import QtQuick 2.6

import LunaNext.Common 0.1

Item {
    id: mainDesktop

    /* Big Red Button */
    Rectangle {
        anchors.fill: parent
        color: "black"
        Text {
            anchors.fill: parent
            text: "Exit"
            color: "red"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment : Text.AlignVCenter
            font.pixelSize: height
            fontSizeMode: Text.Fit
        }
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit();
        }
    }

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
        onTriggered: application.relaunched("");
    }

    Component.onCompleted: {
        var main = Qt.createComponent(Qt.resolvedUrl("main.qml"));

        if (main.status === Component.Error) {
            // Error Handling
            console.error("Error loading main.qml: ", main.errorString());
        }
        else {
            main.createObject(mainDesktop);
        }

        relaunchMainAppTimer.start();
    }
}
