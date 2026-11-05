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
import LuneOS.Telephony 1.0

import "../model"
import "../services"
import "../services/PhoneNumberUtils.js" as PhoneNumberUtils

/**
 * One call group in the call log.
 *
 * Laid out like com.palm.app.phone: the contact's photo on the left, their
 * name with a star if they are a favourite, and the service and the number on
 * lines of their own underneath. Then two columns that keep their place from
 * row to row: the number of calls over the video marker, and the type of call
 * over its time, as on the Pre. Last, a button that opens the individual calls.
 *
 * The artwork is the original's: call-log-list-sprite for the call type,
 * dashboard-unread for the count pill, expand-button for the disclosure.
 */
Column {
    id: callGroupDelegate

    property var historyModel;
    property ContactsModel contacts;
    property DialHandler dialHandler;
    property CallTransports callTransports;
    property UiTheme appTheme

    /// True for the last group of its day, so the row above a day header does
    /// not also draw a divider.
    property bool lastOfDay: false

    property string callGroupId: model.groupId ? model.groupId : model._id // keep backward read-only compatibility with Legacy db structure
    property var contactAddress: model.recentcall_address
    property var remotePerson: (contactAddress && contactAddress.personId) ? contacts.personById(contactAddress.personId) : null

    /// Which account the calls in this group went over; cellular is unlabelled.
    readonly property string callService: (contactAddress && contactAddress.service)
                                              ? contactAddress.service : ""
    readonly property bool isSynergyCall: callService.length > 0 &&
                                          callService !== "com.palm.telephony"

    readonly property string serviceLabel: {
        if (!isSynergyCall || !callTransports) return "";
        return callTransports.labelFor(callService).toUpperCase();
    }

    readonly property string numberForDisplay:
        LibPhoneNumber.formatPhoneNumberForDisplay(contactAddress.addr, contacts.countryCode)

    /// True while the row is swiped aside to show its delete button.
    property bool pendingDelete: false

    /**
     * What the name and the service line have left to share.
     *
     * The row is a photo, the lines of text, the count and video column, the
     * call type and time column and the disclosure button. Everything but the
     * text has a size of its own, so
     * what the text may take is the row less all of them -- and a long enough
     * line has to elide rather than push a neighbour off the end.
     *
     * The two lines used to be capped at a share of the row instead, 55% and
     * 62%, which is right on a screen where 62% of the row is smaller than
     * what is left over and wrong on one where it is not. On a Q25 it was not:
     * "WHATSAPP +31 6 2148 9831" took its 62% and shoved the disclosure button
     * out through the side of the list, and the row below lost half of one.
     *
     * Measured off callGroupDelegate.width, which is the row's own and settled
     * before any of this is laid out. Asking the layout would feed it its own
     * answer, and an eliding Text reports the elided width as its implicit
     * one, so bounding it that way collapses it a word at a time.
     */
    readonly property real detailsWidth: {
        var fixed = Units.gu(4.4)          // the photo
                  + badgeColumnWidth       // the count over the video marker
                  + Units.gu(5)            // the call type over the time
                  + Units.gu(3.4)          // the disclosure button
                  + Units.gu(1) * 4        // the gaps between those and the text
                  + Units.gu(0.8) * 2;     // the row's own margins

        return Math.max(Units.gu(6), callGroupDelegate.width - fixed);
    }

    /// The count and the video marker share one column of a set width, so
    /// they stand at the same place in every row, whatever the name is. A
    /// count too wide for it (three digits) widens the column of that row.
    readonly property real badgeColumnWidth:
        Math.max(Units.gu(3.4), countPill.width)

    /// The tops of the first line and of the two below it, in the row's text
    /// and in the two columns beside it, so all three keep to the same lines.
    readonly property real firstLineHeight: Units.gu(2.4)
    readonly property real lineGap: Units.gu(0.3)

    /// The number, for its own line; left out when it is what the name line
    /// already says, as for a username or an unnamed number.
    readonly property string numberLine: {
        var shown = nameText.text, n = numberForDisplay;
        if (!n || n.length === 0) return "";
        function bare(s) { return String(s).toLowerCase().replace(/[^0-9a-z]/g, ""); }
        return bare(n) === bare(shown) ? "" : n;
    }

    // Swipe-to-delete, as on the legacy call log's SwipeableItem rows.
    Item {
        id: swipeRow

        width: parent.width
        height: appTheme.callLogRowHeight

        Rectangle {
            anchors.fill: parent
            color: appTheme.deleteColor
            visible: callGroupDelegate.pendingDelete

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Units.gu(3)
                color: 'white'
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: qsTr("Delete")
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    callGroupDelegate.pendingDelete = false;
                    historyModel.deleteCallGroup(callGroupDelegate.callGroupId);
                }
            }
        }

        Item {
            id: swipeContainer

            width: parent.width
            height: parent.height
            x: callGroupDelegate.pendingDelete ? -Units.gu(10) : 0

            Behavior on x { NumberAnimation { duration: 150 } }

            Rectangle {
                anchors.fill: parent
                color: rowArea.pressed ? appTheme.listSelectedColor : 'transparent'
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Units.gu(0.8)
                anchors.rightMargin: Units.gu(0.8)
                spacing: Units.gu(1)

                // The contact's photo, on the left as on the original.
                Item {
                    Layout.preferredWidth: Units.gu(4.4)
                    Layout.preferredHeight: Units.gu(4.4)

                    Image {
                        id: avatarPhotoImage
                        objectName: "avatarPhoto"
                        anchors.fill: parent
                        // A person without a photo still has a photos record,
                        // with every path in it empty: keep the stand-in, as
                        // the original always showed one.
                        source: (callGroupDelegate.remotePerson &&
                                 callGroupDelegate.remotePerson.photos &&
                                 callGroupDelegate.remotePerson.photos.listPhotoPath)
                                    ? callGroupDelegate.remotePerson.photos.listPhotoPath
                                    : appTheme.image("list-avatar-default.png")
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    CornerShader {
                        anchors.fill: avatarPhotoImage
                        source: avatarPhotoImage
                        radius: Units.gu(0.4)
                    }
                }

                /*
                 * Up to three lines: the name, the service, the number.
                 *
                 * Each has the whole width of the text to itself, so the name
                 * and the number are seldom elided at all -- on two lines the
                 * service took the front of the number's, and the count and
                 * the video marker took the end of both. A line with nothing
                 * to say is left out: cellular calls have no service, and a
                 * number the name line already shows is not repeated.
                 */
                Item {
                    Layout.fillWidth: true
                    // The ceiling the lines are elided against, so a long one
                    // cannot push the columns beside it off the end of the
                    // row. See detailsWidth.
                    Layout.maximumWidth: callGroupDelegate.detailsWidth
                    Layout.fillHeight: true

                    Item {
                        id: textLines
                        width: parent.width
                        height: callGroupDelegate.firstLineHeight + callGroupDelegate.lineGap
                                + lowerLines.height
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            height: callGroupDelegate.firstLineHeight
                            spacing: Units.gu(0.6)

                            Text {
                                id: nameText
                                objectName: "nameText"
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, Math.max(Units.gu(4),
                                           textLines.width - (favoriteStar.visible
                                                              ? favoriteStar.width + parent.spacing : 0)))
                                color: appTheme.listTextColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("medium")
                                text: (callGroupDelegate.remotePerson && contactAddress.name)
                                          ? contactAddress.name
                                          : callGroupDelegate.numberForDisplay
                            }

                            Image {
                                id: favoriteStar
                                objectName: "favoriteStar"
                                anchors.verticalCenter: parent.verticalCenter
                                width: Units.gu(1.6)
                                height: Units.gu(1.6)
                                fillMode: Image.PreserveAspectFit
                                source: appTheme.image("favorites-star-blue.png")
                                visible: !!callGroupDelegate.remotePerson &&
                                         callGroupDelegate.remotePerson.favorite === true
                            }
                        }

                        Column {
                            id: lowerLines
                            y: callGroupDelegate.firstLineHeight + callGroupDelegate.lineGap
                            width: parent.width

                            Text {
                                id: serviceText
                                objectName: "serviceText"
                                width: parent.width
                                visible: text.length > 0
                                color: appTheme.callLogDetailColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: callGroupDelegate.serviceLabel
                            }

                            Text {
                                id: numberText
                                objectName: "numberText"
                                width: parent.width
                                visible: text.length > 0
                                color: appTheme.callLogDetailColor
                                elide: Text.ElideRight
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: callGroupDelegate.numberLine
                            }
                        }
                    }
                }

                /*
                 * The count on the name's line, the video marker under it over
                 * the two lines below. A column of their own beside the call
                 * type, so both stand in the same place in every row.
                 */
                Item {
                    Layout.preferredWidth: callGroupDelegate.badgeColumnWidth
                    Layout.fillHeight: true

                    Item {
                        width: parent.width
                        height: textLines.height
                        anchors.verticalCenter: parent.verticalCenter

                        /*
                         * How many calls this group stands for.
                         *
                         * The original's .image-toggle-button-pillCountLbl: a
                         * pill that grows sideways with the number, drawn from
                         * dashboard-unread.png with nine pixels held at each
                         * end and the middle stretched, and set in bold.
                         */
                        BorderImage {
                            id: countPill
                            objectName: "countPill"
                            width: Math.max(Units.gu(2.5), countText.implicitWidth + Units.gu(1.4))
                            height: callGroupDelegate.firstLineHeight
                            anchors.horizontalCenter: parent.horizontalCenter

                            visible: model.callcount > 1

                            source: appTheme.image("dashboard-unread.png")
                            border { left: 9; right: 9; top: 0; bottom: 0 }
                            horizontalTileMode: BorderImage.Stretch
                            verticalTileMode: BorderImage.Stretch

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                color: 'white'
                                font.bold: true
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                text: model.callcount
                            }
                        }

                        // The camera from the Video tab: the list's own marker
                        // is drawn for 12 px and is lost at this size.
                        ClippedImage {
                            id: videoMarker
                            objectName: "videoMarker"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: callGroupDelegate.firstLineHeight + callGroupDelegate.lineGap
                               + (Math.max(lowerLines.height, height) - height) / 2
                            wantedWidth: Units.gu(3)
                            wantedHeight: Units.gu(3)
                            source: appTheme.image("menu-icon-video.png")
                            patchGridSize: Qt.size(1, 2)
                            patch: Qt.point(0, 0)
                            visible: callGroupDelegate.isSynergyCall &&
                                     !!callGroupDelegate.callTransports &&
                                     callGroupDelegate.callTransports.supportsVideo(callGroupDelegate.callService)
                        }
                    }
                }

                // What kind of call it was over when it was, as on the Pre's
                // call log. The type is coloured here, because this is the
                // most recent call; the ones inside the drawer are grey.
                Item {
                    Layout.preferredWidth: Units.gu(5)
                    Layout.fillHeight: true

                    Item {
                        width: parent.width
                        height: textLines.height
                        anchors.verticalCenter: parent.verticalCenter

                        ClippedImage {
                            objectName: "callTypeIcon"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (callGroupDelegate.firstLineHeight - height) / 2

                            source: appTheme.image("call-log-list-sprite.png")
                            wantedWidth: Units.gu(2.2)
                            wantedHeight: Units.gu(2.2)
                            // Sized from the image; the two artwork sets differ.
                            patchGridSize: Qt.size(1, 4)
                            patch: (model.recentcall_type === "missed") ? Qt.point(0,0) :
                                   (model.recentcall_type === "incoming") ? Qt.point(0,1) :
                                   (model.recentcall_type === "ignored") ? Qt.point(0,3) : Qt.point(0,2)
                        }

                        Text {
                            objectName: "timeText"
                            width: parent.width
                            y: callGroupDelegate.firstLineHeight + callGroupDelegate.lineGap
                            horizontalAlignment: Text.AlignHCenter
                            color: appTheme.callLogDetailColor
                            font.pixelSize: FontUtils.sizeToPixels("small")

                            property date timeStamp: new Date(model.timestamp)
                            text: Qt.formatTime(timeStamp, Qt.locale().timeFormat(Locale.ShortFormat))
                        }
                    }
                }

                // Opens the individual calls in this group.
                Item {
                    Layout.preferredWidth: Units.gu(3.4)
                    Layout.preferredHeight: Units.gu(3.4)

                    ClippedImage {
                        anchors.centerIn: parent
                        source: appTheme.image("expand-button.png")
                        wantedWidth: Units.gu(3.4)
                        wantedHeight: Units.gu(3.4)
                        imageSize: Qt.size(50, 100)
                        patchGridSize: Qt.size(1, 2)
                        patch: expandArea.pressed ? Qt.point(0,1) : Qt.point(0,0)
                        rotation: callgroupDetail.active ? 180 : 0
                    }

                    MouseArea {
                        id: expandArea
                        anchors.fill: parent
                        onClicked: callgroupDetail.active = !callgroupDetail.active
                    }
                }
            }

            // Tapping the row calls back over whichever account it used;
            // dragging it sideways reveals the delete button.
            MouseArea {
                id: rowArea
                anchors.fill: parent
                z: -1

                property real _pressX: 0

                onPressed: (mouse) => { _pressX = mouse.x; }
                onReleased: (mouse) => {
                    var delta = mouse.x - _pressX;

                    if (delta < -Units.gu(4)) {
                        callGroupDelegate.pendingDelete = true;
                    } else if (delta > Units.gu(4)) {
                        callGroupDelegate.pendingDelete = false;
                    } else if (!callGroupDelegate.pendingDelete &&
                               callGroupDelegate.dialHandler && callGroupDelegate.contactAddress.addr) {
                        callGroupDelegate.dialHandler.dial(callGroupDelegate.contactAddress.addr,
                                                           callGroupDelegate.isSynergyCall ? callGroupDelegate.callService : "",
                                                           false);
                    }
                }
            }
        }
    }

    Loader {
        id: callgroupDetail

        width: parent.width
        active: false
        visible: active

        sourceComponent: Component {
            CallGroupDetails {
                appTheme: callGroupDelegate.appTheme
                callGroupId: callGroupDelegate.callGroupId
                callGroupRemotePerson: callGroupDelegate.remotePerson
                callGroupAddress: callGroupDelegate.contactAddress
                contacts: callGroupDelegate.contacts
                dialHandler: callGroupDelegate.dialHandler
                callTransports: callGroupDelegate.callTransports
            }
        }
    }

    // Closes the group off, after its drawer rather than before it -- an open
    // drawer belongs to the row above it. Left out before a day header, which
    // brings its own rule.
    ListSeparator {
        appTheme: callGroupDelegate.appTheme
        width: parent.width
        drawn: !callGroupDelegate.lastOfDay
    }
}
