/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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

import Eos.Window 0.1
import LunaNext.Common 0.1
import org.nemomobile.voicecall 1.0
import LuneOS.Telephony 1.0

import "../services"
import "../model"
import "../services/IncomingCallsService.js" as IncomingCallsService

/**
 * The incoming call while the phone app is not in front: a system alert
 * window, so it can come up over whatever is on screen, and over the lock
 * screen too. It is the legacy popup strip (IncomingCallStrip), not the
 * in-app page: 2.2.4's on a handset, 3.0.5's on a tablet, at the height
 * those opened it - more with a photo than without.
 *
 * LuneOS_overLockScreen tells the shell this alert belongs above the lock
 * screen and is not dismissed by a tap outside it: a call is answered or
 * declined, not swiped away.
 */
WebOSWindow {
    id: incomingCallAlert

    property ContactsModel contacts;
    property VoiceCallMgrWrapper voiceCallManager
    property QtObject voiceCall;
    property UiTheme appTheme;

    property Contact currentContact: Contact { contactsModel: contacts; lineId: voiceCall ? voiceCall.lineId : "" }

    width: Settings.displayWidth
    height: strip.implicitHeight
    // The tablet's strip has no fill of its own: the shell's panel shows
    // through it, as the system's alert frame did behind 3.0.5's popup.
    color: "transparent"

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"

    /// Takes the call away from the alert, answered, declined or ended.
    function dismiss() {
        incomingCallAlert.hide();
        voiceCall = null;
    }

    Component.onCompleted: {
        incomingCallAlert.setWindowProperty("LuneOS_window", "popupalert");
        incomingCallAlert.setWindowProperty("LuneOS_overLockScreen", "true");
    }

    IncomingCallStrip {
        id: strip
        anchors.fill: parent

        appTheme: incomingCallAlert.appTheme
        currentContact: incomingCallAlert.currentContact

        onAnswerClicked: {
            if (!voiceCall)
                return;
            IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Accepted);
            voiceCall.answer();
            incomingCallAlert.dismiss();
        }
        onRejectClicked: {
            if (!voiceCall)
                return;
            IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Ignored);
            voiceCall.hangup();
            incomingCallAlert.dismiss();
        }
    }
}
