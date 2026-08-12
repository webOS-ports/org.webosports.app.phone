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

import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

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
        // The same white pill the Phone tab is searched with, rather than a
        // bare field with a Unicode magnifier in its placeholder.
        SearchField {
            id: searchFieldInput

            anchors.verticalCenter: parent.verticalCenter
            width: Units.gu(20)

            placeholderText: qsTr("Filter")
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

    // The log sits in a bordered group box, as every list in the original does.
    Rectangle {
        anchors {
            top: allOrMissedRect.bottom
            topMargin: Units.gu(0.4)
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(0.8)
        }
        color: appTheme.listBackgroundColor
        radius: Units.gu(0.8)
        border.color: appTheme.listBorderColor
        border.width: 1
        clip: true

        ListView {
            id: historyList

            anchors.fill: parent
            clip: true
            model: historyListViewModel

            section.property: "timestamp_day"
            section.criteria: ViewSection.FullString

            // The day, in grey caps, with a dark rule running to the edge.
            section.delegate: Item {
                width: historyList.width
                height: Units.gu(2.8)

                Text {
                    id: sectionTextId

                    anchors {
                        left: parent.left
                        leftMargin: Units.gu(1.2)
                        bottom: parent.bottom
                        bottomMargin: Units.gu(0.3)
                    }
                    color: appTheme.listSecondaryTextColor
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: FontUtils.sizeToPixels("small")

                    property date _timestamp: new Date(Number(section) * 86400000)
                    text: PhoneNumberUtils.formatRelativeDay(_timestamp, Qt.locale())
                }

                Rectangle {
                    anchors {
                        left: sectionTextId.right
                        leftMargin: Units.gu(1)
                        right: parent.right
                        rightMargin: Units.gu(1.2)
                        verticalCenter: sectionTextId.verticalCenter
                    }
                    height: 1
                    color: appTheme.listBorderColor
                }
            }

            delegate: CallGroupDelegate {
                width: historyList.width
                historyModel: historyPageId.historyModel
                contacts: historyPageId.contacts
                dialHandler: historyPageId.dialHandler
                callTransports: historyPageId.callTransports
                appTheme: historyPageId.appTheme

                // The row before a day header must not draw a divider too.
                lastOfDay: (index + 1) >= historyListViewModel.count ||
                           historyListViewModel.get(index + 1).timestamp_day !== model.timestamp_day
            }

            Text {
                anchors.centerIn: parent
                visible: historyList.count === 0
                color: appTheme.listSecondaryTextColor
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: buttonOnlyMissed.checked ? qsTr("Your missed call history is empty")
                                               : qsTr("Your call history is empty")
            }
        }
    }
}
