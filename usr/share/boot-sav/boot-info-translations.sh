#! /bin/bash
# Copyright 2011-2023 Yann MRN
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

first_translations_diff() {
APPNAME2=$(eval_gettext $'Boot-Info')  #For .desktop & more
diagnose_boot=$(eval_gettext $'Diagnose the boot of the computer')
create_report=$(eval_gettext $'Create a report about the boot of the computer')
Text_report=$(eval_gettext $'Local report (text file)')
Url_report=$(eval_gettext $'Online report (pastebin URL)')
#SF
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'${APPNAME}, simple tool to diagnose the boot of the computer')
sf=$(eval_gettext $'Easy-to-use (1 click ! )')
sf=$(eval_gettext $'Helpful (helps to get help by email or on your favorite forum)')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'Launch ${APPNAME}, then choose the type of report you prefer (either local or online).')
}

update_translations_diff() {
sf=0
}
