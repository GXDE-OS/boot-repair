#! /bin/bash
# Copyright 2017 Yann MRN
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

#Dummy librairies in case boot-sav-extra is not installed

first_translations_extra() {
[[ "$DEBBUG" ]] && echo "[debug]first_translations_extra"
}

lastgrub_extra() {
[[ "$DEBBUG" ]] && echo "[debug]lastgrub_extra"
}

grub_purge_extra() {
[[ "$DEBBUG" ]] && echo "[debug]grub_purge_extra"
}

activate_hide_lastgrub_if_necessary() {
unset_checkbutton_lastgrub;
[[ "$GUI" ]] && echo 'SET@_checkbutton_lastgrub.hide()'
[[ "$DEBBUG" ]] && echo "[debug]LASTGRUB_ACTION becomes: $LASTGRUB_ACTION"
}

repair_boot_ini_nonfree() {
[[ "$DEBBUG" ]] && echo "[debug] repair_boot_ini_nonfree"
}

installpackagelist_extra() {
[[ "$DEBBUG" ]] && echo "[debug] installpackagelist_extra"
}

repair_dep() {
[[ "$DEBBUG" ]] && echo "[debug] repair_dep"
}

restore_dep() {
[[ "$DEBBUG" ]] && echo "[debug] restore_dep"
}

update_soft() {
}
