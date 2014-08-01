/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
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

/*
 * A simple phone number formatter. Doesn't take into account different locales etc.
 * (123) 456 - 7890
 */
function formatPhoneNumber(number) {

    var numbers = number.replace(/\D/g, '');
    var c = { 0:'(', 3:') ', 6: ' - '};
    var result = '';
    for (var i = 0; i < numbers.length; i++) {
        result += (c[i]||'') + numbers[i];
    }

    return result;
}
