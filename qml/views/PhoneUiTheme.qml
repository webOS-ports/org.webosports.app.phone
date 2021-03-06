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

QtObject {
    property color foregroundColor:'white'
    property color backgroundColor: '#456B8E' //'#444444'
    property Gradient mainGradient: Gradient {
        GradientStop { position: 0.0; color: '#456B8E' }
        GradientStop { position: 1.0; color: '#243849' }
    }
    property Gradient selectedGradient: Gradient {
        GradientStop { position: 0.0; color: '#243849' }
        GradientStop { position: 1.0; color: '#5F93C0' }
    }
    property Gradient unSelectedGradient: Gradient {
        GradientStop { position: 0.0; color: '#43637E' }
        GradientStop { position: 0.5; color: '#20303E' }
        GradientStop { position: 1.0; color: '#263949' }
    }
    property color headerColor:'#6f6f6f'
    property color headerTitle: 'white'
    property color headerTip: 'black'
    property color subForegroundColor:'#6f6f6f'
    property color selectedTabColor: '#6f6f6f'
    property color selectedTabForground: 'grey'
    property color unselectedTabColor: '#6f6f6f'
    property color unselectedTabForground: 'grey'
    property color callActionBtnFgColor: '#0B2161'
    property color callActionBtnFgColorActive: '#045FB4'
}
