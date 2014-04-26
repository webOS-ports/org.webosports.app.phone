import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Button {
    width:parent.width; height:72

    style: ButtonStyle {
        background: BorderImage {
         source: control.pressed ? "images/meegotouch-button-positive-background.png" : "images/meegotouch-button-positive-background.png"
        }
    }
    iconSource:'images/icon-m-telephony-accept.svg'
}
