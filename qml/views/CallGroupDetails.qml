/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 WebOS Ports
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
import LuneOS.Service 1.0
import LuneOS.Telephony 1.0

import "../model"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * The expanded call group: every individual call in it, then what you can do
 * with the number -- call it back, text it, and add it to (or open it in)
 * Contacts. The legacy call log offered the same actions as "drawer sub-items";
 * the QML version listed the calls but none of the actions.
 */
Column {
    id: callGroupDetailsId

    property ContactsModel contacts;

    property var callGroupRemotePerson;
    property var callGroupAddress;
    property string callGroupId;
    property var dialHandler;
    property var callTransports;

    readonly property string callService: (callGroupAddress && callGroupAddress.service)
                                              ? callGroupAddress.service : ""
    readonly property bool isSynergyCall: callService.length > 0 && callService !== "com.palm.telephony"

    readonly property string groupPhoneNumber: callGroupAddress ? (callGroupAddress.addr || "") : ""

    Repeater {
      id: modelRepeater
      width:parent.width
      model: CallGroupItems { callGroupId: callGroupDetailsId.callGroupId }
      delegate: RowLayout {
          id: callphoneDelegate
          spacing: Units.gu(0.5)

          property date _timestamp: new Date(model.timestamp)
          property var _remotePerson: (model.type !== "outgoing") ? model.from : (Array.isArray(model.to) ? model.to[0] : model.to.get(0))
          property string _duration: PhoneNumberUtils.formatDurationShort(model.duration/1000)
          property string _callPhoneNumberForDisplay: LibPhoneNumber.formatPhoneNumberForDisplay(_remotePerson.addr, contacts.countryCode);

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
              text: _duration.length > 0 ? "(" + _duration + ")" : "";
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

   // Actions on the number this group is about, whether or not it belongs to a
   // known contact.
   RowLayout {
       width: parent.width
       height: Units.gu(5)
       spacing: Units.gu(1)
       visible: callGroupDetailsId.groupPhoneNumber.length > 0

       Text {
           Layout.fillWidth: true
           font.pixelSize: FontUtils.sizeToPixels("12pt")
           color: 'white'
           elide: Text.ElideRight
           // Naming the service makes it obvious the call goes back out the
           // same way it came in.
           text: callGroupDetailsId.isSynergyCall && callGroupDetailsId.callTransports
                     ? qsTr("Call back on %1").arg(callGroupDetailsId.callTransports.labelFor(callGroupDetailsId.callService))
                     : qsTr("Call back")

           MouseArea {
               anchors.fill: parent
               onClicked: {
                   if (callGroupDetailsId.dialHandler)
                       callGroupDetailsId.dialHandler.dial(callGroupDetailsId.groupPhoneNumber,
                                                           callGroupDetailsId.isSynergyCall ? callGroupDetailsId.callService : "",
                                                           false);
               }
           }
       }

       Text {
           font.pixelSize: FontUtils.sizeToPixels("12pt")
           color: 'white'
           text: qsTr("Text")

           MouseArea {
               anchors.fill: parent
               onClicked: callGroupDetailsId.sendMessage(callGroupDetailsId.groupPhoneNumber,
                                                         callGroupDetailsId.isSynergyCall ? callGroupDetailsId.callService : "")
           }
       }

       Text {
           Layout.rightMargin: Units.gu(2)
           font.pixelSize: FontUtils.sizeToPixels("12pt")
           color: 'white'
           text: callGroupDetailsId.callGroupRemotePerson ? qsTr("View contact") : qsTr("Add to contacts")

           MouseArea {
               anchors.fill: parent
               onClicked: {
                   if (callGroupDetailsId.callGroupRemotePerson)
                       callGroupDetailsId.viewContact(callGroupDetailsId.callGroupRemotePerson._id);
                   else
                       callGroupDetailsId.addToContacts(callGroupDetailsId.groupPhoneNumber);
               }
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

                       property string _phoneNumberValue: model.value ? model.value : modelData.value
                       property string _callGroupDetailPhoneNumberForDisplay: LibPhoneNumber.formatPhoneNumberForDisplay(_phoneNumberValue, contacts.countryCode);

                       Text {
                           Layout.fillWidth: true
                           font.pixelSize: FontUtils.sizeToPixels("12pt")
                           color:'white'
                           text: _callGroupDetailPhoneNumberForDisplay;

                           MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   if (callGroupDetailsId.dialHandler)
                                       callGroupDetailsId.dialHandler.dial(_phoneNumberValue);
                               }
                           }
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
                               onClicked: callGroupDetailsId.sendMessage(_phoneNumberValue, "")
                           }
                       }
                   }
               }
           }
       }
   }

   /// Opens the messaging app on a conversation with this address. A Synergy
   /// address opens the conversation on its own service rather than as an SMS.
   function sendMessage(address, service) {
       var compose = { messageText: "", personId: "", address: address };
       if (service && service.length > 0 && callTransports) {
           var transport = callTransports.transportFor(service);
           if (transport && transport.serviceName)
               compose.serviceName = transport.serviceName;
       }

       _launch("com.palm.app.messaging", { compose: compose });
   }

   /// Opens the contact in the Contacts app.
   function viewContact(personId) {
       _launch("com.palm.app.contacts", { personId: personId });
   }

   /// Starts a new contact in the Contacts app, pre-filled with this number.
   function addToContacts(phoneNumber) {
       _launch("com.palm.app.contacts", { newContact: { phoneNumbers: [ { value: phoneNumber, type: "type_mobile" } ] } });
   }

   function _launch(appId, params) {
       lunaService.call("luna://com.webos.applicationManager/launch",
                        JSON.stringify({ id: appId, params: params }), undefined,
                        function(error) { console.log("Could not launch " + appId + ": " + error); });
   }

   LunaService {
       id: lunaService
       name: "org.webosports.app.phone"
       usePrivateBus: true
   }
}
