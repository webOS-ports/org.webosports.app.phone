import QtQuick 2.0
import QtQuick.Controls 1.1

TabView {
    id: tabView
    anchors.fill: parent
    Tab { title: "Dial" ;  Item {
       Dialer {id: pDialPage; anchors.horizontalCenter: parent.horizontalCenter }
        }}
    Tab { title: "Video" ; Item {

        }}
    Tab { title: "Favorites" ; Item {}}
    Tab { title: "Call Log" ; Item {
            HistoryPage{id: history}
        }}
    Tab { title: "Voicemail" ; Item {}}
    style: PhoneTabViewStyle{}
        function getIcon(title) {
            if(title === "Dial") {
               return "images/menu-icon-dial.png"
            }
            if(title === "Video") {
               return "images/menu-icon-video.png"
            }
            if(title === "Favorites") {
               return "images/menu-icon-favorites.png"
            }
            if(title === "Call Log") {
               return "images/menu-icon-call-log.png"
            }
            if(title === "Voicemail") {
               return "images/menu-icon-voicemail.png"
            }


        }
}
