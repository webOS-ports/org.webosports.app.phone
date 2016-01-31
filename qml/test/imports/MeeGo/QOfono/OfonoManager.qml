import QtQuick 2.0

Item {
    id: ofonoManager

    property string defaultModem: "/dummy"
    property variant modems: [ "/dummy" ]

    property bool available

    signal modemAdded
    signal modemRemoved
}
