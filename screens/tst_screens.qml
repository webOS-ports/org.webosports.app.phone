/*
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

import QtQuick 2.15
import QtTest 1.2

import LunaNext.Common 0.1

/**
 * The app's screens on one device, as a user gets to them, each saved as a
 * picture: build/test-output/screens/<profile>-<screen>.png.
 *
 * run-tests.sh runs this once per device in PROFILES, each time against a
 * copy of luneos-components' LunaNext.Common whose default profile is that
 * device. It cannot be one run with Settings.setProfile(): Units and
 * FontUtils read the grid unit once, as they load, so a profile switched
 * afterwards moves the screen size and leaves every size inside it at the
 * desktop's.
 *
 * The whole app is built, main.qml as the desktop host builds it, against
 * the stand-ins in luneos-components/test/imports: the mock modem, nemo
 * voicecall (a number dialled becomes a call; "111" rings in), db8 with
 * the sample records in qml/test. Nothing here needs a device.
 *
 * Besides the pictures each screen is checked for what breaks a layout at
 * a size: the page there, inside the window, nothing that matters with no
 * size, nothing wider than the screen.
 */
TestCase {
    id: testCase
    name: "Screens"
    when: windowShown

    readonly property string profile: Settings.profileName
    readonly property string shotDir: decodeURIComponent(
        Qt.resolvedUrl("../build/test-output/screens").toString().replace(/^file:\/\//, ""))

    // The software renderer draws no shader effects, so what is drawn
    // through one cannot be looked for in its pictures.
    readonly property int graphicsApi: GraphicsInfo.api

    property var app: null
    property var win: null

    function init_data() {
        return [{ tag: profile + " " + Settings.displayWidth + "x" + Settings.displayHeight }];
    }

    // The phone window is one of main.qml's children, not a property of it.
    function phoneWindow(root) {
        for (var i = 0; i < root.data.length; ++i) {
            var o = root.data[i];
            if (o && typeof o.showCallLog === "function" && typeof o.incomingCall === "function")
                return o;
        }
        return null;
    }

    function initTestCase() {
        var component = Qt.createComponent(Qt.resolvedUrl("../qml/main.qml"));
        compare(component.status, Component.Ready, component.errorString());
        app = component.createObject(testCase, { runningOnDesktop: true, launchParams: "{}" });
        verify(app, "main.qml");
        win = phoneWindow(app);
        verify(win, "the phone window");
        app.launchServices.ui.showDialpad();
        tryVerify(function() { return win.visible && win.width > 0; }, 3000, "the phone window is up");
        compare(win.width, Settings.displayWidth);
        compare(win.height, Settings.displayHeight);
    }

    function cleanupTestCase() {
        var vcm = app ? app.launchServices.voiceCallManager : null;
        if (vcm)
            vcm.hangupAll();
        if (app)
            app.destroy();
    }

    // A test that failed half way must not leave its call to the next.
    function cleanup() {
        var vcm = app.launchServices.voiceCallManager;
        if (vcm.callCount > 0) {
            vcm.hangupAll();
            tryVerify(function() { return vcm.callCount === 0; }, 3000, "calls left over hung up");
            settle();
        }
    }

    // Depth first, so the first match is the one a user sees first.
    function findAll(item, pred, out) {
        out = out || [];
        if (!item)
            return out;
        if (pred(item))
            out.push(item);
        var kids = item.children || [];
        for (var i = 0; i < kids.length; ++i)
            findAll(kids[i], pred, out);
        return out;
    }

    // Drawn in the phone window: every item up to its content item visible.
    // A closed popup's item can stay visible with no parent, so reaching the
    // window is part of it.
    function shown(item) {
        for (var p = item; p; p = p.parent) {
            if (!p.visible || p.opacity === 0)
                return false;
            if (p === win.contentItem)
                return true;
        }
        return false;
    }

    function textItem(label) {
        var found = findAll(win.contentItem, function(i) {
            return i.text === label && i.width !== undefined && shown(i);
        });
        return found.length ? found[0] : null;
    }

    function clickText(label) {
        var item = null;
        tryVerify(function() { item = textItem(label); return item !== null; }, 3000, "\"" + label + "\" on screen");
        mouseClick(item);
        return item;
    }

    function inWindow(item, what) {
        verify(item, what + " is there");
        verify(shown(item), what + " is not shown");
        var r = item.mapToItem(win.contentItem, 0, 0);
        verify(item.width > 0 && item.height > 0,
               what + " has no size: " + item.width + "x" + item.height);
        verify(r.x >= -1 && r.y >= -1, what + " starts off screen at " + r.x + "," + r.y);
        verify(r.x + item.width <= win.width + 1 && r.y + item.height <= win.height + 1,
               what + " runs off screen: " + r.x + "," + r.y + " " + item.width + "x" + item.height
                    + " in " + win.width + "x" + win.height);
    }

    /// No text shown is wider than the window or starts off its sides,
    /// unless it is elided or wraps - those keep inside by themselves.
    function noTextOffSides(what) {
        var bad = findAll(win.contentItem, function(i) {
            if (typeof i.text !== "string" || i.text.length === 0 || i.contentWidth === undefined
                    || i.width === undefined || !shown(i))
                return false;
            // Scrolled away inside a list or a flickable is not off screen.
            for (var p = i.parent; p; p = p.parent) {
                if (p.contentY !== undefined && p.clip)
                    return false;
            }
            var r = i.mapToItem(win.contentItem, 0, 0);
            var drawn = (i.elide !== undefined && i.elide !== Text.ElideNone)
                    || (i.wrapMode !== undefined && i.wrapMode !== Text.NoWrap)
                    ? Math.min(i.width, i.contentWidth) : i.contentWidth;
            var left = r.x + (i.horizontalAlignment === Text.AlignRight ? i.width - drawn
                            : i.horizontalAlignment === Text.AlignHCenter ? (i.width - drawn) / 2 : 0);
            return left < -1 || left + drawn > win.width + 1;
        });
        var names = bad.map(function(i) {
            var r = i.mapToItem(win.contentItem, 0, 0);
            return "\"" + i.text + "\" at " + Math.round(r.x) + ", " + Math.round(i.contentWidth)
                    + " wide in " + Math.round(i.width);
        });
        compare(names.join(", "), "", what + ": text off the sides");
    }

    function shot(name) {
        settle();
        var done = false;
        var ok = win.contentItem.grabToImage(function(result) {
            result.saveToFile(shotDir + "/" + profile + "-" + name + ".png");
            done = true;
        });
        verify(ok, "grab " + name);
        tryVerify(function() { return done; }, 5000, "saved " + name);
    }

    function settle() {
        wait(400);  // the pages and popups animate in
    }

    // Off any call screen or page, on a tab with no keypad up.
    function backToTabs() {
        app.launchServices.ui.showFavorites();
        settle();
    }

    // The keypad, as the Phone tab (a handset) or the Dialpad button (a
    // tablet) puts it up - and as a "dial" launch does.
    function toDialpad() {
        app.launchServices.ui.showDialpad();
        settle();
    }

    function test_1_dialer() {
        toDialpad();
        var pad = findChild(win.contentItem, "numPad");
        verify(pad, "the keypad");
        tryVerify(function() { return shown(pad); }, 3000, "the keypad shows");
        inWindow(pad, "the keypad");
        var dial = findChild(win.contentItem, "dialButton");
        inWindow(dial, "the dial button");
        inWindow(findChild(win.contentItem, "numberEntry"), "the number field");
        shot("dialer");
        noTextOffSides("dialer");
        // However tall the screen, a key is no taller than it is wide, and
        // the letters under each digit keep inside their key.
        verify(pad.keysHeight <= pad.keysWidth + 1,
               "a key is " + pad.keysWidth + " wide and " + pad.keysHeight + " tall");
        var subs = findAll(pad, function(i) { return i.objectName === "subLabel" && shown(i); });
        verify(subs.length > 0, "the letters under the digits");
        for (var i = 0; i < subs.length; ++i) {
            var key = subs[i].parent;
            var x = subs[i].mapToItem(key, 0, 0).x + (subs[i].width - subs[i].contentWidth) / 2;
            verify(x >= Units.gu(0.5) && x + subs[i].contentWidth <= key.width - Units.gu(0.5),
                   "\"" + subs[i].text + "\" inside its key: " + Math.round(x) + ", "
                       + Math.round(subs[i].contentWidth) + " wide in " + key.width);
        }

        // A number typed: the field, and the contacts it matches.
        findChild(win.contentItem, "numberEntry").text = "555";
        shot("dialer-number");
        noTextOffSides("dialer with a number");
        findChild(win.contentItem, "numberEntry").text = "";
    }

    function test_2_contacts() {
        toDialpad();
        // A tap in the empty number field asks for the contact list.
        var entry = findChild(win.contentItem, "numberEntry");
        mouseClick(entry);
        settle();
        shot("contacts");
        var pad = findChild(win.contentItem, "numPad");
        // On a handset the keypad is put straight back: PhoneTabView closes
        // it for the lookup, then showContacts() -> syncDialpad() opens it
        // again because the Phone tab is showing. The list behind it cannot
        // be reached. Left to the app; marked here so a fix shows up.
        if (!Settings.tabletUi)
            expectFail("", "on a handset the keypad comes back over the contact list");
        verify(!shown(pad), "the keypad makes way for the contact list");
        noTextOffSides("contacts");
    }

    // The contacts that can be called over video, a tab of its own when an
    // account offers video.
    function test_2b_video_contacts() {
        backToTabs();
        var tab = textItem(qsTr("Video"));
        if (!tab)
            skip("no video service in the stand-in accounts");
        mouseClick(tab);
        settle();
        shot("video-contacts");
        verify(!shown(findChild(win.contentItem, "numPad")), "the keypad is not over the video tab");
        noTextOffSides("video contacts");
    }

    function test_3_favorites() {
        backToTabs();
        clickText(qsTr("Favorites"));
        settle();
        shot("favorites");
        noTextOffSides("favorites");
    }

    function test_4_call_log() {
        backToTabs();
        clickText(qsTr("Call Log"));
        settle();
        shot("call-log");
        var rows = [];
        tryVerify(function() {
            rows = findAll(win.contentItem, function(i) { return i.objectName === "nameText" && shown(i); });
            return rows.length > 0;
        }, 3000, "the call log has its rows");
        inWindow(rows[0], "the first call log row's name");
        var filter = findAll(win.contentItem, function(i) {
            return i.placeholderText === qsTr("Filter") && shown(i);
        })[0];
        inWindow(filter, "the call log's filter field");
        noTextOffSides("call log");
    }

    /**
     * A settings page longer than the screen scrolls, by a finger, all the
     * way to its last row, and that row ends above the Done bar rather than
     * under it. The end gets a picture of its own.
     */
    function scrollsAboveDone(name) {
        var content = findAll(win.contentItem, function(i) {
            return i.maximumContentWidth !== undefined && i.contentHeight !== undefined && shown(i);
        })[0];
        verify(content, name + ": the page's content");
        var done = textItem(qsTr("Done"));
        verify(done, name + ": the Done bar");
        var doneTop = done.mapToItem(win.contentItem, 0, 0).y;
        var top = content.mapToItem(win.contentItem, 0, 0).y;
        verify(top + content.height <= doneTop + 1,
               name + ": the content ends at " + (top + content.height) + ", under Done at " + doneTop);
        for (var i = 0; i < 30 && content.contentHeight > content.height && !content.atYEnd; ++i) {
            mouseDrag(content, content.width / 2, content.height * 0.8, 0, -content.height * 0.6);
            wait(50);
        }
        tryVerify(function() { return content.contentHeight <= content.height || content.atYEnd; }, 3000,
                  name + ": scrolls to its end, at " + content.contentY + " of "
                      + (content.contentHeight - content.height));
        shot(name + "-end");
        content.contentY = 0;
    }

    function test_5_app_menu_and_preferences() {
        backToTabs();
        win.openAppMenu();
        settle();
        shot("app-menu");
        clickText(qsTr("Phone Preferences"));
        settle();
        shot("preferences");
        noTextOffSides("preferences");
        scrollsAboveDone("preferences");
        clickText(qsTr("Done"));
        settle();
        verify(!textItem(qsTr("Phone Preferences")), "Done closes the preferences");

        win.openAppMenu();
        settle();
        clickText(qsTr("Phone Accounts"));
        settle();
        shot("accounts");
        noTextOffSides("accounts");
        scrollsAboveDone("accounts");
        clickText(qsTr("Done"));
        settle();
        verify(!textItem(qsTr("Phone Accounts")), "Done closes the accounts");
    }

    function test_6_in_call() {
        backToTabs();
        var vcm = app.launchServices.voiceCallManager;
        toDialpad();
        findChild(win.contentItem, "numberEntry").text = "+15551234567";
        mouseClick(findChild(win.contentItem, "dialButton"));
        // The stand-in has messaging accounts besides the modem and nothing
        // remembered, so the app asks which service to call over.
        var chooser = null;
        tryVerify(function() {
            chooser = findAll(win.contentItem, function(i) {
                return typeof i.ask === "function" && typeof i._choose === "function";
            })[0];
            return chooser && chooser.visible;
        }, 3000, "which service to call over");
        shot("choose-service");
        noTextOffSides("which service");
        chooser._choose(chooser.callTransports.cellularTransport);
        var card = null;
        tryVerify(function() {
            card = findChild(win.contentItem, "callCard");
            return card !== null && shown(card);
        }, 3000, "the call screen");
        shot("dialling");
        // Answered at the other end.
        vcm.callAt(0).status = 1;  // VoiceCall.STATUS_ACTIVE
        shot("in-call");
        inWindow(card, "the call card");
        var hangup = findChild(win.contentItem, "hangupArea");
        verify(hangup, "the hang-up button");
        inWindow(hangup, "the hang-up button");
        noTextOffSides("in call");
        vcm.hangupAll();
        tryVerify(function() { return vcm.callCount === 0; }, 3000, "the call is over");
        settle();
    }

    /**
     * The caller's photo, or the unknown-caller stand-in, fills its square in
     * the frame: the picture differs from the frame alone in the middle of
     * the square and near its top edge, where a stand-in fitted rather than
     * cropped left a band of bare frame.
     */
    function callerPhotoDrawn() {
        var photo = findChild(win.contentItem, "callerPhoto");
        var shape = findChild(win.contentItem, "callerPhotoShape");
        verify(photo && shape, "the caller's photo");
        compare(photo.status, Image.Ready, "the caller's photo loads: " + photo.source);
        if (graphicsApi === GraphicsInfo.Software) {
            console.warn("the software renderer draws no CornerShader; not looking for the photo");
            return;
        }
        var r = photo.mapToItem(win.contentItem, 0, 0);
        var points = [[0.5, 0.5], [0.5, 0.06]];
        function sample(img) {
            return points.map(function(p) {
                return img.pixel(Math.round(r.x + photo.width * p[0]), Math.round(r.y + photo.height * p[1]));
            });
        }
        var withPhoto = sample(grabImage(win.contentItem));
        shape.visible = false;
        wait(50);
        var without = sample(grabImage(win.contentItem));
        shape.visible = true;
        for (var i = 0; i < points.length; ++i)
            verify(!Qt.colorEqual(withPhoto[i], without[i]),
                   "the photo is drawn at " + points[i] + " of its square: " + withPhoto[i] + " as the bare frame");
    }

    function test_7_incoming_call() {
        backToTabs();
        var vcm = app.launchServices.voiceCallManager;
        vcm.manager.dial("provider", "111");  // the stand-in rings in
        tryVerify(function() { return vcm.callCount === 1; }, 3000, "a call rings");
        settle();
        // The window the user is in takes it in place; otherwise the strip,
        // a window of its own, has it.
        var alert = null;
        for (var i = 0; i < app.data.length; ++i) {
            var o = app.data[i];
            if (o && typeof o.present === "function" && typeof o.dismiss === "function" && o.visible)
                alert = o;
        }
        if (alert) {
            verify(alert.width > 0 && alert.height > 0, "the incoming call strip has a size");
            verify(alert.width <= Settings.displayWidth && alert.height <= Settings.displayHeight,
                   "the strip fits the screen: " + alert.width + "x" + alert.height);
            var done = false;
            alert.contentItem.grabToImage(function(result) {
                result.saveToFile(shotDir + "/" + profile + "-incoming-strip.png");
                done = true;
            });
            tryVerify(function() { return done; }, 5000, "saved incoming-strip");
        }
        // In the window the user is in, the call takes the page.
        win.incomingCall(vcm.callAt(0));
        settle();
        shot("incoming");
        noTextOffSides("incoming call");
        callerPhotoDrawn();
        vcm.hangupAll();
        tryVerify(function() { return vcm.callCount === 0; }, 3000, "the call is gone");
        settle();
    }
}
