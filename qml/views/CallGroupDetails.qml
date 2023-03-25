/*
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
import QtQml

import LunaNext.Common 0.1
import LuneOS.Components 1.0
import LuneOS.Telephony 1.0

import "../model"

Column {
    id: callGroupDetailsId

    property ContactsModel contacts;

    property var callGroupRemotePerson;
    property string callGroupId;

    Repeater {
      id: modelRepeater
      width:parent.width
      model: CallGroupItems { callGroupId: callGroupDetailsId.callGroupId }
      delegate: RowLayout {
          id: callphoneDelegate
          spacing: Units.gu(0.5)

          property date _timestamp: new Date(model.timestamp)
          property var _remotePerson: (model.type !== "outgoing") ? model.from : (Array.isArray(model.to) ? model.to[0] : model.to.get(0))
          property string _duration: secondsToTimeString(duration/1000)
          property string _callPhoneNumberForDisplay: LibPhoneNumber.formatPhoneNumberForDisplay(_remotePerson.addr, contacts.countryCode);

          function secondsToTimeString(seconds) {
              if(seconds===0) return '';

              var h = Math.floor(seconds / 3600);
              var m = Math.floor((seconds - (h * 3600)) / 60);
              var s = Math.round(seconds - h * 3600 - m * 60);

              var result = '(';
              if(h>0) result += h + 'h';
              if(m>0) result += m + 'm';
              if(s>0) result += s + 's';
              result += ')';

              return result;
          }

          width:modelRepeater.width
          height: Units.gu(3.2)
          Text {
              font.pixelSize: FontUtils.sizeToPixels("12pt")
              color:'white'
              text: _remotePerson.personAddressType ? contacts.getPhoneNumberTypeStr(_remotePerson.personAddressType): "";
          }
          Text {
              font.pixelSize: FontUtils.sizeToPixels("12pt")
              color:'grey'
              text: _callPhoneNumberForDisplay
          }
          Text {
              Layout.fillWidth: true
              font.pixelSize: FontUtils.sizeToPixels("12pt")
              color:'grey'
              text: _duration;
          }
          ClippedImage {
              Layout.preferredHeight: callphoneDelegate.height
              Layout.preferredWidth: callphoneDelegate.height

              source: Qt.resolvedUrl('images/call-log-list-sprite.png')

              wantedWidth: callphoneDelegate.height
              wantedHeight: callphoneDelegate.height

              imageSize: Qt.size(44, 182)
              patchGridSize: Qt.size(1, 4)
              patch: (model.type==="missed") ? Qt.point(0,0) :
                     (model.type === "incoming") ? Qt.point(0,1) :
                     (model.type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
          }
          Text {
              font.pixelSize: FontUtils.sizeToPixels("12pt")
              color:'grey'
              text: Qt.formatTime(_timestamp, Qt.locale().timeFormat(Locale.ShortFormat));
          }
      }
   }

   // Now put the phone numbers of the remote person, if it is available
   Loader {
       active: callGroupRemotePerson !== null
       width: parent.width
       sourceComponent: Component {
           Column {
               width: parent.width
               Repeater {
                   width: parent.width
                   model: callGroupRemotePerson.phoneNumbers
                   delegate: RowLayout {
                       width: parent.width
                       height: Units.gu(5)

                       property string _callGroupDetailPhoneNumberForDisplay: LibPhoneNumber.formatPhoneNumberForDisplay(model.value ? model.value : modelData.value, contacts.countryCode);

                       Text {
                           Layout.fillWidth: true
                           font.pixelSize: FontUtils.sizeToPixels("12pt")
                           color:'white'
                           text: _callGroupDetailPhoneNumberForDisplay;
                       }
                       Text {
                           font.pixelSize: FontUtils.sizeToPixels("12pt")
                           color:'grey'
                           text: contacts.getPhoneNumberTypeStr(model.type ? model.type : modelData.type);
                       }
                       ClippedImage {
                           source: Qt.resolvedUrl('images/button-sprite.png')

                           wantedWidth: parent.height // square button
                           wantedHeight: parent.height // square button

                           imageSize: Qt.size(183, 244)
                           patchGridSize: Qt.size(3, 4)
                           patch: smsButtonMouseArea.pressed ? Qt.point(2,1) : Qt.point(2,0)

                           MouseArea {
                               id: smsButtonMouseArea
                               anchors.fill: parent
                               onClicked: {
                                   // start the Message app with this contact as target
                               }
                           }
                       }
                   }
               }
           }
       }
   }
}
