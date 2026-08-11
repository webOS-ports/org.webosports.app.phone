/*
 * Copyright (C) 2026 WebOS Ports
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

import LuneOS.Service 1.0

import "IncomingCallsService.js" as IncomingCallsService
import "CallMessages.js" as CallMessages

/**
 * Missed-call and voicemail notifications.
 *
 * The legacy app posted these onto the webOS dashboard from
 * phonePopups/sources/MissedCall.js; on LuneOS the equivalent is a toast from
 * com.webos.notification. Tapping the toast relaunches the phone app on the
 * call log.
 */
Item {
    id: notificationManager

    property var voiceCallManager
    property var telephonyManager
    property var contacts

    readonly property string appId: "org.webosports.app.phone"

    /// Emitted alongside the toast so the app can also raise its own alert
    /// window while the screen is off.
    signal missedCall(string lineId, string displayName);

    function notifyMissedCall(lineId, displayName) {
        var name = (displayName && displayName.length > 0) ? displayName : lineId;

        _createToast(CallMessages.missedCallTitle + ": " + name,
                     { id: appId, params: { action: "calllog" } });

        missedCall(lineId, name);
    }

    function notifyVoicemail(count) {
        if (count <= 0)
            return;

        _createToast(count === 1 ? qsTr("1 new voicemail message")
                                 : qsTr("%1 new voicemail messages").arg(count),
                     { id: appId, params: { action: "voicemail" } });
    }

    function _createToast(message, launchParams) {
        var payload = {
            sourceId: appId,
            message: message,
            iconUrl: "/usr/palm/applications/" + appId + "/icon.png",
            onclick: { appId: launchParams.id, params: launchParams.params }
        };

        lunaService.call("luna://com.webos.notification/createToast", JSON.stringify(payload),
                         undefined,
                         function(error) { console.log("Could not post notification: " + error); });
    }

    function _displayNameFor(lineId) {
        if (!contacts) return "";

        var match = contacts.personByPhoneNumber(lineId);
        if (!match || !match.foundPerson) return "";

        var person = match.foundPerson;
        return (person.nickname && person.nickname.length > 0)
                    ? person.nickname
                    : (person.name.givenName + " " + person.name.familyName).trim();
    }

    Connections {
        target: notificationManager.voiceCallManager

        function onEndingCall(voiceCall) {
            // Only calls that rang out unanswered count as missed; the user
            // rejecting a call is "ignored" and is not worth a notification.
            if (!voiceCall.isIncoming)
                return;
            if (IncomingCallsService.getActionForCall(voiceCall.handlerId) !== IncomingCallsService.Missed)
                return;

            notifyMissedCall(voiceCall.lineId, _displayNameFor(voiceCall.lineId));
        }
    }

    Connections {
        target: notificationManager.telephonyManager

        function onVoicemailMessageCountChanged() {
            notifyVoicemail(telephonyManager.voicemailMessageCount);
        }
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
}
