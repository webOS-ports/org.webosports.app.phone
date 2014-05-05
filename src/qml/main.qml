import QtQuick 2.0
import "views"
import "services"
import "model"
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
//import QtQuick.Particles 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.1


Window {
    id: main
    width: appTheme.appWidth
    height: appTheme.appHeight
    color: appTheme.backgroundColor

    property alias __window: main

    property PhoneUiTheme appTheme: PhoneUiTheme {}

    property string activationReason: 'invoked'
    property Contact activeVoiceCallPerson

    property string providerId: "sim1"
    property string providerType: "GSM"
    property string providerLabel: "Vodaphone"

    Component.onCompleted: {
        var params = JSON.parse(application.launchParameters);
        if (!params.launchedAtBoot) {
            __window.show();
        }
    }


    Connections {
        target: application
        onRelaunched: {
            console.log("DEBUG: Relaunched with parameters: " + parameters);
            // If we're launched at boot time we're not yet visible so bring our window
            // to the foreground
            if (!__window.visible)
                __window.show();
        }
    }

    property VoiceCallManager manager: VoiceCallManager{
        id: manager

        onActiveVoiceCallChanged: {
            if(activeVoiceCall) {
                main.activeVoiceCallPerson = people.personByPhoneNumber(activeVoiceCall.lineId);
                manager.activeVoiceCall.statusText = "active"

                dActiveCall.open();

                if(!__window.visible)
                {
                    main.activationReason = 'activeVoiceCallChanged';
                    __window.show();
                }
            }
            else
            {
                //tabView.pDialPage.numberEntryText = '';

                dActiveCall.close();

                main.activeVoiceCallPerson = null;

                if(main.activationReason != "invoked")
                {
                    main.activationReason = 'invoked'; // reset for next time
                    __window.close();
                }
            }
        }
    }



    function dial(msisdn) {
        if(msisdn === "999") {
         simPin.visible = true
        } else {
         manager.dial(providerId, msisdn);
        }



    }

    function secondsToTimeString(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds - (h * 3600)) / 60);
        var s = seconds - h * 3600 - m * 60;
        if(h < 10) h = '0' + h;
        if(m < 10) m = '0' + m;
        if(s < 10) s = '0' + s;
        return '' + h + ':' + m + ':' + s;
    }

    ActiveCallDialog {id:dActiveCall}

    PhoneTabView {id: tabView}

    ContactManager {id:people}

    OfonoManager {id: ofono}

    SIMPin {id: simPin}
}
