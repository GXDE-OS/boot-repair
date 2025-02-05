#! /bin/bash
# Copyright 2013 Yann MRN
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
local fichier
if [[ "$GUI" ]];then
    echo 'SET@_hbox_osuninstallermenu.show()'
    echo 'SET@_hbox_format_partition.show()'
    echo 'SET@_button_mainapply.show()'
    echo 'SET@_image_main_options.hide()'
    echo 'SET@_checkbutton_repairfilesystems.hide()'
    echo 'SET@_checkbutton_pastebin.hide()'
    echo 'SET@_checkbutton_winboot.hide()'
    echo "SET@_label_appname.set_markup('''<b><big>OS-Uninstaller</big></b>''')" # ${APPNAME_VERSION%~*}
    echo "SET@_label_appdescription.set_text('''$remove_any_os_from_your_computer''')"
    echo 'SET@_logoos.show()'
    echo "SET@_linkbutton_websiteos.show()"
    echo "SET@_label_format_partition.set_text('''$Format_the_partition''')"
fi
####### Combo_format_partition fillin (Format partition) ########
if [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 1 ]] && [[ "$(grep -i windows <<< "${OS_TO_DELETE_NAME}" )" ]] \
|| [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 0 ]];then
    if [[ "$GUI" ]];then
        while read fichier; do
            echo "COMBO@@END@@_combobox_format_partition@@${fichier}"
        done < <(echo ext4; echo "NTFS (fast)"; echo FAT)
    fi
	FORMAT_TYPE=ext4
else
    if [[ "$GUI" ]];then
        while read fichier; do
            echo "COMBO@@END@@_combobox_format_partition@@${fichier}"
        done < <(echo "NTFS (fast)"; echo FAT; echo ext4 )
    fi
	FORMAT_TYPE="NTFS (fast)"
fi
[[ "$GUI" ]] && echo 'SET@_combobox_format_partition.set_active(0)'

#[[ "$GUI" ]] && echo "SET@_mainwindow.set_keep_above(True)"
common_labels_fillin
QTY_OF_PART_FOR_REINSTAL="$QTY_OF_OTHER_LINUX"
set_easy_repair

#Text for the window
[[ "$GUI" ]] && echo "SET@_mainwindow.set_title('''$APPNAME2''')"
#if [[ ! "$FINAL_TEXT" ]];then
	if [[ "$ADVISE_BOOTLOADER_UPDATE" = yes ]]; then
		FINAL_T="<b>$This_will_remove_OS_TO_DELETE\\n$Then_you_will_update_bootloader\\n$Are_you_ok_apply_changes</b>"
	else
		FINAL_T="<b>$Do_you_really_want_to_uninstall_OS_TO_DELETE</b>"
	fi
#fi
if [[ "$WUBI_TO_DELETE" ]];then
	if [[ "$WUBI_TO_DELETE" = manually_remove ]];then
		FINAL_T="$FINAL_T\\n$Wubi_will_be_lost"
	else
		FINAL_T="$FINAL_T\\n$This_will_also_delete_Wubi"
	fi
fi
update_final_uninstall_text
}

update_final_uninstall_text() {
if [[ "$FORMAT_OS" = hide-os ]];then
	FINAL_TEXT="$FINAL_T"
else
	[[ "$WUBI_TO_DELETE" ]] && [[ "$WUBI_TO_DELETE" != manually_remove ]] \
	&& [[ "$WUBI_TO_DELETE_PARTITION" != "$OS_TO_DELETE_PARTITION" ]] \
	&& FINAL_TEXT="$FINAL_T\\n$These_partitions_will_be_formatted" \
	|| FINAL_TEXT="$FINAL_T\\n$This_partition_will_be_formatted"
fi
[[ "$GUI" ]] && echo "SET@_label_osuninstallermenu.set_markup('''$FINAL_TEXT''')"
}

set_easy_repair_diff() {
MAIN_MENU=Recommended-Repair
FORMAT_OS=format-os; [[ "$GUI" ]] && echo 'SET@_checkbutton_format_partition.set_active(True)'
}

_checkbutton_format_partition() {
if [[ "${@}" = True ]];then
	FORMAT_OS=format-os; [[ "$GUI" ]] && echo 'SET@_combobox_format_partition.set_sensitive(True)'
else
	FORMAT_OS=hide-os; [[ "$GUI" ]] && echo 'SET@_combobox_format_partition.set_sensitive(False)'
fi
update_final_uninstall_text
echo "FORMAT_OS becomes : $FORMAT_OS"
}

_combobox_format_partition() {
FORMAT_TYPE="${@}"; echo "FORMAT_TYPE becomes : $FORMAT_TYPE"
}

############################### DETERMINE OS_TO_DELETE #####################################################
# inputs : all
# outputs : $OS_TO_DELETE_PARTITION , OS_TO_DELETE $OS_TO_DELETE
determine_os_to_delete() {
local i
OS_TO_DELETE=0
if [[ "$TOTAL_QTY_OF_OS_INCLUDING_WUBI" = 0 ]] && [[ "$LIVESESSION" = live ]];then
	echo "No OS on this computer."
	[[ "$GUI" ]] && zenity --width=400 --error --text="$No_OS_found_on_this_pc" 2>/dev/null
	choice=exit
    [[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r $TMP_FOLDER_TO_BE_CLEARED
	[[ "$GUI" ]] && echo 'EXIT@@' || exit 0
elif [[ "$TOTAL_QTY_OF_OS_INCLUDING_WUBI" = 1 ]];then
	OS_TO_DELETE=1
else
	for ((i=1;i<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;i++)); do
		echo "${OS__NAME[$i]} (${OS__PARTITION[$i]})" >> ${TMP_FOLDER_TO_BE_CLEARED}/tab
	done
	echo "TAB is $(cat ${TMP_FOLDER_TO_BE_CLEARED}/tab)"
	choice=""
    if [[ "$GUI" ]];then
        while [[ ! "$choice" ]];do
            choice=$(cat ${TMP_FOLDER_TO_BE_CLEARED}/tab | zenity --width=400 --list --hide-header --window-icon=x-os-uninstaller.png \
            --title="$APPNAME2" --text="$Which_os_do_you_want_to_uninstall" --column="" 2>/dev/null ) || unmount_all_partitions_and_quit_glade;
        done
    	for ((i=1;i<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;i++)); do
            [[ "$choice" = "${OS__NAME[$i]} (${OS__PARTITION[$i]})" ]] && OS_TO_DELETE="$i"
        done
    else
        #need to remove blanks
        options=($(for ((i=1;i<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;i++)); do 
            echo "${OS__NAME[$i]} (${OS__PARTITION[$i]})" | sed 's/ /-/g' ;
        done))
        echo "$Which_os_do_you_want_to_uninstall"
        PS3="Enter the corresponding number: "
        select opt in "${options[@]}" "Quit"; do 
            case "$REPLY" in
            1 ) echo "You picked $opt which is option $REPLY"; OS_TO_DELETE=$REPLY; break ;;
            2 ) echo "You picked $opt which is option $REPLY"; OS_TO_DELETE=$REPLY; break ;;
            $(( ${#options[@]}+1 )) ) echo "Goodbye!"; unmount_all_partitions_and_quit_glade; break;;
            *) echo "You picked $opt which is option $REPLY"; OS_TO_DELETE=$REPLY ;break;;
            esac
        done
    fi
fi
OS_TO_DELETE_NAME="${OS__NAME[$OS_TO_DELETE]}"
OS_TO_DELETE_PARTITION="${OS__PARTITION[$OS_TO_DELETE]}"
echo "OS to delete: ${OS_TO_DELETE_NAME} (on $OS_TO_DELETE_PARTITION , disk ${OS__DISK[$OS_TO_DELETE]})"
}

########################## ACTIONS DEPENDING ON USER CHOICE ##########################################
# inputs : all
# outputs : $choice=exit if wubi
case_os_to_delete_is_wubi() {
if [[ "${OS__NAME[$OS_TO_DELETE]}" = Ubuntu_Wubi ]];then
	echo "$Wubi_not_supported\\n\\n$Wubi_see_for_more_info"
	[[ "$GUI" ]] && zenity --width=400 --info --timeout=4 --title="$APPNAME2" --text="$Wubi_not_supported\\n\\n$Wubi_see_for_more_info" 2>/dev/null
	unmount_all_partitions_and_quit_glade
fi
}

########################## ACTIONS DEPENDING ON USER CHOICE ##########################################
# inputs : all
# outputs : $choice=exit if wubi
case_os_to_delete_is_currentlinux() {
if [[ "$OS_TO_DELETE_PARTITION" = "$CURRENTSESSIONPARTITION" ]] && [[ "$LIVESESSION" != live ]];then
	echo "$Please_use_in_live_session"
	[[ "$GUI" ]] && zenity --width=400 --info --timeout=4 --title="$APPNAME2" --text="$Please_use_in_live_session" 2>/dev/null
	unmount_all_partitions_and_quit_glade
fi
}

####################### CHECKS IF THERE ARE OTHER LINUX (WITH GRUB) ####################
#QTY_OF_OTHER_LINUX is useful for os-uninstaller
determine_qty_of_other_linux_with_grub() {
local j
QTY_OF_OTHER_LINUX=0
for ((j=1;j<=QTY_OF_PART_WITH_GRUB;j++)); do
	if [[ "${LISTOFPARTITIONS[${LIST_OF_PART_WITH_GRUB[$j]}]}" != "$OS_TO_DELETE_PARTITION" ]]; then 
		(( QTY_OF_OTHER_LINUX += 1 ))
		#LIST_OF_OTHER_LINUX[$QTY_OF_OTHER_LINUX]="${LIST_OF_PART_WITH_GRUB[$j]}"	#List of other Linux with GRUB
	fi
done
echo "There are $QTY_OF_OTHER_LINUX other Linux (with GRUB) on this computer"
}

########################## Check if the OS to delete is linked to a Wubi install ##########################
# inputs : all
# outputs : WUBI_TO_DELETE
check_OS_linked_to_wubi() {
local i
WUBI_TO_DELETE=""
if [[ -f "${OS__MNT_PATH[$OS_TO_DELETE]}/wubildr" ]];then
	echo "The OS to uninstall contains a Wubi"; WUBI_TO_DELETE=manually_remove
	if [[ "$QTY_WUBI" = 1 ]]; then
		WUBI_TO_DELETE=1; echo "Only 1 Wubi detected, so we choose it"
	else
		for ((i=1;i<=QTY_WUBI;i++)); do 
			if [[ "${OS__PARTITION[${WUBI[$i]}]}" = "$OS_TO_DELETE_PARTITION" ]];then
				WUBI_TO_DELETE="$i"
				echo "Several Wubi, but only 1 Wubi inside the Windows to delete, so we normally format it with Windows."
			fi
		done
	fi  
	if [[ "$WUBI_TO_DELETE" = manually_remove ]];then 
		echo "Several Wubi but no one inside Windows partition, so we don't delete any Wubi as we don't know how to choose the right Wubi"
	fi
	WUBI_TO_DELETE_PARTITION="${OS__PARTITION[${WUBI[$WUBI_TO_DELETE]}]}"
fi
}

