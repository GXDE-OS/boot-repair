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

########################## RESTORE MBR #################################
restore_mbr() {
local temp BETWEEN_PARENTHESIS HBACKUP DBACKUP
DISK_TO_RESTORE_MBR="${MBR_TO_RESTORE%% (*}"; 
echo "$(title_gen "Restore MBR of $DISK_TO_RESTORE_MBR")
"
[[ "$DEBBUG" ]] && echo "Restore $MBR_TO_RESTORE into $DISK_TO_RESTORE_MBR"
temp="${MBR_TO_RESTORE#* (}"; BETWEEN_PARENTHESIS="${temp%)*}"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Restore_MBR. $Please_wait''')"
if [[ -f $LOGREP/${DISK_TO_RESTORE_MBR#*/dev/}/current_mbr.img ]];then	#Security
	#cp $LOGREP/$DISK_TO_RESTORE_MBR/current_mbr.img $LOGREP/$DISK_TO_RESTORE_MBR/mbr_before_restoring_mbr.img
	if [[ "$MBR_TO_RESTORE" =~ xp ]];then
		install-mbr -e ${TARGET_PARTITION_FOR_MBR} ${DISK_TO_RESTORE_MBR}; echo "install-mbr -e ${TARGET_PARTITION_FOR_MBR} ${DISK_TO_RESTORE_MBR}"
	elif [[ "$BETWEEN_PARENTHESIS" =~ mbr ]];then
		BETWEEN_PARENTHESIS="${BETWEEN_PARENTHESIS#* }"
		[[ -f "/usr/lib/syslinux/mbr/${BETWEEN_PARENTHESIS}.bin" ]] && BETWEEN_PARENTHESIS=mbr/"$BETWEEN_PARENTHESIS"
		echo "dd if=/usr/lib/syslinux/${BETWEEN_PARENTHESIS}.bin of=${DISK_TO_RESTORE_MBR}"
		dd if=/usr/lib/syslinux/${BETWEEN_PARENTHESIS}.bin of=${DISK_TO_RESTORE_MBR} bs=446 count=1 2>/dev/null
		bootflag_action ${TARGET_PARTITION_FOR_MBR}
	else
		echo "Error : $MBR_TO_RESTORE [$BETWEEN_PARENTHESIS] could not be restored in $DISK_TO_RESTORE_MBR. $PLEASECONTACT"
		[[ "$GUI" ]] && zenity --width=400 --error --text="Error : $MBR_TO_RESTORE could not be restored in $DISK_TO_RESTORE_MBR. $PLEASECONTACT" 2>/dev/null
	fi
else
	[[ "$GUI" ]] && zenity --width=400 --error --text="Error : $LOGREP/${DISK_TO_RESTORE_MBR#*/dev/}/current_mbr.img does not exist. MBR could not be restored. $PLEASECONTACT" 2>/dev/null
	ERROR="Error : $LOGREP/${DISK_TO_RESTORE_MBR#*/dev/}/current_mbr.img does not exist. $PLEASECONTACT"; echo "$ERROR"
fi
}


######################### RESTORE BKP EFI  #############################
restore_efi_bkp_files() {
#called by first_actions
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	EFIDO="${BLKIDMNT_POINT[$i]}/"
	for chgfile in Microsoft/Boot/bootmgfw.efi Microsoft/Boot/bootx64.efi Boot/bootx64.efi;do
		for eftmp in efi EFI;do
			EFIFICH="$EFIDO$eftmp/$chgfile"
			restore_one_efi_bkp
		done
	done
done
}

restore_one_efi_bkp() {
EFIFOLD="${EFIFICH%/*}"
EFIFICHEND="${chgfile##*/}"
NEWEFIL="$EFIFOLD/bkp$EFIFICHEND"
if [[ -f "$EFIFICH.grb" ]];then
	echo "rm $EFIFICH $EFIFICH.grb" && rm "$EFIFICH"
	[[ ! -f "$EFIFICH" ]] && rm "$EFIFICH.grb"
fi
if [[ -f "$EFIFICH.bkp" ]] || [[ -f "$NEWEFIL" ]];then
	[[ -f "$EFIFICH" ]] && echo "rm $EFIFICH" && rm "$EFIFICH"
	if [[ -f "$EFIFICH" ]];then
		echo "Error: could not rm $EFIFICH"
	else
		[[ -f "$EFIFICH.bkp" ]] && echo "mv $EFIFICH.bkp $EFIFICH" && mv "$EFIFICH.bkp" "$EFIFICH"
		[[ -f "$NEWEFIL" ]] && echo "mv $NEWEFIL $EFIFICH" && mv "$NEWEFIL" "$EFIFICH"
	fi
fi
}

######################### UNHIDE BOOT MENUS ############################
unhide_boot_menus_xp() {
[[ "$DEBBUG" ]] && echo "[debug]Unhide boot menu ($UNHIDEBOOT_TIME seconds) if Wubi detected"
local i word MODIFDONE
if [[ "$QTY_WUBI" != 0 ]];then
	for ((i=1;i<=NBOFPARTITIONS;i++)); do
		if [[ -f "${BLKIDMNT_POINT[$i]}/boot.ini" ]];then
			[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Unhide_boot_menu. $This_may_require_several_minutes''')"
			cp "${BLKIDMNT_POINT[$i]}/boot.ini" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_old"
			cp "${BLKIDMNT_POINT[$i]}/boot.ini" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new"
			MODIFDONE=""
			for word in $(cat "${BLKIDMNT_POINT[$i]}/boot.ini"); do #No " around cat
				if [[ "$word" =~ "timeout=" ]] && [[ "$word" != "timeout=$UNHIDEBOOT_TIME" ]];then
					sed -i "s/${word}.*/timeout=${UNHIDEBOOT_TIME}/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new"
					MODIFDONE=yes
				fi #http://ubuntuforums.org/showthread.php?p=12394097#post12394097
			done
			if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
				echo "Unhide Windows XP boot menu in ${LISTOFPARTITIONS[$i]}/boot.ini"
				mv "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new" "${BLKIDMNT_POINT[$i]}/boot.ini"
			elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new" ]];then
				echo "Error: could not unhide XP in ${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini"
				[[ "$GUI" ]] && zenity --width=400 --error --text="Error: could not unhide XP in ${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini" 2>/dev/null
			else
				rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_old"
				rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/boot.ini_new"
			fi
		fi
	done
fi
}

unhide_boot_menus_etc_default_grub() {
local i MODIFDONE word
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]];then
		[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Unhide_boot_menu. $This_may_require_several_minutes''')"
		cp "${BLKIDMNT_POINT[$i]}/etc/default/grub" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_old"
		cp "${BLKIDMNT_POINT[$i]}/etc/default/grub" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
		MODIFDONE=""
		for word in $(cat "${BLKIDMNT_POINT[$i]}/etc/default/grub"); do
			if [[ "$word" =~ "GRUB_TIMEOUT=" ]] && [[ ! "$word" =~ "#GRUB_TIMEOUT=" ]] && [[ "$word" != "GRUB_TIMEOUT=${UNHIDEBOOT_TIME}" ]];then
				sed -i "s/${word}.*/GRUB_TIMEOUT=${UNHIDEBOOT_TIME}/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
				MODIFDONE=yes #Set timout to UNHIDEBOOT_TIME seconds
			elif [[ "$word" =~ "GRUB_HIDDEN_TIMEOUT=" ]] && [[ ! "$word" =~ "#GRUB_HIDDEN_TIMEOUT=" ]];then
				sed -i "s/${word}.*/#${word}/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
				MODIFDONE=yes #Comment GRUB_HIDDEN_TIMEOUT
			elif [[ "$word" =~ "GRUB_DISABLE_RECOVERY=" ]] && [[ ! "$word" =~ "#GRUB_DISABLE_RECOVERY=" ]];then
				sed -i "s/${word}.*/#${word}/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
				MODIFDONE=yes #Comment GRUB_DISABLE_RECOVERY
			elif [[ "$word" =~ "GRUB_TIMEOUT_STYLE=" ]] && [[ ! "$word" =~ "#GRUB_TIMEOUT_STYLE=" ]] && [[ ! "$word" =~ "GRUB_TIMEOUT_STYLE=menu" ]];then
				sed -i "s/${word}.*/GRUB_TIMEOUT_STYLE=menu/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
				MODIFDONE=yes #Set GRUB_TIMEOUT_STYLE to menu (generally instead of hidden)				
			elif [[ "$word" =~ "GRUB_DISABLE_OS_PROBER=" ]] && [[ "$word" != "GRUB_DISABLE_OS_PROBER=false" ]];then
				sed -i "s/${word}.*/GRUB_DISABLE_OS_PROBER=false/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
				MODIFDONE=yes #Set GRUB_DISABLE_OS_PROBER to false
			fi
		done
		if [[ ! "$(cat "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new" | grep 'GRUB_DISABLE_OS_PROBER=false' )" ]];then
			echo "GRUB_DISABLE_OS_PROBER=false" >> "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
			MODIFDONE=yes 
		fi
		if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
			echo "
Unhide GRUB boot menu in ${LISTOFPARTITIONS[$i]#*/dev/}/etc/default/grub"
			mv "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new" "${BLKIDMNT_POINT[$i]}/etc/default/grub"
		elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new" ]];then
			echo "Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]#*/dev/}/etc/default/grub"
			[[ "$GUI" ]] && zenity --width=400 --error --text="Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]#*/dev/}/etc/default/grub" 2>/dev/null
		else
			rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_old"
			rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/etc_default_grub_new"
		fi
	fi
done
}

unhide_boot_menus_grubcfg() {
local i FLD MODIFDONE word
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	for FLD in grub grub2;do
		if [[ -f "${BLKIDMNT_POINT[$i]}/boot/$FLD/grub.cfg" ]];then
			[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Unhide_boot_menu. $This_may_require_several_minutes''')"
			cp "${BLKIDMNT_POINT[$i]}/boot/$FLD/grub.cfg" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_old"
			cp "${BLKIDMNT_POINT[$i]}/boot/$FLD/grub.cfg" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new"
			MODIFDONE=""
			for word in $(cat "${BLKIDMNT_POINT[$i]}/boot/$FLD/grub.cfg"); do
				if [[ "$word" =~ "timeout=" ]] && [[ "$word" != "timeout=$UNHIDEBOOT_TIME" ]];then
					sed -i "s/$word.*/timeout=$UNHIDEBOOT_TIME/" "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new"
					MODIFDONE=yes #Set timout to UNHIDEBOOT_TIME seconds
				fi
			done
			if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
				echo "
Unhide GRUB boot menu in ${LISTOFPARTITIONS[$i]#*/dev/}/boot/$FLD/grub.cfg"
				mv "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new" "${BLKIDMNT_POINT[$i]}/boot/$FLD/grub.cfg"
				[[ "$i" = "$REGRUB_PART" ]] && rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_old" #Not needed
			elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new" ]];then
				echo "Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]#*/dev/}/boot/$FLD/grub.cfg"
				[[ "$GUI" ]] && zenity --width=400 --error --text="Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]#*/dev/}/boot/$FLD/grub.cfg" 2>/dev/null
			else
				rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_old"
				rm "$LOGREP/${LISTOFPARTITIONS[$i]#*/dev/}/grub.cfg_new"
			fi
		fi
	done
done
}

####################### STATS FOR IMPROVING THE TOOLS ##################
stats() {
local i URLST CODO WGETST
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (net-check). $This_may_require_several_minutes''')"
WGETTIM=8
check_internet_connection
if [[ "$INTERNET" = connected ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (net-ok). $This_may_require_several_minutes''')"
	URLST="http://sourceforge.net/projects/$APPNAME/files/statistics/$APPNAME"
	URLSTBI="http://sourceforge.net/projects/boot-info/files/statistics/boot-info"
	CODO="counter/download"
	WGETST="wget -T $WGETTIM -o /dev/null -O /dev/null"
	for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
		[[ -d "${OS__MNT_PATH[$i]}/$APPNAME" ]] || [[ -d "${OS__MNT_PATH[$i]}/var/log/$APPNAME" ]] && [[ "${OS__MNT_PATH[$i]}" ]] && NEWUSER=""
	done
	[[ "$MAIN_MENU" =~ mm ]] && [[ "$NEWUSER" ]] && $WGETST $URLST.user.$CODO
	[[ "$MAIN_MENU" =~ fo ]] && [[ "$NEWUSER" ]] && $WGETST $URLSTBI.user.$CODO
	[[ "$MAIN_MENU" =~ fo ]] && $WGETST $URLSTBI.usage.$CODO
	if [[ "$MAIN_MENU" = Custom-Repair ]];then
		[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (cus). $This_may_require_several_minutes''')"
		[[ "$NEWUSER" ]] && [[ "$MAIN_MENU" = Custom-Repair ]] && $WGETST $URLST.customrepairbynewuser.$CODO \
		|| $WGETST $URLST.customrepair.$CODO
	fi
	stats_diff
fi
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB. $Please_wait''')"
}

############################# BOOTFLAG #################################
bootflag_action() {
#called by first_actions & restore_mbr
local PARTTOBEFLAGGED=$1 temp PRIMARYNUM DISKTOFLAG r
temp="${LISTOFPARTITIONS[$PARTTOBEFLAGGED]}"	#sdXY
PRIMARYNUM="${temp##*[a-z]}"				#Y (1~4) of sdXY
DISKTOFLAG="${DISK_PART[$PARTTOBEFLAGGED]}" #sdX
[[ ! "$(echo "$FDISKL" | grep '*' | grep "/$temp " )" ]] \
&& echo "parted $DISKTOFLAG set $PRIMARYNUM boot on" && parted $DISKTOFLAG set $PRIMARYNUM boot on
for r in 1 2 3 4;do
	[[ "$(echo "$FDISKL" | grep '*' | grep "/$DISKTOFLAG$r " )" ]] && [[ "$r" != "$PRIMARYNUM" ]] \
	&& echo "parted $DISKTOFLAG set $r boot off" && parted $DISKTOFLAG set $r boot off
done #Don't work if "Can't have a partition outside the disk!" http://ubuntuforums.org/showpost.php?p=12179704&postcount=23
}

############################# REMOVE HIDDEN FLAG #################################
remove_hiddenflag() {
local PARTTOUNFLAG=$1 PARTB PRIMARYNUM DISKTOUNFLAG userok=yes
PARTB="${LISTOFPARTITIONS[$PARTTOUNFLAG]}"	#/dev/sdXY
PRIMARYNUM="${PARTB##*[a-z]}"				#Y (1~4) of sdXY
DISKTOUNFLAG="${DISK_PART[$PARTTOUNFLAG]}" #sdX
update_translations
text="$Do_u_wanna_remove_hidden_flag_from_PARTB"
if [[ "$GUI" ]];then
	echo "$text"
	end_pulse
	zenity --width=400 --question --title="$APPNAME2" --text="$text" 2>/dev/null || userok=""
	start_pulse
else
	read -r -p "$text [yes/no] " response
	[[ ! "$response" =~ y ]] && userok=""
fi
[[ "$userok" ]] && echo "parted $DISKTOUNFLAG set $PRIMARYNUM hidden off" && parted $DISKTOFLAG set $PRIMARYNUM hidden off 2>/dev/null
}

##################### REPAIR WINDOWS ################################
repair_boot_ini() {
SYSTEM1=Windows
update_translations
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Repair_SYSTEM1_bootfiles. $This_may_require_several_minutes''')"
local i j part disk temp num tempnum templetter tempdisk letter tempfld
[[ "$DEBBUG" ]] && echo "[debug]repair_boot_ini (solves bug#923374)"
echo "Quantity of real Windows: $QUANTITY_OF_REAL_WINDOWS"
for ((i=1;i<=NBOFPARTITIONS;i++)); do #http://ubuntuforums.org/showthread.php?p=12210940#post12210940
	if [[ "${WINXPTOREPAIR[$i]}" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]];then
		part="${LISTOFPARTITIONS[$i]}"	#sdXY
		disk="${DISK_PART[$i]}" 		#sdX
		num="${part##*[a-z]}"			#Y of sdXY
		tempnum=$num
		fdiskk="$(LANGUAGE=C LC_ALL=C fdisk -l $disk 2>/dev/null)"
		for ((j=1;j<num;j++)); do #Skip empty&extended http://ubuntuforums.org/showthread.php?t=813628
			temp="$(grep ${disk}$j <<< "$fdiskk" )"
			[[ ! "$temp" ]] || [[ "$(grep -i Extended <<< "$temp" )" ]] && [[ "$fdiskk" ]] && ((tempnum -= 1 ))
		done
		templetter=$(cut -c3 <<< ${DISK_PART[$i]} )	#X of sdXY
		tempdisk=0
		for letter in a b c d e f g h i j k;do
			[[ "$templetter" = "$letter" ]] && break || ((tempdisk += 1 ))
		done
		BOOTPINI="$(ls ${BLKIDMNT_POINT[$i]}/ 2>/dev/null | grep -ix boot.ini )"
		if [[ ! "$BOOTPINI" ]];then #may be BOOT.INI or Boot.ini
			tempfld="${BLKIDMNT_POINT[$i]}/boot.ini"
			echo "[boot loader]
timeout=$UNHIDEBOOT_TIME
default=multi(0)disk(0)rdisk($tempdisk)partition($tempnum)\WINDOWS
[operating systems]
multi(0)disk(0)rdisk($tempdisk)partition($tempnum)\WINDOWS=\"Windows\" /noexecute=optin /fastdetect" > "$tempfld"
			echo "Fixed $tempfld"
		else
			BOOTPINI="${BLKIDMNT_POINT[$i]}/$BOOTPINI"
			if [[ ! "$(cat "$BOOTPINI" | grep "on($tempnum)" | grep -v default )" ]] \
			|| [[ ! "$(cat "$BOOTPINI" | grep "on($tempnum)" | grep default )" ]] \
			&& [[ "$(cat "$BOOTPINI" | grep multi | grep disk | grep rdisk | grep partition )" ]];then
				sed -i.bak "s|on([0-9])|on(${tempnum})|g" "$BOOTPINI"
				echo "Repaired $BOOTPINI"
			elif [[ -f "$BOOTPINI.bak" ]];then
				echo "Detected $BOOTPINI.bak"
			fi
		fi
		for file in ntldr NTDETECT.COM;do
			if [[ ! "$(ls ${BLKIDMNT_POINT[$i]}/ 2>/dev/null | grep -ix $file )" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]];then
				for ((j=1;j<=NBOFPARTITIONS;j++)); do
					if [[ "$(ls ${BLKIDMNT_POINT[$j]}/ 2>/dev/null | grep -ix $file )" ]];then
						filetocopy="$(ls ${BLKIDMNT_POINT[$j]} 2>/dev/null | grep -ix $file )"
						cp "${BLKIDMNT_POINT[$j]}/$filetocopy" "${BLKIDMNT_POINT[$i]}/$filetocopy"
						echo "Copied $filetocopy from ${LISTOFPARTITIONS[$j]#*/dev/} to ${LISTOFPARTITIONS[$i]#*/dev/}"			
						break
					fi
				done
				[[ ! "$(ls ${BLKIDMNT_POINT[$i]}/ 2>/dev/null | grep -ix $file )" ]] && repair_boot_ini_nonfree
				[[ ! "$(ls ${BLKIDMNT_POINT[$i]}/ 2>/dev/null | grep -ix $file )" ]] && ERROR="No ntldr nor NTDETECT could be created in ${LISTOFPARTITIONS[$i]#*/dev/}. $PLEASECONTACT"
			fi
		done
	fi
done
}

repair_bootmgr() {
[[ "$DEBBUG" ]] && echo "[debug]repair_bootmgr"
local i j folder
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ "${WINSETOREPAIR[$i]}" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]] && [[ "$QTY_SUREEFIPART" = 0 ]];then
		echo "WinSE in ${LISTOFPARTITIONS[$i]#*/dev/}"
		for looop in 1 2;do #First not recovery
			for loop in 1 2;do #then first same disk
				scan_windows_parts
				if [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]];then
					for ((j=1;j<=NBOFPARTITIONS;j++)); do
						if ( ( [[ "$looop" = 1 ]] && [[ "${RECOV[$j]}" != recovery-or-hidden ]] ) \
						|| ( [[ "$looop" = 2 ]] && [[ "${RECOV[$j]}" = recovery-or-hidden ]] ) ) \
						&& ( ( [[ "$loop" = 1 ]] && [[ "${DISKNB_PART[$i]}" = "${DISKNB_PART[$j]}" ]] ) \
						|| ( [[ "$loop" = 2 ]] && [[ "${DISKNB_PART[$i]}" != "${DISKNB_PART[$j]}" ]] ) ) \
						&& [[ "${WINMGR[$j]}" != no-bmgr ]] && [[ "${WINBCD[$j]}" != no-b-bcd ]];then
							[[ ! "${WINBOOT[$i]}" ]] && mkdir "${BLKIDMNT_POINT[$i]}/${WINBOOT[$j]}" && WINBOOT[$i]="${WINBOOT[$j]}"
							cp -r ${BLKIDMNT_POINT[$j]}/${WINBOOT[$j]}/* "${BLKIDMNT_POINT[$i]}/${WINBOOT[$i]}/"
							cp "${BLKIDMNT_POINT[$j]}/${WINMGR[$j]}" "${BLKIDMNT_POINT[$i]}/${WINMGR[$j]}"
							echo "Copied Win boot files from ${LISTOFPARTITIONS[$j]#*/dev/} to ${LISTOFPARTITIONS[$i]#*/dev/}"
							if [[ "${WINGRL[$j]}" != no-grldr ]];then
								[[ ! -f "${BLKIDMNT_POINT[$j]}/grldr" ]] && echo "Strange -f /grldr. $PLEASECONTACT"
								if [[ "${WINGRL[$i]}" = no-grldr ]];then
									if [[ ! "$(ls ${BLKIDMNT_POINT[$i]}/${WINGRL[$j]} 2>/dev/null )" ]];then
										cp "${BLKIDMNT_POINT[$j]}/${WINGRL[$j]}" "${BLKIDMNT_POINT[$i]}/"
										echo "Copied /${WINGRL[$j]} file from ${LISTOFPARTITIONS[$j]#*/dev/} to ${LISTOFPARTITIONS[$i]#*/dev/}"
									fi
								fi
							fi
						fi
					done
				fi
			done
		done
		scan_windows_parts
		if [[ "${WINL[$i]}" = no-winload ]] || [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]];then
			#http://askubuntu.com/questions/155492/why-cannot-ubuntu-12-04-detect-windows-7-dual-boot
			[[ "${WINBCD[$i]}" = no-b-bcd ]] && echo "${BLKIDMNT_POINT[$i]}/${WINBOOT[$i]} may need repair."
			[[ "${WINL[$i]}" = no-winload ]] &&	echo "${BLKIDMNT_POINT[$i]}/Windows/System32/winload.exe may need repair."
			[[ "${WINMGR[$i]}" = no-bmgr ]] && echo "${BLKIDMNT_POINT[$i]}/bootmgr may need repair."
		fi
	fi
done
}

################################ ADD KERNEL ############################
add_kernel_option() {
echo "add_kernel_option CHOSEN_KERNEL_OPTION is : $CHOSEN_KERNEL_OPTION"
local line
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Add_a_kernel_option $CHOSEN_KERNEL_OPTION. $This_may_require_several_minutes''')"
if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" ]];then
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/grub_new
	while read line; do
		if [[ "$line" =~ "GRUB_CMDLINE_LINUX_DEFAULT=" ]];then
			[[ ! "$line" =~ "#GRUB_CMDLINE_LINUX_DEFAULT=" ]] && [[ ! "$line" =~ "# GRUB_CMDLINE_LINUX_DEFAULT=" ]] && echo "#$line" >> $TMP_FOLDER_TO_BE_CLEARED/grub_new
			echo "${line%\"*} ${CHOSEN_KERNEL_OPTION}\"" >> $TMP_FOLDER_TO_BE_CLEARED/grub_new
		else
			echo "$line" >> $TMP_FOLDER_TO_BE_CLEARED/grub_new
		fi
	done < <(cat "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" )
	cp -f $TMP_FOLDER_TO_BE_CLEARED/grub_new "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
	echo "Added kernel options in ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/etc/default/grub"
fi
}

########################### FlexNet ####################################
blankextraspace() {
if [[ ! -f "$LOGREP/${GRUBSTAGEONE#*/dev/}/before_wiping.img" ]];then #works: http://paste.ubuntu.com/1172629
	local partition a SECTORS_TO_WIPE BYTES_PER_SECTOR cmd
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f "$TMP_FOLDER_TO_BE_CLEARED/sort"
	for partition in $(ls "/sys/block/${GRUBSTAGEONE#*/dev/}/" 2>/dev/null | grep "${GRUBSTAGEONE#*/dev/}");do
		echo "$(cat "/sys/block/${GRUBSTAGEONE#*/dev/}/${partition#*/dev/}/start" )" >> "$TMP_FOLDER_TO_BE_CLEARED/sort"
	done
	echo 2048 >> "$TMP_FOLDER_TO_BE_CLEARED/sort" # Blank max 2048 sectors (in case the first partition is far)
	#http://askubuntu.com/questions/158299/why-does-installing-grub2-give-an-iso9660-filesystem-destruction-warning
	a=$(cat "$TMP_FOLDER_TO_BE_CLEARED/sort" | sort -g -r | tail -1 )  #sort the file in the increasing order
	[[ "$(grep "^[0-9]\+$" <<< $a )" ]] && SECTORS_TO_WIPE=$(($a-1)) || SECTORS_TO_WIPE="-1"
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f "$TMP_FOLDER_TO_BE_CLEARED/sort"
	BYTES_PER_SECTOR="$(stat -c %B $GRUBSTAGEONE)"
	cmd="dd if=$GRUBSTAGEONE of=$LOGREP/${GRUBSTAGEONE#*/dev/}/before_wiping.img bs=$BYTES_PER_SECTOR count=$SECTORS_TO_WIPE seek=1"
	echo "$cmd"
	$cmd 2>/dev/null
	if [[ ! -f "$LOGREP/${GRUBSTAGEONE#*/dev/}/before_wiping.img" ]] \
	|| [[ ! "$(ls "/sys/block/${GRUBSTAGEONE#*/dev/}/" 2>/dev/null | grep "${GRUBSTAGEONE#*/dev/}")" ]];then
		ERROR="Could not backup, wipe cancelled. $PLEASECONTACT"; echo "$ERROR"
	else	
		echo "WIPE $GRUBSTAGEONE : $SECTORS_TO_WIPE sectors * $BYTES_PER_SECTOR bytes"
		if [[ "$SECTORS_TO_WIPE" -gt 0 ]] && [[ "$SECTORS_TO_WIPE" -le 2048 ]] && [[ "$BYTES_PER_SECTOR" -ge 512 ]] \
		&& [[ "$BYTES_PER_SECTOR" -le 1024 ]];then
			cmd="dd if=/dev/zero of=$GRUBSTAGEONE bs=$BYTES_PER_SECTOR count=$SECTORS_TO_WIPE seek=1"
			#seek=1, so MBR (icl. partition table) is not wiped
			echo "$cmd"
			$cmd 2>/dev/null
		else
			MSSG="By security, $GRUBSTAGEONE sectors were not wiped. \
			(one of these values is incorrect: SECTORS_TO_WIPE=$SECTORS_TO_WIPE , BYTES_PER_SECTOR=$BYTES_PER_SECTOR )"
			end_pulse
			[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$MSSG" 2>/dev/null
			start_pulse
			ERROR="$MSSG $PLEASECONTACT"; echo "$ERROR"
		fi
	fi
fi
}

######################### UNCOMMENT GFXMODE ############################
uncomment_gfxmode() {
local line
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Uncomment_GRUB_GFXMODE. $This_may_require_several_minutes''')"
sed -i 's/#GRUB_GFXMODE/GRUB_GFXMODE/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" \
&& sed -i 's/# GRUB_GFXMODE/GRUB_GFXMODE/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" \
&& echo "Uncommented GRUB_GFXMODE in ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}/etc/default/grub"
}

########################## Final sequence ##############################

display_action_settings_start() {
ACTION_SETTINGS_START="

"
if [[ "$MAIN_MENU" != Recommended-Repair ]];then
	if [[ "$MAIN_MENU" =~ fo ]];then
		THISSET="Suggested repair"
		ACTION_SETTINGS_START="${ACTION_SETTINGS_START}Suggested repair: ______________________________________________________________

$IMPVARUN
"
	else
		THISSET="Default settings of $CLEANNAME"
		ACTION_SETTINGS_START="${ACTION_SETTINGS_START}Default settings: ______________________________________________________________

$IMPVARUN
"
	fi
	[[ "$BTEXTUN" ]] || [[ "$ATEXTUN" ]] && ACTION_SETTINGS_START="$ACTION_SETTINGS_START
Blockers in case of suggested repair: __________________________________________

$BTEXTUN $ATEXTUN
"
	[[ "$TEXTUN" ]] && ACTION_SETTINGS_START="$ACTION_SETTINGS_START
Confirmation request before suggested repair: __________________________________

$TEXTUN
"
	[[ "$TEXTENDUN" ]] && ACTION_SETTINGS_START="$ACTION_SETTINGS_START
Final advice in case of suggested repair: ______________________________________

$TEXTENDUN
"
fi
if [[ "$MAIN_MENU" =~ Custom ]];then
	ACTION_SETTINGS_START="$ACTION_SETTINGS_START
User settings: _________________________________________________________________
"
fi
WIOULD=will
debug_echo_important_variables
}

display_action_settings_end() {
[[ "$MAIN_MENU" != Boot-Info ]] && echo "$IMPVAR"
TEECOUNTER=0
}

first_actions() {
[[ "$DEBBUG" ]] && echo "[debug] first_actions=action before removal (if os-un)"
[[ "$MBR_ACTION" != reinstall ]] && [[ "$BOOTFLAG_ACTION" ]] && [[ "$BOOTFLAG_TO_USE" ]] && bootflag_action $BOOTFLAG_TO_USE
[[ "$MBR_ACTION" = reinstall ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$EFIPART_TO_USE" = "${LIST_EFIPART[1]}" ]] \
&& [[ "${EFI_TYPE[$EFIPART_TO_USE]}" = hidenESP ]] && remove_hiddenflag $EFIPART_TO_USE  #only if default esp
[[ "$MBR_ACTION" = reinstall ]] && fix_fstab
[[ "$RESTORE_BKP_ACTION" ]] || [[ "$CREATE_BKP_ACTION" ]] && restore_efi_bkp_files
if [[ "$WINBOOT_ACTION" ]];then
	repair_boot_ini
	repair_bootmgr
fi
}

actions_final() {
[[ "$DEBBUG" ]] && echo "[debug] actions_final=action after removal (if os-un)"
[[ "$MBR_ACTION" = reinstall ]] && remove_stage1_from_other_os_partitions
[[ "$MBR_ACTION" = reinstall ]] && reinstall_grub_from_non_removable
[[ "$KERNEL_PURGE" ]] && kernel_purge
if [[ "$GRUBPURGE_ACTION" ]] && [[ "$MBR_ACTION" = reinstall ]];then
	grub_purge
else
	[[ "$UNHIDEBOOT_ACTION" ]] && unhide_boot_menus_etc_default_grub #Requires all OS partitions to be mounted
	if [[ "$MBR_ACTION" = reinstall ]];then
		reinstall_grub_from_chosen_linux
	elif [[ "$MBR_ACTION" = restore ]];then
		restore_mbr
	fi
	unmount_all_and_success
fi
}

unhideboot_and_textprepare() {
BSERROR=""
if [[ "$UNHIDEBOOT_ACTION" ]];then
	[[ "$DEBBUG" ]] && echo "[debug]unhideboot"
	unhide_boot_menus_xp
	unhide_boot_menus_grubcfg	#To replace the "-1"
fi
TEXTBEG=""
TEXTEND=""
if [[ "$MBR_ACTION" != nombraction ]] || [[ "$UNHIDEBOOT_ACTION" ]] || [[ "$FSCK_ACTION" ]] \
|| [[ "$BOOTFLAG_ACTION" ]] || [[ "$WINBOOT_ACTION" ]];then
	if [[ "$ERROR" ]];then
		TEXTBEG="$An_error_occurred_during
$ERROR

"
	else
		TEXTBEG="$Successfully_processed

"
	fi
	if [[ "$LOCKEDESP" ]] || [[ "$NVRAMLOCKED" ]] || [[ "$GRUBFOUNDONANOTHERDISK" ]];then #Messages that could not be anticipated before repair
		if [[ "$LOCKEDESP" ]];then
			FUNCTION=Locked-ESP; TYP=/boot/efi; TOOL1=gParted; TYPE3=/boot/efi; update_translations
			FLAGTYP=boot; OPTION2="$Separate_TYPE3_partition"; update_translations
			TEXTEND="$TEXTEND$FUNCTION_detected $You_may_want_to_retry_after_creating_TYP_part (FAT32, 100MB~250MB, $start_of_the_disk, $FLAGTYP_flag). $Via_TOOL1 \
$Then_select_this_part_via_OPTION2_of_TOOL3
"
			[[ "${SECUREBOOT%% *}" != disabled ]] && TEXTEND="$TEXTEND$Please_disable_OPTION5_in_BIOS $Then_try_again
"
		fi
		if [[ "$NVRAMLOCKED" ]];then
			FILE1="${LISTOFPARTITIONS[$EFIPART_TO_USE]#*/dev/}${EFIGRUBFILE#*/boot/efi}";
			SYSTEM1="${OSNAME[$REGRUB_PART]}"
			FUNCTION=Locked-NVram; OPTION5=SecureBoot; update_translations
			[[ ! "$EFIBMGRAFT" =~ Boot ]] && TEXTEND="$TEXTEND$FUNCTION_detected $Please_setup_firmware_on_SYSTEM1_FILE1
" || TEXTEND="$TEXTEND$FUNCTION_detected ($LSBRELIS) $PLEASECONTACT
$Please_setup_firmware_on_SYSTEM1_FILE1
"
			[[ "${SECUREBOOT%% *}" != disabled ]] && TEXTEND="$TEXTEND$Please_disable_OPTION5_in_BIOS $Then_try_again
"
		fi
		if [[ "$GRUBFOUNDONANOTHERDISK" ]];then
			TEXTEND="$TEXTEND$Only_MBR_of_current_OS_was_fixed $To_fix_other_MBRs_use_again_from_live_session
"
		fi
	else
		TEXTEND="$You_can_now_reboot
"
		textprepare
	fi
#elif [[ ! "$MAIN_MENU" =~ nf ]];then
#	TEXTEND="$No_change_on_your_pc"
fi
echo "
$TEXTBEG$TEXTMID$TEXTEND"
}

textprepare() {
#called by debug_echo_important_var_first (justbootinfo_br_and_bi  and expander) & unhideboot_and_textprepare
first_translations
if [[ "$MBR_ACTION" = reinstall ]];then
	if [[ "$FORCE_GRUB" = force-in-PBR ]] || [[ "$ADVISE_BOOTLOADER_UPDATE" = yes ]];then
		TEXTEND="$TEXTEND$Please_update_main_bootloader
"
	elif [[ "$GRUBPACKAGE" =~ efi ]];then #[[ ! -d /sys/firmware/efi ]] || [[ ! "$CREATE_BKP_ACTION" ]] && [[ "$EFIGRUBFILE" ]]
			FILE1="${LISTOFPARTITIONS[$EFIPART_TO_USE]#*/dev/}${EFIGRUBFILE#*/boot/efi}";
			SYSTEM1="${OSNAME[$REGRUB_PART]}" ; update_translations
			TEXTEND="$TEXTEND$Please_setup_firmware_on_SYSTEM1_FILE1
"
	elif [[ "$NBOFDISKS" != 1 ]];then
		if [[ "$REMOVABLEDISK" ]];then
			TEXTEND="$TEXTEND$Please_setup_bios_on_removable_disk
"
		else
			a="$(echo "$PARTEDLM" | grep "$NOFORCE_DISK:" )"; a="${a%:*}"; a="${a##*:}"
			[[ "$a" ]] && DISK1="${NOFORCE_DISK#*/dev/} ($a)" || DISK1="${NOFORCE_DISK#*/dev/}"
			update_translations
			TEXTEND="$TEXTEND$Please_setup_bios_on_DISK1
"
		fi
	fi
	if [[ "${SECUREBOOT%% *}" = enabled ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ ! "$GRUBPACKAGE" =~ sign ]] && [[ "$GRUBPACKAGE" =~ efi ]];then
		OPTION5=SecureBoot; update_translations
		TEXTEND="$TEXTEND$Please_disable_OPTION5_in_BIOS
"
	fi
	if [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] || [[ "$MACEFIFILEPRESENCE" ]];then
		TEXTEND="$TEXTEND$You_may_also_want_to_install_PROGRAM6 (https://help.ubuntu.com/community/ubuntupreciseon2011imac)
"
	fi
	#Case /boot partition ends after 100GB from start of the disc https://forum.ubuntu-fr.org/viewtopic.php?pid=22555203#p22555203
	if [[ "${FARBIOS[$BOOTPART]}" != not-far ]] && [[ ! "$GRUBPACKAGE" =~ efi ]] && [[ "$LIVESESSION" = live ]];then #&& [[ "${GPT_DISK[${DISKNB_PART[$REGRUB_PART]}]}" != is-GPT ]] 
		SYSTEM2="${LISTOFPARTITIONS[$BOOTPART]#*/dev/} (end>100GB)"; TYP=/boot; TOOL1=gParted; TYPE3=/boot; update_translations
		OPTION2="$Separate_TYPE3_partition"; update_translations
		[[ "$DEBBUG" ]] && echo "$Boot_files_of_SYSTEM2_are_far"
		TEXTEND="$TEXTEND
$Boot_files_of_SYSTEM2_are_far \
$You_may_want_to_retry_after_creating_TYP_part (EXT4, >200MB, $start_of_the_disk). $Via_TOOL1 \
$Then_select_this_part_via_OPTION2_of_TOOL3 ($BootPartitionDoc)"
	fi
	#Case ESP ends after 100GB from start of the disc
	if [[ "${FARBIOS[$EFIPART_TO_USE]}" != not-far ]] && [[ "$GRUBPACKAGE" =~ efi ]] && [[ "$LIVESESSION" = live ]];then
		SYSTEM2="${LISTOFPARTITIONS[$EFIPART_TO_USE]#*/dev/} (end>100GB)"; TYP=ESP; TOOL1=gParted; TYPE3=/boot/efi; update_translations
		FLAGTYP=boot; OPTION2="$Separate_TYPE3_partition"; update_translations
		[[ "$DEBBUG" ]] && echo "$Boot_files_of_SYSTEM2_are_far"
		TEXTEND="$TEXTEND
$Boot_files_of_SYSTEM2_are_far \
$You_may_want_to_retry_after_creating_TYP_part (FAT32, 100MB~250MB, $start_of_the_disk, $FLAGTYP_flag). $Via_TOOL1 \
$Then_select_this_part_via_OPTION2_of_TOOL3"
	fi
	if [[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ "$WINEFIFILEPRESENCE" ]] && [[ "$GRUBPACKAGE" =~ efi ]];then
		OPTION="$Msefi_too"
        OPTION1="$Msefi_too"
		update_translations
		if [[ "$WINEFI_BKP_ACTION" ]];then
			TEXTEND="$TEXTEND$You_may_want_to_retry_after_deactivating_OPTION
"
		else
			temp=""
			if [[ "$EFIGRUBFILE" ]];then
				temp="${EFIGRUBFILE#*/boot/efi}"
				temp="${temp#*EFI/}"
				temp="${temp#*efi/}"
				temp="$Via_command_in_win
bcdedit /set {bootmgr} path \\\\EFI\\\\${temp////\\\\}"
			fi # \\ are displayed \ in zenity
			TEXTEND="$TEXTEND$If_boot_win_try_change_firmware_order
$If_firmware_blocked_change_win_order
$temp
"
#$Alternatively_you_can_try_OPTION1
		fi
	fi
	if [[ "$FINALMSG_UPDATEGRUB" ]];then #must be bef to avoid duplicate msg 'may need to change to Legacy'
		[[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ ! "$WINEFIFILEPRESENCE" ]] && SYSTEM8=Windows || SYSTEM8=MacOS
		SYSTEM6="${OSNAME[$REGRUB_PART]}"; COMMANDTOTYP5='sudo update-grub'; update_translations
		TEXTEND="$TEXTEND$Reboot_in_SYSTEM6_and_COMMANDTOTYP5_to_add_SYSTEM8_entry
"
	elif [[ ! -d /sys/firmware/efi ]] && [[ "$GRUBPACKAGE" =~ efi ]];then
		MODE1=BIOS-compatibility/CSM/Legacy; MODE2=UEFI; update_translations
		TEXTEND="$TEXTEND$Boot_is_MODE1_may_need_change_to_MODE2
"
	elif [[ -d /sys/firmware/efi ]] && [[ ! "$GRUBPACKAGE" =~ efi ]];then
		MODE1=UEFI; MODE2=BIOS-compatibility/CSM/Legacy; update_translations
		TEXTEND="$TEXTEND$Boot_is_MODE1_may_need_change_to_MODE2
"
	fi
fi
if [[ "$ROOTDISKMISSING" ]];then
	TEXTEND="$TEXTEND$Broken_wubi_detected
$Missingrootdiskurl
"
fi
}


stats_and_endpulse() {
[[ "$SENDSTATS" != nostats ]] && stats
end_pulse
}

finalzenity_and_exitapp() {
if [[ "$GUI" ]];then
    zenity --width=400 --info --title="$APPNAME2" --text="$TEXTBEG$TEXTMID$TEXTEND" 2>/dev/null
    if [[ -f "$FILENAME" ]];then
        if [[ "$(type -p leafpad)" ]];then	#to avoid opening in term
            leafpad "$FILENAME" &
        else
            xdg-open "$FILENAME" &
        fi
    fi
else
    echo "$TEXTBEG$TEXTMID$TEXTEND"
fi
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r "$TMP_FOLDER_TO_BE_CLEARED"
[[ "$DEBBUG" ]] && echo "End of unmount_all_and_success (SHOULD NOT SEE THIS ON LOGS)"
[[ "$GUI" ]] && echo 'EXIT@@' || exit 0
}


########################## PASTEBIN ACTION ##########################################
pastebinaction() {
local temp line PACKAGELIST=pastebinit FUNCTION=BootInfo FILETOTEST=pastebinit
LAB="$Create_a_BootInfo_report"
[[ "$GUI" ]] || [[ "$DEBBUG" ]] && echo "SET@_label0.set_text('''$LAB. $This_may_require_several_minutes''')"
cp "$TMP_LOG" "${TMP_LOG}t"

[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (bis). $This_may_require_several_minutes''')"

. /usr/share/boot-sav/b-i-s.sh
echo "${APPNAME}-$APPNAME_VERSION $([[ "$DEBBUG" ]] && echo debug || echo "     ") $([[ "$FILTERED" ]] && echo "         " || echo no-filter )                              [$DATE]" >> "${TMP_LOG}b"
if [[ "$MAIN_MENU" = Boot-Info ]];then
    title_gen "Boot Info Summary" >> "${TMP_LOG}b"
    [[ "$DEBBUG" ]] && echo "[debug] bis"
    bootinfoscript
	[[ "$USERCHOICES" ]] && echo "$(title_gen "User choice")
$USERCHOICES" >> "${TMP_LOG}b"
    echo "$ECHO_LVM_RAID_PREPAR" >> "${TMP_LOG}b"
    echo "$ACTION_SETTINGS_START" >> "${TMP_LOG}b"
    #"does not start on physical sector boundary" is frequent from fdisk
    if [[ "$DEBBUG" ]];then
        while read line; do
            [[ ! "$line" ]] || [[ "$(echo "$line" | grep -v B/s | grep -v 'while true' | grep -v 'sleep 0' | grep -v 'does not start on physical sector boundary' )" ]] \
            && echo "$line" >> "${TMP_LOG}b"
        done < <(cat ${TMP_LOG}t )
    fi
else
    title_gen "$CLEANNAME Summary" >> "${TMP_LOG}b"
    [[ "$USERCHOICES" ]] && echo "User choice:
$USERCHOICES" >> "${TMP_LOG}b"
    echo "$ECHO_LVM_RAID_PREPAR" >> "${TMP_LOG}b"
    echo "$ACTION_SETTINGS_START" >> "${TMP_LOG}b"
    #Filters on strings that don't start a line
    while read line; do
        [[ ! "$line" ]] || [[ "$(echo "$line" | grep -v B/s | grep -v 'while true' | grep -v 'sleep 0' | grep -v 'does not start on physical sector boundary' )" ]] \
        && echo "$line" >> "${TMP_LOG}b"
    done < <(cat ${TMP_LOG}t )
    title_gen "Boot Info After Repair" >> "${TMP_LOG}b"
    [[ "$DEBBUG" ]] && echo "[debug] bis"
    bootinfoscript
fi

sed -i "/^SET@/ d" "${TMP_LOG}b"
sed -i "/^DEBUG=>/ d" "${TMP_LOG}b"
sed -i "/^\[debug\]/ d" "${TMP_LOG}b"
sed -i "/^COMBO@@/ d" "${TMP_LOG}b"
sed -i "/^done/ d" "${TMP_LOG}b"
sed -i "/^gpg:/ d" "${TMP_LOG}b"
sed -i "/^Executing: gpg/ d" "${TMP_LOG}b"
sed -i "/^Reading/ d" "${TMP_LOG}b"
sed -i "/^Building dependency/ d" "${TMP_LOG}b"
sed -i "/^Need to get/ d" "${TMP_LOG}b"
sed -i "/^After this operation/ d" "${TMP_LOG}b"
sed -i "/^Gtk-Message: / d" "${TMP_LOG}b"
sed -i "/^Get:/ d" "${TMP_LOG}b"
sed -i "/^Download complete/ d" "${TMP_LOG}b"
sed -i "/^E: Package 'pastebinit' has no installation candidate/ d" "${TMP_LOG}b"
# Package 'linux-xxx' is not installed, so not removed
sed -i "/^Package 'linux-/ d" "${TMP_LOG}b"
sed -i "/^Memtest86+ needs a 16-bit/ d" "${TMP_LOG}b"
sed -i "/^Warning: os-prober will be executed/ d" "${TMP_LOG}b"
sed -i "/^Its output will be used to detect bootable binaries/ d" "${TMP_LOG}b"
sed -i "/^(Reading database/ d" "${TMP_LOG}b"
sed -i "/^Generating grub configuration file/ d" "${TMP_LOG}b"
if [[ "$FILTERED" ]];then
	sed -i "/^Warning: Unable to open / d" "${TMP_LOG}b"
	sed -i "/^Warning: The driver descriptor says/ d" "${TMP_LOG}b"
	sed -i "/^sh: getcwd/ d" "${TMP_LOG}b"
	sed -i "/^1+0/ d" "${TMP_LOG}b"
	sed -i "/^sh: 0: getc/ d" "${TMP_LOG}b"
	sed -i "/^ping: google.com/ d" "${TMP_LOG}b"
fi

[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (ter). $This_may_require_several_minutes''')"

repup=yes
if [[ "$GUI" ]] || [[ "$MAIN_MENU" != Boot-Info ]] && [[ ! "$APPNAME" =~ inf ]] && [[ "$UPLOAD" ]];then
    if [[ ! "$FORCEYES" ]];then
        text="$Upload_report ?"
        end_pulse
        if [[ "$GUI" ]];then
            zenity --width=400 --question --title="$(eval_gettext "Boot-Info")" --text="$text" 2>/dev/null || repup=no
        else
            read -r -p "$text [yes/no] " response
            [[ ! "$response" =~ y ]] && repup=no
        fi
        echo "$text $repup"
        start_pulse
    fi
fi
PASTEBIN_URL=""
if [[ "$UPLOAD" ]] && [[ "$repup" = yes ]];then
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (net-check). $This_may_require_several_minutes''')"
	check_internet_connection
	ask_internet_connection
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (url). $This_may_require_several_minutes''')"
	if [[ "$(type -p pastebinit)" ]];then #[[ "$INTERNET" = connected ]] && 
		if [[ "$(lsb_release -is)" = Debian ]] && [[ ! "$(lsb_release -ds)" =~ Boot-Repair-Disk ]];then
			PASTEB="paste.debian.net"
		elif [[ "$(lsb_release -is)" = Ubuntu ]];then
			PASTEB="paste.ubuntu.com"
		else
			PASTEB="sprunge.us"
		fi
		PASTEBIN_URL=$(cat "${TMP_LOG}b" | pastebinit -a $APPNAME -f bash -b $PASTEB)
		pastebin_retry
		pastebin_retry
	fi
fi
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (qua). $This_may_require_several_minutes''')"

[[ "$ERROR" ]] && or_to_your_favorite_support_forum=""
if [[ "$PASTEBIN_URL" != "http://$PASTEB/" ]] && [[ "$PASTEBIN_URL" != "https://$PASTEB/" ]] \
&& [[ "$PASTEBIN_URL" != "http://$PASTEB" ]] && [[ "$PASTEBIN_URL" != "https://$PASTEB" ]] \
&& [[ "$PASTEBIN_URL" ]] && [[ ! "$PASTEBIN_URL" =~ new-paste ]] && [[ ! "$PASTEBIN_URL" =~ host ]];then
	TEXTMID="$Please_write_url_on_paper
$PASTEBIN_URL

"
	[[ ! "$MAIN_MENU" =~ nf ]] && TEXTMID="$TEXTMID
$Indicate_it_in_case_still_pb
boot.repair@gmail.com $or_to_your_favorite_support_forum

" || TEXTMID="$TEXTMID
$Indicate_url_if_pb $On_forums_eg

"
elif [[ -f "${TMP_LOG}b" ]];then
	if  [[ "$GUI" ]];then
		FILENAME="$LOGREP/Boot-Info_$DATE.txt" #can't include the ~/
		mv "${TMP_LOG}b" "$FILENAME"
		update_translations
		TEXTMID="$FILENAME_has_been_created

"
		[[ ! "$MAIN_MENU" =~ nf ]] && TEXTMID="$TEXTMID
$Indicate_its_content_in_case_still_pb
boot.repair@gmail.com $or_to_your_favorite_support_forum

" || TEXTMID="$TEXTMID
$Indicate_content_if_pb $On_forums_eg

"
	else
		TEXTMID="$(cat ${TMP_LOG}b)"
	fi
else
	TEXTMID="(Could not create BootInfo. $PLEASECONTACT )"
fi

check_if_grub_in_windoz_bootsector
if [[ "$BSERROR" ]];then
	PARTBS="$BSERROR"; TOOL1=TestDisk; update_translations
	TEXTMID="$TEXTMID
$Please_fix_bs_of_PARTBS $Via_TOOL1
(https://help.ubuntu.com/community/BootSectorFix)


"
fi
}


pastebin_retry() {
if [[ "$PASTEBIN_URL" = "http://$PASTEB/" ]] || [[ "$PASTEBIN_URL" = "https://$PASTEB/" ]] \
|| [[ "$PASTEBIN_URL" = "http://$PASTEB" ]] || [[ "$PASTEBIN_URL" = "https://$PASTEB" ]] \
|| [[ ! "$PASTEBIN_URL" ]] || [[ "$PASTEBIN_URL" =~ new-paste ]] || [[ "$PASTEBIN_URL" =~ host ]];then
	[[ "$PASTEBIN_URL" =~ host ]] && echo "No internet for $PASTEB ($PASTEBIN_URL)." >> "${TMP_LOG}b"
	if [[ "$PASTEB" =~ ubuntu ]];then
		echo "$PASTEB ko ($PASTEBIN_URL)" >> "${TMP_LOG}b"
		PASTEB="paste.debian.net"
	elif [[ "$PASTEB" =~ debian ]];then
		echo "$PASTEB ko ($PASTEBIN_URL)" >> "${TMP_LOG}b"
		PASTEB="sprunge.us"
	else
		echo "$PASTEB ko ($PASTEBIN_URL)" >> "${TMP_LOG}b"
		PASTEB="paste.ubuntu.com"
	fi
	PASTEBIN_URL=$(cat "${TMP_LOG}b" | pastebinit -a $APPNAME -f bash -b $PASTEB)
fi
}

check_if_grub_in_windoz_bootsector() {
local GRUBINBS="" PARTBS="" line
	[[ "$GUI" ]] || [[ "$DEBBUG" ]] && echo "SET@_label0.set_text('''$LAB (bs-check). $This_may_require_several_minutes''')"
	while read line;do
		[[ "$(grep ': __' <<< "$line")" ]] && GRUBINBS="" && PARTBS="${line%:*}"
		[[ "$PARTBS" ]] && [[ "$(echo "$line" | grep "is installed in the boot sector" | grep -i grub )" ]] && GRUBINBS=ok
		[[ "$PARTBS" ]] && [[ "$GRUBINBS" ]] && [[ "$(echo "$line" | grep "Operating System" | grep -i windows )" ]] && ERROR="bs-check $line $PLEASECONTACT" && BSERROR="$PARTBS"
		[[ "$(grep '==========' <<< "$line")" ]] && break
	done < <(cat "${TMP_LOG}b")
}

unmount_all_and_success_br_and_bi() {
[[ "$DEBBUG" ]] && echo "[debug] unmount_all_and_success_br_and_bi"
TEXTMID=""
FILENAME=""
unhideboot_and_textprepare
#[[ "$PASTEBIN_ACTION" ]] && 
pastebinaction
rm "${TMP_LOG}t"
unmount_all_blkid_partitions_except_df
if [[ "$LIVESESSION" = live ]] && [[ "$BLKID" =~ zfs ]];then #https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bullseye%20Root%20on%20ZFS.html#rescuing-using-a-live-cd
	[[ "$DEBBUG" ]] && echo "[debug] mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {} $(mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {})" \
		|| echo "mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {} $(mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {}  2>/dev/null)"
	[[ "$DEBBUG" ]] && echo "[debug] zpool export -f -a $(zpool export -f -a)" || echo "zpool export -f -a $(zpool export -f -a 2>/dev/null)"
fi
stats_and_endpulse
finalzenity_and_exitapp
}


############WHEN CLICKING BOOTINFO BUTTON
justbootinfo_br_and_bi() {
[[ "$GUI" ]] && echo 'SET@_mainwindow.hide()'
[[ "$GUI" ]] && start_pulse
debug_echo_important_var_first
MAIN_MENU=Boot-Info
MBR_ACTION=nombraction ; UNHIDEBOOT_ACTION="" ; FSCK_ACTION="" ; WUBI_ACTION=""
GRUBPURGE_ACTION="" ; BLANKEXTRA_ACTION="" ; UNCOMMENT_GFXMODE="" ; KERNEL_PURGE=""
BOOTFLAG_ACTION="" ; WINBOOT_ACTION="" #; PASTEBIN_ACTION=create-bootinfo
RESTORE_BKP_ACTION=""; CREATE_BKP_ACTION=""; WINEFI_BKP_ACTION=""
[[ "$DEBBUG" ]] && echo "[debug]MAIN_MENU becomes : $MAIN_MENU"
LAB="$Create_a_BootInfo_report"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB. $This_may_require_several_minutes''')"
actions
}

debug_echo_important_var_first() {
if [[ ! "$IMPVARUN" ]];then
	debug_echo_important_variables
	IMPVARUN="$IMPVAR"
	LANGUAGE=C LC_ALL=C blockers_check
	[[ "$GRUBPACKAGE" =~ sign ]] && EFIGRUBFILE="/efi/****/shim****.efi (**** will be updated in the final message)" \
    || EFIGRUBFILE="/efi/****/grub****.efi (**** will be updated in the final message)"
	LANGUAGE=C LC_ALL=C textprepare
    #textprepare
    first_translations #back to user language
	BTEXTUN="$BTEXT"
	ATEXTUN="$ATEXT"
	TEXTUN="$TEXT"
	TEXTENDUN="$(echo "$TEXTEND" | sed 's|\\\\|\\|g' )"  # \\ are displayed \ in zenity , so need to reverse for the log
fi
}
