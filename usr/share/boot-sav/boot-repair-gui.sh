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

########################## mainwindow filling ##########################################
mainwindow_filling() {
if [[ "$GUI" ]];then
    echo 'SET@_vbox_bootrepairmenu.show()'
    echo "SET@_label_bootrepairsubtitle.set_markup('''<b>$Repair_the_boot_of_the_computer</b>''')"
    echo "SET@_label_recommendedrepair.set_text('''${Recommended_repair}\\n($repairs_most_frequent_problems)''')"
    echo "SET@_label_justbootinfo.set_text('''${Create_a_BootInfo_report}\\n($to_get_help_by_email_or_forum)''')"
#    echo "SET@_label_pastebin.set_text('''$Create_a_BootInfo_report ($to_get_help_by_email_or_forum)''')"
    echo 'SET@_vbox_pastebin.show()'
    echo "SET@_label_appname.set_markup('''<b><big>Boot-Repair</big></b>''')" #${APPNAME_VERSION%~*}
    echo "SET@_label_appdescription.set_text('''$Repair_the_boot_of_the_computer''')"
    echo 'SET@_logobr.show()'
    echo 'SET@_logo_brmenu.show()'
    echo "SET@_linkbutton_websitebr.show()"
    echo "SET@_label_repairfilesystems.set_text('''$Repair_file_systems''')"
    [[ "$(lsb_release -is)" != Debian ]] && echo 'SET@_checkbutton_repairfilesystems.show()'
    echo "SET@_label_wubi.set_text('''$Repair_Wubi''')"
    echo 'SET@_checkbutton_wubi.show()'
fi
common_labels_fillin
set_easy_repair
}

set_easy_repair_diff() {
MAIN_MENU=Recommended-Repair
set_easy_repair_diff_br_and_bi
}	


_button_recommendedrepair() {
_button_mainapply
}

_button_justbootinfo() {
justbootinfo_br_and_bi
}


_checkbutton_repairfilesystems() {
if [[ "${@}" = True ]]; then
	FSCK_ACTION=" repair-filesystems"
	if [[ ! "$ROOTDISKMISSING" ]];then
        echo "$Please_backup_data"
        [[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$Please_backup_data" 2>/dev/null
    fi
else
	FSCK_ACTION=""
fi
[[ "$DEBBUG" ]] && echo "[debug]FSCK_ACTION becomes: $FSCK_ACTION"
}

_checkbutton_wubi() {
[[ "${@}" = True ]] && WUBI_ACTION=" repair-wubi" || WUBI_ACTION=""
[[ "$DEBBUG" ]] && echo "[debug]WUBI_ACTION becomes: $WUBI_ACTION"
}

############# Pastebinit
_checkbutton_pastebin() {
[[ "${@}" = True ]] && PASTEBIN_ACTION=create-bootinfo || PASTEBIN_ACTION=""
[[ "$DEBBUG" ]] && echo "[debug]PASTEBIN_ACTION becomes: $PASTEBIN_ACTION"
}
