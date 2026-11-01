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
import QtMultimedia 6.3

import LuneOS.Service 1.0
import LuneOS.System 1.0

/**
 * The tones of the call alerts: the alert tone for a dropped call and a failed
 * dial, the notification tone for a missed call. Each is the one picked in
 * the preferences, as LunaSysMgr played for a popup of that class.
 *
 * Both play on "palerts", through audiod's playSound as the shell plays a
 * banner's sound, so the music is lowered under them and they take the
 * output audiod has for alerts. In a call that sink ends up on the droid
 * card's primary output, which the Mediatek HAL hands to the modem as
 * background sound: in the call's route, not to the far end.
 *
 * audiod only takes WAV, so a tone picked as anything else plays here, on the
 * same sink. So does one audiod turns down.
 */
Item {
    id: sounds

    property string alertTone: "/usr/palm/sounds/alert.wav"
    property string notificationTone: "/usr/palm/sounds/notification.wav"
    /// "Mute Sound" in the system menu.
    property bool muted: false

    readonly property string sinkName: "palerts"

    /// A tone was started, whichever way it goes out.
    signal played(string path)

    function playAlert() {
        _play(alertTone);
    }

    function playNotification() {
        _play(notificationTone);
    }

    function _play(path) {
        if (muted || !path)
            return;

        played(path);

        if (!_audiodTakes(path)) {
            _playHere(path);
            return;
        }

        lunaService.call("luna://com.webos.service.audio/playSound", JSON.stringify(_playSoundRequest(path)),
                         function(message) {
                             var response = JSON.parse(message.payload);
                             if (!response.returnValue)
                                 sounds._refused(path, response.errorText);
                         },
                         function(message) { sounds._refused(path, message); });
    }

    function _audiodTakes(path) {
        return /\.wav$/i.test(path);
    }

    function _playSoundRequest(path) {
        return { fileName: path, sink: sinkName };
    }

    function _refused(path, why) {
        console.warn("phone: audiod did not play " + path + " (" + why + "), playing it here");
        _playHere(path);
    }

    // An output of its own for each tone, as RingManager has for each ring:
    // Qt's GStreamer backend forgets the device of an output it stopped on.
    function _playHere(path) {
        var previous = player.audioOutput;
        player.audioOutput = null;

        var sink = null;
        var outputs = mediaDevices.audioOutputs;
        for (var i = 0; i < outputs.length; i++) {
            if (outputs[i].id.toString() === sinkName)
                sink = outputs[i];
        }
        player.audioOutput = outputComponent.createObject(sounds, sink ? { device: sink } : {});
        if (previous)
            previous.destroy();

        player.source = path;
        player.play();
    }

    MediaPlayer {
        id: player
    }

    MediaDevices {
        id: mediaDevices
    }

    Component {
        id: outputComponent
        AudioOutput {}
    }

    LunaService {
        id: lunaService
        name: "org.webosports.app.phone"
    }

    SystemPreferences {
        clientName: "org.webosports.app.phone"
        keys: ["alerttone", "notificationtone", "muteSound"]
        onUpdated: (response) => sounds._preferences(response)
        onError: (message) => console.log("phone: no alert tones in the preferences: " + message)
    }

    function _preferences(response) {
        if (response.alerttone && response.alerttone.fullPath)
            alertTone = response.alerttone.fullPath;
        if (response.notificationtone && response.notificationtone.fullPath)
            notificationTone = response.notificationtone.fullPath;
        if (response.muteSound !== undefined)
            muted = response.muteSound === true;
    }
}
