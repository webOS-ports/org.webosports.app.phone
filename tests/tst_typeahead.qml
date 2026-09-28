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

import "../qml/services/TypeAhead.js" as TypeAhead

/**
 * Typing on a list page filters it.
 *
 * The page holds key focus and hands each press here, so what this decides is
 * what reaches the field and, just as much, what does not: a key this claims
 * is a key the page and its list never see.
 */
TestCase {
    name: "TypeAhead"

    /// Stands in for the search field: all the helper touches is `text`.
    QtObject {
        id: field
        property string text: ""
    }

    /// A key event as Keys.onPressed delivers one.
    function _event(key, text, modifiers) {
        return { key: key,
                 text: text === undefined ? "" : text,
                 modifiers: modifiers === undefined ? Qt.NoModifier : modifiers };
    }

    function init() { field.text = ""; }

    function test_a_printable_character_goes_into_the_field() {
        verify(TypeAhead.handleKey(_event(Qt.Key_B, "b"), field));
        verify(TypeAhead.handleKey(_event(Qt.Key_O, "o"), field));
        compare(field.text, "bo");
    }

    /// Shift is how capitals are made, so it is not treated as a chord: the
    /// character arrives already capitalised.
    function test_shift_still_types() {
        verify(TypeAhead.handleKey(_event(Qt.Key_B, "B", Qt.ShiftModifier), field));
        compare(field.text, "B");
    }

    /// A chord is a command. Ctrl+A is "select all" somewhere, never an "a".
    function test_a_chord_is_left_alone() {
        var chords = [Qt.ControlModifier, Qt.AltModifier, Qt.MetaModifier];
        for (var i = 0; i < chords.length; ++i) {
            verify(!TypeAhead.handleKey(_event(Qt.Key_A, "a", chords[i]), field),
                   "modifier " + chords[i] + " was typed");
        }
        compare(field.text, "");
    }

    function test_backspace_rubs_out_while_there_is_something_to_rub_out() {
        field.text = "ab";
        verify(TypeAhead.handleKey(_event(Qt.Key_Backspace), field));
        compare(field.text, "a");

        verify(TypeAhead.handleKey(_event(Qt.Key_Backspace), field));
        compare(field.text, "");

        // And then it is the page's again -- going back, most likely. Claiming
        // it here would swallow the key to no effect.
        verify(!TypeAhead.handleKey(_event(Qt.Key_Backspace), field));
    }

    function test_escape_clears_a_filter_and_nothing_else() {
        field.text = "abc";
        verify(TypeAhead.handleKey(_event(Qt.Key_Escape), field));
        compare(field.text, "");

        verify(!TypeAhead.handleKey(_event(Qt.Key_Escape), field));
    }

    /**
     * The keys a list page needs for itself.
     *
     * Return has to reach the selected row and the arrows have to scroll, so
     * none of them may be claimed. Return and Tab are the interesting ones:
     * they carry text, but it is a control character rather than anything
     * anyone would search for.
     */
    function test_the_keys_the_page_needs_are_left_alone() {
        var passed = [
            _event(Qt.Key_Return, "\r"),
            _event(Qt.Key_Enter, "\r"),
            _event(Qt.Key_Tab, "\t"),
            _event(Qt.Key_Up),
            _event(Qt.Key_Down),
            _event(Qt.Key_Left),
            _event(Qt.Key_Right),
            _event(Qt.Key_Shift),
            _event(Qt.Key_Call)
        ];

        for (var i = 0; i < passed.length; ++i)
            verify(!TypeAhead.handleKey(passed[i], field),
                   "key 0x" + passed[i].key.toString(16) + " was claimed");

        compare(field.text, "");
    }

    /// Digits and punctuation search too: a call log is full of numbers, and
    /// the filter matches them as readily as it matches a name.
    function test_digits_and_punctuation_type() {
        verify(TypeAhead.handleKey(_event(Qt.Key_0, "0"), field));
        verify(TypeAhead.handleKey(_event(Qt.Key_Plus, "+"), field));
        verify(TypeAhead.handleKey(_event(Qt.Key_Space, " "), field));
        compare(field.text, "0+ ");
    }

    /// Nothing to type into is not a crash.
    function test_no_field_is_not_an_error() {
        verify(!TypeAhead.handleKey(_event(Qt.Key_A, "a"), null));
    }
}
