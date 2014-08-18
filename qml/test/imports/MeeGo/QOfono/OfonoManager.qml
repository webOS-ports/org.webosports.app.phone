import QtQuick 2.0

Item {
    id: ofonoManager

    property variant modems: [ "/dummy" ]

    property bool available

    signal modemAdded
    signal modemRemoved
}
