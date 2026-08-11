/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtQuick.Layouts 1.2
import QtQuick.Controls.LuneOS 2.0

import LunaNext.Common 0.1
import LuneOS.Components 1.0
import LuneOS.Service 1.0

BasePage {
    id: historyPageId
    pageName: "History"

    property alias historyModel: historyListViewModel.sourceModel

    // All / Missed button chooser
    Row {
        id: allOrMissedRect
        anchors.horizontalCenter: parent.horizontalCenter
        height: Units.gu(4)
        spacing: Units.gu(3)

        Row {
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            RadioButton {
                text: "All"
                LuneOSRadioButton.useCollapsedLayout: true
                checked: true
                width: Units.gu(14)
                height: parent.height
            }
            RadioButton {
                id: buttonOnlyMissed
                text: "Missed"
                LuneOSRadioButton.useCollapsedLayout: true
                width: Units.gu(14)
                height: parent.height
            }
        }
        Binding {
            target: historyModel
            property: "showOnlyMissed"
            value: buttonOnlyMissed.checked
        }
        TextField {
            id: searchFieldInput
            height: parent.height
            width: Units.gu(14)
            text: ""
            placeholderText: "🔍 Filter..."
        }
    }

    Connections {
        target: historyListViewModel.sourceModel
        function onCountChanged()
        {
            historyListViewModel._updateModel();
        }
    }
    ListModel {
        id: historyListViewModel
        property Db8Model sourceModel
        property string filter: searchFieldInput.text
        onFilterChanged: _updateModel();
        Component.onCompleted: _updateModel();

        // A call from a number that is not in Contacts has no name to search,
        // so the filter has to look at the number itself as well.
        function _matches(callGroup, needle) {
            var address = callGroup.recentcall_address;
            if (!address) return false;

            if (address.name && address.name.toLowerCase().indexOf(needle) >= 0)
                return true;

            var digits = needle.replace(/[^0-9+]/g, '');
            if (digits.length === 0) return false;

            return !!address.addr && String(address.addr).replace(/[^0-9+]/g, '').indexOf(digits) >= 0;
        }

        function _updateModel() {
            historyListViewModel.clear(); // we can do better
            if (!sourceModel) return;

            var needle = filter.toLowerCase();

            for(var i=0; i<sourceModel.count; ++i) {
                var eltSrc = sourceModel.get(i);
                if(filter.length === 0 || historyListViewModel._matches(eltSrc, needle))
                {
                    historyListViewModel.append(eltSrc);
                }
            }
        }
    }

    ListView {
        id:historyList
        anchors {
            top:allOrMissedRect.bottom
            bottom:parent.bottom
            left: parent.left
            right: parent.right
        }
        spacing:4
        clip:true
        model: historyListViewModel

        section.property: "timestamp_day"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            width: parent.width
            height: childrenRect.height
            Rectangle {
                width: Units.gu(1) //parent.width
                color: appTheme.panelBorderColor
                height: sectionTextId.height/5
                anchors.left: parent.left
                anchors.verticalCenter: sectionTextId.verticalCenter
            }
            Text {
                id: sectionTextId
                x: Units.gu(2)
                color: "lightgrey"
                font.bold: true
                font.pixelSize: FontUtils.sizeToPixels("18pt")
                property date _timestamp: new Date(Number(section)*86400000) //  convert timestamp_day to ms
                text: _timestamp.toLocaleDateString()
            }
            Rectangle {
                width: parent.width - sectionTextId.contentWidth - Units.gu(3) //Units.gu(1) //parent.width
                color: appTheme.panelBorderColor
                height: sectionTextId.height/5
                anchors.right: parent.right
                anchors.verticalCenter: sectionTextId.verticalCenter
            }

        }

        delegate: CallGroupDelegate {
            width: historyList.width
            historyModel: historyPageId.historyModel
            contacts: historyPageId.contacts
            dialHandler: historyPageId.dialHandler
            callTransports: historyPageId.callTransports
            appTheme: historyPageId.appTheme
        }

        Text {
            anchors.centerIn: parent
            visible: historyList.count === 0
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("20pt")
            text: buttonOnlyMissed.checked ? qsTr("Your missed call history is empty")
                                           : qsTr("Your call history is empty")
        }
    }
}

