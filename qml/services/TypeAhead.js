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

.pragma library

/**
 * Typing on a list page goes into that page's filter, without the user having
 * to put the cursor there first.
 *
 * On a device with a physical keyboard the keys are always under the thumbs,
 * so a list you have to tap a field on before you can search it is a list with
 * a step in it that the hardware does not need.
 *
 * The page holds key focus and calls this; the field is never focused. That is
 * deliberate and is the whole reason this exists rather than the page simply
 * handing focus to its field: focus on a text field is what brings the
 * on-screen keyboard up, and on a phone with keys of its own there is nothing
 * for it to do but cover the list being filtered. Tapping the field still
 * focuses it in the ordinary way, so a device without a keyboard loses
 * nothing.
 */

/**
 * Routes one key press into `field`.
 *
 * Returns true when the key was used, which the caller assigns to
 * event.accepted so that anything it did not want carries on to whatever else
 * was going to handle it.
 */
function handleKey(event, field) {
    if (!field)
        return false;

    // A chord is a command, not typing. Shift is not in that list: it is how
    // capitals are made, and the character arrives already capitalised.
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
        return false;

    if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
        // Only ours while there is something to rub out. An empty filter
        // leaves Backspace to mean whatever it means on this page -- going
        // back, most likely -- rather than swallowing it to no effect.
        if (field.text.length === 0)
            return false;

        field.text = field.text.slice(0, field.text.length - 1);
        return true;
    }

    if (event.key === Qt.Key_Escape) {
        if (field.text.length === 0)
            return false;

        field.text = "";
        return true;
    }

    /*
     * One printable character, and nothing else.
     *
     * event.text is empty for the arrow keys and the modifiers, and holds a
     * control character for Return, Tab and the like -- none of which is
     * something to search for, and Return in particular has to stay available
     * to the row that is selected.
     */
    var text = event.text;
    if (text.length !== 1)
        return false;

    var code = text.charCodeAt(0);
    if (code < 0x20 || code === 0x7f)
        return false;

    field.text += text;
    return true;
}
