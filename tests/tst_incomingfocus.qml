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
import QtQuick.Controls 2.0
import QtTest 1.2

import "../qml/views"
import "../qml/model"
import "../qml/services"

/**
 * No text field holds the focus while the incoming call page is up: the
 * on-screen keyboard comes up for whichever field has it, over the answer and
 * decline buttons (sargo, 2026-11-07: the call rang out behind it).
 *
 * - the page takes the focus from a field as it is shown;
 * - and back from a field that takes it while the page is up;
 * - the dialer's keyboard proxy, which takes the focus back whenever it loses
 *   it while the dialer shows, leaves it with the page;
 * - with the page gone, fields work as before.
 */
Item {
    id: root
    width: 480
    height: 800

    TestCase {
        name: "IncomingFocus"
        when: windowShown

        PhoneUiTheme { id: theme }
        Contact { id: caller; lineId: "8:someone" }
        CallTransports { id: transports }

        Component {
            id: fieldComponent
            TextField { width: 200; height: 40 }
        }
        Component {
            id: pageComponent
            IncomingCallPage { width: 480; height: 800 }
        }
        Component {
            id: dialerComponent
            DialerPage { appTheme: theme; width: 480; height: 800 }
        }

        function field() {
            var f = createTemporaryObject(fieldComponent, root);
            verify(f !== null, "the field did not load");
            f.forceActiveFocus();
            verify(f.activeFocus, "the field took no focus to begin with");
            return f;
        }

        function page() {
            var p = createTemporaryObject(pageComponent, root,
                                          { appTheme: theme, currentContact: caller,
                                            callTransports: transports });
            verify(p !== null, "the page did not load");
            return p;
        }

        function test_thePageTakesTheFocusFromAField() {
            var f = field();
            var p = page();
            verify(p.activeFocus);
            verify(!f.activeFocus);
        }

        function test_aFieldDoesNotKeepTheFocusWhileThePageIsUp() {
            var f = field();
            var p = page();
            f.forceActiveFocus();
            tryVerify(function() { return p.activeFocus && !f.activeFocus; }, 1000);
        }

        function test_theDialerLeavesTheFocusWithThePage() {
            var d = createTemporaryObject(dialerComponent, root);
            verify(d !== null, "the dialer did not load");
            d.takeKeyFocus();
            var p = page();
            verify(p.activeFocus);
            wait(100);                      // the dialer's refocus timer has had its turn
            verify(p.activeFocus, "the dialer took the focus back");
        }

        function test_withThePageHiddenAFieldKeepsTheFocus() {
            var f = field();
            var p = page();
            p.visible = false;
            f.forceActiveFocus();
            wait(50);
            verify(f.activeFocus);
        }
    }
}
