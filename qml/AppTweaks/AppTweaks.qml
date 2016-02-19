/*
 * Copyright (C) 2014 Christophe Chapuis <chris.chapuis@gmail.com>
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

pragma Singleton

import QtQuick 2.0
import LuneOS.Components 1.0

Item {
    id: appTweaks

    // common property values
    property string owner: "org.webosports.app.phone"
    property string serviceName: "org.webosports.app.phone"

    // aliases for each tweak
    property alias dialpadFeedbackTweakValue: dialpadFeedbackTweak.value

    //// tweak definitions

    // DialerPage
    Tweak {
        id: dialpadFeedbackTweak
        owner: appTweaks.owner
        serviceName: appTweaks.serviceName
        key: "dialPadFeedback"
        defaultValue: "noFeedback"
    }

}
