import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Button {
     width:72;height:72

    style: ButtonStyle {
        background: BorderImage {
         source: control.pressed ? "images/meegotouch-toolbar-button-background.png" : "images/meegotouch-toolbar-button-background.png"
        }
    }

}
