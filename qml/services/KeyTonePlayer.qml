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

import LuneOS.Service 1.0

import "../AppTweaks"

/**
 * The beep of a dialpad key, for this end only: audiod's DTMF generator
 * (com.palm.audio/dtmf/playDTMF), a 200 ms one-shot that stops by itself on
 * the feedback sink.
 *
 * With a call up the same stream reaches the ear through the call. A carrier
 * call does not pass through PulseAudio, but the Mediatek HAL hands whatever
 * the primary output plays during a call to the modem as background sound,
 * mixed into the downlink, so it comes out wherever the call does. Which is
 * also why inCall says feedbackOnly: without it audiod would try to send the
 * tone to the network as well, and that is the caller's to do.
 *
 * Dialpad Feedback in the phone's tweaks decides, as Android's "dial pad
 * tones" does both in the Dialer and in a call. The ringer switch does not
 * come into it in a call: on Android the DTMF stream leaves the streams the
 * ringer mutes while a call is up (AudioService.updateStreamVolumeAlias).
 */
QtObject {
    property string feedback: AppTweaks.dialpadFeedbackTweakValue

    property QtObject service: LunaService {
        name: "org.webosports.app.phone"
    }

    // Only 0-9, * and # have tones, and only with sound feedback switched on.
    function play(key, inCall) {
        if (!(feedback === "vibrateSound" || feedback === "soundOnly"))
            return;
        if (!/^[0-9*#]$/.test(key))
            return;
        var request = { name: key };
        if (inCall)
            request.feedbackOnly = true;
        service.call("luna://com.palm.audio/dtmf/playDTMF", JSON.stringify(request),
                     undefined, function(message) {
            console.log("Unable to play DTMF tone");
        });
    }
}
