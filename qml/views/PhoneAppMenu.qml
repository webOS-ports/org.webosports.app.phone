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
import QtQuick.Controls 2.5

// The menus, switches and fields here are the platform's, so they have to
// be drawn by the platform's style rather than whatever Controls defaults to.
import QtQuick.Controls.LuneOS 2.0

import LuneOS.Service 1.0

/**
 * The application menu, ported from the legacy phoneAppMenu: clear call
 * history, call voicemail, and shortcuts into the sounds and preferences apps.
 * The QML app had no app menu at all, so clearing the call log was impossible
 * from inside the app.
 *
 * A Menu's default property collects its entries, so the confirmation dialog
 * lives in the page that owns the menu, not here.
 */
Menu {
    id: phoneAppMenu

    property var dialHandler

    /// Asked to empty the call log; the owner confirms before it happens.
    signal clearHistoryRequested();
    /// Asked for the phone preferences page.
    signal preferencesRequested();
    /// Asked for the list of accounts calls can be placed over.
    signal accountsRequested();

    MenuItem {
        text: qsTr("Clear Call History")
        onTriggered: phoneAppMenu.clearHistoryRequested()
    }

    MenuItem {
        text: qsTr("Call Voicemail")
        enabled: !!phoneAppMenu.dialHandler
        onTriggered: phoneAppMenu.dialHandler.dialVoicemail()
    }

    MenuItem {
        text: qsTr("Phone Accounts")
        onTriggered: phoneAppMenu.accountsRequested()
    }

    MenuItem {
        text: qsTr("Phone Preferences")
        onTriggered: phoneAppMenu.preferencesRequested()
    }

    MenuItem {
        text: qsTr("Sounds & Ringtones")
        onTriggered: phoneAppMenu._launch("com.palm.app.soundsandalerts")
    }

    MenuItem {
        text: qsTr("Preferences & Accounts")
        onTriggered: phoneAppMenu._launch("com.palm.app.accounts")
    }

    function _launch(appId) {
        lunaService.call("luna://com.webos.applicationManager/launch",
                         JSON.stringify({ id: appId }), undefined,
                         function(error) { console.log("Could not launch " + appId + ": " + error); });
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
        usePrivateBus: true
    }
}
