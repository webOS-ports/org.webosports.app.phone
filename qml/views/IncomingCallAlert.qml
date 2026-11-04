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
 * The incoming call while the phone app is not in front, and a call
 * waiting whether it is or not: a system alert window, so it can come up
 * over whatever is on screen - the call card included - and over the lock
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
    property QtObject callTransports

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
        drawWatch.stop();
        incomingCallAlert.hide();
        voiceCall = null;
    }

    /**
     * Puts the alert up for a ringing call.
     *
     * On sargo on 2026-11-03 the shell once never took the window up: show()
     * went out, the compositor sent no configure, nothing was drawn, the
     * screen stayed dark and the call rang out unseen - even after the power
     * key turned the screen on. It could not be made to happen again on
     * purpose. A window that is up draws its first frame within a frame or
     * two; one that has not after drawTimeoutMs is hidden and shown again,
     * which gives it a new surface, as surfaceRecovery does for the call card.
     */
    function present(call) {
        dismiss();
        voiceCall = call;
        _drawn = false;
        _reshows = 0;
        _shownAt = Date.now();
        console.log("Incoming call alert: showing");
        show();
        drawWatch.restart();
    }

    /// How long the alert may take to draw before it is shown afresh.
    property int drawTimeoutMs: 1500
    /// How many times it is shown afresh before giving up.
    property int maxReshows: 2

    property bool _drawn: true
    property int _reshows: 0
    property double _shownAt: 0

    // Only the first frame counts. (Connections has no `enabled` under the
    // QtQuick 2.0 import this file uses; the strip draws few frames anyway.)
    Connections {
        target: incomingCallAlert
        function onFrameSwapped() {
            if (incomingCallAlert._drawn)
                return;
            incomingCallAlert._drawn = true;
            console.log("Incoming call alert: drawn " + (Date.now() - incomingCallAlert._shownAt) + " ms after show");
        }
    }

    function _checkDrawn() {
        if (_drawn || !visible || !voiceCall)
            return;
        if (_reshows >= maxReshows) {
            console.warn("Incoming call alert: still not drawn after " + _reshows + " fresh shows");
            return;
        }
        _reshows++;
        console.warn("Incoming call alert: not drawn " + (Date.now() - _shownAt) + " ms after show; showing it afresh");
        hide();
        show();
        drawWatch.restart();
    }

    Timer {
        id: drawWatch
        objectName: "drawWatch"
        interval: incomingCallAlert.drawTimeoutMs
        onTriggered: incomingCallAlert._checkDrawn()
    }

    onVisibleChanged: console.log("Incoming call alert: visible " + visible)

    /*
     * The strip is for a call that is ringing or waiting, and goes as soon as
     * it is neither - however that came about. A call answered by a headset
     * button or rejected elsewhere, or a waiting call taken with hold and
     * answer, never passes through the buttons below, and the strip used to
     * stay up over the call screen until the last call ended.
     */
    Connections {
        target: incomingCallAlert.voiceCall
        ignoreUnknownSignals: true

        function onStatusChanged() {
            var status = incomingCallAlert.voiceCall.status;
            if (status !== VoiceCall.STATUS_INCOMING && status !== VoiceCall.STATUS_WAITING)
                incomingCallAlert.dismiss();
        }
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
        serviceLabel: incomingCallAlert.callTransports && incomingCallAlert.voiceCall
                      ? incomingCallAlert.callTransports.callServiceLabel(incomingCallAlert.voiceCall.providerId)
                      : ""

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
