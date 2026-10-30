/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import "../services"
import "../model"

/**
 * The call in progress while the screen is locked.
 *
 * The phone window lives under the lock screen, so a call answered there, or
 * a call the screen locks on, would carry on with nothing on screen to hang it
 * up, mute it or turn the speaker on. Legacy webOS put the phone's PIN card up
 * instead: the same call screen in lockedmode, over the lock. This is that
 * card - the call screen in lockedMode, in a system alert window the shell
 * shows over the lock screen.
 *
 * LuneOS_overLockScreen puts it there; LuneOS_callAlert "incall" tells the
 * shell it is a call already answered, not one ringing, so the display is not
 * held on for it the way it is for a ringing call - the proximity sensor
 * blanks it against the ear as on the ordinary call screen.
 */
WebOSWindow {
    id: lockedCallWindow

    property UiTheme appTheme
    property QtObject voiceCall
    property ContactsModel contacts
    property Contact currentContact
    property VoiceCallMgrWrapper voiceCallMgrWrapper
    property TelephonyManager telephonyManager
    property AudioRouteManager audioRouteManager
    property CallTransports callTransports

    /// "Unlock": the call screen steps aside for the lock screen.
    signal unlockRequested()

    width: Settings.displayWidth
    // As much as the shell will give it: it fits an alert between the status
    // bar and the gesture area.
    height: Settings.displayHeight

    keepAlive: true
    windowType: "_WEBOS_WINDOW_TYPE_SYSTEM_UI"
    color: appTheme ? appTheme.backgroundColor : "black"

    function dismiss() {
        lockedCallWindow.hide();
        voiceCall = null;
    }

    Component.onCompleted: {
        lockedCallWindow.setWindowProperty("LuneOS_window", "popupalert");
        lockedCallWindow.setWindowProperty("LuneOS_overLockScreen", "true");
        lockedCallWindow.setWindowProperty("LuneOS_callAlert", "incall");
    }

    ActiveCallPage {
        anchors.fill: parent

        lockedMode: true
        appTheme: lockedCallWindow.appTheme
        voiceCall: lockedCallWindow.voiceCall
        contacts: lockedCallWindow.contacts
        currentContact: lockedCallWindow.currentContact
        voiceCallMgrWrapper: lockedCallWindow.voiceCallMgrWrapper
        telephonyManager: lockedCallWindow.telephonyManager
        audioRouteManager: lockedCallWindow.audioRouteManager
        callTransports: lockedCallWindow.callTransports

        onUnlockRequested: lockedCallWindow.unlockRequested()
    }
}
