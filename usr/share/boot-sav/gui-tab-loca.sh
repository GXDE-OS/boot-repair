#! /bin/bash
# Copyright 2013-2023 Yann MRN
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

osbydefault_consequences() {
[[ "$GUI" ]] && echo 'SET@_button_mainapply.set_sensitive(False)' #To avoid applying before variables are changed
RETOURCOMBO_ostoboot_bydefault_OLD="$RETOURCOMBO_ostoboot_bydefault"
FORCE_PARTITION="${LISTOFPARTITIONS[$REGRUB_PART]}"
[[ "$DEBBUG" ]] && echo "[debug]osbydefault_consequences $FORCE_PARTITION"
combobox_separateusr_fillin
combobox_separateboot_fillin				#activates kernelpurge if necessary
combobox_efi_fillin							#activates grubpurge if necessary
combobox_place_grub_and_removable_fillin	#after separate_efi_show_hide & combobox_separateusr_fillin
if [[ "$GUI" ]];then
    [[ "${APTTYP[$USRPART]}" != nopakmgr ]] && echo 'SET@_checkbutton_purge_grub.show()' || echo 'SET@_checkbutton_purge_grub.hide()'
fi
activate_hide_lastgrub_if_necessary
BLANKEXTRA_ACTION="";
UNCOMMENT_GFXMODE="";
ATA=""; 
unset_kerneloption;
if [[ "$GUI" ]];then
    [[ "$GRUBPACKAGE" =~ efi ]] && echo 'SET@_checkbutton_blankextraspace.set_sensitive(False)' || echo 'SET@_checkbutton_blankextraspace.set_sensitive(True)'
    echo 'SET@_checkbutton_blankextraspace.set_active(False)'
    echo 'SET@_checkbutton_uncomment_gfxmode.set_active(False)'
    echo 'SET@_checkbutton_ata.set_active(False)'
    echo 'SET@_checkbutton_add_kernel_option.set_active(False)'
    echo 'SET@_button_mainapply.set_sensitive(True)'
fi
}

show_tab_grub_location() {
if [[ "$GUI" ]];then
    if [[ "$1" = on ]];then
        echo 'SET@_tab_grub_location.set_sensitive(True)'; echo 'SET@_vbox_grub_location.show()'
    else
        echo 'SET@_tab_grub_location.set_sensitive(False)'; echo 'SET@_vbox_grub_location.hide()'
    fi
fi
}

######################## Separate boot ############################
_checkbutton_separateboot() {
if [[ "${@}" = True ]]; then
	USE_SEPARATEBOOTPART=use-separate-boot; BOOTPART="$BOOTPART_TO_USE"
	[[ "$GUI" ]] && echo 'SET@_combobox_separateboot.set_sensitive(True)'
	if [[ "${BLKIDMNT_POINT[$REGRUB_PART]}" =~ sav/zfs ]] || [[ "$(df -Th / | grep zfs )" ]];then
		textwbz="Warning: this would impact fstab. This is not recommended with ZFS."
		[[ ! "$GUI" ]] && echo "$textwbz" || zenity --width=400 --warning --text="$textwbz" 2>/dev/null
	fi
else
	USE_SEPARATEBOOTPART=""; BOOTPART="$REGRUB_PART"
	[[ "$GUI" ]] && echo 'SET@_combobox_separateboot.set_sensitive(False)'
fi
activate_kernelpurge_if_necessary
select_place_grub_in_on_or_all_mbr
[[ "$DEBBUG" ]] && echo "[debug]USE_SEPARATEBOOTPART becomes : $USE_SEPARATEBOOTPART"
}

combobox_separateboot_fillin() {
QTY_PARTWITHOUTOS=0
if [[ "$SEP_BOOT_PARTS_PRESENCE" ]];then
	local typecsbf lup csbf fichier icsf
	[[ "$DEBBUG" ]] && echo "[debug]combobox_separateboot_fillin"
	[[ "$GUI" ]] && echo "COMBO@@CLEAR@@_combobox_separateboot"
	for typecsbf in is---sepboot maybesepboot;do
		for lup in 1 2 3;do #In priority sep boot located on the same disk
			for ((csbf=1;csbf<=NBOFPARTITIONS;csbf++)); do
				if ( [[ "$lup" = 1 ]] && [[ "${DISK_PART[$REGRUB_PART]}" = "${DISK_PART[$csbf]}" ]] && [[ "$csbf" = "${BOOTPART_IN_FSTAB_OF[$REGRUB_PART]}" ]] ) \
				|| ( [[ "$lup" = 2 ]] && [[ "${DISK_PART[$REGRUB_PART]}" = "${DISK_PART[$csbf]}" ]] && [[ "$csbf" != "${BOOTPART_IN_FSTAB_OF[$REGRUB_PART]}" ]] ) \
				|| ( [[ "$lup" = 3 ]] && [[ "${DISK_PART[$REGRUB_PART]}" != "${DISK_PART[$csbf]}" ]] ) \
				&& [[ "${PART_WITH_SEPARATEBOOT[$csbf]}" = "$typecsbf" ]];then
					(( QTY_PARTWITHOUTOS += 1 ))
					LIST_PARTWITHOUTOS[$QTY_PARTWITHOUTOS]="$csbf"
				fi
			done
		done
	done
    if [[ "$GUI" ]];then
        while read fichier; do echo "COMBO@@END@@_combobox_separateboot@@${fichier}";done < <( for ((icsf=1;icsf<=QTY_PARTWITHOUTOS;icsf++)); do
            echo "${LISTOFPARTITIONS[${LIST_PARTWITHOUTOS[$icsf]}]}"
        done)
        echo 'SET@_combobox_separateboot.set_active(0)'; 
        echo 'SET@_combobox_separateboot.set_sensitive(True)' #solves glade3 bug
        echo 'SET@_combobox_separateboot.set_sensitive(False)' #solves glade3 bug
        echo 'SET@_vbox_separateboot.show()'
    fi
    BOOTPART_TO_USE="${LIST_PARTWITHOUTOS[1]}"
else
	[[ "$GUI" ]] && echo 'SET@_vbox_separateboot.hide()'
fi

if [[ "$LIVESESSION" != live ]] && [[ "${BOOTPART_IN_FSTAB_OF[$REGRUB_PART]}" ]] \
	|| [[ "${BOOT_AND_KERNEL_IN[$REGRUB_PART]}" != with-boot ]] && [[ "$QTY_BOOTPART" != 0 ]];then
	USE_SEPARATEBOOTPART=use-separate-boot; BOOTPART="$BOOTPART_TO_USE"
	[[ "$GUI" ]] && echo 'SET@_checkbutton_separateboot.set_active(True)'
	[[ "$GUI" ]] && echo 'SET@_combobox_separateboot.set_sensitive(True)'
else
	USE_SEPARATEBOOTPART=""; BOOTPART="$REGRUB_PART"
	[[ "$GUI" ]] && echo 'SET@_checkbutton_separateboot.set_active(False)'
	[[ "$GUI" ]] && echo 'SET@_combobox_separateboot.set_sensitive(False)'
fi
if [[ "$GUI" ]] && [[ "$LIVESESSION" != live ]];then
	echo 'SET@_checkbutton_separateboot.set_sensitive(False)'
	echo 'SET@_combobox_separateboot.set_sensitive(False)'
fi
activate_kernelpurge_if_necessary
activate_grubpurge_if_necessary
}

_combobox_separateboot() {
local RET_sepboot="${@}" csb
[[ "$DEBBUG" ]] && echo "[debug]RET_sepboot (BOOTPART_TO_USE) : $RET_sepboot"
for ((csb=1;csb<=NBOFPARTITIONS;csb++)); do
	if [[ "$RET_sepboot" = "${LISTOFPARTITIONS[$csb]}" ]] && [[ "$USE_SEPARATEBOOTPART" ]];then
		if [[ "$LIVESESSION" = live ]];then
			BOOTPART_TO_USE="$csb"
			BOOTPART="$BOOTPART_TO_USE"
			activate_kernelpurge_if_necessary
			activate_grubpurge_if_necessary #if menu.lst
		fi
	fi
done
}

######################## Separate /usr #################################

combobox_separateusr_fillin() {
QTY_SEP_USR_PARTS=0
if [[ "$SEP_USR_PARTS_PRESENCE" ]];then
	local lup fichier icsf csbf
	[[ "$DEBBUG" ]] && echo "[debug]combobox_sepusr_fillin"
	[[ "$GUI" ]] && echo "COMBO@@CLEAR@@_combobox_sepusr"
	for lup in 1 2 3;do #In priority sep usr located on the same disk
		for ((csbf=1;csbf<=NBOFPARTITIONS;csbf++)); do
			if ( [[ "$lup" = 1 ]] && [[ "${DISK_PART[$REGRUB_PART]}" = "${DISK_PART[$csbf]}" ]] && [[ "$csbf" = "${USR_OF_PART[$REGRUB_PART]}" ]] ) \
			|| ( [[ "$lup" = 2 ]] && [[ "${DISK_PART[$REGRUB_PART]}" = "${DISK_PART[$csbf]}" ]] && [[ "$csbf" != "${USR_OF_PART[$REGRUB_PART]}" ]] ) \
			|| ( [[ "$lup" = 3 ]] && [[ "${DISK_PART[$REGRUB_PART]}" != "${DISK_PART[$csbf]}" ]] ) \
			&& [[ "${SEPARATE_USR_PART[$csbf]}" = is-sep-usr ]];then
				(( QTY_SEP_USR_PARTS += 1 ))
				LIST_SEP_USR_PARTS[$QTY_SEP_USR_PARTS]="$csbf"
			fi
		done
	done
    if [[ "$GUI" ]];then
        while read fichier; do echo "COMBO@@END@@_combobox_sepusr@@${fichier}";done < <( for ((icsf=1;icsf<=QTY_SEP_USR_PARTS;icsf++)); do
            echo "${LISTOFPARTITIONS[${LIST_SEP_USR_PARTS[$icsf]}]}"
        done)
        echo 'SET@_combobox_sepusr.set_active(0)'; 
        echo 'SET@_vbox_sepusr.show()'
    fi
    USRPART_TO_USE="${LIST_SEP_USR_PARTS[1]}"
else
	[[ "$GUI" ]] && echo 'SET@_vbox_sepusr.hide()'
fi

if [[ "$LIVESESSION" != live ]] && [[ "${USR_OF_PART[$REGRUB_PART]}" ]] \
|| [[ "${USRPRESENCE_OF_PART[$REGRUB_PART]}" != with--usr ]] && [[ "$QTY_SEP_USR_PARTS" != 0 ]];then
	USE_SEPARATEUSRPART=use-separate-usr
	USRPART="$USRPART_TO_USE"
	[[ "$GUI" ]] && echo 'SET@_combobox_sepusr.set_sensitive(True)' #solves glade3 bug
	[[ "$GUI" ]] && echo 'SET@_label_sepusr.set_sensitive(True)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_sepusr.set_active(True)'
else
	USE_SEPARATEUSRPART=""
	USRPART="$REGRUB_PART"
	[[ "$GUI" ]] && echo 'SET@_combobox_sepusr.set_sensitive(False)' #solves glade3 bug
	[[ "$GUI" ]] && echo 'SET@_label_sepusr.set_sensitive(False)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_sepusr.set_active(False)'
fi
if [[ "$GUI" ]] && [[ "$LIVESESSION" != live ]];then
	echo 'SET@_checkbutton_sepusr.set_sensitive(False)'
	echo 'SET@_combobox_sepusr.set_sensitive(False)'
fi
}

_combobox_sepusr() {
local RETOURCOMBO_separateusr="${@}" csb
[[ "$DEBBUG" ]] && echo "[debug]RETOURCOMBO_sepusr (USRPART_TO_USE) : $RETOURCOMBO_sepusr"
for ((csb=1;csb<=NBOFPARTITIONS;csb++)); do
	[[ "$RETOURCOMBO_sepusr" = "${LISTOFPARTITIONS[$csb]}" ]] && USRPART_TO_USE="$csb"
done
[[ "$USE_SEPARATEUSRPART" ]] && USRPART="$USRPART_TO_USE" && activate_grubpurge_if_necessary
}

############################## EFI #####################################
_checkbutton_efi() {
if [[ "${@}" = True ]];then
	set_efi
else
	unset_efi
fi
[[ "$DEBBUG" ]] && echo "[debug]GRUBPACKAGE becomes: $GRUBPACKAGE"
activate_grubpurge_if_necessary
}

set_efi() {
GRUBPACKAGE=grub-efi
[[ "$GUI" ]] && echo 'SET@_checkbutton_signed.show()'
if [[ "${SECUREBOOT%% *}" != disabled ]] && [[ "$ARCHIPC" != 32 ]] ;then #&& [[ "${ARCH_OF_PART[... != 32 ]] -> added as blockers before repair
	set_signed
	[[ "$GUI" ]] && echo 'SET@_checkbutton_signed.set_active(True)'
else #there is currently no grub-efi-ia32-signed
	unset_signed #works: http://ubuntuforums.org/showthread.php?t=2098914
	[[ "$GUI" ]] && echo 'SET@_checkbutton_signed.set_active(False)'
fi
[[ "$ARCHIPC" = 32 ]] && [[ "$GUI" ]] && echo 'SET@_checkbutton_signed.set_sensitive(False)'
[[ "$ARCHIPC" != 32 ]] && [[ "$GUI" ]] && echo 'SET@_checkbutton_signed.set_sensitive(True)'
[[ "$GUI" ]] && echo 'SET@_combobox_efi.set_sensitive(True)'
[[ "$GUI" ]] && echo 'SET@_vbox_place_or_force.hide()'
[[ "$GUI" ]] && echo 'SET@_checkbutton_legacy.hide()'
activate_hide_lastgrub_if_necessary
update_bkp_boxes
}
		
unset_efi() {
GRUBPACKAGE=grub2
[[ "$GUI" ]] && echo 'SET@_checkbutton_signed.hide()'
[[ "$GUI" ]] && echo 'SET@_combobox_efi.set_sensitive(False)'
[[ "$GUI" ]] && echo 'SET@_vbox_place_or_force.show()'
[[ "$GUI" ]] && echo 'SET@_checkbutton_legacy.show()'
activate_hide_lastgrub_if_necessary
update_bkp_boxes
}

_combobox_efi() {
local RETOURCOMBO_efi="${@}" i
[[ "$DEBBUG" ]] && echo "[debug]RETOURCOMBO_efi (EFIPART_TO_USE) : $RETOURCOMBO_efi"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	[[ "$RETOURCOMBO_efi" = "${LISTOFPARTITIONS[$i]}" ]] && EFIPART_TO_USE="$i"
done
[[ "$DEBBUG" ]] && echo "[debug]EFIPART_TO_USE becomes : $EFIPART_TO_USE"
}

combobox_efi_fillin() {
local lup1 lup mef icef temp tempdisq fichier
[[ "$DEBBUG" ]] && echo "[debug]combobox_efi_fillin ${LISTOFPARTITIONS[$REGRUB_PART]} , ${GPTTYPE[$REGRUB_PART]}"
QTY_EFIPART=0
QTY_SUREEFIPART=0
for lup in 1 2 3 4 5 6;do #same disk > not live-usb > live-usb 
	for mef in is---ESP hidenESP;do #not hidden first
		for wup in 1 2;do #esp without win files first, then esp with win files
			for mmcc in 1 2;do #avoid usb and mmc
				for egpt in is-GPT notGPT;do
					for ((icef=1;icef<=NBOFPARTITIONS;icef++));do
						temp=""
						tempdisq="${DISKNB_PART[$icef]}"
						if ( [[ "$wup" = 1 ]] && [[ ! "${WINEFI[$icef]}" ]] ) || ( [[ "$wup" = 2 ]] && [[ "${WINEFI[$icef]}" ]] ) \
						&& ( ( [[ "${USBDISK[$tempdisq]}" = not-usb ]] && [[ "${MMCDISK[$tempdisq]}" = not-mmc ]] && [[ "$mmcc" = 1 ]] ) \
						|| ( [[ "${USBDISK[$tempdisq]}" != not-usb ]] || [[ "${MMCDISK[$tempdisq]}" != not-mmc ]] && [[ "$mmcc" = 2 ]] ) ) \
						&& [[ "${EFI_TYPE[$icef]}" = "$mef" ]] && [[ "${GPT_DISK[$tempdisq]}" = "$egpt" ]];then
							if [[ "$tempdisq" = "${DISKNB_PART[$REGRUB_PART]}" ]];then
								[[ "$lup" = 1 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" = "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS and in fstab) in same disk"
								[[ "$lup" = 2 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" != "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS but not in fstab) in same disk"
							elif [[ "${USBDISK[$tempdisq]}" != liveusb ]] && [[ "${MMCDISK[$tempdisq]}" != livemmc ]];then
								[[ "$lup" = 3 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" = "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS and in fstab) in another disk"
								[[ "$lup" = 4 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" != "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS but not in fstab) in another disk"
							else
								[[ "$lup" = 5 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" = "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS and in fstab) in a live disk"
								[[ "$lup" = 6 ]] && [[ "${ESP_IN_FSTAB_OF_PART[$REGRUB_PART]}" != "$icef" ]] && temp=ok \
								&& [[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$icef]} EFI part (detected by BIS but not in fstab) in a live disk"
							fi
							if [[ "$temp" = ok ]];then
								(( QTY_EFIPART += 1 ))  #Listed in adv options
								LIST_EFIPART[$QTY_EFIPART]="$icef"
								[[ "$lup" != 5 ]] && [[ "$lup" != 6 ]] && (( QTY_SUREEFIPART += 1 )) #if ESP not on live disk , except if contains the OS
							fi
						fi
					done
				done
			done
		done
	done
done
if [[ "$GUI" ]];then
    echo "COMBO@@CLEAR@@_combobox_efi"
    while read fichier; do echo "COMBO@@END@@_combobox_efi@@${fichier}";done < <( for ((icef=1;icef<=QTY_EFIPART;icef++)); do
        echo "${LISTOFPARTITIONS[${LIST_EFIPART[$icef]}]}"
    done)
    echo 'SET@_combobox_efi.set_active(0)'; 
    echo 'SET@_combobox_efi.set_sensitive(True)' #solves glade3 bug
fi
EFIPART_TO_USE="${LIST_EFIPART[1]}"
NOTEFIREASON=""
[[ "$DEBBUG" ]] && echo "[debug]EFIFILPRESENT $EFIFILPRESENT, QTY_SUREEFIPART $QTY_SUREEFIPART"
#selects grub-efi if either winefi detected or if no legacy windows detected. If WinEFI detected, takes even ESP in live-discs as last chance.
#Windows is not Legacy if installed on GPT  (WIN_ON_GPT=y)
if ( [[ "$QUANTITY_OF_REAL_WINDOWS" = 0 ]] && [[ "$QTY_SUREEFIPART" != 0 ]] ) || [[ "$WIN_ON_GPT" ]] && [[ "$QTY_EFIPART" != 0 ]];then #forum.ubuntu-fr.org/viewtopic.php?id=1091731
    #boot-repair will block if [[ ! -d /sys/firmware/efi ]] 
	#&& [[ "$QUANTITY_OF_DETECTED_MACOS" = 0 ]] && [[ ! "$MACEFIFILEPRESENCE" ]] bug#1250611
	#[[ "${BIOS_BOOT_DISK[${DISKNB_PART[$EFIPART_TO_USE]}]}" != hasBIOSboot ]]
	set_efi
	[[ "$GUI" ]] && echo 'SET@_checkbutton_efi.set_active(True)'
else
	unset_efi
	[[ "$GUI" ]] && echo 'SET@_checkbutton_efi.set_active(False)'
	if [[ "$QTY_EFIPART" = 0 ]];then
		[[ "$GUI" ]] && echo 'SET@_vbox_efi.hide()'
		NOTEFIREASON="no ESP detected"  # Blocker if [[ "$WIN_ON_GPT" ]] && [[ "$QTY_EFIPART" = 0 ]]
	else
		[[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && NOTEFIREASON="legacy Windows detected"
		[[ "$QTY_SUREEFIPART" = 0 ]] && NOTEFIREASON="no ESP detected outside live discs"
	fi
fi
activate_grubpurge_if_necessary
}

######################### OS to boot by default ########################
_combobox_ostoboot_bydefault() {
local cotbbd
RETOURCOMBO_ostoboot_bydefault="${@}"
[[ "$DEBBUG" ]] && echo "[debug]RETOURCOMBO_ostoboot_bydefault : ${RETOURCOMBO_ostoboot_bydefault}"
if [[ "$RETOURCOMBO_ostoboot_bydefault" = "$RETOURCOMBO_ostoboot_bydefault_OLD" ]];then
	[[ "$DEBBUG" ]] && echo "[debug]Warning: Duplicate _combobox_ostoboot_bydefault (probably user tried to select impossible OS)"
elif [[ "$RETOURCOMBO_ostoboot_bydefault" =~ "(via" ]];then
	REGRUB_PART="${LIST_OF_PART_FOR_REINSTAL[1]}"
	CHANGEDEFAULTOS="$RETOURCOMBO_ostoboot_bydefault"
	osbydefault_consequences
else
	for ((cotbbd=1;cotbbd<=NBOFPARTITIONS;cotbbd++)); do 
		[[ "$DEBBUG" ]] && echo "[debug]${LABEL_PART_FOR_REINSTAL[$cotbbd]}"
		if [[ "$RETOURCOMBO_ostoboot_bydefault" =~ "${LISTOFPARTITIONS[$cotbbd]#*/dev/} " ]];then
			if [[ "$REGRUB_PART" = "$cotbbd" ]];then
				[[ "$DEBBUG" ]] && echo "[debug]Warning: Duplicate _combobox_ostoboot_bydefault ${LISTOFPARTITIONS[$i]}."
			elif [[ "$LIVESESSION" != live ]] && [[ "$cotbbd" != 1 ]];then
                echo "$Please_use_in_live_session $This_will_enable_this_feature"
                [[ "$GUI" ]] && zenity --width=400 --info --timeout=3 --title="$APPNAME2" --text="$Please_use_in_live_session $This_will_enable_this_feature" 2>/dev/null
				[[ "$GUI" ]] && echo 'SET@_combobox_ostoboot_bydefault.set_active(0)'
			elif [[ "${ARCH_OF_PART[$cotbbd]}" = 64 ]] && [[ "$(uname -m)" != x86_64 ]] && [[ "$cotbbd" != 1 ]];then
                echo "$Please_use_in_a_64bits_session $This_will_enable_this_feature"
				[[ "$GUI" ]] && zenity --width=400 --info --timeout=3 --title="$APPNAME2" --text="$Please_use_in_a_64bits_session $This_will_enable_this_feature" 2>/dev/null
				[[ "$GUI" ]] && echo 'SET@_combobox_ostoboot_bydefault.set_active(0)'
			else
				REGRUB_PART="$cotbbd"
				CHANGEDEFAULTOS=""
				osbydefault_consequences
			fi
		fi
	done
fi
}

combobox_ostoboot_bydefault_fillin() {
local cotbdf cotbdfb fichier parttmpp
[[ "$DEBBUG" ]] && echo "[debug]combobox_ostoboot_bydefault_fillin"
QTY_OF_PART_FOR_REINSTAL=0
if [[ "$QTY_OF_PART_WITH_GRUB" != 0 ]] || [[ "$QTY_OF_PART_WITH_APTGET" != 0 ]];then
	if [[ "$(uname -m)" != x86_64 ]];then
		[[ "$DEBBUG" ]] && echo "[debug]Order Linux according to their arch type, first 32bit then 64bit"
		loop_ostoboot_bydefault_fillin 64
		loop_ostoboot_bydefault_fillin 32
	else
		loop_ostoboot_bydefault_fillin noorder
	fi
	if [[ "$QTY_OF_PART_FOR_REINSTAL" != 0 ]];then
		if [[ ! "$OS_TO_DELETE_NAME" ]];then
			for ((cotbdf=1;cotbdf<=NBOFPARTITIONS;cotbdf++)); do
				if [[ "$(grep "${LISTOFPARTITIONS[$cotbdf]#*/dev/}:" <<< "$OSPROBER" )" ]] && [[ ! "${GRUBOK_OF_PART[$cotbdf]}" ]] && [[ "${APTTYP[$cotbdf]}" = nopakmgr ]] \
				&& [[ "${USR_IN_FSTAB_OF_PART[$cotbdf]}" = part-has-no-fstab ]] && [[ "$cotbdf" != "${LIST_OF_PART_FOR_REINSTAL[1]}" ]];then
					(( QTY_OF_PART_FOR_REINSTAL += 1 ))
					LIST_OF_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]="$cotbdf"
					LABEL_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]="${LISTOFPARTITIONS[$cotbdf]#*/dev/}:${OSNAME[$cotbdf]} \(via ${LISTOFPARTITIONS[${LIST_OF_PART_FOR_REINSTAL[1]}]#*/dev/} menu\)"
				fi
			done
		fi
        if [[ "$GUI" ]];then
            while read fichier; do echo "COMBO@@END@@_combobox_ostoboot_bydefault@@${fichier}";done < <( for ((cotbdf=1;cotbdf<=QTY_OF_PART_FOR_REINSTAL;cotbdf++)); do
                echo "${LABEL_PART_FOR_REINSTAL[$cotbdf]}"
            done)
            echo 'SET@_combobox_ostoboot_bydefault.set_sensitive(True)' #solves glade3 bug
        fi
	fi
fi
}


loop_ostoboot_bydefault_fillin() {
local tmparch=$1 ilobf grubtmp looop bootyp
if [[ "$LIVESESSION" != live ]];then
	for ((ilobf=1;ilobf<=NBOFPARTITIONS;ilobf++)); do #TODO to be checked, maybe use same ordering as below
		[[ "${GRUBOK_OF_PART[$ilobf]}" ]] || [[ "${APTTYP[$ilobf]}" != nopakmgr ]] \
		|| ( [[ "${USR_IN_FSTAB_OF_PART[$ilobf]}" != part-has-no-fstab ]] && [[ "$SEP_USR_PARTS_PRESENCE" ]] ) \
		&& subloop_ostobootbydefault_fillin
	done
else
	[[ "$DEBBUG" ]] && echo "[debug]Order Linux $tmparch bits"
	for looop in 1 2 3 4;do #Reinstall, then purge, then sep /usr
		for grubtmp in grub2 grub1 nogrub;do #prefers Linux with grub-install then maybe separate /usr	
			for bootyp in with-boot no-kernel no---boot;do #prefers Linux with /boot then /boot without kernel, then maybe separate /boot	
				for dischaswin in has-win no-wind;do #prefers linux not on same disc as windows
					for ((ilobf=1;ilobf<=NBOFPARTITIONS;ilobf++)); do
						if [[ "${GRUBVER[$ilobf]}" = "$grubtmp" ]] && [[ "${BOOT_AND_KERNEL_IN[$ilobf]}" = "$bootyp" ]] \
						&& [[ "${REALWINONDISC[${DISKNB_PART[$ilobf]}]}" != "$dischaswin" ]];then
							if [[ "$looop" = 1 ]] && [[ "${GRUBOK_OF_PART[$ilobf]}" ]] && [[ "${APTTYP[$ilobf]}" != nopakmgr ]];then
								subloop_ostobootbydefault_fillin
							elif [[ "$looop" = 2 ]] && [[ "${GRUBOK_OF_PART[$ilobf]}" ]] && [[ "${APTTYP[$ilobf]}" = nopakmgr ]];then
								subloop_ostobootbydefault_fillin
							elif [[ "$looop" = 3 ]] && [[ "${APTTYP[$ilobf]}" != nopakmgr ]] \
							&& [[ ! "${GRUBOK_OF_PART[$ilobf]}" ]];then
								subloop_ostobootbydefault_fillin
							elif [[ "$looop" = 4 ]] && [[ "${APTTYP[$ilobf]}" = nopakmgr ]] \
							&& [[ ! "${GRUBOK_OF_PART[$ilobf]}" ]] && [[ "$SEP_USR_PARTS_PRESENCE" ]] \
							&& [[ "${USR_IN_FSTAB_OF_PART[$ilobf]}" != part-has-no-fstab ]];then
								subloop_ostobootbydefault_fillin	
							fi
						fi
					done
				done
			done
		done
	done
fi
}

subloop_ostobootbydefault_fillin() {
if [[ "${LISTOFPARTITIONS[$ilobf]}" != "$OS_TO_DELETE_PARTITION" ]] && [[ "${PART_WITH_OS[$ilobf]}" = is-os ]] \
&& [[ "${ARCH_OF_PART[$ilobf]}" != "$tmparch" ]] && [[ "${ARCH_OF_PART[$ilobf]}" ]];then
	(( QTY_OF_PART_FOR_REINSTAL += 1 ))
	LIST_OF_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]="$ilobf"
	[[ "${OSNAME[$ilobf]}" ]] \
	&& LABEL_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]="${LISTOFPARTITIONS[$ilobf]#*/dev/} \(${OSNAME[$ilobf]}\)" \
	|| LABEL_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]="${LISTOFPARTITIONS[$ilobf]#*/dev/}"
	[[ "$DEBBUG" ]] && echo "[debug]LABEL_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL] ${LABEL_PART_FOR_REINSTAL[$QTY_OF_PART_FOR_REINSTAL]}"
fi
}

##################### Removable disk
_checkbutton_is_removable_disk() {
[[ "${@}" = True ]] && REMOVABLEDISK=is-removable-disk || REMOVABLEDISK=""
[[ "$DEBBUG" ]] && echo "[debug]REMOVABLEDISK becomes : $REMOVABLEDISK"
}

##################### Place all disks
_radiobutton_place_alldisks() {
[[ "${@}" = True ]] && set_radiobutton_place_alldisks || echo 'SET@_vbox_is_removable_disk.hide()'
}

set_radiobutton_place_alldisks() {
local srpad
[[ "$DEBBUG" ]] && echo "[debug]set_radiobutton_place_alldisks"
FORCE_GRUB=place-in-all-MBRs
if [[ "$GUI" ]];then
	for ((srpad=1;srpad<=QTY_OF_PART_WITH_GRUB;srpad++)); do
		[[ "${DISK_PART[$REGRUB_PART]}" != "${DISK_PART[${LIST_OF_PART_WITH_GRUB[$srpad]}]}" ]] && echo 'SET@_vbox_is_removable_disk.show()'
	done
fi
}

#################### Place GRUB
_radiobutton_place_grub() {
[[ "${@}" = True ]] && set_radiobutton_place_grub || echo 'SET@_combobox_place_grub.set_sensitive(False)'
}

set_radiobutton_place_grub() {
[[ "$DEBBUG" ]] && echo "[debug]set_radiobutton_place_grub"
[[ "$GUI" ]] && echo 'SET@_combobox_place_grub.set_sensitive(True)'; FORCE_GRUB=place-in-MBR
}

_combobox_place_grub() {
NOFORCE_DISK="${@}"
[[ "$DEBBUG" ]] && echo "[debug]RETOURCOMBO_place_grub (NOFORCE_DISK) : $NOFORCE_DISK"
}

combobox_place_grub_and_removable_fillin() {
local fichier cpgarf DISKA a DISK1
#Place GRUB into #########
NOFORCE_DISK="${DISK_PART[$REGRUB_PART]}"
if [[ "$GUI" ]];then
	echo "COMBO@@CLEAR@@_combobox_place_grub"
	while read fichier; do
		echo "COMBO@@END@@_combobox_place_grub@@${fichier}";
	done < <( echo "${NOFORCE_DISK}";
	for ((cpgarf=1;cpgarf<=NBOFDISKS;cpgarf++)); do
		[[ "${LISTOFDISKS[$cpgarf]}" != "${NOFORCE_DISK}" ]] && echo "${LISTOFDISKS[$cpgarf]}" #Propose by default the disk of PART_TO_REINSTALL_GRUB
	done)
	echo 'SET@_combobox_place_grub.set_active(0)'
fi

#Place GRUB in all MBR , and removable disk ####
select_place_grub_in_on_or_all_mbr

#Force GRUB into #########
FORCE_PARTITION="${LISTOFPARTITIONS[$REGRUB_PART]}"
[[ "$GUI" ]] && echo "SET@_label_force_grub.set_text('''$Force_GRUB_into $FORCE_PARTITION ($for_chainloader)''')"
}

select_place_grub_in_on_or_all_mbr() {
#called by combobox_place_grub_and_removable_fillin & _checkbutton_separateboot
REMOVABLEDISK=""
SHOW_REMOVABLEDISK=no
#if [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] && [[ ! "$MACEFIFILEPRESENCE" ]];then
#	[[ "$GUI" ]] && echo 'SET@_radiobutton_force_grub.show()'
#	if [[ "$FORCE_GRUB" != force-in-PBR ]];then
#		echo 'SET@_radiobutton_force_grub.set_active(True)'; FORCE_GRUB=force-in-PBR
#	fi
# ( [[ ! "$USE_SEPARATEBOOTPART" ]] && [[ ! "$USE_SEPARATEUSRPART" ]] ||
#RAID is broken if install GRUB in sdX
#Mac: forum.ubuntu-fr.org/viewtopic.php?id=1091731
#fi
#if [[ "/${LISTOFPARTITIONS[$REGRUB_PART]}" =~ "/md" ]] || [[ ! "${LISTOFPARTITIONS[$REGRUB_PART]}" =~ "mapper/" ]] && [[ "$NBOFDISKS" != 1 ]] && [[ ! "$GRUBPACKAGE" =~ efi ]];then
#	[[ "$GUI" ]] && echo 'SET@_radiobutton_place_alldisks.show()'
#	if [[ "$QUANTITY_OF_REAL_WINDOWS" = 0 ]];then
#		[[ "$GUI" ]] && echo 'SET@_radiobutton_place_alldisks.set_active(True)';
#		set_radiobutton_place_alldisks
#		DISKA="${DISK_PART[$REGRUB_PART]}"
#		for ((cpgarf=1;cpgarf<=TOTAL_QUANTITY_OF_OS;cpgarf++));do
#			if [[ "${OS__DISK[$cpgarf]}" != "$DISKA" ]];then
#				[[ "$DEBBUG" ]] && echo "[debug]It exists another disk with OS"
#				[[ "$GUI" ]] && echo 'SET@_vbox_is_removable_disk.show()'
#				a="$(grep "${DISKA}:" <<< "$PARTEDLM" )"; a="${a%:*}"; a="${a##*:}"
#				[[ "$a" ]] && DISK5="$DISKA ($a)" || DISK5="$DISKA"
#				DISK1="$DISK5"
#				update_translations
#				[[ "$GUI" ]] && echo "SET@_label_is_removable_disk.set_text('''$DISK5_is_a_removable_disk''')"
#				SHOW_REMOVABLEDISK=yes
#				if [[ ! "${REMOVABLE[$DISKA]}" ]];then
#					#end_pulse
#					REMOVABLE[$DISKA]=yes
#					if [[ ! "$FORCEYES" ]];then
#						if [[ "$GUI" ]];then
#							zenity --width=400 --question --text="$Is_DISK1_removable" 2>/dev/null || REMOVABLE[$DISKA]=no
#						else
#							read -r -p "$Is_DISK1_removable [yes/no] " response
#							[[ "$response" =~ y ]] || REMOVABLE[$DISKA]=no
#						fi
#					fi
#					[[ "$DEBBUG" ]] && echo "$Is_DISK1_removable ${REMOVABLE[$DISKA]}"
#					USERCHOICES="$USERCHOICES
#Is ${DISK1} a removable disk? ${REMOVABLE[$DISKA]}"
#				fi
#				if [[ "${REMOVABLE[$DISKA]}" = yes ]];then
#					REMOVABLEDISK=is-removable-disk;
#					[[ "$GUI" ]] && echo 'SET@_checkbutton_is_removable_disk.set_active(True)'
#				else
#					REMOVABLEDISK="";
#					[[ "$GUI" ]] && echo 'SET@_checkbutton_is_removable_disk.set_active(False)'
#				fi			
#				break
#			fi
#		done
#	else
#		[[ "$GUI" ]] && echo 'SET@_radiobutton_place_grub.set_active(True)';
#		set_radiobutton_place_grub
#	fi
#else
	[[ "$GUI" ]] && echo 'SET@_radiobutton_place_grub.set_active(True)';
	set_radiobutton_place_grub
#fi
}

######################## Force GRUB
_radiobutton_force_grub() {
[[ "${@}" = True ]] && FORCE_GRUB=force-in-PBR
[[ "$DEBBUG" ]] && echo "[debug]FORCE_GRUB becomes : $FORCE_GRUB"
}
