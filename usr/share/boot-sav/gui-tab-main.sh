#! /bin/bash
# Copyright 2023 Yann MRN
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

###################################### DEFAULT FILLING #########################################
set_easy_repair() {
[[ "$GUI" ]] && echo 'SET@_button_recommendedrepair.set_sensitive(False)' #To avoid applying before variables are changed
set_easy_repair_diff #Differences between BR, BI and OS-U
[[ "$DEBBUG" ]] && echo "[debug]MAIN_MENU becomes : $MAIN_MENU"
MBR_ACTION=nombraction
UNHIDEBOOT_ACTION=""
if [[ "$TOTAL_QUANTITY_OF_OS" != 0 ]] && [[ "$NB_MBR_CAN_BE_RESTORED" != 0 ]] || [[ "$QTY_OF_PART_FOR_REINSTAL" != 0 ]];then
	UNHIDEBOOT_TIME=10
	UNHIDEBOOT_ACTION=" unhide-bootmenu-10s"
    [[ "$GUI" ]] && echo 'SET@_checkbutton_unhide_boot_menu.set_active(True)'
	if [[ "$QTY_OF_PART_FOR_REINSTAL" != 0 ]];then
		set_checkbutton_reinstall_grub
		[[ "$GUI" ]] && echo 'SET@_checkbutton_reinstall_grub.set_active(True)' #Sometimes no consequence
	else
		[[ "$GUI" ]] && echo 'SET@_checkbutton_reinstall_grub.hide()'
		if [[ "$QTY_WUBI" != 0 ]] || [[ "$WUBILDR" ]] && [[ ! "$CANBOOTWIN" ]];then
            if [[ ! "$FORCEYES" ]];then
                if [[ "$GUI" ]];then
                    zenity --width=400 --question --text="$Can_you_boot_windows" 2>/dev/null && CANBOOTWIN=yes || CANBOOTWIN=no
                else
                    read -r -p "$Can_you_boot_windows [yes/no] " response
                    [[ "$response" =~ y ]] && CANBOOTWIN=yes || CANBOOTWIN=no
                fi
            fi
			[[ "$DEBBUG" ]] && echo "$Can_you_boot_windows $CANBOOTWIN"
            USERCHOICES="$USERCHOICES
When rebooting the computer, can you successfully start Windows? $CANBOOTWIN"
		fi
		if [[ "$CANBOOTWIN" = no ]] || [[ ! "$CANBOOTWIN" ]];then
            if [[ ! "$WINEFIFILEPRESENCE" ]];then
                set_checkbutton_restore_mbr
                [[ "$GUI" ]] && echo 'SET@_checkbutton_restore_mbr.set_active(True)' #Sometimes no consequence
            else
                ADVISE_BOOTLOADER_UPDATE=yes
            fi
		fi
	fi
elif [[ "$NBOFPARTITIONS" != 0 ]];then #http://askubuntu.com/questions/215432/cant-boot-after-disk-error-12-10
	#Works: http://paste2.org/p/2481100
	echo "No OS to fix."
	unset_checkbutton_reinstall_grub
	unset_checkbutton_restore_mbr
    if [[ "$GUI" ]];then
        echo 'SET@_checkbutton_reinstall_grub.hide()'
        echo 'SET@_hbox_unhide.hide()'
        echo 'SET@_button_recommendedrepair.hide()'
    fi
else
	echo "Error: no partitions"
	if [[ "$GUI" ]] && [[ "$APPNAME" =~ pa ]];then
		echo 'SET@_expander1.hide()'
		echo 'SET@_button_recommendedrepair.hide()'
	fi
fi
bootflag_update
WINBOOT_ACTION=""
if [[ "$QTY_WINBOOTTOREPAIR" = 0 ]];then
    [[ "$GUI" ]] && echo 'SET@_vbox_winboot.set_sensitive(False)'
else
	[[ "$GUI" ]] && echo 'SET@_vbox_winboot.set_sensitive(True)'
	if [[ ! "$GRUBPACKAGE" =~ efi ]];then
	    [[ "$GUI" ]] && echo 'SET@_checkbutton_winboot.set_active(True)'
		WINBOOT_ACTION=" win-legacy-basic-fix"
	fi
fi
[[ "$GUI" ]] && echo 'SET@_button_recommendedrepair.set_sensitive(True)' #To avoid applying before variables are changed
}

set_easy_repair_diff_br_and_bi() {
#if [[ "$QTY_OF_PART_FOR_REINSTAL" = 0 ]] && [[ "$NB_MBR_CAN_BE_RESTORED" = 0 ]] && [[ "$(grep BYT <<< "$PARTEDLM" )" ]] \
#|| [[ "$ROOTDISKMISSING" ]] || [[ "$MOUNTERROR" ]];then
#	FSCK_ACTION=" repair-filesystems"; echo 'SET@_checkbutton_repairfilesystems.set_active(True)'
#else
	FSCK_ACTION=""
    [[ "$GUI" ]] && echo 'SET@_checkbutton_repairfilesystems.set_active(False)'
#fi
if [[ "$QTY_WUBI" != 0 ]];then
	WUBI_ACTION=" repair-wubi"
    [[ "$GUI" ]] && echo 'SET@_checkbutton_wubi.set_active(True)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_wubi.set_sensitive(True)'
else
	WUBI_ACTION=""
    [[ "$GUI" ]] && echo 'SET@_checkbutton_wubi.set_active(False)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_wubi.set_sensitive(False)'
fi
#PASTEBIN_ACTION=create-bootinfo
#[[ "$GUI" ]] && echo 'SET@_checkbutton_pastebin.set_active(True)'
UPLOAD=pastebin
[[ "$GUI" ]] && echo 'SET@_checkbutton_upload.set_active(True)'
}	


############### Backup table and logs
_button_backup_table() {
[[ "$GUI" ]] && echo 'SET@_mainwindow.hide()'
[[ "$GUI" ]] && echo 'SET@_backupwindow.show()'
}

_button_cancelbackup() {
[[ "$GUI" ]] && echo 'SET@_mainwindow.show()'
[[ "$GUI" ]] && echo 'SET@_backupwindow.hide()'
}

_backup_filechooserwidget() {
CHOSENBACKUPREP="${@}"
[[ "$DEBBUG" ]] && echo "[debug]CHOSENBACKUPREP $CHOSENBACKUPREP"
}

_button_savebackup() {
local bsb FUNCTION=ZIP PACKAGELIST=zip FILETOTEST=zip temp temp2 FILE
if [[ "$GUI" ]];then
    echo 'SET@_backupwindow.hide()'
    start_pulse
    echo "SET@_label0.set_text('''$Backup_table. $Please_wait''')"
fi
[[ "$DEBBUG" ]] && echo "[debug]_button_savebackup"
installpackagelist
if [[ "$(type -p zip)" ]];then
	TMP_BKPFOLDER="$(mktemp -td ${APPNAME}-BKP-XXXXX)"
	cp -r /var/log/$APPNAME/* "$TMP_BKPFOLDER"
	cd "$TMP_BKPFOLDER"
	temp="backup_$DATE"
	temp2="${CHOSENBACKUPREP}/$temp"
	zip -r $temp2 *
	FILE="${temp2}.zip"
	update_translations
	end_pulse
	[[ "$GUI" ]] && zenity --width=400 --info --text="$logs_have_been_saved_into_FILE" 2>/dev/null
	[[ "$GUI" ]] && echo 'SET@_mainwindow.show()'
else
	end_pulse
	[[ "$GUI" ]] && echo 'SET@_backupwindow.hide()'
fi
}

############### Unhide bootmenu
_spinbutton_unhide_boot_menu() {
UNHIDEBOOT_TIME="${@}"; UNHIDEBOOT_TIME="${UNHIDEBOOT_TIME%*.0}"
[[ "$DEBBUG" ]] && echo "[debug]UNHIDEBOOT_TIME becomes: $UNHIDEBOOT_TIME"
[[ "$UNHIDEBOOT_ACTION" ]] && UNHIDEBOOT_ACTION=" unhide-bootmenu-${UNHIDEBOOT_TIME}s"
}

_checkbutton_unhide_boot_menu() {
if [[ "${@}" = True ]]; then
	UNHIDEBOOT_ACTION="unhide-bootmenu-${UNHIDEBOOT_TIME}s";
    [[ "$GUI" ]] && echo 'SET@_spinbutton_unhide_boot_menu.set_sensitive(True)'
else
	UNHIDEBOOT_ACTION="";
    [[ "$GUI" ]] && echo 'SET@_spinbutton_unhide_boot_menu.set_sensitive(False)'
fi
[[ "$DEBBUG" ]] && echo "[debug]UNHIDEBOOT_ACTION becomes : $UNHIDEBOOT_ACTION"
}


############## Reinstall GRUB
_checkbutton_reinstall_grub() {
if [[ "${@}" = True ]]; then
	set_checkbutton_reinstall_grub
else
	show_tab_grub_location off
	show_tab_grub_options off
	[[ "$MBR_ACTION" != restore ]] && MBR_ACTION=nombraction
	[[ "$DEBBUG" ]] && echo "[debug]MBR_ACTION becomes: $MBR_ACTION"
	update_bkp_boxes
fi
}

set_checkbutton_reinstall_grub() {
[[ "$DEBBUG" ]] && echo "[debug]set_checkbutton_reinstall_grub"
show_tab_grub_location on
show_tab_grub_options on
show_tab_mbr_options off
[[ "$GUI" ]] && echo 'SET@_checkbutton_restore_mbr.set_active(False)'
MBR_ACTION=reinstall
REGRUB_PART="${LIST_OF_PART_FOR_REINSTAL[1]}"
update_bkp_boxes
osbydefault_consequences
[[ "$GUI" ]] && echo 'SET@_combobox_ostoboot_bydefault.set_active(0)' #Sometimes no consequences
[[ "$DEBBUG" ]] && echo "[debug]MBR_ACTION is set : $MBR_ACTION (NBOFDISKS is $NBOFDISKS)"
}

update_bkp_boxes() {
RESTORE_BKP_ACTION=""
if [[ "$BKPFILEPRESENCE" ]];then
	[[ "$GUI" ]] && echo 'SET@_checkbutton_restore_bkp.show()'
else
	[[ "$GUI" ]] && echo 'SET@_checkbutton_restore_bkp.hide()'
fi
if [[ "$MBR_ACTION" = reinstall ]] && [[ "$GRUBPACKAGE" =~ efi ]];then
	[[ "$BKPFILEPRESENCE" ]] && RESTORE_BKP_ACTION=" restore-efi-backups"
	[[ "$BKPFILEPRESENCE" ]] && [[ "$GUI" ]] && echo 'SET@_checkbutton_restore_bkp.set_active(True)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_create_bkp.show()'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_winefi_bkp.show()'
	CREATE_BKP_ACTION=" use-standard-efi-file"
	[[ "$GUI" ]] && echo 'SET@_checkbutton_create_bkp.set_active(True)'
	#http://ubuntuforums.org/showpost.php?p=12457638&postcount=9
	#if [[ "$WINBKPFILEPRESENCE" ]];then
		#WINEFI_BKP_ACTION=" rename-ms-efi" &&	echo 'SET@_checkbutton_winefi_bkp.set_active(True)'
		[[ "$GUI" ]] && echo 'SET@_checkbutton_winefi_bkp.show()'
	#fi
else
	CREATE_BKP_ACTION=""
	WINEFI_BKP_ACTION=""
	[[ "$GUI" ]] && echo 'SET@_checkbutton_create_bkp.hide()'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_winefi_bkp.hide()'
fi
}

unset_checkbutton_reinstall_grub() {
show_tab_grub_location off
show_tab_grub_options off
update_bkp_boxes
}


########################### Restore MBR
_checkbutton_restore_mbr() {
if [[ "${@}" = True ]]; then
	echo 'SET@_checkbutton_reinstall_grub.set_active(False)'
	unset_checkbutton_reinstall_grub
	MBR_ACTION=restore
	set_checkbutton_restore_mbr
else
	[[ "$MBR_ACTION" != reinstall ]] &&	MBR_ACTION=nombraction
	unset_checkbutton_restore_mbr
fi
}

set_checkbutton_restore_mbr() {
MBR_ACTION=restore
show_tab_mbr_options on
update_bkp_boxes
[[ "$GUI" ]] && echo 'SET@_combobox_restore_mbrof.set_active(0)'
MBR_TO_RESTORE="${MBR_CAN_BE_RESTORED[1]}"; combobox_restore_mbrof_consequences
[[ "$DEBBUG" ]] && echo "[debug]MBR_ACTION becomes : $MBR_ACTION"
}

unset_checkbutton_restore_mbr() {
show_tab_mbr_options off
update_bkp_boxes
}

############################### Bkp
_checkbutton_create_bkp() {
if [[ "${@}" = True ]]; then
	CREATE_BKP_ACTION=" use-standard-efi-file"
	[[ "$GUI" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ "$WINEFIFILEPRESENCE" ]] && echo 'SET@_checkbutton_winefi_bkp.show()' #|| WINEFI_BKP_ACTION=rename-ms-efi 
else
	CREATE_BKP_ACTION=""
	[[ "$GUI" ]] && echo 'SET@_checkbutton_winefi_bkp.hide()'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_winefi_bkp.set_active(False)'
	WINEFI_BKP_ACTION=""
fi
}

_checkbutton_restore_bkp() {
if [[ "${@}" = True ]]; then
	RESTORE_BKP_ACTION=" restore-efi-backups"
else
	RESTORE_BKP_ACTION=""
fi
}

_checkbutton_winefi_bkp() {
[[ "${@}" = True ]] && WINEFI_BKP_ACTION=" rename-ms-efi" || WINEFI_BKP_ACTION=""
}

############### Action items ################

_button_mainquit() {
[[ "$GUI" ]] && echo 'SET@_mainwindow.hide()'
WIOULD=would
[[ "$MAIN_MENU" =~ Recomm ]] && debug_echo_important_variables
if [[ "$MAIN_MENU" != Boot-Info ]];then
    title_gen "Default settings"
    echo "$IMPVAR"
fi
unmount_all_partitions_and_quit_glade
}

_button_mainapply() {
if [[ "$MAIN_MENU" =~ fo ]];then
	justbootinfo_br_and_bi
else
	[[ "$GUI" ]] && echo 'SET@_mainwindow.hide()'
	start_pulse
	TEXT=""
	ATEXT=""
	BTEXT=""
	LAB="$Applying_changes"
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB $This_may_require_several_minutes''')"
	check_internet_connection
	blockers_check
	if [[ "$BTEXT" ]];then
		echo "$BTEXT"
		end_pulse
		[[ "$GUI" ]] && zenity --width=400 --error --title="$APPNAME2" --text="$BTEXT" 2>/dev/null
		unmount_all_partitions_and_quit_glade
	elif [[ "$ATEXT" ]];then
        printf "\nRepair blocked: ________________________________________________________________\n"
        echo "$ATEXT"
		end_pulse
		[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$ATEXT" 2>/dev/null
		[[ "$GUI" ]] && echo 'SET@_mainwindow.show()'
	elif [[ "$TEXT" ]];then
        [[ "$DEBBUG" ]] && printf "\nAdvices: _______________________________________________________________________\n"
        end_pulse
        tmanswer=yes
        if [[ ! "$FORCEYES" ]];then
            if [[ "$GUI" ]];then
                zenity --width=400 --question --title="$APPNAME2" --text="$TEXT" 2>/dev/null || tmanswer=no
            else
                read -r -p "$TEXT [yes/no] " response
                [[ "$response" =~ y ]] || tmanswer=no
            fi
        fi
        [[ "$DEBBUG" ]] && echo "$TEXT $tmanswer"
        [[ "$tmanswer" = yes ]] && mainapplypulsate || unmount_all_partitions_and_quit_glade
	else
		actions
	fi
fi
}

blockers_check() {
ERROR=""
first_translations
#called by _button_mainapply and _button_justbootinfo
[[ "$GRUBPURGE_ACTION" ]] || [[ "$KERNEL_PURGE" ]] && [[ "$MBR_ACTION" = reinstall ]] && check_internet_connection
#Block and quit
if [[ "$MBR_ACTION" = restore ]] && [[ ! "$DISK_TO_RESTORE_MBR" ]];then
	BTEXT="No disk to restore MBR. $PLEASECONTACT"
elif [[ "$(mount | grep '/target' )" ]] && [[ "$MBR_ACTION" = reinstall ]] && [[ ! "$DEBBUG" ]];then
    FUNCTION='/target'; SYSTEM2="$(lsb_release -is)" ; update_translations
	BTEXT="$FUNCTION_detected $Plz_close_SYSTEM2_installer_then_retry"
elif [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ ! "$WINEFIFILEPRESENCE" ]] && [[ "$LIVESESSION" != live ]] && [[ -d /sys/firmware/efi ]];then
    FUNCTION=LegacyWindows; update_translations
    BTEXT="$FUNCTION_detected $Use_in_live_session_with_your_BIOS_set_in_Legacy_mode"
elif [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ "$WINEFIFILEPRESENCE" ]] && [[ "$LIVESESSION" != live ]] && [[ ! -d /sys/firmware/efi ]];then
    FUNCTION=WindowsEFI; DISK5="$DISK33"; update_translations
    BTEXT="$FUNCTION_detected $Use_in_live_session_with_your_BIOS_set_in_UEFI_mode $Eg_use_DISK5_usb_efi"
elif [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] && [[ ! "$MACEFIFILEPRESENCE" ]] && [[ "$LIVESESSION" != live ]] && [[ -d /sys/firmware/efi ]];then
    FUNCTION=LegacyMacOS; update_translations
    BTEXT="$FUNCTION_detected $Use_in_live_session_with_your_BIOS_set_in_Legacy_mode"
elif [[ "$MACEFIFILEPRESENCE" ]] && [[ "$LIVESESSION" != live ]] && [[ ! -d /sys/firmware/efi ]];then
    FUNCTION=MacEFI; DISK5="$DISK33"; update_translations
    BTEXT="$FUNCTION_detected $Use_in_live_session_with_your_BIOS_set_in_UEFI_mode $Eg_use_DISK5_usb_efi"
elif [[ "$WINEFIFILEPRESENCE" ]] || [[ "$MACEFIFILEPRESENCE" ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$MBR_ACTION" = reinstall ]] && [[ ! -d /sys/firmware/efi ]];then
	DISK5="$DISK33";update_translations
	BTEXT="$Current_session_is_CSM $Use_in_live_session_with_your_BIOS_set_in_UEFI_mode $Eg_use_DISK5_usb_efi"
fi

#Block and main window
if [[ "$MBR_ACTION" = reinstall ]] && [[ "$LIVESESSION" != live ]] && [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" != "$CURRENTSESSIONPARTITION" ]];then
	ATEXT="$Please_use_in_live_session $This_will_enable_this_feature"
elif [[ ! "$WINEFIFILEPRESENCE" ]] && [[ ! "$MACEFIFILEPRESENCE" ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$MBR_ACTION" = reinstall ]] && [[ ! -d /sys/firmware/efi ]];then
	DISK5="$DISK33";update_translations
	ATEXT="$Current_session_is_CSM $Use_in_live_session_with_your_BIOS_set_in_UEFI_mode $Eg_use_DISK5_usb_efi $This_will_enable_this_feature"
elif [[ "${ARCH_OF_PART[$REGRUB_PART]}" = 64 ]] || [[ "${ARCH_OF_PART[$USRPART]}" = 64 ]] && [[ "$(uname -m)" != x86_64 ]] && [[ "$MBR_ACTION" = reinstall ]];then
	FUNCTION=64bits; FUNCTION44=64bits; DISK44="$DISK33";update_translations
	ATEXT="$FUNCTION_detected $Please_use_in_a_64bits_session ($Please_use_DISK44_which_is_FUNCTION44_ok) $This_will_enable_this_feature"
elif [[ "$DISTRIB_DESCRIPTION" =~ Debian ]] || [[ "$DISTRIB_DESCRIPTION" =~ Unknown ]] && [[ "$FSCK_ACTION" ]];then
	FUNCTION=FSCK; FUNCTION44=FSCK; DISK44="$DISK33";update_translations
	ATEXT="$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok $This_will_enable_this_feature"
elif [[ "$MBR_ACTION" = reinstall ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ ! "$(type -p efibootmgr)" ]];then
	PACKAGELIST=efibootmgr; update_translations
	ATEXT="$please_install_PACKAGELIST $Then_try_again $Alternatively_you_can_use"
elif [[ "$MBR_ACTION" = restore ]] && [[ ! "$MBR_TO_RESTORE" =~ xp ]] || [[ "$BOOTFLAG_ACTION" ]] && [[ ! "$(type -p parted)" ]];then
	PACKAGELIST=parted; update_translations
	ATEXT="$please_install_PACKAGELIST $Then_try_again $Alternatively_you_can_use"
elif [[ "$MBR_ACTION" = restore ]] && [[ "$MBR_TO_RESTORE" =~ xp ]] && [[ ! "$(type -p install-mbr)" ]];then
	PACKAGELIST=mbr; update_translations
	ATEXT="$please_install_PACKAGELIST $Then_try_again $Alternatively_you_can_use"
#elif [[ "$GRUBPURGE_ACTION" ]] || [[ "$KERNEL_PURGE" ]] && [[ "$MBR_ACTION" = reinstall ]] && [[ "$INTERNET" = no-internet ]];then
#	OPTION="$Check_internet"; update_translations
#	ATEXT="$No_internet_connection_detected. $Please_connect_internet $Then_try_again $Alternatively_you_may_want_to_retry_after_deactivating_OPTION" 
elif [[ "$MBR_ACTION" = reinstall ]] && [[ "$GRUBPURGE_ACTION" = purge-grub ]] && [[ "${APTTYP[$USRPART]}" = nopakmgr ]];then
	ATEXT="No valid package manager in ${OSNAME[$REGRUB_PART]} (${LISTOFPARTITIONS[$USRPART]}). $PLEASECONTACT"
elif [[ "$MBR_ACTION" = reinstall ]] && [[ ! "$GRUBPACKAGE" =~ efi ]] && [[ "${GPT_DISK[${DISKNB_PART[$REGRUB_PART]}]}" = is-GPT ]] \
&& [[ "${BIOS_BOOT_DISK[${DISKNB_PART[$REGRUB_PART]}]}" = no-BIOSboot ]];then
	FUNCTION=GPT; TYP=BIOS-Boot; FLAGTYP=bios_grub; TOOL1=Gparted; TYPE3=/boot/efi; update_translations
	OPTION1="$Separate_TYPE3_partition";update_translations
	ATEXT="$FUNCTION_detected $Please_create_TYP_part (>1MB, $No_filesystem, $FLAGTYP_flag). $Via_TOOL1 $Then_try_again"
	[[ "$QTY_EFIPART" != 0 ]] && ATEXT="$ATEXT
$Alternatively_you_can_try_OPTION1"
	#echo "(debug) $MBR_ACTION $GRUBPACKAGE $FORCE_GRUB ${BIOS_BOOT_DISK[${DISKNB_PART[$REGRUB_PART]}]} (${LISTOFPARTITIONS[$REGRUB_PART]})"
elif [[ "$MBR_ACTION" = reinstall ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$QTY_EFIPART" = 0 ]];then  ### TBC, was NB_BISEFIPART=0
	TYP=ESP; FLAGTYP=boot; TOOL1=Gparted; TYPE3=/boot/efi; update_translations
	OPTION1="$Separate_TYPE3_partition"; update_translations
	ATEXT="$Please_create_TYP_part (FAT32, 100MB~250MB, $start_of_the_disk, $FLAGTYP_flag). $Via_TOOL1 $Then_try_again"
elif ( [[ ! "$USE_SEPARATEUSRPART" ]] && [[ "${ARCH_OF_PART[$REGRUB_PART]}" = 32 ]] ) || ( [[ "$USE_SEPARATEUSRPART" ]] && [[ "${ARCH_OF_PART[$USRPART]}" = 32 ]] ) \
	&& [[ "$GRUBPACKAGE" =~ signed ]] && [[ "$MBR_ACTION" = reinstall ]] ;then
	FUNCTION=32bit-vs-signed-efi; update_translations
	ATEXT="$FUNCTION_detected $You_may_want_install_64os $This_will_enable_this_feature"
elif [[ "$BLKID" =~ zfs ]] && [[ "$MAIN_MENU" != Boot-Info ]] && [[ ! "$($PACKVERSION zfsutils-linux)" =~ '2.' ]];then
	PACK7=zfsutils; update_translations
	ATEXT="$Please_retry_from_a_live_disc_containing_a_recent_version_of_PACK7
"
elif [[ "$MBR_ACTION" = restore ]] || [[ "$MBR_ACTION" = reinstall ]] && [[ "$CRYPTPART" ]] && [[ "$QUANTITY_OF_DETECTED_LINUX" = 0 ]];then
	ATEXT="$Encryption_detected $Please_decrypt (cryptsetup open)"
fi

#Ask confirmation before repair
if [[ "$MBR_ACTION" = reinstall ]];then
	if [[ "$GRUBPURGE_ACTION" ]] || [[ "$KERNEL_PURGE" ]]  && [[ "$INTERNET" = no-internet ]];then
		TEXT="$TEXT$Continuing_without_internet_would_unbootable $Please_connect_internet
"
	elif [[ "$FDISKL" =~ SFS ]];then
		FUNCTION=SFS; TOOL1="TestDisk"; TOOL2="EASEUS-Partition-Master / MiniTool-Partition-Wizard"; update_translations
		TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_converting_SFS $Via_TOOL1_or_TOOL2
"
	fi
	if [[ "$GRUBPACKAGE" =~ efi ]];then #grub-efi ok even without GPT (see ReadEFIdos)
#		if [[ ! -d /sys/firmware/efi ]] && [[ ! "$WINEFIFILEPRESENCE" ]] && [[ ! "$MACEFIFILEPRESENCE" ]];then # if WinEFI or MacEFI, is blocked (above)
#			MODE1=BIOS-compatibility/CSM/Legacy; MODE2=EFI; TYPE3=/boot/efi; OPTION="$Separate_TYPE3_partition"; update_translations
#			TEXT="$TEXT$Boot_is_MODE1_may_need_change_to_MODE2
#"
#			[[ ! "$EFIFILPRESENT" ]] && TEXT="$TEXT$Alternatively_you_may_want_to_retry_after_deactivating_OPTION
#"
#        fi
        if ( [[ ! "$USE_SEPARATEUSRPART" ]] && [[ "${ARCH_OF_PART[$REGRUB_PART]}" = 32 ]] ) || ( [[ "$USE_SEPARATEUSRPART" ]] && [[ "${ARCH_OF_PART[$USRPART]}" = 32 ]] ) \
		&& [[ "$ARCHIPC" = 64 ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$MBR_ACTION" = reinstall ]];then  # TBC
			PARTITION1="${LISTOFPARTITIONS[$REGRUB_PART]}"; update_translations
			TEXT="$TEXT$You_have_installed_on_PARTITION1_EFI_incompat $You_may_want_install_64os
"
		fi
#        if [[ "${SECUREBOOT%% *}" = enabled ]] && [[ "$WINEFIFILEPRESENCE" ]];then   ## à passer dans le message final ???
#			MODE1=Secure; MODE2=non-Secure; update_translations;
#			TEXT="$TEXT$Boot_is_MODE1_may_need_change_to_MODE2
#"
#		fi
        if [[ "${BIOS_BOOT_DISK[${DISKNB_PART[$REGRUB_PART]}]}" = hasBIOSboot ]] && [[ ! "$WINEFIFILEPRESENCE" ]] && [[ "$QTY_SUREEFIPART" = 0 ]];then
			FUNCTION=BIOS-Boot; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_deactivating_OPTION
"
		fi
        if [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ ! "$WINEFIFILEPRESENCE" ]];then
			FUNCTION=LegacyWindows; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_deactivating_OPTION
"
		fi
        if [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] && [[ ! "$MACEFIFILEPRESENCE" ]] && [[ ! "$WINEFIFILEPRESENCE" ]];then
			FUNCTION=LegacyMacOS; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_deactivating_OPTION
"
		fi
		if [[ "${EFI_TYPE[$EFIPART_TO_USE]}" = hidenESP ]] && [[ "$EFIPART_TO_USE" != "${LIST_EFIPART[1]}" ]];then #only if not default esp. Else, B-R will propose to remove hidden flag.
			HIDDENESP="${LISTOFPARTITIONS[$EFIPART_TO_USE]}"; TOOL1=Gparted; update_translations;
			TEXT="$TEXT$You_may_want_retry_after_remov_hidden_flag_from_HIDDENESP $Via_TOOL1
"
		fi
		if [[ "$QTY_SUREEFIPART" = 0 ]];then
			FUNCTION=ESP-on-live-disc; update_translations; 
			TEXT="$TEXT$FUNCTION_detected $Please_check_advanced_options
"
		fi
	else
		[[ "$GRUBVER[$REGRUB_PART]" = grub ]] && TEXT="$TEXT$This_will_install_an_obsolete_bootloader (GRUB Legacy).
"
		if [[ -d /sys/firmware/efi ]];then
            if [[ ! "$WIN_ON_GPT" ]] && [[ "$WIN_ON_DOS" ]];then #update-grub in EFI session will not detect WinLegacy https://forum.ubuntu-fr.org/viewtopic.php?pid=22282356#p22282356
				FUNCTION=LegacyWindows; MODE1=EFI; MODE2=BIOS-compatibility/CSM/Legacy; update_translations
				[[ "$LIVESESSION" = live ]] && FINALMSG_UPDATEGRUB=yes
				TEXT="$TEXT$FUNCTION_detected $Boot_is_MODE1_may_need_change_to_MODE2
"
            fi
            if [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] && [[ ! "$MACEFIFILEPRESENCE" ]];then #update-grub in EFI session may not detect MacLegacy
				FUNCTION=LegacyMacOS; MODE1=EFI; MODE2=BIOS-compatibility/CSM/Legacy; update_translations
				[[ "$LIVESESSION" = live ]] && FINALMSG_UPDATEGRUB=yes
				TEXT="$TEXT$FUNCTION_detected $Boot_is_MODE1_may_need_change_to_MODE2
"
            fi
		fi
		if [[ "$QTY_SUREEFIPART" = 0 ]];then
			if [[ "$WIN_ON_GPT" ]];then
				FUNCTION=Windows-on-GPT; TYP=ESP; FLAGTYP=boot; update_translations
				TEXT="$TEXT$FUNCTION_detected \
$You_may_want_to_retry_after_creating_TYP_part (FAT32, 100MB~250MB, $start_of_the_disk, $FLAGTYP_flag).
"
			elif [[ -d /sys/firmware/efi ]] && [[ ! "$WIN_ON_DOS" ]];then
					MODE1=EFI; MODE2=ESP; TYP=ESP; FLAGTYP=boot; update_translations
					TEXT="$TEXT$Boot_is_MODE1_but_no_MODE2_part_detected \
$You_may_want_to_retry_after_creating_TYP_part (FAT32, 100MB~250MB, $start_of_the_disk, $FLAGTYP_flag).
"
			fi
		fi #efi <500MB ubuntuforums.org/showthread.php?t=2021534
		if [[ "$WIN_ON_GPT" ]] && [[ "$QTY_SUREEFIPART" != 0 ]] && [[ ! "$WINEFIFILEPRESENCE" ]];then #if win efi files were deleted by mistake
			FUNCTION=WindowsGPTwithoutESP; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected You may want to retry after repairing ESP via command in Windows: bcdboot Letter:\Windows /l fr-fr /s x: /f ALL
"
		elif [[ "$WIN_ON_GPT" ]] && [[ "$QTY_SUREEFIPART" != 0 ]];then #if user forced grub-pc
			FUNCTION=WindowsEFI; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_activating_OPTION
"
		fi
		if [[ "$MACEFIFILEPRESENCE" ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]];then
			FUNCTION=MacEFI; TYPE3=/boot/efi; update_translations; OPTION="$Separate_TYPE3_partition"; update_translations
			TEXT="$TEXT$FUNCTION_detected $You_may_want_to_retry_after_activating_OPTION
"
		fi
	fi
fi
if [[ "$BLKID" =~ zfs ]] && [[ "$SUCCESSACTZFS" = no ]];then
	if [[ "$MAIN_MENU" != Boot-Info ]];then
		TEXT="${TEXT}Warning: ZFS not activated correctly. Repair will fail unless you mount the pools on /mnt/boot-sav/zfs before continuing. $PLEASECONTACT
"
	else
		TEXT="${TEXT}Warning: ZFS not activated correctly. Boot-info might be incomplete or inaccurate. $PLEASECONTACT
"
	fi
fi
if [[ "$BLKID" =~ zfs ]] && [[ "$MAIN_MENU" = Boot-Info ]] && [[ ! "$($PACKVERSION zfsutils-linux)" =~ '2.' ]];then
	TEXT="${TEXT}Warning: old zfsutils version ($($PACKVERSION zfsutils-linux)). Boot-info might be incomplete or inaccurate. You may want to retry from a recent live disc.
"
fi
if [[ "$MAIN_MENU" != Boot-Info ]] && [[ "$CRYPTPART" ]] && ( [[ ! "$(type -p cryptsetup)" ]] || [[ ! "$(cryptsetup status /dev/mapper/vgubuntu-root | grep 'is activ' )" ]] );then
	TEXT="$TEXT$You_may_want_decrypt (cryptsetup open)
"
fi

[[ "$TEXT" ]] && TEXT="$TEXT$Are_u_sure_u_want_to_continue_anyway"
}
	
mainapplypulsate() {
start_pulse
actions
}

_mainwindow() {
unmount_all_partitions_and_quit_glade
}

unmount_all_partitions_and_quit_glade() {
choice=exit
if [[ "$GUI" ]];then
    echo 'SET@_mainwindow.hide()'
    zenity --width=400 --info --timeout=4 --title="$APPNAME2" --text="$Operation_aborted. $No_change_on_your_pc" 2>/dev/null | (echo "Operation_aborted"; unmount_all_blkid_partitions_except_df)
else
    echo "$Operation_aborted. $No_change_on_your_pc"
    unmount_all_blkid_partitions_except_df
fi
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r $TMP_FOLDER_TO_BE_CLEARED
[[ "$GUI" ]] && echo 'EXIT@@' || exit 0
}

resizemainwindow() {
if [[ "$GUI" ]];then
    sleep 0.1; echo 'SET@_mainwindow.resize(10,10)'
fi
}

_expander1() {
local RETOUREXP=${@}
if [[ ${RETOUREXP} = True ]]; then
	if [[ "$APPNAME" =~ boot- ]];then
		[[ "$GUI" ]] && echo 'SET@_button_mainapply.hide()' && echo 'SET@_hbox_bootrepairmenu.show()'
		set_easy_repair
	fi
else
	[[ "$GUI" ]] && [[ "$APPNAME" =~ boot- ]] && echo 'SET@_hbox_bootrepairmenu.hide()' \
	&& echo 'SET@_button_mainapply.show()' && echo 'SET@_button_mainapply.set_sensitive(False)'
	debug_echo_important_var_first
	[[ "$APPNAME" =~ fo ]] && MAIN_MENU=Boot-Info || MAIN_MENU=Custom-Repair
	[[ "$GUI" ]] && [[ "$APPNAME" =~ boot- ]] && echo 'SET@_button_mainapply.set_sensitive(True)' 
fi
[[ "$DEBBUG" ]] && echo "[debug]MAIN_MENU becomes : $MAIN_MENU"
resizemainwindow
}

############## About
_button_thanks() {
zenity --width=400 --info --title="$APPNAME2" --text="THANKS TO EVERYBODY PARTICIPATING DIRECTLY OR INDIRECTLY TO MAKE THIS SOFTWARE A USEFUL TOOL FOR THE FOSS COMMUNITY:
testers,coders,translators,donators,everybody helping and sharing knowledge on forums-wiki...Babdu,Hizoka,oldfred,bcbc,AnsuzP,Josepe,mörgæs,Meierfra,Gert,arvidjaar,Adrian,GRUB-devs,drs305,srs5694,Geole and many more" 2>/dev/null
}

_button_translate() {
xdg-open "https://translations.launchpad.net/boot-repair" &
}
