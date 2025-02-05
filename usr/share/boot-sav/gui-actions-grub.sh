#! /bin/bash
# Copyright 2024 Yann MRN
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


###################### ADD OR REMOVE /BOOT /USR /BOOT/EFI IN FSTAB #################################
fix_fstab() {
local bootusr CHANGEDONE TMPPART_TO_USE FSTABFIXTYPE line CORRECTLINE NEWFSTAB ADDIT temp regrubfstab="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/fstab"
if [[ ! -f "$regrubfstab" ]];then
	echo "Error: no $regrubfstab"
else
	for bootusr in /boot /usr /boot/efi;do
		[[ "$bootusr" = /boot ]] && TMPPART_TO_USE="$BOOTPART_TO_USE" && FLINE1A=0 && FLINE1B=2 && FLINE2A=1 && FLINE2B=2 #1204, Fedora13
		[[ "$bootusr" = /usr ]] && TMPPART_TO_USE="$USRPART_TO_USE" && FLINE1A=0 && FLINE1B=2 && FLINE2A=1 && FLINE2B=2 #1204, ?
		[[ "$bootusr" = /boot/efi ]] && TMPPART_TO_USE="$EFIPART_TO_USE" && FLINE1A=0 && FLINE1B=1 && FLINE2A=1 && FLINE2B=1 #1204, ?
		( [[ "$bootusr" = /boot ]] && [[ "$USE_SEPARATEBOOTPART" ]] ) \
		|| ( [[ "$bootusr" = /usr ]] && [[ "$USE_SEPARATEUSRPART" ]] ) \
		|| ( [[ "$bootusr" = /boot/efi ]] && [[ "$GRUBPACKAGE" =~ efi ]] ) \
		&& FSTABFIXTYPE=added || FSTABFIXTYPE=removed
		if [[ "$LIVESESSION" != live ]] && [[ "$bootusr" != /boot/efi ]];then
			[[ "$DEBBUG" ]] && echo "[debug] $bootusr not $FSTABFIXTYPE in installed session"
		elif [[ ! "${PART_UUID[$TMPPART_TO_USE]}" ]] && [[ "$FSTABFIXTYPE" = added ]];then
			echo "Error: no UUID to add $bootusr $TMPPART_TO_USE (${LISTOFPARTITIONS[$TMPPART_TO_USE]#*/dev/}, ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/})"
		else
			OLDFSTAB="$LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/etc_fstab_old"
			[[ ! -f "$OLDFSTAB" ]] && cp "$regrubfstab" "$OLDFSTAB"
			NEWFSTAB="$LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/etc_fstab_new"
			rm -f "$NEWFSTAB"
			ADDIT=""
			if [[ "$FSTABFIXTYPE" = added ]];then
				temp="$(lsblk -n -o FSTYPE ${LISTOFPARTITIONS[$TMPPART_TO_USE]} )" #ex: vfat
				CORRECTLINEBEG="UUID=${PART_UUID[$TMPPART_TO_USE]}  $bootusr       $temp"
				CORRECTLINEMID1='    umask=0077      ' #20.04 /boot/efi (https://forum.ubuntu-fr.org/viewtopic.php?pid=22273685#p22273685) UUID=FC23-4CBE  /boot/efi       vfat    umask=0077      0       1
				CORRECTLINEMID2='    defaults      '
				CORRECTLINEMID3='    relatime      '
				CORRECTLINEMID4='    umask=0022,fmask=0022,dmask=0022      ' #20.04 /boot/efi in zfs install
				CORRECTLINEEND1="$FLINE1A       $FLINE1B"
				CORRECTLINEEND2="$FLINE2A       $FLINE2B"
				ADDIT=yes
			fi
			CHANGEDONE=""
			while read line; do
				if [[ "$line" =~ "$bootusr" ]] && [[ ! "$line" =~ "$bootusr/" ]] && [[ ! "$line" =~ "#" ]];then
					CONTROL=""
					if [[ "$FSTABFIXTYPE" = added ]];then
						for midlin in "$CORRECTLINEMID1" "$CORRECTLINEMID2" "$CORRECTLINEMID3" "$CORRECTLINEMID4";do #check all possible combinations, and allow any nb of spaces
							for endlin in "$CORRECTLINEEND1" "$CORRECTLINEEND2";do
								[[ "$(echo "$line" | sed 's/ //g' )" = "$(echo "$CORRECTLINEBEG$midlin$endlin" | sed 's/ //g' )" ]] && CONTROL=correct_lin_already_in_fstab
							done
						done
					fi
					if [[ "$CONTROL" ]];then
						echo "$line" >> "$NEWFSTAB"
						ADDIT="" #If the correct line was already in fstab, keep it and don't add a new one
					else
						CHANGEDONE=yes && echo "#$line" >> "$NEWFSTAB" #Comment any incorrect line containing $bootusr
					fi
				else
					echo "$line" >> "$NEWFSTAB"
				fi
			done < <(cat "$regrubfstab" )
			[[ "$ADDIT" ]] && CHANGEDONE=yes && echo "$CORRECTLINEBEG$CORRECTLINEMID2$CORRECTLINEEND1" >> "$NEWFSTAB"  #add a new line
			if [[ ! "$CHANGEDONE" ]];then
				[[ "$DEBBUG" ]] && echo "[debug]$regrubfstab unchanged for $bootusr"
			elif [[ -f "$NEWFSTAB" ]];then
				cp "$NEWFSTAB" "$regrubfstab"
				echo "$bootusr $FSTABFIXTYPE in ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/fstab"
			else
				echo "Error: no $NEWFSTAB"
			fi
		fi
	done
fi
}

fix_grub_d() {
#Fix incorrect file rights http://forum.ubuntu-fr.org/viewtopic.php?pid=9665071
local fichero direct="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d/"
if [[ -d "$direct" ]];then
	for fichero in $(ls "$direct" 2>/dev/null);do
		if [[ "$(grep '_' <<< $fichero )" ]] && [[ "$(ls -l "$direct" 2>/dev/null | grep "$fichero" | grep -v rwxr-xr-x )" ]];then
			chmod a+x "$direct$fichero"
			echo "Fixed file rights of $direct$fichero"
		fi
	done
	[[ "$DEBBUG" ]] && echo "[debug]End fix $direct"
else
	echo "No $direct folder. $PLEASECONTACT"
fi
}


########################### REINSTALL GRUB ##############################
reinstall_grub_from_chosen_linux() {
#called by purge_end & actions_final
[[ "$UNCOMMENT_GFXMODE" ]] && uncomment_gfxmode
[[ "$ADD_KERNEL_OPTION" ]] && add_kernel_option
fix_grub_d
[[ "$FORCE_GRUB" = place-in-all-MBRs ]] && [[ ! "$GRUBPACKAGE" =~ efi ]] \
&& [[ ! "$REMOVABLEDISK" ]] && loop_install_grub_in_all_other_disks
#Reinstall in main MBR at the end to avoid core.img missing
NOW_IN_OTHER_DISKS=""
NOFORCE_DISK="$BCKUPNOFORCE_DISK"
reinstall_grub
[[ "${UPDATEGRUB_OF_PART[$USRPART]}" != noupdategrub ]] && grub_mkconfig_main
if [[ "$KERNEL_PURGE" ]] || [[ "$GRUBPURGE_ACTION" ]];then
	restore_resolvconf_and_unchroot
else
	unchroot_linux_to_reinstall
fi
mount_all_blkid_partitions_except_df
#[[ "$DEBBUG" ]] && echo "[debug]Mount all the partitions for the logs"
}



reinstall_grub_from_non_removable() {
NOW_USING_CHOSEN_GRUB=""  #used in 'force_unmount_and_prepare_chroot', and 'mount_separate_boot_if_required'
NOW_IN_OTHER_DISKS=yes  #used in 'reinstall_grubstageone'
[[ "$FORCE_GRUB" = place-in-all-MBRs ]] && NOFORCE_DISK="${DISK_PART[$REGRUB_PART]}" #in case user changed disc before selecting install-in-all-mbrs
BCKUPREGRUB_PART="$REGRUB_PART"
BCKUPNOFORCE_DISK="$NOFORCE_DISK"
BCKUPUSRPART="$USRPART"
if [[ ! "$GRUBPACKAGE" =~ efi ]] && [[ "$FORCE_GRUB" = place-in-all-MBRs ]] && [[ "$REMOVABLEDISK" ]];then
	local x n icrmf GRUBOS_ON_OTHERDISK=""
	[[ "$DEBBUG" ]] && echo "$NOFORCE_DISK is removable, so we reinstall GRUB of the removable media only in its disk MBR"
	REGRUB_PART=none
	for y in 1 2;do # Try to reinstall, then purge
		for ((x=1;x<=NBOFPARTITIONS;x++));do
			if ( [[ "$y" = 1 ]] && [[ "${GRUBOK_OF_PART[$x]}" ]] ) \
			|| ( [[ "$y" = 2 ]] && [[ ! "${GRUBOK_OF_PART[$x]}" ]] && [[ "${APTTYP[$x]}" != nopakmgr ]]) \
			&& ( [[ "${ARCH_OF_PART[$x]}" = 32 ]] || [[ "$(uname -m)" = x86_64 ]] ) \
			&& [[ "$REGRUB_PART" = none ]] \
			&& ( [[ "${GPT_DISK[${DISKNB_PART[$x]}]}" != is-GPT ]] || [[ "${BIOS_BOOT_DISK[${DISKNB_PART[$x]}]}" != no-BIOSboot ]] ) \
			&& [[ "${REALWINONDISC[${DISKNB_PART[$x]}]}" = no-wind ]] \
			&& [[ "${DISK_PART[$x]}" != "$BCKUPNOFORCE_DISK" ]];then
				GRUBOS_ON_OTHERDISK=yes
				if [[ "$LIVESESSION" = live ]] && [[ ! "$USE_SEPARATEBOOTPART" ]] && [[ ! "$USE_SEPARATEUSRPART" ]];then
					REGRUB_PART="$x"
					if [[ "${GRUBOK_OF_PART[$x]}" ]];then
						USRPART="$x"
						loop_install_grub_in_all_other_disks #First installs the grub of the 2nd Linux (the one on non-removable disc) in MBRs of discs without OS
						if [[ "$INSTALLEDINOTHERDISKS" ]];then
							[[ "${UPDATEGRUB_OF_PART[$USRPART]}" != noupdategrub ]] && grub_mkconfig_main
							unchroot_linux_to_reinstall
							mount "${LISTOFPARTITIONS[$BCKUPREGRUB_PART]}" "${BLKIDMNT_POINT[$BCKUPREGRUB_PART]}"
						fi
					else
						#PURGE_IN_OTHER_DISKS=yes
						# grub_purge
						echo "Warning: you may need to run this tool again after disconnecting the removable disk. $PLEASECONTACT"
					fi
					break
					break
				fi
			fi
		done
	done
#	if [[ ! "$GRUBOS_ON_OTHERDISK" ]];then #No GRUB on other disks, so will restore MBRs
#		for ((n=1;n<=NBOFDISKS;n++));do
#			if [[ "${USBDISK[$n]}" != liveusb ]] && [[ "${MMCDISK[$n]}" != livemmc ]] && [[ "${DISK_HASOS[$n]}" = has-os ]] \
#			&& [[ "${GPT_DISK[$n]}" != is-GPT ]] && [[ "${EFI_DISK[$n]}" = has-noESP ]] && [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]];then
#				for ((icrmf=1;icrmf<=NB_MBR_CAN_BE_RESTORED;icrmf++));do
#					MBR_TO_RESTORE="${MBR_CAN_BE_RESTORED[$icrmf]}"
#					if [[ "$MBR_TO_RESTORE" =~ "${LISTOFDISKS[$n]} " ]];then
#						combobox_restore_mbrof_consequences
#						restore_mbr
#						break
#					fi
#				done
#			fi
#		done
#	el
	if [[ ! "$LIVESESSION" = live ]] || [[ "$USE_SEPARATEBOOTPART" ]] || [[ "$USE_SEPARATEUSRPART" ]] && [[ "$GRUBOS_ON_OTHERDISK" ]];then
		GRUBFOUNDONANOTHERDISK=yes
	fi
	REGRUB_PART="$BCKUPREGRUB_PART"; USRPART="$BCKUPUSRPART"
fi
NOW_USING_CHOSEN_GRUB=yes
force_unmount_and_prepare_chroot
}



reinstall_grub() {
FORCEPARAM=""
RECHECK=""
#title_gen "lspci -nnk | grep -iA3 vga"
#${CHROOTCMD}lspci -nnk | grep -iA3 vga
title_gen "Reinstall the $GRUBPACKAGE of ${LISTOFPARTITIONS[$REGRUB_PART]}"
echo "$CHROOTCMD${GRUBTYPE_OF_PART[$USRPART]} --version"
GVERSION="$($CHROOTCMD${GRUBTYPE_OF_PART[$USRPART]} --version)" #-v in old, -V in new distros
# grub-install (GNU GRUB 0.97), "grub-install (GRUB) 1.99-21ubuntu3.1", or "grub-install (GRUB) 2.00-5ubuntu3", "grub-install (GRUB) 2.02~beta2-9ubuntu1"
GSVERSION="${GVERSION%%.*}"  #grub-install (GRUB) 1 or "grub-install (GNU GRUB 0" or "grub-install (GRUB) 2"
echo "$GVERSION"
if ( [[ "$GSVERSION" =~ 0 ]] && [[ ! "$GRUBPACKAGE" = grub ]] ) \
|| ( [[ ! "$GSVERSION" =~ 0 ]] && [[ "$GRUBPACKAGE" = grub ]] );then
	ERROR="Wrong GRUB version detected ($GSVERSION). $PLEASECONTACT"; echo "$ERROR"
	[[ "$GSVERSION" =~ 0 ]] && GRUBPACKAGE=grub
	[[ ! "$GSVERSION" =~ 0 ]] && GRUBPACKAGE=grub-pc
fi
[[ "$GSVERSION" =~ 0 ]] && ATA=""
if [[ "$GRUBPACKAGE" =~ efi ]];then
	[ -d /sys/firmware/efi ] && echo "${CHROOTCMD}modprobe efivars $(LC_ALL=C ${CHROOTCMD}modprobe efivars)" #cf geole / ubuntu-fr
	[[ "$GSVERSION" =~ 0 ]] || [[ "$GSVERSION" =~ 1 ]] && [[ ! "$GVERSION" =~ "1.99-21" ]] && [[ "$GRUBPACKAGE" =~ signed ]] \
	&& echo "GRUB too old for SecureBoot. Defaulting to grub-efi. $PLEASECONTACT" && GRUBPACKAGE=grub-efi
	echo "
${CHROOTCMD}efibootmgr -v (filtered) before grub install"
	EFIBMGRBEF="$(LANGUAGE=C LC_ALL=C ${CHROOTCMD}efibootmgr -v | grep -v dp: | grep -v data:)"
	echo "$EFIBMGRBEF

${CHROOTCMD}uname -r"
	RARINGK="$(LANGUAGE=C LC_ALL=C ${CHROOTCMD}uname -r)"
	echo "$RARINGK"
#	BUGGYK=""
#	[[ "$RARINGK" =~ 3.8.0-[1-9][0-9] ]] || [[ "$RARINGK" =~ 3.8.[1-9] ]] || [[ "$RARINGK" =~ 3.9.[0-9] ]] && BUGGYK=is-buggy
#	[[ "$BUGGYK" ]] && FUNCTION=buggy-kernel || FUNCTION=WinEFI
#	if [[ ! "$WINEFI_BKP_ACTION" ]];then
#		OPTION="$Msefi_too"
#		repbg=yes
#		update_translations
#		end_pulse
#		zenity --width=400 --question --title="$APPNAME2" --text="$FUNCTION_detected $Do_you_want_activate_OPTION $If_any_fail_try_other" 2>/dev/null || repbg=no
#		echo "$FUNCTION_detected $Do_you_want_activate_OPTION $repbg $If_any_fail_try_other"
#		start_pulse
#		[[ "$repbg" = yes ]] && WINEFI_BKP_ACTION=" rename-ms-efi" && CREATE_BKP_ACTION=backup-and-rename-efi-files #fixes 1173423
#	fi
	GRUBSTAGEONE=""
	DEVGRUBSTAGEONE=""
	[[ "$GSVERSION" =~ 2 ]] && [[ "${ARCH_OF_PART[$USRPART]}" = 32 ]] && FORCEPARAM=" --efi-directory=/boot/efi --target=i386-efi"
	if [[ "${ARCH_OF_PART[$USRPART]}" = 64 ]];then
		[[ "$GSVERSION" =~ 2 ]] && FORCEPARAM=" --efi-directory=/boot/efi --target=x86_64-efi"
		if [[ "$GRUBPACKAGE" =~ signed ]];then
			FORCEPARAM="$FORCEPARAM --uefi-secure-boot"
		#elif [[ "$GVERSION" = "2.06~4~manjaro" ]] || [[ "$GVERSION" = "2.02~beta2" ]];then
		#	FORCEPARAM="$FORCEPARAM" #unrecognized option '--no-uefi-secure-boot' for 2.06~4~manjaro
		#else
		#	FORCEPARAM="$FORCEPARAM --no-uefi-secure-boot"
		fi
	fi
	[[ "$GVERSION" =~ "1.99-21ubuntu3.10" ]] && FORCEPARAM="$FORCEPARAM $NOFORCE_DISK"
	ATA=""
	[[ "$CHROOTCMD" =~ /boot-sav/zfs ]] && fix_etc_default_grub_for_zfs
	reinstall_grubstageone
	echo "
${CHROOTCMD}efibootmgr -v (filtered) after grub install"
	EFIBMGRAFT="$(LANGUAGE=C LC_ALL=C ${CHROOTCMD}efibootmgr -v | grep -v dp: | grep -v data:)"
	echo "$EFIBMGRAFT"
	if [[ "$EFIBMGRBEF" = "$EFIBMGRAFT" ]];then
		LSBRELIS="$(LANGUAGE=C LC_ALL=C ${CHROOTCMD}lsb_release -is)"
		if ( [[ "$(echo "$LSBRELIS" | grep -i Mint )" ]] || [[ "$(echo "$LSBRELIS" | grep -i Zorin )" ]] && [[ "$EFIBMGRAFT" =~ buntu ]] ) \
		|| ( [[ "$(echo "$LSBRELIS" | grep -i Mint )" ]] || [[ "$(echo "$LSBRELIS" | grep -i LMDE )" ]] && [[ "$EFIBMGRAFT" =~ ebian ]] ) \
		|| [[ "$(echo "$EFIBMGRAFT" | grep -i "$LSBRELIS" )" ]];then #coz mint displays 'ubuntu' in UEFI list
			NVRAMUNCHANGED=yes && echo "Warning: NVram was not modified."
		else
			NVRAMLOCKED=yes; 
			echo "Warning: NVram is locked ($LSBRELIS not found in efibootmgr)."
		fi
	fi
elif [[ "$FORCE_GRUB" = force-in-PBR ]];then
	GRUBSTAGEONE="$FORCE_PARTITION"
	DEVGRUBSTAGEONE="$GRUBSTAGEONE"
	FORCEPARAM=" --force"
	echo "
==> Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into the $GRUBSTAGEONE partition"
	reinstall_grubstageone
else
	GRUBSTAGEONE="$NOFORCE_DISK"
	DEVGRUBSTAGEONE="$GRUBSTAGEONE"
	echo "
==> Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into the MBR of $GRUBSTAGEONE"
	reinstall_grubstageone
fi
}

fix_etc_default_grub_for_zfs() {
echo "${CHROOTCMD}grub-probe /boot"
LANGUAGE=C LC_ALL=C ${CHROOTCMD}grub-probe /boot
#echo "${CHROOTCMD}update-initramfs -c -k all"
#LANGUAGE=C LC_ALL=C ${CHROOTCMD}update-initramfs -c -k all
sed -i 's/#GRUB_CMDLINE_LINUX=/GRUB_CMDLINE_LINUX=/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
sed -i 's/# GRUB_CMDLINE_LINUX=/GRUB_CMDLINE_LINUX=/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
#Needed until grub becomes zfs compatible. https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bullseye%20Root%20on%20ZFS.html#step-5-grub-installation
RTPL="$(zfs list | grep ROOT/ | grep v/zfs | grep -v zfs/ )"
RTPL="${RTPL%% *}" # eg. tmprpool/ROOT/ubuntu_64fs0l
if [[ "$LIVESESSION" = live ]];then #don't risk to break installed session
	echo "Set GRUB_CMDLINE_LINUX=\"root=ZFS=${RTPL}\" in ${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/defgrub_new
	while read line; do
		if [[ "$line" =~ "GRUB_CMDLINE_LINUX=" ]];then
			[[ ! "$line" =~ "#GRUB_CMDLINE_LINUX=" ]] && [[ ! "$line" =~ "# GRUB_CMDLINE_LINUX=" ]] && echo "#$line" >> $TMP_FOLDER_TO_BE_CLEARED/defgrub_new
			echo "GRUB_CMDLINE_LINUX=\"root=ZFS=${RTPL}\"" >> $TMP_FOLDER_TO_BE_CLEARED/defgrub_new
		else
			echo "$line" >> $TMP_FOLDER_TO_BE_CLEARED/defgrub_new
		fi
	done < <(cat "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" )
	cp -f $TMP_FOLDER_TO_BE_CLEARED/defgrub_new "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
else
	echo "cat /etc/default/grub (filtered)"
	cat /etc/default/grub | sed -e '/^$/d' -e '/#/d'
fi
echo "${CHROOTCMD}update-grub"
${CHROOTCMD}update-grub
}

loop_install_grub_in_all_other_disks() {
local n
INSTALLEDINOTHERDISKS=""
#&& [[ "${LISTOFDISKS[$n]}" != "$BCKUPNOFORCE_DISK" ]]  #equals [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]]
for ((n=1;n<=NBOFDISKS;n++)); do
	if [[ "${DISK_HASOS[$n]}" != has-os ]] && ( [[ "${USBDISK[$n]}" =~ no ]] && [[ "${MMCDISK[$n]}" =~ no ]] ) \
	&& [[ "${USBDISK[$n]}" != liveusb ]] && [[ "${MMCDISK[$n]}" != livemmc ]] && [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]] \
	&& ( [[ "${GPT_DISK[$n]}" != is-GPT ]] || [[ "${BIOS_BOOT_DISK[$n]}" != no-BIOSboot ]] ) \
	&& [[ "${REALWINONDISC[$n]}" = no-wind ]];then
		INSTALLEDINOTHERDISKS=yes
		echo "
==> Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into MBRs of all disks without OS, except live-disks and USB/MMC disks."
		break
	fi
done
if [[ "$INSTALLEDINOTHERDISKS" ]];then
	if [[ "$REMOVABLEDISK" ]];then
		force_unmount_and_prepare_chroot
		fix_grub_d
	fi
	for ((n=1;n<=NBOFDISKS;n++)); do
		if [[ "${DISK_HASOS[$n]}" != has-os ]] && ( [[ "${USBDISK[$n]}" =~ no ]] && [[ "${MMCDISK[$n]}" =~ no ]] ) \
		&& [[ "${USBDISK[$n]}" != liveusb ]] && [[ "${MMCDISK[$n]}" != livemmc ]] && [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]] \
		&& ( [[ "${GPT_DISK[$n]}" != is-GPT ]] || [[ "${BIOS_BOOT_DISK[$n]}" != no-BIOSboot ]] ) \
		&& [[ "${REALWINONDISC[$n]}" = no-wind ]];then
			NOFORCE_DISK="${LISTOFDISKS[$n]}" #name of the non-removable disk on which we install grub in the mbr
			reinstall_grub
		fi
	done
fi
}

reinstall_grubstageone() {
local SETUPOUTPUT cfg ztyp z r dd
repflex=yes
repoom=yes
repldm=yes
#dpkg_function
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Reinstall_GRUB ${GRUBSTAGEONE#*/dev/}. $This_may_require_several_minutes''')"
grubinstall
if [[ ! "$NOW_IN_OTHER_DISKS" ]];then
	if [[ "$(cat "$CATTEE" | grep FlexNet )" ]] \
	|| [[ "$(cat "$CATTEE" | grep 't known to reserve space' )" ]] || [[ "$BLANKEXTRA_ACTION" ]];then
		if [[ ! "$BLANKEXTRA_ACTION" ]];then
			#iso9660: http://askubuntu.com/questions/158299/why-does-installing-grub2-give-an-iso9660-filesystem-destruction-warning
			[[ "$(cat "$CATTEE" | grep 't known to reserve space' )" ]] && FUNCTION=Extra-MBR-space-error || FUNCTION=FlexNet
			update_translations
			if [[ ! "$FORCEYES" ]];then
				if [[ "$GUI" ]];then
					end_pulse
					zenity --width=400 --question --title="$APPNAME2" --text="$FUNCTION_detected $Please_backup_data $Do_you_want_to_continue" 2>/dev/null || repflex=no
					start_pulse
				else
					read -r -p "$FUNCTION_detected $Please_backup_data $Do_you_want_to_continue [yes/no] " response
					[[ ! "$response" =~ y ]] && repflex=no
				fi
			fi
		fi
		if [[ "$repflex" = yes ]];then
			blankextraspace
			grubinstall
		else
			ERROR="User cancelled $FUNCTION solving."; echo "$ERROR"
		fi
	fi
	if [[ "$(cat "$CATTEE" | grep recheck )" ]] || [[ "$(cat "$CATTEE" | grep 'device.map' )" ]];then
		RECHECK=" --recheck"
		grubinstall
	fi
	if [[ "$(cat "$CATTEE" | grep 'this LDM has no Embedding Partition' )" ]];then
		#Workaround for https://bugs.launchpad.net/bugs/1061255
		#Works: http://paste.ubuntu.com/1401572
		FUNCTION=LDM-blocker; update_translations
		for ((b=1;b<=NBOFDISKS;b++)); do
			[[ "${LISTOFDISKS[$b]}" = "$GRUBSTAGEONE" ]] && GRUBSTAGEONENB="$b"
		done
		SKIPP="$(cat /sys/block/${GRUBSTAGEONE#*/dev/}/size)"
		(( SKIPP -= 1 ))
		if [[ "$SKIPP" -gt 10000 ]] && [[ "${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" -ge 512 ]] \
		&& [[ "${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" -le 2048 ]];then
			echo "
dd if=$GRUBSTAGEONE bs=${BYTES_PER_SECTOR[$GRUBSTAGEONENB]} count=1 skip=6 | hd"
			LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip=6 2>/dev/null | hd
			echo "
dd if=$GRUBSTAGEONE bs=${BYTES_PER_SECTOR[$GRUBSTAGEONENB]} count=1 skip=$SKIPP | hd"
			LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip="$SKIPP" 2>/dev/null | hd
			if [[ ! "$(LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip="$SKIPP" 2>/dev/null | hd | grep PRIVHEAD )" ]] \
			&& [[ ! "$(LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip=6 2>/dev/null | hd | grep PRIVHEAD )" ]];then
				ERROR="Error: no PRIVHEAD in 6th nor last sector. $PLEASECONTACT"; echo "$ERROR"
			fi
			if [[ "$(LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip="$SKIPP" 2>/dev/null | hd | grep PRIVHEAD )" ]];then
				if [[ ! "$FORCEYES" ]];then
					if [[ "$GUI" ]];then
						end_pulse
						zenity --width=400 --question --title="$APPNAME2" --text="$FUNCTION_detected $Please_backup_data $Do_you_want_to_continue" 2>/dev/null || repldm=no
						start_pulse
					else
						read -r -p "$FUNCTION_detected $Please_backup_data $Do_you_want_to_continue [yes/no] " response
						[[ ! "$response" =~ y ]] && repldm=no
					fi
				fi
				echo "$FUNCTION_detected $Please_backup_data $Do_you_want_to_continue $repldm"
				if [[ "$repldm" = yes ]];then
					echo "dd if=/dev/zero of=$GRUBSTAGEONE bs=${BYTES_PER_SECTOR[$GRUBSTAGEONENB]} seek=$SKIPP count=1"
					LANGUAGE=C LC_ALL=C dd if=/dev/zero of="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" seek="$SKIPP" count=1 2>/dev/null
					grubinstall
				else
					ERROR="User cancelled $FUNCTION solving."; echo "$ERROR"
				fi
			fi
			if [[ "$(LANGUAGE=C LC_ALL=C dd if="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" count=1 skip=6 2>/dev/null | hd | grep PRIVHEAD )" ]];then
				echo "$PLEASECONTACT"
				if [[ ! "$FORCEYES" ]];then
					if [[ "$GUI" ]];then
						end_pulse
						zenity --width=400 --question --title="$APPNAME2" --text="$FUNCTION_detected This will delete the 6th sector of ${GRUBSTAGEONE#*/dev/}. $Do_you_want_to_continue" 2>/dev/null || repldm=no
						start_pulse
					else
						read -r -p "$FUNCTION_detected This will delete the 6th sector of $GRUBSTAGEONE. $Do_you_want_to_continue [yes/no] " response
						[[ ! "$response" =~ y ]] && repldm=no
					fi
				fi
				echo "$FUNCTION_detected This will delete the 6th sector of $GRUBSTAGEONE. $Do_you_want_to_continue $repldm"
				if [[ "$repldm" = yes ]];then
					echo "dd if=/dev/zero of=$GRUBSTAGEONE bs=${BYTES_PER_SECTOR[$GRUBSTAGEONENB]} seek=6 count=1"
					LANGUAGE=C LC_ALL=C dd if=/dev/zero of="$GRUBSTAGEONE" bs="${BYTES_PER_SECTOR[$GRUBSTAGEONENB]}" seek=6 count=1 2>/dev/null
					grubinstall
				else
					ERROR="User cancelled $FUNCTION solving"; echo "$ERROR"
				fi
			fi
		else
			ERROR="Error: bad parameters for LDM workaround."; echo "$ERROR $PLEASECONTACT"
		fi
	elif [[ "$(cat "$CATTEE" | grep 'will not proceed with blocklists' )" ]];then
		FORCEPARAM=" --force" #http://www.linuxquestions.org/questions/linux-newbie-8/problem-installing-fedora-17-in-dual-booting-with-windows-7-a-4175412439/page2.html
		grubinstall
	fi
	if [[ "$(cat "$CATTEE" | grep ': error: out of memory.' )" ]] && [[ ! "$ATA" ]];then
		FUNCTION=out-of-memory
		OPTION="$Ata_disk"
		update_translations
		if [[ ! "$FORCEYES" ]];then
			if [[ "$GUI" ]];then
				end_pulse
				zenity --width=400 --question --title="$APPNAME2" --text="$FUNCTION_detected $Do_you_want_activate_OPTION" 2>/dev/null || repoom=no
				start_pulse
			else
				read -r -p "$FUNCTION_detected $Do_you_want_activate_OPTION [yes/no] " response
				[[ ! "$response" =~ y ]] && repoom=no
			fi
		fi
		echo "$FUNCTION_detected $Do_you_want_activate_OPTION $repoom"
		#http://paste.ubuntu.com/1041994 solved by ATA
		if [[ "$repoom" = yes ]];then
			ATA=" --disk-module=ata"
			grubinstall
		else
			echo "$You_may_want_to_retry_after_activating_OPTION"
			end_pulse
			[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$You_may_want_to_retry_after_activating_OPTION" 2>/dev/null
			start_pulse
		fi
	fi
	if [[ "$(cat "$CATTEE" | grep ': error: out of memory.' )" ]] && [[ "$ATA" ]] \
	&& [[ ! "$(cat "$CATTEE" | grep 'Installation finished. No error reported.' )" ]] \
	|| [[ "$(cat "$CATTEE" | grep 'will not proceed with blocklists' )" ]];then
		embeddingerror=yes
		FUNCTION="Embedding-error-in-$GRUBSTAGEONE"
		TYPE3=/boot
		update_translations
		OPTION="$Separate_TYPE3_partition"
		update_translations
		echo "$FUNCTION_detected $You_may_want_to_retry_after_activating_OPTION"
		end_pulse
		zenity --width=400 --warning --title="$APPNAME2" --text="$FUNCTION_detected $You_may_want_to_retry_after_activating_OPTION" 2>/dev/null
		start_pulse
	fi
	if [[ "$(cat "$CATTEE" | grep 'failed to run command' | grep grub | grep install )" ]];then
		echo "Failed to run command grub-install detected."
		${CHROOTCMD}type ${GRUBTYPE_OF_PART[$USRPART]}
		for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/ /usr/sbin/lib*/*/*/ /usr/bin/lib*/*/*/ /sbin/lib*/*/*/ /bin/lib*/*/*/;do #not sure "type" is available in all distros
			for gi in grub-install grub2-install grub-install.unsupported;do
				if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}$gg$gi" ]];then
					LANG=C ls -l "${BLKIDMNT_POINT[$REGRUB_PART]}$gg$gi" 2>/dev/null
					chmod a+x "${BLKIDMNT_POINT[$REGRUB_PART]}$gg$gi"
					LANG=C ls -l "${BLKIDMNT_POINT[$REGRUB_PART]}$gg$gi" 2>/dev/null
				fi
			done
		done
		grubinstall
	fi

	if [[ "$GRUBPACKAGE" =~ efi ]];then
		for ((efitmmmp=1;efitmmmp<=NBOFPARTITIONS;efitmmmp++));do
			EFIDO="${BLKIDMNT_POINT[$efitmmmp]}"
			[[ -d "$EFIDO/EFI" ]] && EFIDOFI="$EFIDO/EFI/" || EFIDOFI="$EFIDO/efi/"
			REFC=refind.conf
			REFI=""
			[[ -f "$EFIDOFI/Microsoft/Boot/$REFC" ]] || [[ -f "$EFIDOFI/BOOT/$REFC" ]] || [[ -f "$EFIDOFI/refind/$REFC" ]] \
			&& REFI=y && echo "Refind detected on ${LISTOFPARTITIONS[$efitmmmp]#*/dev/}"
			[[ -f "$EFIDOFI/Microsoft/bootmgfw.efi" ]] && [[ "$REFI" ]] && echo "Restore /Microsoft/Boot/bootmgfw.efi" \
			&& mv "$EFIDOFI/Microsoft/bootmgfw.efi" "$EFIDOFI/Microsoft/Boot/bootmgfw.efi"
		done
		BEFIDO="${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
		NEEDMENUUPDATE=""
		LOCKEDESP=""
		#https://bugs.launchpad.net/bugs/1090829 / https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1091477
		if [[ "$(cat "$CATTEE" | grep 'Input/output')" ]] || [[ "$(cat "$CATTEE" | grep Read-only )" ]];then
			echo "
dosfsck -a ${LISTOFPARTITIONS[$EFIPART_TO_USE]}"
			LANGUAGE=C LC_ALL=C dosfsck -a ${LISTOFPARTITIONS[$EFIPART_TO_USE]}
			grubinstall
			if [[ "$(cat "$CATTEE" | grep 'Input/output')" ]] || [[ "$(cat "$CATTEE" | grep Read-only )" ]];then
				echo "
rm -Rf ${LISTOFPARTITIONS[$EFIPART_TO_USE]}/ubuntu .. fedora"
				[[ "${OSNAME[$REGRUB_PART]}" =~ buntu ]] || [[ "${OSNAME[$REGRUB_PART]}" =~ int ]] && LANGUAGE=C LC_ALL=C rm -Rf ${LISTOFPARTITIONS[$EFIPART_TO_USE]}/EFI/ubuntu
				[[ "${OSNAME[$REGRUB_PART]}" =~ edora ]] && LANGUAGE=C LC_ALL=C rm -Rf ${LISTOFPARTITIONS[$EFIPART_TO_USE]}/EFI/fedora
				grubinstall
				[[ "$(cat "$CATTEE" | grep 'Input/output')" ]] || [[ "$(cat "$CATTEE" | grep Read-only )" ]] \
				&& ERROR="Write-locked ESP.  $PLEASECONTACT" && LOCKEDESP=yes && echo "
$DASH (Write-locked ESP) dmesg:
$(dmesg)

$DASH cat /var/log/syslog:
$(cat /var/log/syslog)"
			fi
		fi
		#https://ubuntuforums.org/showthread.php?t=2400234
		if [[ "$(cat "$CATTEE" | grep 'error: cannot open' | grep 'Not a directory' )" ]];then #grub-install: error: cannot open `/boot/efi/EFI/ubuntu/grubx64.efi': Not a directory.
			echo "Not a directory error detected. Delete corresponding folder/file." #Hard to isolate 'ubuntu' coz of special character `
			[[ "$(cat "$CATTEE" | grep 'Not a directory' | grep /boot/efi/EFI/ubuntu )" ]] && echo "${CHROOTCMD}rm -Rf /boot/efi/EFI/ubuntu" \
			&& LANGUAGE=C LC_ALL=C ${CHROOTCMD}rm -Rf /boot/efi/EFI/ubuntu
			[[ "$(cat "$CATTEE" | grep 'Not a directory' | grep /boot/efi/EFI/fedora )" ]] && echo "${CHROOTCMD}rm -Rf /boot/efi/EFI/fedora" \
			&& LANGUAGE=C LC_ALL=C ${CHROOTCMD}rm -Rf /boot/efi/EFI/fedora
			grubinstall
			[[ "$(cat "$CATTEE" | grep 'error: cannot open' | grep 'Not a directory' )" ]] && ERROR="Write-locked ESP, not a directory error. $PLEASECONTACT" && LOCKEDESP=yes
		fi
		
		EFIGRUBFILE=""
		for secureb in grub shim;do #Signed GRUB in priority
			if [[ "$GRUBPACKAGE" =~ sign ]] || [[ "$secureb" = grub ]];then #http://ubuntuforums.org/showthread.php?p=12376694#post12376694
				for z in "$BEFIDO/efi/"*/${secureb}*.efi "$BEFIDO/EFI/"*/${secureb}*.efi;do
					#Prefers efi file in folder corresponding to OS name. TODO: complete with main distribs (need to know in which folder they install grub*.efi)
					if ( [[ "${OSNAME[$REGRUB_PART]}" =~ buntu ]] || [[ "${OSNAME[$REGRUB_PART]}" =~ int ]] || [[ "${OSNAME[$REGRUB_PART]}" =~ Zorin ]] && [[ "$z" =~ buntu ]] && ( [[ ! "$EFIGRUBFILE" =~ buntu ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ edora ]] && [[ "$z" =~ edora ]] && ( [[ ! "$EFIGRUBFILE" =~ edora ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ rch ]] && [[ "$z" =~ rch ]] && ( [[ ! "$EFIGRUBFILE" =~ rch ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ use ]] && [[ "$z" =~ use ]] && ( [[ ! "$EFIGRUBFILE" =~ use ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ ebian ]] || [[ "${OSNAME[$REGRUB_PART]}" =~ LMDE ]] && ( [[ "$z" =~ ebian ]] || [[ "$z" =~ sid ]] ) && ( [[ ! "$EFIGRUBFILE" =~ ebian ]] && [[ ! "$EFIGRUBFILE" =~ sid ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ at ]] && [[ "$z" =~ at ]] && ( [[ ! "$EFIGRUBFILE" =~ at ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ ali ]] && [[ "$z" =~ ali ]] && ( [[ ! "$EFIGRUBFILE" =~ ali ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ op ]] && [[ "$z" =~ op ]] && ( [[ ! "$EFIGRUBFILE" =~ op ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "${OSNAME[$REGRUB_PART]}" =~ neon ]] && [[ "$z" =~ neon ]] && ( [[ ! "$EFIGRUBFILE" =~ neon ]] || [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] )) \
					|| ( [[ "$(echo "${OSNAME[$REGRUB_PART]}" | sed -e '/buntu/d' -e '/int/d' -e '/orin/d' -e '/edora/d' -e '/rch/d' -e '/use/d' -e '/ebian/d' -e '/at/d' -e '/ali/d' -e '/op/d' -e '/neon/d' )" ]] \
					&& [[ "$(echo "$z" | sed -e '/buntu/d' -e '/int/d' -e '/orin/d' -e '/edora/d' -e '/rch/d' -e '/use/d' -e '/ebian/d' -e '/sid/d' -e '/at/d' -e '/ali/d' -e '/op/d' -e '/neon/d' )" ]] && [[ ! "$EFIGRUBFILE" =~ "$secureb" ]] ) ;then
						[[ "$(echo "$z" | grep -v '*' | grep -vi Microsoft | grep -vi "efi/Boot/$secureb" )" ]] && EFIGRUBFILE="$z"
					fi
				done
			fi
		done

		### Copies EFI/Ubuntu/grubx64.efi (and shim) to all ESPs.
		if [[ "$EFIGRUBFILE" ]];then
			EFIGRUBFILESHORT="${EFIGRUBFILE#*$BEFIDO/}"
			EFIGRUBFILESHORT="${EFIGRUBFILESHORT#*/}" #eg ubuntu/shimx64.efi
			EFIGRUBFILEDIR="${EFIGRUBFILESHORT%/*}" #eg ubuntu
			EFIGRUBFILEDIRFULL="${EFIGRUBFILE%/*}"
			for ((efitmp=1;efitmp<=NBOFPARTITIONS;efitmp++));do #https://blueprints.launchpad.net/boot-repair/+spec/grub-on-several-efi
				EFIDO="${BLKIDMNT_POINT[$efitmp]}"
				if [[ "${EFI_TYPE[$efitmp]}" = is---ESP ]] \
				&& [[ "${USBDISK[${DISKNB_PART[$efitmp]}]}" != liveusb ]] && [[ "${MMCDISK[${DISKNB_PART[$efitmp]}]}" != livemmc ]] \
				&& [[ ! -d "$EFIDO/sys" ]];then #todo paste ubuntu 6037509
					[[ "$(ls "$EFIDO"/ 2>/dev/null | grep efi)" ]] && EFIDOFI="$EFIDO/efi/" || EFIDOFI="$EFIDO/EFI/"
					#echo "(debug) beglsefi1 $EFIGRUBFILESHORT ; $EFIGRUBFILEDIR , $EFIDO ."
					[[ "$DEBBUG" ]] && md5_efi_partition #debug
					mkdir -p "$EFIDOFI$EFIGRUBFILEDIR"
					if [[ ! -f "$EFIDOFI$EFIGRUBFILESHORT" ]];then
						echo "cp $EFIGRUBFILE $EFIDOFI$EFIGRUBFILESHORT"
						cp "$EFIGRUBFILE" "$EFIDOFI$EFIGRUBFILESHORT"
						NEEDMENUUPDATE=y
						EFIFOLD="$EFIDOFI$EFIGRUBFILEDIR"
						copy_grub_along_with_shim
					fi
				fi
			done
		else
			ERROR="Error: no grub*.efi generated for ${OSNAME[$REGRUB_PART]}. $PLEASECONTACT"; echo "$ERROR"
		fi

		######### WINEFI_BKP_ACTION and CREATE_BKP_ACTION    (efi files renaming)
		#/efi/ubuntu/grubx64.efi, grubia32.efi http://forum.ubuntu-fr.org/viewtopic.php?id=207366&p=69
		MEMADDEDENTRY=""
		for tmprecov in 1 2 3 4;do
			for ((efitmp=1;efitmp<=NBOFPARTITIONS;efitmp++));do #http://forum.ubuntu-fr.org/viewtopic.php?pid=10305051#p10305051
				EFIDO="${BLKIDMNT_POINT[$efitmp]}"
				if ( [[ "$tmprecov" = 1 ]] && [[ "${RECOV[$efitmp]}" != recovery-or-hidden ]] && [[ "${DISKNB_PART[$efitmp]}" = "${DISKNB_PART[$EFIPART_TO_USE]}" ]] ) \
				|| ( [[ "$tmprecov" = 2 ]] && [[ "${RECOV[$efitmp]}" != recovery-or-hidden ]] && [[ "${DISKNB_PART[$efitmp]}" != "${DISKNB_PART[$EFIPART_TO_USE]}" ]] ) \
				|| ( [[ "$tmprecov" = 3 ]] && [[ "${RECOV[$efitmp]}" = recovery-or-hidden ]] && [[ "${DISKNB_PART[$efitmp]}" = "${DISKNB_PART[$EFIPART_TO_USE]}" ]] ) \
				|| ( [[ "$tmprecov" = 4 ]] && [[ "${RECOV[$efitmp]}" = recovery-or-hidden ]] && [[ "${DISKNB_PART[$efitmp]}" != "${DISKNB_PART[$EFIPART_TO_USE]}" ]] ) \
				&& [[ "${EFI_TYPE[$efitmp]}" = is---ESP ]] \
				&& [[ "${USBDISK[${DISKNB_PART[$efitmp]}]}" != liveusb ]] && [[ "${MMCDISK[${DISKNB_PART[$efitmp]}]}" != livemmc ]];then
					[[ "$(ls "$EFIDO"/ 2>/dev/null | grep efi)" ]] && EFIDOFI="$EFIDO/efi/" || EFIDOFI="$EFIDO/EFI/"
					REFC=refind.conf
					REFI=""
					[[ -f "$EFIDOFI/Microsoft/Boot/$REFC" ]] || [[ -f "$EFIDOFI/BOOT/$REFC" ]] || [[ -f "$EFIDOFI/refind/$REFC" ]] && REFI=y
					if [[ "$REFI" ]] && [[ -f "$EFIDOFI/Microsoft/bootmgfw.efi" ]];then #fix Refind hacks
						mv -f "$EFIDOFI/Microsoft/Boot/bootmgfw.efi" "$EFIDOFI/Microsoft/Boot/bootmgfwrefind.efi"
						rm -f "$EFIDOFI/Microsoft/Boot/bootmgfw.efi"
						cp -f "$EFIDOFI/Microsoft/bootmgfw.efi" "$EFIDOFI/Microsoft/Boot/bootmgfw.efi"
					fi
					if [[ -d "$EFIDOFI/BOOT-rEFIndBackup" ]];then
						mv -f "$EFIDOFI/BOOT" "$EFIDOFI/BOOTrefind"
						rm -rf "$EFIDOFI/BOOT"
						cp -rf "$EFIDOFI/BOOT-rEFIndBackup" "$EFIDOFI/BOOT"
					fi
					if [[ "$CREATE_BKP_ACTION" ]] && [[ "$EFIGRUBFILE" ]];then #Workaround for http://askubuntu.com/questions/150174/sony-vaio-with-insyde-h2o-efi-bios-will-not-boot-into-grub-efi
						mkdir -p "${EFIDOFI}Boot"
						[[ "$WINEFI_BKP_ACTION" ]] && mkdir -p "${EFIDOFI}Microsoft/Boot"
						for chgfile in Microsoft/Boot/bootmgfw.efi Microsoft/Boot/bootx64.efi Boot/bootx64.efi;do
							if [[ "$WINEFI_BKP_ACTION" ]] || [[ ! "$chgfile" =~ Mi ]];then
								EFIFICH="$EFIDOFI$chgfile"
								EFIFOLD="${EFIFICH%/*}"
								EFIFICHEND="${chgfile##*/}"
								NEWEFIL="$EFIFOLD/bkp$EFIFICHEND"
								#Backup Win file
								#locked to /EFI/Boot/bootx64.efi: http://ubuntuforums.org/showthread.php?p=12366736#post12366736)
								#and http://forum.thinkpads.com/viewtopic.php?f=9&t=107246
								#locked to bootmgfw.efi: http://askubuntu.com/questions/150174/sony-vaio-with-insyde-h2o-efi-bios-will-not-boot-into-grub-efi
								echo "df ${LISTOFPARTITIONS[$efitmp]}"
								DFX="$(df "${LISTOFPARTITIONS[$efitmp]}" )"
								if [[ "$DFX" =~ "100%" ]] || [[ "$DFX" =~ "9[0-9]%" ]];then
									echo "mv winEFI cancelled (${LISTOFPARTITIONS[$efitmp]} full)"
								elif [[ ! -f "$NEWEFIL" ]] && [[ -f "$EFIFICH" ]] && [[ ! -f "$EFIFICH.grb" ]];then
									cp "$EFIFICH" "$LOGREP/${LISTOFPARTITIONS[$efitmp]#*/dev/}"
									#cp "$EFIFICH" "$EFIFICH.bkp"
									echo "mv $EFIFICH $NEWEFIL"
									mv "$EFIFICH" "$NEWEFIL"
									NEEDMENUUPDATE=y
									[[ -f "$EFIFICH" ]] && echo "Error: $EFIFICH still pr. $PLEASECONTACT"
								fi
								#When no Windows EFI file
								if [[ ! -f "$EFIFICH" ]];then #Create fake Win file
									if [[ -f "$EFIFICH.grb" ]]; then
										echo "Error: still $EFIFICH.grb. $PLEASECONTACT"
									else
										if [[ ! -f "$NEWEFIL" ]];then #original has not been backed up
											echo "touch $EFIFICH.grb"
											touch "$EFIFICH.grb"
											[[ ! -f "$EFIFICH.grb" ]] && echo "Error no $EFIFICH.grb"
										fi
										if [[ -f "$NEWEFIL" ]] || [[ -f "$EFIFICH.grb" ]]; then
											echo "cp $EFIGRUBFILE $EFIFICH"
											cp "$EFIGRUBFILE" "$EFIFICH"
											copy_grub_along_with_shim
										fi
									fi
								fi
							fi
						done
						[[ "$DEBBUG" ]] && md5_efi_partition #debug
					fi
					if [[ "$DEBBUG" = TODO ]];then ########### TODO: To be converted in an optional feature in the "GRUB Options" tab
						#Workaround https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1024383
						echo "Add $EFIDO efi entries in $GRUBCUSTOM"
						GRUBCUSTOM="${BLKIDMNT_POINT[$REGRUB_PART]}"/etc/grub.d/25_custom
						[[ -f "$GRUBCUSTOM" ]] && echo "mv 25_custom" && mv "$GRUBCUSTOM" "$LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/25_custom"
						for WINORMAC in Microsoft Boot MacOS Other;do #Other: http://ubuntuforums.org/showthread.php?p=12421487#post12421487
							if [[ "$WINORMAC" = MacOS ]];then
								for z in "$EFIDOFI"*/{,*/}*/*.scap;do
									[[ ! "$z" =~ '*' ]] && add_custom_efi
								done
							else
								for priorityefi in 1 2;do
									for z in "$EFIDOFI"*/{,*/}*.efi;do
										ZFOLD="${z%/*}"
										ZFICHEND="${z##*/}"
										ZNEWFIL="$ZFOLD/bkp$ZFICHEND"
										if ( [[ "$priorityefi" = 1 ]] && [[ "${ZFICHEND%%p*}" = bk ]] ) \
										|| ( [[ "$priorityefi" = 2 ]] && [[ "${ZFICHEND%%p*}" != bk ]] && [[ ! -f "$ZNEWFIL" ]] ) \
										&& [[ ! "$z" =~ '*' ]] \
										&& [[ ! "$z" =~ memtest.efi ]] && [[ ! "$z" =~ grub ]]  && [[ ! "$z" =~ shim ]] \
										&& ( [[ "$z" =~ "$EFIDOFI$WINORMAC" ]] || [[ "$WINORMAC" = Other ]] ) \
										&& [[ ! "$z" =~ bootmgr.efi ]];then #http://ubuntuforums.org/showpost.php?p=12114780&postcount=18
											[[ "$(grep "$z,$efitmp;" <<< "$MEMADDEDENTRY")" ]] \
											&& echo "${LISTOFPARTITIONS[$efitmp]#*/dev/}/$ZFICHEND already added" || add_custom_efi
										fi
									done
								done
							fi
						done
					fi
				fi
			done
		done
		[[ "$NEEDMENUUPDATE" ]] && grubinstall
	fi
	if [[ "$GI_EXITCODE" != 0 ]];then
		if [[ "$GRUBPACKAGE" =~ efi ]];then
			grubinstall_recheck
			[[ "$GI_EXITCODE" != 0 ]] && grubinstall_nonvram
		else
			grubinstall_recheck
			[[ "$GI_EXITCODE" != 0 ]] && ERROR="--recheck exit code: $GI_EXITCODE $PLEASECONTACT" && echo "$ERROR"
		fi
	fi
fi
}


copy_grub_along_with_shim() {
#why: https://bugs.launchpad.net/boot-repair/+bug/1752851
#called twice in reinstall_grubstageone()
if [[ "$EFIGRUBFILE" =~ shim ]] && [[ ! -f "$EFIFOLD"/grubx64.efi ]] && [[ ! -f "$EFIFOLD"/grubia32.efi ]];then #solves bug #1752851
	if [[ -f "$EFIGRUBFILEDIRFULL"/grubx64.efi ]];then
		echo "cp $EFIGRUBFILEDIRFULL/grubx64.efi $EFIFOLD/"
		cp $EFIGRUBFILEDIRFULL/grubx64.efi $EFIFOLD/
	elif [[ -f "$EFIGRUBFILEDIRFULL"/grubia32.efi ]];then
		echo "cp $EFIGRUBFILEDIRFULL/grubia32.efi $EFIFOLD/"
		cp $EFIGRUBFILEDIRFULL/grubia32.efi $EFIFOLD/
	else
		echo "Warning: no grub*.efi in same folder as shim. $PLEASECONTACT
"
	fi
fi
}


force_unmount_and_prepare_chroot() {
#called by loop_install_grub_in_all_other_disks (if other GRUB) & reinstall_grub_main_mbr
[[ "$DEBBUG" ]] && echo "[debug]force_unmount_and_prepare_chroot"
[[ "$CLEANNAME" =~ r ]] && force_unmount_os_partitions_in_mnt_except_reinstall_grub #OS are not recognized if partitions are not unmounted
prepare_chroot
if [[ "$KERNEL_PURGE" ]] || [[ "$GRUBPURGE_ACTION" ]] && [[ "$NOW_USING_CHOSEN_GRUB" ]];then
	if [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" != "$CURRENTSESSIONPARTITION" ]];then
		mv "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf" "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf.old"
		cp /etc/resolv.conf "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf"  # Required to connect to the Internet.
	fi
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''Purge ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (dep). $This_may_require_several_minutes''')"
	#repair_dep "$REGRUB_PART"
	update_cattee
	aptget_update_function
fi
}

add_custom_efi() {
if [[ ! -f "$GRUBCUSTOM" ]];then
	echo '#!/bin/sh' > "$GRUBCUSTOM"
	echo 'exec tail -n +3 $0' >> "$GRUBCUSTOM"
	chmod a+x "$GRUBCUSTOM"
fi
EFIFIL="${z#*$EFIDO}" #eg /EFI/Microsoft/Boot/bootmgr.efi or /efi/bootmgfw.efi, /efi/Boot/bootx64.efi, or /efi/APPLE/EXTENSIONS/Firmware.scap
[[ "$WINORMAC" = Microsoft ]] && WINORMAC2=Windows || WINORMAC2="$WINORMAC"
[[ "$(grep Windows "$GRUBCUSTOM")" ]] && [[ "$WINORMAC" = Boot ]] && WINORMAC2="Windows Boot" #http://superuser.com/questions/494601/windows-8-fails-to-load-after-boot-repair
if [[ "$WINORMAC" = Other ]];then
	EFILABEL="${EFIFIL#*/}"
else
	if [[ "$EFILABEL" =~ bootmgfw.efi ]];then
		[[ "${RECOV[$efitmp]}" = recovery-or-hidden ]] && EFILABEL=recovery || EFILABEL=loader
	elif [[ "${RECOV[$efitmp]}" = recovery-or-hidden ]];then
		EFILABEL="recovery ${EFIFIL##*/}"
	else
		EFILABEL="${EFIFIL##*/}"
	fi
	EFILABEL="$WINORMAC2 UEFI $EFILABEL"
fi
[[ "$(grep "$EFILABEL" "$GRUBCUSTOM")" ]] && EFILABEL="$EFILABEL ${LISTOFPARTITIONS[$efitmp]}"
[[ -f "$z".grb ]] && EFILABEL="GRUB on $EFILABEL"
EFIENTRY1="
menuentry \"$EFILABEL\" {
search --fs-uuid --no-floppy --set=root ${PART_UUID[$efitmp]}
chainloader (\${root})$EFIFIL
}"
#see also http://ubuntuforums.org/showpost.php?p=12098088&postcount=9
#http://ubuntuforums.org/showpost.php?p=12114780&postcount=18
#http://www.rodsbooks.com/ubuntu-efi/index.html (/ubuntu/boot.efi)
#works: http://ubuntuforums.org/showpost.php?p=12361742&postcount=4
if [[ "$(grep "$EFILABEL" "$GRUBCUSTOM")" ]];then
	echo "Warning: $EFILABEL already in $GRUBCUSTOM. $PLEASECONTACT"
else
	echo "Adding custom $z"
	echo "$EFIENTRY1" >> "$GRUBCUSTOM"
	MEMADDEDENTRY="$z,$efitmp;$MEMADDEDENTRY"
fi
}


grubinstall() {
update_cattee
echo "
${CHROOTCMD}${GRUBTYPE_OF_PART[$USRPART]}$FORCEPARAM$RECHECK$ATA $DEVGRUBSTAGEONE"
LANGUAGE=C LC_ALL=C $CHROOTCMD${GRUBTYPE_OF_PART[$USRPART]}$FORCEPARAM$RECHECK$ATA $DEVGRUBSTAGEONE
GI_EXITCODE="$?"
[[ "$GI_EXITCODE" != 0 ]] && echo "Exit code: $GI_EXITCODE"
}

grubinstall_recheck() {
update_cattee
echo "
${CHROOTCMD}${GRUBTYPE_OF_PARTZ[$USRPART]}$FORCEPARAM$ATA --recheck $DEVGRUBSTAGEONE"
LANGUAGE=C LC_ALL=C $CHROOTCMD${GRUBTYPE_OF_PARTZ[$USRPART]}$FORCEPARAM$ATA --recheck $DEVGRUBSTAGEONE
GI_EXITCODE="$?"
}

grubinstall_nonvram() {
update_cattee
echo "
${CHROOTCMD}${GRUBTYPE_OF_PARTZ[$USRPART]}$FORCEPARAM$ATA --no-nvram $DEVGRUBSTAGEONE"
LANGUAGE=C LC_ALL=C $CHROOTCMD${GRUBTYPE_OF_PARTZ[$USRPART]}$FORCEPARAM$ATA --no-nvram $DEVGRUBSTAGEONE
GI_EXITCODE="$?"
[[ "$GI_EXITCODE" != 0 ]] && ERROR="--no-nvram exit code: $GI_EXITCODE $PLEASECONTACT" && echo "$ERROR"
}

grub_mkconfig_main() {
[[ "$GRUBPACKAGE" = grub ]] && UPDATEYES=" -y" || UPDATEYES=""
grub_mkconfig
if [[ "$(cat "$CATTEE" | grep 'Unrecognized option' )" ]] && [[ "$UPDATEYES" = " -y" ]];then #in case grub2 detected as grub1
	UPDATEYES=""
	grub_mkconfig
fi
#exclude 'error: cannot find a GRUB drive' because false-positive on ESPs.
[[ "$(cat "$CATTEE" | grep 'error:' | grep -v 'error: cannot find a GRUB drive' | grep -v 'grub-probe: error: failed to get canonical path' )" ]] && ERROR="Error detected in grub_mkconfig. $PLEASECONTACT"
for z in grub grub2;do #Set Windows as default OS
	if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}"/boot/$z/grub.cfg ]] && [[ "$CHANGEDEFAULTOS" ]];then
		CHANGEDEFAULTOS="${CHANGEDEFAULTOS%%\:*}" #the partion of the OS to default, eg sda5
		r="$(cat "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/$z/grub.cfg" | grep "${CHANGEDEFAULTOS})" | grep menuentry | grep -v '#' )"
		if [[ "$r" ]];then
			r="${r#*menuentry \'}"; r="${r%%\'*}" #eg Windows 7 (loader) (on /dev/sda11)
			dd="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
			if [[ -f "$dd" ]];then
				sed -i "s|GRUB_DEFAULT=.*|GRUB_DEFAULT=\"${r}\"|" "$dd"
				echo "
Set $r as default entry"
				grub_mkconfig
			fi
		else
			echo "Warning: no Windows in ${BLKIDMNT_POINT[$REGRUB_PART]}/boot/$z/grub.cfg"
		fi
	fi
done
}

grub_mkconfig() {
update_cattee
if [[ "${UPDATEGRUB_OF_PART[$USRPART]}" = update-grub ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''Grub-update. $This_may_require_several_minutes''')"
	echo "
$CHROOTCMD${UPDATEGRUB_OF_PART[$USRPART]}$UPDATEYES"
	LANGUAGE=C LC_ALL=C $CHROOTCMD${UPDATEGRUB_OF_PART[$USRPART]}$UPDATEYES
elif [[ "${UPDATEGRUB_OF_PART[$USRPART]}" =~ mkconfig ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''Grub-mkconfig. $This_may_require_several_minutes''')"
	for cfg in "/" "2/";do
		if [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub$cfg" ]];then
			echo "
$CHROOTCMD${UPDATEGRUB_OF_PART[$USRPART]}${cfg}grub.cfg"
			LANGUAGE=C LC_ALL=C $CHROOTCMD${UPDATEGRUB_OF_PART[$USRPART]}${cfg}grub.cfg
		fi
	done
fi
}

#####Used by repair, uninstaller (for GRUB reinstall, and purge)
force_unmount_os_partitions_in_mnt_except_reinstall_grub() {
[[ "$DEBBUG" ]] && echo "[debug]Unmount all OS partitions except / and partition where we reinstall GRUB (${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/})"
local fuopimerg
[[ "$GUI" ]] && echo "SET@_label0.set_text('''Unmount all except ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}. $This_may_require_several_minutes''')"
pkill pcmanfm	#To avoid it automounts
if [[ ! "$FEDORA_DETECTED" ]];then
	for ((fuopimerg=1;fuopimerg<=NBOFPARTITIONS;fuopimerg++)); do
		if [[ "${PART_WITH_OS[$fuopimerg]}" = is-os ]] && [[ "${BLKIDMNT_POINT[$fuopimerg]}" ]] \
		&& [[ "${BLKIDMNT_POINT[$fuopimerg]}" != /boot ]] && [[ "${BLKIDMNT_POINT[$fuopimerg]}" != /usr ]] && [[ ! "${BLKIDMNT_POINT[$fuopimerg]}" =~ /zfs ]] \
		&& [[ ! "${OSNAME[$fuopimerg]}" =~ Fedora ]] && [[ ! "${OSNAME[$fuopimerg]}" =~ Arch ]] \
		&& [[ "$fuopimerg" != "$REGRUB_PART" ]] && [[ "${EFI_TYPE[$fuopimerg]}" = isnotESP ]];then
			umount "${BLKIDMNT_POINT[$fuopimerg]}"
		fi #http://forum.ubuntu-fr.org/viewtopic.php?id=957301 , http://forums.linuxmint.com/viewtopic.php?f=46&t=108870&p=612288&hilit=grub#p612288
	done
fi
}

mount_separate_boot_if_required() {
[[ "$DEBBUG" ]] && echo "[debug] mount_separate_boot_if_required $NOW_IN_OTHER_DISKS , $USE_SEPARATEBOOTPART, $GRUBPACKAGE ,$USE_SEPARATEUSRPART"
if [[ "$NOW_USING_CHOSEN_GRUB" ]];then
	if [[ "$USE_SEPARATEBOOTPART" ]];then
		pkill pcmanfm	#To avoid it automounts
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/boot"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" 2>/dev/null )" ]] && [[ "$KERNEL_PURGE" ]];then
			echo "Rename ${LISTOFPARTITIONS[$BOOTPART_TO_USE]}/boot to boot_bak"
			cp -r "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" "${BLKIDMNT_POINT[$REGRUB_PART]}/boot_bak"
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
		fi
		if [[ "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}" != "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" ]];then
			umount "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
			BLKIDMNT_POINT[$BOOTPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
			echo "Mount ${LISTOFPARTITIONS[$BOOTPART_TO_USE]} on ${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
			mount "${LISTOFPARTITIONS[$BOOTPART_TO_USE]}" "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
		fi
	fi
	[[ -d "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}/boot" ]] && [[ ! -d "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}/dev" ]] \
	&& mv "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}/boot" "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}/boot_rm"
	if [[ "$GRUBPACKAGE" =~ efi ]];then
		pkill pcmanfm	#To avoid it automounts
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/boot/efi"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi" )" ]];then
			echo "${LISTOFPARTITIONS[$REGRUB_PART]}/boot/efi not empty"
		fi
		if [[ "${BLKIDMNT_POINT[$EFIPART_TO_USE]}" != "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi" ]];then
			umount "${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
			BLKIDMNT_POINT[$EFIPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
			echo "Mount ${LISTOFPARTITIONS[$EFIPART_TO_USE]} on ${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
			mount "${LISTOFPARTITIONS[$EFIPART_TO_USE]}" "${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
			efitmp="$EFIPART_TO_USE";
            [[ "$DEBBUG" ]] && md5_efi_partition
			aa="$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi/efi" 2>/dev/null)"
			[[ ! "$aa" =~ ubuntu ]] && [[ ! "$aa" =~ mint ]] && echo "No ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/boot/efi/efi/ ubuntu/mint folder"
		fi
	fi
	if [[ "$USE_SEPARATEUSRPART" ]] && [[ "${BLKIDMNT_POINT[$USRPART_TO_USE]}" != "${BLKIDMNT_POINT[$REGRUB_PART]}/usr" ]];then
		pkill pcmanfm	#To avoid it automounts
		umount "${BLKIDMNT_POINT[$USRPART_TO_USE]}"
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/usr" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/usr"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/usr" 2>/dev/null )" ]];then
			echo "Warning: ${LISTOFPARTITIONS[$REGRUB_PART]}/usr not empty. $PLEASECONTACT"
			ls "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
			echo ""
		fi
		BLKIDMNT_POINT[$USRPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
		echo "Mount ${LISTOFPARTITIONS[$USRPART_TO_USE]} on ${BLKIDMNT_POINT[$USRPART_TO_USE]}"
		mount "${LISTOFPARTITIONS[$USRPART_TO_USE]}" "${BLKIDMNT_POINT[$USRPART_TO_USE]}"
	fi
fi
}


#Used by reinstall_grub_main_mbr, loop_install_grub_in_all_other_disks (reinstal), restore_resolvconf_and_unchroot (purge)
unchroot_linux_to_reinstall() {
[[ "$GUI" ]] && echo "SET@_label0.set_text('''Unchroot. $Please_wait''')"
local w
if [[ "$LIVESESSION" = live ]];then
	pkill pcmanfm	#avoids automounts
	[[ "$GRUBPACKAGE" =~ efi ]] && umount "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
	[[ "$USE_SEPARATEBOOTPART" ]] && umount "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
	[[ "$USE_SEPARATEUSRPART" ]] && umount "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
	for w in run sys proc dev/pts dev; do umount -lf "${BLKIDMNT_POINT[$REGRUB_PART]}/$w" ; done
fi
}


prepare_chroot() {
#called by force_unmount_and_prepare_chroot (GRUB reinstall), and prepare_chroot_and_internet (purge)
[[ "$DEBBUG" ]] && echo "[debug]prepare_chroot"
if [[ "$LIVESESSION" = live ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (chroot). $This_may_require_several_minutes''')"
	local w
	CHROOTCMD="chroot ${BLKIDMNT_POINT[$REGRUB_PART]} "
	CHROOTUSR="chroot \"${BLKIDMNT_POINT[$REGRUB_PART]}\" "
	#CHROOTCMD='chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" '
	#CHROOTUSR='chroot \"${BLKIDMNT_POINT[$REGRUB_PART]}\" '
	if [[ "${BLKIDMNT_POINT[$REGRUB_PART]}" =~ sav/zfs ]];then
		#https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bullseye%20Root%20on%20ZFS.html#rescuing-using-a-live-cd
		for w in dev proc run sys; do
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
			mount --make-private --rbind /$w "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
		done
		mount -t tmpfs tmpfs "${BLKIDMNT_POINT[$REGRUB_PART]}/run"
		mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/run/lock"
		#if [[ "$GUI" ]];then
		#		end_pulse
		#		zenity --width=400 --info --text="Type 'sudo chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" /bin/bash --login' in a terminal, then close this window." 2>/dev/null
		#		start_pulse
		#	else
		#		read -r -p "Type 'sudo chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" /bin/bash --login' in another terminal, then press [Enter] here to proceed."
		#fi
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mkdir -p /boot
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mount /boot 2>/dev/null  #in case a zfs distro has /boot in fstab
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mkdir -p /boot/grub
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mount /boot/grub
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mkdir -p /boot/efi
		#chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" mount /boot/efi
		#echo "${CHROOTCMD}mount -a"
		#"${CHROOTCMD}mount -a" #mounts acc to fstab (e.g. jammy:  sda2 on /boot/efi, and /boot/efi/grub on boot/grub)
		echo "modprobe zfs $(modprobe zfs)"  #cf geole
	else
		[[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/dev" ]] && mount ${LISTOFPARTITIONS[$REGRUB_PART]} "${BLKIDMNT_POINT[$REGRUB_PART]}" \
		&& echo "Mounted ${LISTOFPARTITIONS[$REGRUB_PART]} on ${BLKIDMNT_POINT[$REGRUB_PART]}" \
		|| echo "[debug] Already mounted ${LISTOFPARTITIONS[$REGRUB_PART]} on ${BLKIDMNT_POINT[$REGRUB_PART]}" #debug error 127
		for w in dev dev/pts proc run sys; do
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
			mount -B /$w "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
		done  #ubuntuforums.org/showthread.php?t=1965163
	fi
else
	CHROOTCMD=""
	CHROOTUSR=""
fi
mount_separate_boot_if_required
}

update_cattee() {
(( TEECOUNTER += 1 ))
CATTEE="$TMP_FOLDER_TO_BE_CLEARED/$TEECOUNTER.tee"
exec >& >(tee "$CATTEE")
}
