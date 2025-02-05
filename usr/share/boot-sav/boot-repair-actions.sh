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

########################## REPAIR SEQUENCE DEPENDING ON USER CHOICE ##########################################
actions() {
display_action_settings_start
[[ "$MAIN_MENU" = Recommended-Repair ]] && echo "
Recommended repair: ____________________________________________________________
"
display_action_settings_end
FSFIXED=""
[[ "$FSCK_ACTION" ]] && fsck_function	#Unmount all OS partition then remounts them
if [[ "$FSFIXED" ]];then #scan again then run the Recommended Repair
	check_os_and_mount_blkid_partitions_gui
	check_which_mbr_can_be_restored
	[[ "$DEBBUG" ]] && echo_df_and_fdisk
	#save_log_on_disks
	mainwindow_filling
	WIOULD=would
	debug_echo_important_variables
	_button_mainapply
else
	first_actions
	[[ "$WUBI_ACTION" ]] && wubi_function
	[[ "$MBR_ACTION" != nombraction ]] && freed_space_function	#Requires Linux partitions to be mounted
	actions_final
fi
}

########################## UNMOUNT ALL AND SUCCESS REPAIR ##########################################
unmount_all_and_success() {
unmount_all_and_success_br_and_bi
}


########################################### REPAIR WUBI ##################################################################
wubi_function() {
local i repwubok=yes
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Repair_file_systems Wubi. $This_may_require_several_minutes''')"
for ((i=1;i<=QTY_WUBI;i++)); do
	echo "mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk ${MOUNTPOINTWUBI[$i]}"
	mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk "${MOUNTPOINTWUBI[$i]}" #failed mount http://ubuntuforums.org/showthread.php?t=2083353
	WUBIHOMEMOUNTED=""	
	if [[ -f "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk" ]] ;then
		mkdir -p "${MOUNTPOINTWUBI[$i]}/home"
		echo "mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk ${MOUNTPOINTWUBI[$i]}/home"
		mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk "${MOUNTPOINTWUBI[$i]}/home"
		WUBIHOMEMOUNTED=yes
	fi
	xdg-open "${MOUNTPOINTWUBI[$i]}/home" &
	teeext="$The_browser_will_access_wubi (${MOUNTPOINTWUBI[$i]}/home) $Please_backup_data_now $Then_close_this_window"
	echo "$teeext"
	end_pulse
	[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$teeext" 2>/dev/null
	start_pulse
	pkill pcmanfm	#To avoid it automounts
	[[ "$WUBIHOMEMOUNTED" ]] && echo "umount ${MOUNTPOINTWUBI[$i]}/home" && umount "${MOUNTPOINTWUBI[$i]}/home"
	echo "umount ${MOUNTPOINTWUBI[$i]}"
	umount "${MOUNTPOINTWUBI[$i]}"	
done
#text="$This_will_try_repair_wubi $Please_backup_data $Do_you_want_to_continue"
#zenity --width=400 --question --title="$APPNAME2" --text="$text" 2>/dev/null || repwubok=no
#start_pulse
#echo "$text $repwubok"
#if [[ "$repwubok" = yes ]];then
	for ((i=1;i<=QTY_WUBI;i++)); do
		[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Repair_file_systems Wubi$i. $This_may_require_several_minutes''')"
		if [[ -f "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk" ]] ;then
			echo "fsck -f -y ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk"
			LANGUAGE=C LC_ALL=C fsck -f -y "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk"
		fi
		echo "fsck -f -y ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk"
		LANGUAGE=C LC_ALL=C fsck -f -y "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk"
	done
#fi
}

########################################### REPAIR PARTITIONS (FSCK) ##################################################################
fsck_function() {
update_cattee
local i #FUNCTION=NTFSFIX PACKAGELIST=ntfsprogs FILETOTEST=ntfsfix
force_unmount_blkid_partitions
#fsck -fyM  # repair partitions detected in the /etc/fstab except those mounted
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Repair_file_systems ${LISTOFPARTITIONS[$i]#*/dev/}. $This_may_require_several_minutes''')"
#	if [[ "$(echo "$BLKID" | grep ntfs | grep "${LISTOFPARTITIONS[$i]#*/dev/}:" )" ]];then
#		[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
#		[[ "$(type -p $FILETOTEST)" ]] && echo "
#ntfsfix ${LISTOFPARTITIONS[$i]}" \
#		&& LANGUAGE=C LC_ALL=C ntfsfix ${LISTOFPARTITIONS[$i]}	#Repair NTFS partitions
#	else
		echo "
fsck -fyM ${LISTOFPARTITIONS[$i]}"
		LANGUAGE=C LC_ALL=C fsck -fyM ${LISTOFPARTITIONS[$i]}	#Repair other partitions (except if mounted = security)
#	fi
done
[[ "$(cat "$CATTEE" | grep 'FILE SYSTEM WAS MODIFIED' )" ]] && FSFIXED=yes
mount_all_blkid_partitions_except_df
}

#Called by fsck_function
force_unmount_blkid_partitions() {
local i
if [[ ! "$FORCEYES" ]];then
	if [[ "$GUI" ]];then
		end_pulse
		zenity --width=400 --info --title="$APPNAME2" --text="$Filesystem_repair_need_unmount_parts $Please_close_all_programs $Then_close_this_window" 2>/dev/null
		start_pulse
	else
		read -r -p "$Filesystem_repair_need_unmount_parts $Please_close_all_programs [Enter] "
	fi
fi
echo "Force Unmount all blkid partitions (for fsck) except / /boot /cdrom /dev /etc /home /opt /pas /proc /rofs /sys /tmp /usr /var "
pkill pcmanfm	#To avoid it automounts
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	[[ "${BLKIDMNT_POINT[$i]}" ]] \
	&& [[ "$(echo "${BLKIDMNT_POINT[$i]}" | grep -v /zfs | grep -v /boot | grep -v /cdrom | grep -v /dev | grep -v /etc| grep -v /home \
	| grep -v /opt | grep -v /pas | grep -v /proc | grep -v /rofs | grep -v /sys | grep -v /tmp | grep -v /usr | grep -v /var )" ]] \
	&& umount "${BLKIDMNT_POINT[$i]}"
done
}

########################################### FREED SPACE ACTION ##################################################################
freed_space_function() {
local i USEDPERCENT THISPARTITION temp
#Workaround for https://bugs.launchpad.net/bugs/610358
[[ "$DEBBUG" ]] && echo "[debug]Freed space function"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''Checking full partitions. $This_may_require_several_minutes''')"
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ ! "${OS__RECOORHID[$i]}" ]] && [[ ! "${OS__SEPWINBOOOT[$i]}" ]] && [[ ! "${READONLY[$i]}" ]];then
		determine_usedpercent
		if [[ "$USEDPERCENT" != [0-9][0-9] ]] && [[ "$USEDPERCENT" != [0-9] ]] && [[ "$USEDPERCENT" != 100 ]];then
			echo "Could not detect USEDPERCENT of ${OS__PARTITION[$i]} ($USEDPERCENT)."
			df ${OS__PARTITION[$i]} | grep /
			echo ""
		elif [[ "$USEDPERCENT" -ge 97 ]];then
			temp="$(echo "$BLKID" | grep "${OS__PARTITION[$i]}:")"; temp=${temp#*TYPE=\"}; temp=${temp%%\"*}
			if [[ ! "${READONLY[$i]}" ]] || [[ "$temp" != ntfs ]];then
				echo "${OS__PARTITION[$i]} is $USEDPERCENT % full"
                if [[ ! "$FORCEYES" ]];then
                    if [[ "$GUI" ]];then
                        end_pulse
                        if [[ -d "${OS__MNT_PATH[$i]}/home" ]];then
                            xdg-open "${OS__MNT_PATH[$i]}/home" &
                        elif [[ -d "${OS__MNT_PATH[$i]}/Documents and Settings" ]];then
                            xdg-open "${OS__MNT_PATH[$i]}/Documents and Settings" &
                        elif [[ "${OS__PARTITION[$i]}" = "$CURRENTSESSIONPARTITION" ]];then
                            xdg-open "/" &
                        elif [[ "${OS__MNT_PATH[$i]}" =~ "/mnt/boot-sav" ]];then #To avoid https://bugs.launchpad.net/ubuntu/+source/xdg-utils/+bug/821284
                            xdg-open "/mnt/boot-sav" &
                        else
                            xdg-open "/" &
                        fi
                        THISPARTITION="${OS__PARTITION[$i]} \(${OS__NAME[$i]}\)"
                        update_translations
                        zenity --width=400 --warning --title="$APPNAME2" --text="$THISPARTITION_is_nearly_full $This_can_prevent_to_start_it. $Please_use_the_file_browser $Close_this_window_when_finished" 2>/dev/null
                        determine_usedpercent
                        if [[ "$USEDPERCENT" -ge 98 ]];then
                            textt="$THISPARTITION_is_still_full $This_can_prevent_to_start_it ($Power_manager_error)."
                            echo "$textt"
                            [[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$textt" 2>/dev/null
                        fi
                        start_pulse
                    else
                        read -r -p "$THISPARTITION_is_nearly_full $This_can_prevent_to_start_it."
                    fi
                fi
			fi
		fi
	fi
done
}

determine_usedpercent() {
USEDPERCENT="$(df ${OS__PARTITION[$i]} | grep / | grep % )"
USEDPERCENT=${USEDPERCENT%%\%*}; USEDPERCENT=${USEDPERCENT##* }
}


######################### STATS FOR IMPROVING BOOT-REPAIR##################
stats_diff() {
#[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (20). $This_may_require_several_minutes''')"
#[[ ! "$PASTEBIN_ACTION" ]] && $WGETST $URLST.noreport.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (20). $This_may_require_several_minutes''')"
[[ "$DISABLEWEBCHECK" ]] && $WGETST $URLST.nointernetchk.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (19). $This_may_require_several_minutes''')"
[[ ! "$UPLOAD" ]] && $WGETST $URLST.local.$CODO	#[[ "$PASTEBIN_ACTION" ]] && 
if [[ "$MAIN_MENU" = Boot-Info ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (18). $This_may_require_several_minutes''')"
	$WGETST $URLST.bootinfo.$CODO
else
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (18). $This_may_require_several_minutes''')"
	[[ "$BLKID" =~ zfs ]] && $WGETST $URLST.zfs.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (17). $This_may_require_several_minutes''')"
	[[ "$GRUBPACKAGE" =~ sign ]] && $WGETST $URLST.secureboot.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (16). $This_may_require_several_minutes''')"
	[[ "$MAIN_MENU" = Recommended-Repair ]] && $WGETST $URLST.recommendedrepair.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (15). $This_may_require_several_minutes''')"
	$WGETST $URLST.repair.$CODO
	[[ "$GRUBPURGE_ACTION" ]] && $WGETST $URLST.purge.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (14). $This_may_require_several_minutes''')"
	[[ "$MBR_ACTION" != reinstall ]] && $WGETST $URLST.$MBR_ACTION.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (13). $This_may_require_several_minutes''')"
	[[ "$FSCK_ACTION" ]] &&	$WGETST $URLST.fsck.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (12). $This_may_require_several_minutes''')"
	[[ "$UNCOMMENT_GFXMODE" ]] && $WGETST $URLST.gfx.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (11). $This_may_require_several_minutes''')"
	[[ "$ADD_KERNEL_OPTION" ]] && $WGETST $URLST.kernel.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (10). $This_may_require_several_minutes''')"
	[[ "$ATA" ]] && $WGETST $URLST.ata.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (9). $This_may_require_several_minutes''')"
	[[ "$KERNEL_PURGE" ]] && $WGETST $URLST.kernelpurge.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (8). $This_may_require_several_minutes''')"
	[[ "$GRUBPACKAGE" =~ efi ]] && $WGETST $URLST.efi.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (7). $This_may_require_several_minutes''')"
	if [[ "$(lsb_release -is)" =~ Debian ]] && [[ -f /etc/skel/.config/autostart/boot-repair.desktop ]] \
	|| [[ "$(lsb_release -ds)" =~ Boot-Repair-Disk ]];then
		$WGETST $URLST.boot-repair-disk.$CODO
	elif [[ "$(lsb_release -is)" =~ Mint ]];then #Mint13 --> LinuxMint
		$WGETST $URLST.mint.$CODO
	elif [[ "$(lsb_release -is)" =~ Ubuntu ]];then
		$WGETST $URLST.ubuntu.$CODO
	elif [[ "$(lsb_release -is)" =~ Debian ]];then
		$WGETST $URLST.debian.$CODO
	else
		$WGETST $URLST.otherhost.$CODO
	fi
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (6). $This_may_require_several_minutes''')"
	if [[ "$QUANTITY_OF_DETECTED_LINUX" != 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" = 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST $URLST.linuxonly.$CODO
	elif [[ "$QUANTITY_OF_DETECTED_LINUX" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" != 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" = 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST $URLST.winonly.$CODO
	elif [[ "$QUANTITY_OF_DETECTED_LINUX" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST $URLST.maconly.$CODO
	fi
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (5). $This_may_require_several_minutes''')"
	[[ "$QUANTITY_OF_UNKNOWN_OS" != 0 ]] && $WGETST $URLST.unknownos.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (4). $This_may_require_several_minutes''')"
	if [[ "$TOTAL_QUANTITY_OF_OS" = 0 ]];then
		$WGETST $URLST.0os.$CODO
	elif [[ "$TOTAL_QUANTITY_OF_OS" = 1 ]];then
		$WGETST $URLST.1os.$CODO
	elif [[ "$TOTAL_QUANTITY_OF_OS" = 2 ]];then
		$WGETST $URLST.2os.$CODO
	else
		$WGETST $URLST.3osormore.$CODO
	fi
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (3). $This_may_require_several_minutes''')"
	[[ "$BLKID" =~ LVM2_member ]] && $WGETST $URLST.lvm.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (2). $This_may_require_several_minutes''')"
	[[ "$DMRAID" ]] && $WGETST $URLST.dmraid.$CODO
	[[ "$MD_ARRAY" ]] && $WGETST $URLST.mdadm.$CODO
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (1). $This_may_require_several_minutes''')"
fi
}

