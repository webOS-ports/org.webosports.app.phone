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

import QtQuick 2.6
import QtQuick.Window 2.3

import "../services/IncomingCallsService.js" as IncomingCallsService

/// The incoming call while the phone app is in front; IncomingCallAlert shows
/// the same view when it is not.
BasePage {
    id: incommingCallDialog
    pageName: "IncomingCall"

    /*
     * Nothing on this page is typed into, so no text field may hold the
     * focus while it is up: the on-screen keyboard comes up for whichever
     * field has it, over the answer and decline buttons, and comes back each
     * time the window is activated -- on sargo on 2026-11-07 a call rang out
     * behind it. The page takes the focus as it is shown, and takes it back
     * from any field that gets it while the call rings, wherever that field
     * is in the window (a page under this one, a popup above it).
     */
    /// Read by DialerPage, whose keyboard proxy takes the focus back whenever
    /// it loses it while the dialer shows: not from this page, or the two
    /// would hand it back and forth while the page is pushed over the dialer.
    readonly property bool holdsFocusFromFields: true

    function _takeFocus() {
        // Called later as well (see below), by which time the page may be gone.
        if (!incommingCallDialog.visible)
            return;
        incommingCallDialog.forceActiveFocus();
        Qt.inputMethod.hide();
    }

    onVisibleChanged: if (visible) _takeFocus()
    Component.onCompleted: if (visible) _takeFocus()

    /// Whatever has the focus in this window, followed as it moves.
    readonly property Item _focusHolder: Window.activeFocusItem

    on_FocusHolderChanged: {
        var item = _focusHolder;
        if (visible && item && item.inputMethodHints !== undefined && item.cursorPosition !== undefined)
            // Not from inside the focus change itself: Qt is still handing
            // the focus over, and a second change made now is lost.
            Qt.callLater(_takeFocus);
    }

    IncomingCallView {
        anchors.fill: parent

        appTheme: incommingCallDialog.appTheme
        currentContact: incommingCallDialog.currentContact
        serviceLabel: incommingCallDialog.callTransports && incommingCallDialog.voiceCall
                      ? incommingCallDialog.callTransports.callServiceLabel(incommingCallDialog.voiceCall.providerId)
                      : ""

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
