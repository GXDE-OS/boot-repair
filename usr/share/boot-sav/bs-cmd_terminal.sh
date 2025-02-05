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

####################### LIBRARIES THAT CAN BE CALLED BEFORE G2S ####################

################## ECHO VERSION ##################################
check_appname_version() {
check_package_manager
APPNAME_VERSION=$($PACKVERSION boot-sav )
G2S="glade2script$G2SPY_VERSION"; G2S_VERSION=$($PACKVERSION $G2S )  # dpkg-query -W -f='${Version}' paquet
[[ "$1" ]] && echo "$APPNAME version : $APPNAME_VERSION "
[[ "$DEBBUG" ]] && echo "G2S version : $G2S_VERSION"
}

#################### CHECK PACKAGE MANAGER ############################
check_package_manager() {
if [[ "$(type -p apt-get)" ]];then
	PACKMAN=apt-get
	PACKYES="-y"
	PACKINS=install
	PACKPURGE=purge
	PACKUPD="-y update"
	PACKVERSION='dpkg-query -W -f=${Version}'
elif [[ "$(type -p yum)" ]];then
	PACKMAN=yum
	PACKYES=-y
	PACKINS=install
	PACKPURGE=erase
	PACKUPD=makecache
	PACKVERSION='rpm -q --qf=%{version}'
elif [[ "$(type -p zypper)" ]];then
	PACKMAN='zypper --non-interactive'
	PACKYES=''
	PACKINS=in
	PACKPURGE=rm
	PACKUPD=ref
	PACKVERSION="zypper se -s --match-exact"
elif [[ "$(type -p pacman)" ]];then
	PACKMAN=pacman
	PACKYES='' #--noconfirm unrecognized
	PACKINS=-Sy
	PACKPURGE=-R
	PACKUPD="-Sy --noconfirm pacman; pacman-db-upgrade"
	PACKVERSION="pacman -Q"
else
    echo "Current distribution is not supported. Please use Boot-Repair-Disk."
	[[ "$GUI" ]] && zenity --width=400 --error --text"Current distribution is not supported. Please use Boot-Repair-Disk." 2>/dev/null
	choice="exit"; [[ "$GUI" ]] && echo 'EXIT@@' || exit 1
fi
}


######################### CHECK EFI PARTITIONS #########################
esp_check() {
#ESP with Windows bootmgr: http://ubuntuforums.org/showthread.php?t=2090605
part="${LISTOFPARTITIONS[$i]}" #eg /dev/mapper/isw_beaibbhjji_Volume0p1
f=""
while read line;do
	if [[ "$line" =~ /dev/ ]] || [[ "$line" =~ "pool/" ]];then
		[[ "$line" =~ "${DISK_PART[$i]}:" ]] && [[ "$part" =~ "${DISK_PART[$i]}" ]] && f=ok || f=""  # part =~ ${DISK_PART  in order to avoid issues when e.g. part=md127p1 but md127 is not in blkid so DISK_PART=fallback (eg. vda)
	fi #eg 11:162GB:162GB:210MB:fat32::boot, hidden;
	EFIPARTNUMERO="${line%%:*}" #eg 1
	#echo "[debug] WWW $line <$EFIPARTNUMERO>${part##*[a-z]}>" #
	if [[ "$EFIPARTNUMERO" = "${part##*[a-z]}" ]] && [[ "$f" ]];then
		if [[ "$(echo "$line" | grep ':fat' | grep boot | grep -v hidden | grep -v ':ext')" ]] \
		|| [[ "$(echo "$line" | grep ':fat' | grep esp | grep -v hidden | grep -v ':ext')" ]] \
		|| [[ "$(echo "$line" | grep ':fat' | grep ':EFI system partition:' | grep -v hidden | grep -v ':ext')" ]];then #exclude ext4 because hidden win esp: 3:548MB:1079MB:531MB:ext4:DUPFAT32:boot, hidden, esp;
			this_part_is_esp
		elif [[ "$(echo "$line" | grep ':fat' | grep boot | grep -v ':ext')" ]] \
		|| [[ "$(echo "$line" | grep ':fat' | grep esp | grep -v ':ext')" ]] \
		|| [[ "$(echo "$line" | grep ':fat' | grep ':EFI system partition:' | grep -v ':ext')" ]];then
			it_is_hidden_esp
		fi
	fi
done < <(echo "$PARTEDLM")
#if partedlm could not be used (is broken, or if part has fallback disk), then checks EFI in fdisk
if [[ "${EFI_TYPE[$i]}" = isnotESP ]] && ( [[ ! "$(echo "$PARTEDLM" | grep / )" ]] || [[ ! "$part" =~ "${DISK_PART[$i]}" ]] );then 
	while read line;do 
		if [[ "$line" =~ "$part " ]];then
			#EFI working without GPT: http://forum.ubuntu-fr.org/viewtopic.php?pid=9962371#p9962371
			if [[ "$(echo "$line" | grep "$part " | grep '*' | grep -i fat | grep -v ext | grep -vi ntfs | grep -v hidden)" ]] \
			|| [[ "$(echo "$line" | grep "$part " | grep EFI | grep -v ext | grep -v hidden)" ]] \
			&& [[ "$(lsblk $part -n -o FSTYPE )" =~ fat ]];then #to avoid false positive not vfat (eg OS on ext4)
				#don't add grep fat here. https://launchpadlibrarian.net/299779679/Boot-Repair%20bug.txt
				#hidden partitions are shown as normal in fdisk, and some hidden win esp are shown as normal EFI
				this_part_is_esp  #if partedlm is broken, then assumes it's ESP and hope it's not hidden
			fi
		fi
	done < <(echo "$FDISKL")
fi
}

this_part_is_esp() {
if [[ "${EFI_TYPE[$i]}" != is---ESP ]];then
	[[ "${GPT_DISK[${DISKNB_PART[$i]}]}" = is-GPT ]] && (( NB_EFIPARTONGPT += 1 ))
	EFI_DISK[${DISKNB_PART[$i]}]=has---ESP
	EFI_TYPE[$i]=is---ESP
	(( NB_BISEFIPART += 1 ))
fi
}

it_is_hidden_esp() {
if [[ "${EFI_TYPE[$i]}" != is---ESP ]];then
	[[ "${EFI_DISK[${DISKNB_PART[$i]}]}" != has---ESP ]] && EFI_DISK[${DISKNB_PART[$i]}]=hashidESP
	EFI_TYPE[$i]=hidenESP
fi
}

esp_detect() {
. /usr/share/boot-sav/bs-common.sh
blkid_fdisk_and_parted_update
check_blkid_partitions
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	esp_check
	if [[ "${EFI_TYPE[$i]}" = is---ESP ]];then
		echo "${LISTOFPARTITIONS[$i]#*/dev/} is ESP"
	elif [[ "${EFI_TYPE[$i]}" = hidenESP ]];then
		echo "${LISTOFPARTITIONS[$i]#*/dev/} is hidden ESP"
	else
		echo "${LISTOFPARTITIONS[$i]#*/dev/} is not ESP"
	fi
done
}

########################## CHECK IF LIVE-SESSION #######################
check_if_live_session() {
CURRENTSESSIONPARTITION="$(findmnt -n -o SOURCE / | grep -v snap)" #eg rpool/ROOT/ubuntu_64fs0l or /dev/sda3
#CURRENTSESSIONPARTITION="${CURRENTSESSIONPARTITION#*dev/}"  #eg rpool/ROOT/ubuntu_64fs0l or sda3
[[ ! "$CURRENTSESSIONPARTITION" ]] && echo "Error: empty findmnt -n -o SOURCE / , $PLEASECONTACT"
hash lsb_release && DISTRIB_DESCRIPTION="$(lsb_release -ds)" || DISTRIB_DESCRIPTION=Unknown-name
if [ "$(grep -E '(boot=casper)|(boot=live)' /proc/cmdline)" ] || [[ "$(findmnt -n -o FSTYPE / | grep -E 'squashfs|aufs|overlay'  | grep -v snap)" ]];then #aufs bug#1281815, overlay since 19.10
	LIVESESSION=live
else
	LIVESESSION=installed
	CURRENTSESSIONNAME="$The_system_now_in_use - $DISTRIB_DESCRIPTION"
fi
}


############################# CHECK EFI DMSG AND SECUREBOOT #####################
check_efi_dmesg_and_secureboot() {
#http://forum.ubuntu-fr.org/viewtopic.php?id=742721
local ue="$(dmesg | grep EFI | grep -v Variables )" SPECIALSB=""
SECUREBOOT=disabled
EFIDMESG=""
( [[ -f /sys/class/dmi/id/bios_vendor ]] || [[ -f /sys/class/dmi/id/bios_version ]] ) \
&& EFIDMESG="BIOS/UEFI firmware: $(head -n 1 /sys/class/dmi/id/bios_version 2>/dev/null)$([[ -f /sys/class/dmi/id/bios_release ]] && echo "($(head -n 1 /sys/class/dmi/id/bios_release))") from $(head -n 1 /sys/class/dmi/id/bios_vendor 2>/dev/null)
"
if [[ -d /sys/firmware/efi ]];then
	modprobe efivars #cf geole / ubuntu-fr
	EFIDMESG="${EFIDMESG}The firmware is EFI-compatible, and is set in EFI-mode for this $LIVESESSION-session.
"
	[[ ! "$ue" ]] && EFIDMESG="${EFIDMESG}No EFI in dmseg.
"
	#SecureBoot http://launchpadlibrarian.net/119223180/ubiquity_2.12.8_2.12.9.diff.gz
	#https://fr.opensuse.org/openSUSE:UEFI#Comment_savoir_si_le_Secure_Boot_est_activ.C3.A9
	local efi_vars sb_var
	for efi_vars in /sys/firmware/efi/vars /sys/firmware/efi/efivars;do
		  sb_var="$efi_vars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c/data"
		sb_var2="$efi_vars/SecureBoot-a8be4df61-93ca-11d2-aa0d-00e098032b8c/data"
		if [[ -e "$sb_var" ]];then
			#[[ "$(printf %x \'"$(cat "$sb_var")")" = 1 ]] && SECUREBOOT=enabled || SECUREBOOT=disabled
			#https://stackoverflow.com/questions/46163678/get-rid-of-warning-command-substitution-ignored-null-byte-in-input
			[[ "$(printf %x \'"$(tr -d '\0' < "$sb_var")")" = 1 ]] && SECUREBOOT=enabled
		elif [[ -e "$sb_var2" ]];then
			[[ "$(printf %x \'"$(tr -d '\0' < "$sb_var2")")" = 1 ]] && SECUREBOOT=enabled
		elif [[ -d "$efi_vars" ]];then
			for tst in $(ls $efi_vars 2>/dev/null);do
				if [[ "$tst" =~ "SecureBoot" ]];then
					if [ -e "$efi_vars/$tst/data" ];then
						[ "$(printf %x \'"$(tr -d '\0' < "$efi_vars/$tst/data")")" = 1 ] && SECUREBOOT=enabled && SPECIALSB=yes
						EFIDMESG="${EFIDMESG}Found $efi_vars/$tst/data. $PLEASECONTACT
	"
					fi
				fi
			done
		fi
		if [[ "$SECUREBOOT" = disabled ]] && [[ "$(grep signed /proc/cmdline)" ]] && [[ -d "$efi_vars" ]];then
			SPECIALSB=yes
			a=""; for b in $(ls $efi_vars 2>/dev/null);do a="$b,$a";done
			EFIDMESG="${EFIDMESG}Special SecureBoot - $PLEASECONTACT
	grep signed /proc/cmdline: $(grep signed /proc/cmdline)
	ls $efi_vars : $a
	"
		fi
	done
	local FUNCTION=SB-detect PACKAGELIST=mokutil FILETOTEST=mokutil
	[[ "$SPECIALSB" ]] && [[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	if [[ "$(type -p mokutil)" ]];then
		if [[ "$SECUREBOOT" = disabled ]];then
			if [[ "$(mokutil --sb-state 2>&1)" =~ 'Secure Boot is enabled' ]] || [[ "$(mokutil --sb-state 2>&1)" =~ 'SecureBoot enabled' ]];then
				SECUREBOOT="enabled according to mokutil - $PLEASECONTACT"
			elif [[ "$(mokutil --sb-state 2>&1)" =~ 'Failed to read' ]] || [[ "$(mokutil --sb-state 2>&1)" =~ 'system doesn' ]] || [[ "$(mokutil --sb-state 2>&1)" =~ 'strange data' ]];then
				SECUREBOOT="disabled - $(mokutil --sb-state 2>&1)"
			elif [[ "$(mokutil --sb-state 2>&1)" =~ 'Secure Boot is disabled' ]] || [[ "$(mokutil --sb-state 2>&1)" =~ 'SecureBoot disabled' ]];then
				SECUREBOOT="disabled (confirmed by mokutil)"
			else
				SECUREBOOT="disabled - $(mokutil --sb-state 2>&1) - $PLEASECONTACT"
			fi
		elif [[ ! "$(mokutil --sb-state 2>&1)" =~ 'Secure Boot is enabled' ]] && [[ ! "$(mokutil --sb-state 2>&1)" =~ 'SecureBoot enabled' ]] && [[ "$SECUREBOOT" = enabled ]];then
			SECUREBOOT="enabled but mokutil says: $(mokutil --sb-state 2>&1) - $PLEASECONTACT"
		fi
	fi
	EFIDMESG="${EFIDMESG}SecureBoot $SECUREBOOT.
"
	local FUNCTION=UEFI PACKAGELIST=efibootmgr FILETOTEST=efibootmgr
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	if [[ "$(type -p efibootmgr)" ]];then
		EFIDMESG="${EFIDMESG}$(LANGUAGE=C LC_ALL=C efibootmgr -v | grep -v dp: | grep -v data:)" # | sed 's|\\|\\\\|g'
	else
		EFIDMESG="${EFIDMESG}Please install package efibootmgr and retry."
	fi
else
	#[[ "$LIVESESSION" = installed ]] && SECUREBOOT=disabled
	if [[ "$WINEFIFILEPRESENCE" ]];then
		EFIDMESG="${EFIDMESG}The firmware is EFI-compatible, but this $LIVESESSION-session is in Legacy/BIOS/CSM mode (not in EFI mode).
"
	elif [[ "$ue" ]];then
		EFIDMESG="${EFIDMESG}The firmware seems EFI-compatible, but this $LIVESESSION-session is in Legacy/BIOS/CSM mode (not in EFI mode).
"
	elif [[ "$(lsb_release -is)" = Debian ]];then
		EFIDMESG="${EFIDMESG}This $LIVESESSION-session is in Legacy/BIOS/CSM mode (not in EFI mode). See https://wiki.debian.org/UEFI
"
	else
		EFIDMESG="${EFIDMESG}This $LIVESESSION-session is in Legacy/BIOS/CSM mode (not in EFI mode).
"
	fi
fi
}

paragraph_syst_info(){
ECHO_ARCH_SECTION=""
[[ ! "$1" ]] && ECHO_ARCH_SECTION="$(title_gen "Host/Hardware" )
"
ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
CPU architecture: $ARCHIPC-bit"
[[ "$(type -p lshw)" ]] && ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
Video: $(echo $(LANG=C sudo lshw -C display | grep product | sed 's/product://g')) from $(echo $(LANG=C sudo lshw -C display | grep vendor | sed 's/vendor://g'))"
[[ "$(uname -m)" =~ 64 ]] && LIVE_ARCH=64 || LIVE_ARCH=32
if [[ "$LIVESESSION" = live ]];then
	ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
Live-session OS is $(lsb_release -is) $LIVE_ARCH-bit ($DISTRIB_DESCRIPTION, $(lsb_release -cs), $(uname -m))"
	if [[ "$DEBBUG" ]];then
		if [ "$(grep 'boot=casper' /proc/cmdline)" ];then ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
This session has been detected as 'live' because /proc/cmdline contains boot=casper.";fi
		if [ "$(grep 'boot=live' /proc/cmdline)" ];then ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
This session has been detected as 'live' because /proc/cmdline contains boot=live.";fi
		[[ "$DR" =~ loop ]] && ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
This session has been detected as 'live' because df / contains loop."
		[[ "$(df -Th / | grep aufs)" ]] && ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
This session has been detected as 'live' because df -T / contains aufs."
		[[ "$(df -Th / | grep overlay)" ]] && ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
This session has been detected as 'live' because df -T / contains overlay."
	fi
else
	ECHO_ARCH_SECTION="$ECHO_ARCH_SECTION
BOOT_IMAGE of the installed session in use:
$(cat /proc/cmdline | sed 's/BOOT_IMAGE=//g' )
df -Th / : $(df -Th / | grep / )" #rpool/ROOT/ubuntu_64fs0l
	#deletes only the 'BOOT_IMAGE' string, nothing before nothing after.
fi
}

################################### TAIL COMMON LOGS #####################
# https://bugs.launchpad.net/boot-info/+bug/1719537
tail_common_logs() {
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	for j in syslog kern.log Xorg.0.log dpkg.log journal;do
		if [[ -f "${BLKIDMNT_POINT[$i]}/var/log/$j" ]];then
			title_gen "tail -n $1 ${LISTOFPARTITIONS[$i]#*/dev/}/var/log/$j"
			tail -n $1 "${BLKIDMNT_POINT[$i]}/var/log/$j"
		fi
	done
done
}


bootinfo-cli() {
. /usr/share/boot-sav/gui-init.sh
translat_init
lib_init
check_os_and_mount_blkid_partitions_gui
check_which_mbr_can_be_restored
mainwindow_filling
warnings_and_show_mainwindow
UPLOAD="$1"
justbootinfo_br_and_bi
}


########################### CHECKS THE OS NAMES AND PARTITIONS AND TYPES ##################################
### TOTAL_QUANTITY_OF_OS must be initialized before first use
check_os_detected_by_os-prober() {
local ligne temp part disk tempp ADDOS m i
OSPROBER="$(os-prober)"
if [[ "$LIVESESSION" = installed ]];then
    #Add CurrentSession at the beginning of OSPROBER (so that GRUB reinstall of CurrentSession is selected by default)
    OSPROBER="${CURRENTSESSIONPARTITION}:${CURRENTSESSIONNAME}:CurrentSession:linux
$OSPROBER"
fi
if [[ "$OSPROBER" ]];then
	while read ligne; do
		if [[ "$ligne" =~ / ]] && [[ "$ligne" =~ ':' ]] && [[ ! "$ligne" =~ "@/efi/" ]] && [[ ! "$ligne" =~ "@/EFI/" ]] \
        && [[ ! "$(echo "$ligne" | grep indows | grep boot )" ]] \
        && [[ ! "$ligne" =~ '(boot)' ]];then #exclude 'Windows 10 (boot)' /dev/sda2@/efi/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi , or /dev/nvme0n1p1@/efi/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi
			part=${ligne%%:*}
            ADDOS=yes
            for ((j=1;j<=TOTAL_QUANTITY_OF_OS;j++));do #To avoid duplicates since os-prober is run twice (bef and aft mount)
                [[ "${OS__PARTITION[$j]}" = "$part" ]] && ADDOS=""
            done
            if [[ "$ADDOS" ]];then
                (( TOTAL_QUANTITY_OF_OS += 1 ))
                OS__PARTITION[$TOTAL_QUANTITY_OF_OS]=$part			#e.g. sda1 or sdc10 or rpool/ROOT/ubuntu_64fs0l
                determine_disk_from_part
                OS__DISK[$TOTAL_QUANTITY_OF_OS]=$disk				#e.g. "sda" or "sdc"
                tempp=${ligne#*:}
                OS__COMPLETE_NAME[$TOTAL_QUANTITY_OF_OS]=$tempp		#e.g. "Ubuntu 10.04.1 LTS (10.04):Ubuntu:linux" or "Windows 7:Windows:chain"
                temp=${tempp%%:*}									#e.g. "Ubuntu 10.04.1 LTS (10.04)"
                if [[ "$temp" ]];then
                    if [[ "$temp" =~ Ubuntu ]];then
                        OS__NAME[$TOTAL_QUANTITY_OF_OS]=${temp% (*}		#e.g. "Ubuntu 10.04.1 LTS"
                    else
                        OS__NAME[$TOTAL_QUANTITY_OF_OS]=${temp}		#e.g. "Windows 7"
                    fi
                else
                    OS__NAME[$TOTAL_QUANTITY_OF_OS]=${tempp#*:}		#e.g. "Arch:linux"
                fi
            fi
		fi
	done < <(echo "$OSPROBER")
fi
}

########################################### REMOVE STAGE1 FROM UNWANTED PARTITIONS #############################################
remove_stage1_from_other_os_partitions() {
[[ "$DEBBUG" ]] && echo "[debug]Remove_mislocated_stage1"
local i temp j
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -d "${BLKIDMNT_POINT[$i]}/Boot" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/BOOT" ]] && [[ -d "${BLKIDMNT_POINT[$i]}/boot" ]];then
		temp=0
		for j in $(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null); do #For fat (case insensitive)
			[[ "$j" = Boot ]] || [[ "$j" = BOOT ]] || [[ "$j" = boot ]] && (( temp += 1 ))
		done
		if [[ "$temp" != 1 ]];then
			echo "
$DASH Several ($temp) /boot folders exist in ${LISTOFPARTITIONS[$i]#*/dev/}/ and may disturb os-prober, boot renamed into oldbooot."
			mv "${BLKIDMNT_POINT[$i]}/boot" "${BLKIDMNT_POINT[$i]}/oldbooot"
		fi
	fi
	if [[ -f "${BLKIDMNT_POINT[$i]}/boot.ini" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/ntldr" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/bootmgr" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/Windows/System32/winload.exe" ]] \
	&& [[ ! -d "${BLKIDMNT_POINT[$i]}/selinux" ]];then
		if [[ -d "${BLKIDMNT_POINT[$i]}/boot/grub" ]];then
			echo "
GRUB detected inside Windows partition. ${LISTOFPARTITIONS[$i]#*/dev/}/boot/grub renamed into boot/grub_old"
			mv "${BLKIDMNT_POINT[$i]}/boot/grub" "${BLKIDMNT_POINT[$i]}/boot/grub_old"
		fi
		if [[ -d "${BLKIDMNT_POINT[$i]}/grub" ]];then
			echo "
GRUB detected inside Windows partition. ${LISTOFPARTITIONS[$i]#*/dev/}/grub renamed into grub_old"
			mv "${BLKIDMNT_POINT[$i]}/grub" "${BLKIDMNT_POINT[$i]}/grub_old"
		fi
	#elif [[ -d "${BLKIDMNT_POINT[$i]}/selinux" ]] && [[ -d "${BLKIDMNT_POINT[$i]}/grub" ]];then
	#	echo "/grub detected inside a Linux partition. Rename ${BLKIDMNT_POINT[$i]}/grub into grub_old"
	#	mv "${BLKIDMNT_POINT[$i]}/grub" "${BLKIDMNT_POINT[$i]}/grub_old"
	fi
done
}


## generates the ${name}${file} title bar to always be 80 characters in length. ##
title_gen() {
  local name_file name_file_length equal_signs_line_length equal_signs_line;
  name_file="${1}${2}";
  name_file_length=${#name_file};
  equal_signs_line_length=$(((80-${name_file_length})/2-1));
  # Build "===" string.
  printf -v equal_signs_line "%${equal_signs_line_length}s";
  printf -v equal_signs_line "%s" "${equal_signs_line// /=}";
  if [ "$((${name_file_length}%2))" -eq 1 ]; then
     # If ${name_file_length} is odd, add an extra "=" at the end.
     printf "\n%s %s %s=\n\n" "${equal_signs_line}" "${name_file}" "${equal_signs_line}"
  else
     printf "\n%s %s %s\n\n" "${equal_signs_line}" "${name_file}" "${equal_signs_line}"
  fi
}
