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

import QtQuick 2.0
import QtTest 1.2

import "../qml/views"
import "../qml/services"

/**
 * The preferences page does what the legacy scene did: forwarding is a
 * switch with the number under it, caller ID is "show", a change the
 * network turns down puts the switch back, and dialing shortcuts are a list
 * with an editor of their own.
 */
Item {
    width: 720
    height: 2000

    PhoneUiTheme { id: theme }
    TelephonyManager { id: telephony }
    SupplementaryServices { id: supplementary }
    DialingShortcuts { id: shortcuts }
    CallTransports { id: transports }

    PhonePrefsPage {
        id: page
        anchors.fill: parent
        appTheme: theme
        telephonyManager: telephony
        supplementaryServices: supplementary
        dialingShortcuts: shortcuts
        callTransports: transports
    }

    TestCase {
        name: "PrefsPage"
        when: windowShown

        function findAll(item, pred, acc) {
            acc = acc || [];
            if (!item)
                return acc;
            if (pred(item))
                acc.push(item);
            var kids = [];
            for (var i = 0; i < item.children.length; i++) kids.push(item.children[i]);
            if (item.contentItem && item.contentItem !== item && kids.indexOf(item.contentItem) < 0)
                kids.push(item.contentItem);
            for (var j = 0; j < kids.length; j++) findAll(kids[j], pred, acc);
            return acc;
        }
        function row(label) {
            return findAll(page, function(o) { return o.label === label || o.text === label; })[0];
        }
        function shown(item) {
            for (var o = item; o && o !== page; o = o.parent)
                if (!o.visible)
                    return false;
            return true;
        }
        function toggle(sw) {
            sw.toggle();
            sw.toggled();
        }
        function numberField(numberRow) {
            return findAll(numberRow, function(o) { return o.hasOwnProperty("echoMode"); })[0];
        }

        function init() {
            supplementary.callForwardingUnconditional = "";
            supplementary.hideCallerId = "default";
            supplementary.callWaiting = "disabled";
            page._forwardOpen = false;
            wait(20);
        }

        function test_forwarding_number_shows_with_the_switch() {
            var sw = row("Call Forwarding");
            verify(shown(sw));
            compare(sw.checked, false);
            var forwardRow = findAll(page, function(o) { return o.placeholderText === "Enter Number"; })[0];
            var field = numberField(forwardRow);
            verify(!shown(forwardRow), "the number field is up while forwarding is off");

            toggle(sw);
            verify(shown(forwardRow), "switching forwarding on does not ask for the number");
            compare(supplementary.callForwardingUnconditional, "", "forwarded before there was a number");

            field.forceActiveFocus();
            field.text = "+31612345678";
            field.textEdited();
            field.editingFinished();
            compare(supplementary.callForwardingUnconditional, "+31612345678");

            toggle(sw);
            compare(sw.checked, false);
            compare(supplementary.callForwardingUnconditional, "", "switching off left forwarding on");
            verify(!shown(forwardRow));
        }

        function test_caller_id_is_shown_unless_hidden() {
            var sw = row("Show My Caller ID");
            compare(sw.checked, true, "the network default should read as shown");
            toggle(sw);
            compare(supplementary.hideCallerId, "enabled");
            toggle(sw);
            compare(supplementary.hideCallerId, "disabled");
        }

        function test_call_waiting() {
            var sw = row("Call Waiting");
            compare(sw.checked, false);
            toggle(sw);
            compare(supplementary.callWaiting, "enabled");
        }

        function test_a_refused_change_puts_the_switch_back() {
            var sw = row("Call Waiting");
            sw.toggle();              // the user's tap, which oFono then refuses
            compare(sw.checked, true);
            supplementary.callWaitingSet(false);
            compare(sw.checked, false);
        }

        // And keeps following the network after that
        function test_a_refused_change_leaves_the_switches_bound() {
            var waiting = row("Call Waiting");
            waiting.toggle();
            supplementary.callWaitingSet(false);
            supplementary.callWaiting = "enabled";
            compare(waiting.checked, true, "call waiting stopped following the network");

            var callerId = row("Show My Caller ID");
            callerId.toggle();
            supplementary.callerIdSet(false);
            supplementary.hideCallerId = "enabled";
            compare(callerId.checked, false, "caller ID stopped following the network");

            var forwarding = row("Call Forwarding");
            forwarding.toggle();
            supplementary.forwardingSet(false);
            supplementary.callForwardingUnconditional = "+31612345678";
            compare(forwarding.checked, true, "call forwarding stopped following the network");
        }

        function test_shortcuts_list_only_what_is_set() {
            tryVerify(function() { return shortcuts.hasShortcuts !== undefined; });
            var rows = findAll(page, function(o) { return o.hasOwnProperty("swipe") && o.hasOwnProperty("modelData"); });
            var set = shortcuts.supportedLengths.filter(function(l) { return shortcuts.prefixFor(l).length > 0; });
            compare(rows.length, set.length);
            for (var i = 0; i < rows.length; i++)
                verify(rows[i].contentItem.children[0].text.indexOf(shortcuts.prefixFor(rows[i].modelData)) === 0);
        }

        function test_adding_a_shortcut() {
            var add = row("+ Add a number");
            add.clicked();
            var editor = findAll(page, function(o) { return o.hasOwnProperty("sourceComponent") && o.active && o.item
                                                       && o.item.header && o.item.header.title === "Dialing Shortcuts"; })[0];
            verify(editor, "+ Add a number opened nothing");
            var lengths = findAll(editor.item, function(o) { return o.hasOwnProperty("values") && o.hasOwnProperty("chosen"); })[0];
            lengths.value = 6;
            var prefix = findAll(editor.item, function(o) { return o.placeholderText === "Enter Number"; })[0];
            prefix.text = "0201";
            var done = findAll(editor.item, function(o) { return o.hasOwnProperty("text") && o.text === "Done" && o.hasOwnProperty("clicked"); })[0];
            done.clicked();
            tryCompare(shortcuts, "hasShortcuts", true);
            tryVerify(function() { return shortcuts.prefixFor(6) === "0201"; }, 1000, "the shortcut was not stored");
            compare(editor.active, false);
        }

        function test_no_sim_says_so_instead_of_waiting() {
            var wasPresent = telephony.present;
            telephony.present = false;
            try {
                var noSim = findAll(page, function(o) { return o.text === "No SIM card" && o.hasOwnProperty("busy"); })[0];
                verify(noSim && shown(noSim), "no 'No SIM card' row in Calls");
                compare(noSim.busy, false);
                verify(!shown(row("Call Forwarding")));
                verify(!shown(row("Show My Caller ID")));
                var reading = findAll(page, function(o) { return o.text === "Reading from network" && shown(o); });
                compare(reading.length, 0, "still reading from a network there is no SIM for");
                var voicemail = findAll(page, function(o) { return o.placeholderText === "No SIM card"; })[0];
                verify(voicemail && shown(voicemail), "the voicemail field still waits for the network");
                compare(voicemail.enabled, false);
            } finally {
                telephony.present = wasPresent;
            }
        }

        function test_radio_off_says_so() {
            var wasOnline = telephony.radioOnline;
            telephony.radioOnline = false;
            try {
                var offline = findAll(page, function(o) { return o.text === "No network connection" && o.hasOwnProperty("busy"); })[0];
                verify(offline && shown(offline));
            } finally {
                telephony.radioOnline = wasOnline;
            }
        }

        function test_sim_lock_row_follows_the_sim() {
            verify(row("Lock SIM Card") || row("Unlock SIM Card") || row("PUK Required"));
            compare(!!row("Change SIM Card PIN") && shown(row("Change SIM Card PIN")), telephony.simPinLocked);
        }
    }
}
