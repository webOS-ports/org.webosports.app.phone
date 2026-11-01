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

import "../services/IncomingCallsService.js" as IncomingCallsService

/// The incoming call while the phone app is in front; IncomingCallAlert shows
/// the same view when it is not.
BasePage {
    id: incommingCallDialog
    pageName: "IncomingCall"

    IncomingCallView {
        anchors.fill: parent

        appTheme: incommingCallDialog.appTheme
        currentContact: incommingCallDialog.currentContact

        onAnswerClicked: {
            IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Accepted);
            voiceCall.answer();
        }
        onRejectClicked: {
            IncomingCallsService.setActionForCall(voiceCall.handlerId, IncomingCallsService.Ignored);
            voiceCall.hangup();
        }
    }
}
