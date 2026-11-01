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
import QtQml 2.2

import QOfono 0.2
import Nemo.DBus 2.0

/**
 * Why oFono says each call on any modem ended.
 *
 * DisconnectReason is a signal of its own on org.ofono.VoiceCall, sent just
 * before the call goes. QOfonoVoiceCall declares it but only listens to
 * PropertyChanged, so its disconnectReason() never fires; hence the
 * DBusInterface. The call's line comes from QOfono.
 *
 * Loaded by VoiceCallMgrWrapper through a Loader: without one of these two
 * modules this file does not load, and the app must still start. Calls then
 * just go without a reason.
 */
Item {
    id: reasons

    signal reasonReported(string lineId, string reason)

    property var _watched: ({})

    function _watch(path) {
        if (!_watched[path])
            _watched[path] = watchedCall.createObject(reasons, { callPath: path });
    }

    function _unwatch(path) {
        var call = _watched[path];
        if (call) {
            delete _watched[path];
            call.destroy();
        }
    }

    OfonoManager {
        id: ofono
    }

    Instantiator {
        model: ofono.modems
        delegate: OfonoVoiceCallManager {
            modemPath: modelData
            onCallAdded: (call) => reasons._watch(call)
            onCallRemoved: (call) => reasons._unwatch(call)
        }
    }

    Component {
        id: watchedCall

        Item {
            id: watched

            property string callPath: ""

            OfonoVoiceCall {
                id: ofonoCall
                voiceCallPath: watched.callPath
            }

            DBusInterface {
                bus: DBus.SystemBus
                service: "org.ofono"
                path: watched.callPath
                iface: "org.ofono.VoiceCall"
                signalsEnabled: true

                // Typed: the plugin invokes this with the signal's own types,
                // and Qt 6 refuses a QString for the QVariant of an untyped one.
                function disconnectReason(reason: string) {
                    reasons.reasonReported(ofonoCall.lineIdentification, reason);
                }
            }
        }
    }
}
