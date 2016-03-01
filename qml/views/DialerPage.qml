/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Window 2.1
import LuneOS.Service 1.0
import LuneOS.Components 1.0
import LunaNext.Common 0.1

import "../AppTweaks"

BasePage {
    id: pDialPage

    pageName: "Dialer"
    property alias number: numEntry.text

    function reset() {
        numEntry.text = "";
    }

    LunaService {
        id: service
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }

    NumberEntry {
        id: numEntry

        anchors {
            top: pDialPage.top
            left:dialButton.left
            right:dialButton.right
        }

        textColor: '#ffffff'
    }

    NumPad {
        id: numPad
        anchors {
            top: numEntry.bottom
            bottom: dialButton.top
            left:dialButton.left
            right:dialButton.right
        }

        onSendKey: {
            if(AppTweaks.dialpadFeedbackTweakValue === "vibrateSound" || AppTweaks.dialpadFeedbackTweakValue === "vibrateOnly") {
                service.call("luna://com.palm.vibrate/vibrate", JSON.stringify({
                                                              period: 100, duration: 10
                                                          }), undefined,
                                           vibrateFailure)
            }
            function vibrateFailure(message) {
                console.log("Unable to vibrate");
            }

            numEntry.insert(String.fromCharCode(keycode));
        }
    }

    DialButton {
        id: dialButton

        anchors {
            bottom: parent.bottom
            bottomMargin: Units.gu(2)
            left: parent.left
            right: parent.right
        }

        onClicked: {
            if(numEntry.text.length > 0) {
                if(numEntry.text[0] === "*") {
                    telephonyManager.initiateUssd(number);
                }
                else {
                    voiceCallMgrWrapper.dial(numEntry.getPhoneNumber());
                }
            } else {
                console.log('Number entry is blank.');
            }
        }
    }
}
