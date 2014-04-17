import QtQuick 2.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0

TabViewStyle {
    frameOverlap: 1
    tab: Rectangle {
        color: styleData.selected ? main.appTheme.backgroundColor : main.appTheme.unselectedTabColor
        border.color:  main.appTheme.backgroundColor
        implicitWidth: tabView.width/5
        implicitHeight: 50
        radius: 2
        ColumnLayout{
            anchors.fill: parent

            Image{
                id: icon
                width: 32
                height: 32
                source: tabView.getIcon(styleData.title)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                  id: text
                  anchors.top: icon.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: styleData.title
                  color: styleData.selected ? main.appTheme.foregroundColor : main.appTheme.foregroundColor
                 }
        }


    }
    frame: Rectangle { color: main.appTheme.backgroundColor }}
