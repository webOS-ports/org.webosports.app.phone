import QtQuick 2.0
import QtQuick.Window 2.0
import "content"
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
//import QtQuick.Particles 2.0
import QtQuick.Layouts 1.0


Window {
    id: main
    //width: Screen.width
    //height: Screen.height
    width: 500
    height: 800
    color: appTheme.backgroundColor

    property alias __window: main

    property PhoneUiTheme appTheme: PhoneUiTheme {}

    property string activationReason: 'invoked'

    property string providerId: "sim1"
    property string providerType: "GSM"
    property string providerLabel: "Vodaphone"


    //function operatorPressed(operator) { CalcEngine.operatorPressed(operator) }

    //function keyPressed(digit) { console.log(digit) }

    Component.onCompleted: {
        __window.show();
    }

    property VoiceCallManager manager: VoiceCallManager{
        id: manager

        onActiveVoiceCallChanged: {
            if(activeVoiceCall) {
                //main.activeVoiceCallPerson = people.personByPhoneNumber(activeVoiceCall.lineId);
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

                //main.activeVoiceCallPerson = null;

                if(main.activationReason != "invoked")
                {
                    main.activationReason = 'invoked'; // reset for next time
                    __window.close();
                }
            }
        }
    }



    function dial(msisdn) {
        manager.dial(providerId, msisdn);
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

    PeopleModel {id:people}
}
