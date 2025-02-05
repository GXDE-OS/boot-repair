#! /bin/bash
# Copyright 2015 Yann MRN
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

############# UNINSTALL SEQUENCE DEPENDING ON USER CHOICE ##############
actions() {
LAB="$Uninstalling_os"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB $This_may_require_several_minutes''')"
display_action_settings_start
[[ "$MAIN_MENU" = Recommended-Repair ]] && echo "Recommended removal: ___________________________________________________________
"
display_action_settings_end
first_actions
erase_the_partition
remove_efi_if_needed
actions_final
}

unmount_all_and_success() {
TEXTMID="$We_hope_you_enjoyed_it_and_feedback"
unhideboot_and_textprepare
title_gen "df"
df
stats_and_endpulse
finalzenity_and_exitapp
}


################### ERASE OS_TO_DELETE_PARTITION #######################
#inputs : $OS_TO_DELETE_PARTITION, $WUBI_TO_DELETE
erase_the_partition() {
if [[ "$WUBI_TO_DELETE" != "" ]] && [[ "$WUBI_TO_DELETE" != several_wubi ]] && [[ "$WUBI_TO_DELETE" != manually_remove ]];then
	echo "erase Wubi located on ${OS__PARTITION[${WUBI[$WUBI_TO_DELETE]}]}"
	if [[ "$FORMAT_OS" = format-os ]];then
		rm -r "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuntu"
	else
		mv "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuntu" "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuuntu_old" #Debug
	fi
fi
echo "Erase $OS_TO_DELETE_PARTITION"
mkdir -p "${OS__MNT_PATH[$OS_TO_DELETE]}/deleted_os"
mv "${OS__MNT_PATH[$OS_TO_DELETE]}"/* "${OS__MNT_PATH[$OS_TO_DELETE]}/deleted_os" #If formating fails, the Linux won't be visible by the bootloader
if [[ "$FORMAT_OS" = format-os ]];then
	pkill pcmanfm
	umount "${OS__MNT_PATH[$OS_TO_DELETE]}"
	if [[ "$FORMAT_TYPE" =~ NTFS ]]; then
		mkntfs -f /dev/$OS_TO_DELETE_PARTITION
	elif [[ "$FORMAT_TYPE" = FAT ]]; then
		mkfs.fat /dev/$OS_TO_DELETE_PARTITION
	elif [[ "$FORMAT_TYPE" = ext4 ]]; then
		mkfs.ext4 /dev/$OS_TO_DELETE_PARTITION
	fi
fi
}

remove_efi_if_needed() {
tmp=""
if [[ "$QTY_EFIPART" != 0 ]] && [[ -d /sys/firmware/efi ]] && [[ "$TOTAL_QUANTITY_OF_OS" = 2 ]];then #difficult to do it safe if >2 OS
		BTO="$(LANGUAGE=C LC_ALL=C efibootmgr)"
		echo "
$DASH efibootmgr
$BTO
"
	if [[ "$MBR_ACTION" = nombraction ]] && [[ ! "$(echo "$OS_TO_DELETE_NAME" | grep -i windows)" ]] && [[ "$WINEFIFILEPRESENCE" ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" != 0 ]];then
		echo "
$DASH Remove the $OS_TO_DELETE_NAME entry in UEFI"
		for uuu in ubuntu mint debian fedora suse arch hat kali pop linux;do
			[[ ! "$tmp" ]] && [[ "$(echo "$OS_TO_DELETE_NAME" | grep -i $uuu)" ]] && tmp="$(echo "$BTO" | grep -i $uuu)" #Boot0004* Linux
		done
	fi
	if [[ "$MBR_ACTION" != nombraction ]] && [[ "$(echo "$OS_TO_DELETE_NAME" | grep -i windows)" ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 1 ]];then
		title_gen "Remove the Windows entry in UEFI"
		tmp="$(echo "$BTO" | grep -i windows)"
	fi
	if [[ "$tmp" ]];then
		tmp="${tmp%%\**}" #Boot0004
		BETR="${tmp##*Boot000}" #4
		if [[ "$BETR" ]];then
			title_gen "efibootmgr -b $BETR -B"
			LANGUAGE=C LC_ALL=C efibootmgr -b $BETR -B
		fi
	fi
fi
}

################### STATS FOR IMPROVING OS-UNINSTALLER##################
stats_diff() {
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (4). $This_may_require_several_minutes''')"
$WGETST $URLST.uninstall.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (3). $This_may_require_several_minutes''')"
$WGETST $URLST.$MBR_ACTION.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (2). $This_may_require_several_minutes''')"
$WGETST $URLST.${OS__TYPE[$OS_TO_DELETE]}.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (1). $This_may_require_several_minutes''')"
[[ "$FORMAT_TYPE" != "NTFS (fast)" ]] && $WGETST $URLST.$FORMAT_TYPE.$CODO
}
