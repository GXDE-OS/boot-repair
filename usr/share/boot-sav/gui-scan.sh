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


##################### Main function for GUI preparation ################
check_os_and_mount_blkid_partitions_gui() {
delete_tmp_folder_to_be_cleared #[[ ! "$1" ]] && 
blkid_fdisk_and_parted_update
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB ($([[ -d /sys/firmware/efi ]] && echo "EFI-session" || echo "BIOS-session" )). $This_may_require_several_minutes''')"
#[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (mount). $This_may_require_several_minutes''')"
#echo_blkid
check_blkid_partitions					#In order to save MBR of all disks detected by blkid
#determine_bios_boot						#to avoid mounting BIOS Boot
TOTAL_QUANTITY_OF_OS=0; check_os_detected_by_os-prober		#run os-prober a first time before mounting partitions
mount_all_blkid_partitions_except_df    #need to be between the 2 check_os_detected_by_os-prober (need to update os-prober if btrfs)
determine_part_uuid						#After check_blkid_partitions
check_location_first_partitions			#Output: $BYTES_BEFORE_PART[$disk]
check_os_detected_by_os-prober			#run os-prober a 2nd time after mounting 
mount_all_blkid_partitions_except_df		#To update OS_Mount_points
determine_part_with_os $1				#after check_os_detected_by_os-prober, to get OSNAME (before check_recovery_or_hidden)
check_recovery_or_hidden				#After mount_all_blkid_partitions_except_df & before logs
put_the_current_mbr_in_tmp
#[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB. $This_may_require_several_minutes''')"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB ($([[ -d /sys/firmware/efi ]] && echo "EFI-session" || echo "BIOS-session" )). $This_may_require_several_minutes''')"
check_disk_types					#before part_types (for usb and gpt and esp_check)
check_part_types $1				#After mount_all_blkid_partitions_except_df & determine_part_uuid & determine_part_with_os
check_efi_dmesg_and_secureboot 				#Ideally after check_efi_parts
#[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Scanning_systems. $Please_wait''')"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB ($([[ -d /sys/firmware/efi ]] && echo "SecureBoot ${SECUREBOOT%%ed*}ed" || echo "BIOS-session" )). $Please_wait''')"
paragraph_part_info
}

delete_tmp_folder_to_be_cleared() {
update_translations
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (os-prober). $This_may_require_several_minutes''')"
[[ "$DEBBUG" ]] && echo "[debug]Delete the content of TMP_FOLDER_TO_BE_CLEARED"
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/* || echo "Error: TMP_FOLDER_TBC empty. $PLEASECONTACT"
}

paragraph_part_info() {
local i d a b x y
ECHO_PARTS_INFO="Disks info: ____________________________________________________________________
"
for ((d=1;d<=NBOFDISKS;d++)); do
	ECHO_PARTS_INFO="$ECHO_PARTS_INFO
${LISTOFDISKS[$d]#*/dev/}	: ${GPT_DISK[$d]},	${BIOS_BOOT_DISK[$d]},	${EFI_DISK[$d]}, \
	${USBDISK[$d]},	${MMCDISK[$d]}, ${DISK_HASOS[$d]},	${REALWINONDISC[$d]},	${SECTORS_BEFORE_PART[$d]} sectors * ${BYTES_PER_SECTOR[$d]} bytes"
done
ECHO_PARTS_INFO="$ECHO_PARTS_INFO

Partitions info (1/3): _________________________________________________________
"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
    ECHO_PARTS_INFO="$ECHO_PARTS_INFO
${LISTOFPARTITIONS[$i]#*/dev/}	: ${PART_WITH_OS[$i]},	${ARCH_OF_PART[$i]}, ${APTTYP[$i]},	${DOCGRUB[$i]},	${GRUBVER[$i]},	${GRUBTYPE_OF_PART[$i]},	${GRUB_ENV[$i]},	${UPDATEGRUB_OF_PART[$i]},	${FARBIOS[$i]}"
done
ECHO_PARTS_INFO="$ECHO_PARTS_INFO

Partitions info (2/3): _________________________________________________________
"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	ECHO_PARTS_INFO="$ECHO_PARTS_INFO
${LISTOFPARTITIONS[$i]#*/dev/}	: ${EFI_TYPE[$i]},	${FSTAB_HASGOODEFI_OFPART[$i]},	${WINNT[$i]},	${WINL[$i]},	${RECOV[$i]},	${WINMGR[$i]},	${WINBOOTPART[$i]}, $(lsblk ${LISTOFPARTITIONS[$i]} -n -o FSTYPE)"
done
ECHO_PARTS_INFO="$ECHO_PARTS_INFO

Partitions info (3/3): _________________________________________________________
"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	ECHO_PARTS_INFO="$ECHO_PARTS_INFO
${LISTOFPARTITIONS[$i]#*/dev/}	: ${PART_WITH_SEPARATEBOOT[$i]},	${BOOT_AND_KERNEL_IN[$i]},	${FSTAB_HAS_GOOD_BOOT[$i]},	${SEPARATE_USR_PART[$i]},	${USRPRESENCE_OF_PART[$i]},	${USR_IN_FSTAB_OF_PART[$i]},	${CUSTOMIZER[$i]},	${DISK_PART[$i]#*/dev/}"
done
if [[ "$DEBBUG" ]];then
    title_gen "parted -lm"
    while read line; do
        [[ "$line" ]] && echo "$line"
    done < <(echo "$PARTEDLM" )
    title_gen "lsblk -o KNAME,TYPE,FSTYPE,SIZE,LABEL (filtered)"
    #UUID et MODEL are buggy: LANGUAGE=C lsblk -o KNAME,TYPE,FSTYPE,SIZE,LABEL,MODEL,UUID
    while read line; do
        [[ "$line" ]] && [[ ! "$line" =~ squashfs ]] && [[ ! "$line" =~ "sr[0-9]" ]] && echo "$line"
    done < <(LANGUAGE=C LC_ALL=C lsblk -o KNAME,TYPE,FSTYPE,SIZE,LABEL )
    title_gen "lsblk -o KNAME,ROTA,RO,RM,STATE,MOUNTPOINT (filtered)"
    while read line; do
        [[ "$line" ]] && [[ ! "$line" =~ loop ]] && [[ ! "$line" =~ "sr[0-9]" ]] && echo "$line"
    done < <(LANGUAGE=C LC_ALL=C lsblk -o KNAME,ROTA,RO,RM,STATE,MOUNTPOINT )
    title_gen "mount (filtered)"
    while read line; do
        [[ "$line" =~ "dev/" ]] || [[ "$line" =~ "pool/" ]] && [[ ! "$line" =~ hugetlbfs ]] && [[ ! "$line" =~ tmpfs ]] && [[ ! "$line" =~ mqueue ]] && [[ ! "$line" =~ devpts ]] && echo "$line"
    done < <(mount )
    #debug
    title_gen "ls (filtered)"
    a=/sys/block/;for x in $(ls $a);do if [[ ! "$x" =~ ram ]] && [[ ! "$x" =~ oop ]] && [[ ! "$x" =~ sr ]];then b="";for y in $(ls $a$x);do b="$b $y";done;echo "$a$x: $b";fi;done
    a="";for x in $(ls /dev);do if [[ ! "$x" =~ ram ]] && [[ ! "$x" =~ oop ]] && [[ ! "$x" =~ tty ]] && [[ ! "$x" =~ vcs ]] && [[ ! "$x" =~ i2c ]] \
    && [[ ! "$x" =~ drm_ ]] && [[ ! "$x" =~ network_ ]] && [[ ! "$x" =~ vbox ]];then a="$a $x";fi;done;echo "/dev: $a"
    if [[ "$(ls /dev | grep -ix md )" ]];then
        a="";for x in $(ls /dev/md);do a="$a $x";done;echo "ls /dev/md: $a"
    fi
    #often /dev/mapper contains only 1 'control' file.
    for y in /dev/mapper /dev/cciss; do
        if [[ -d $y ]];then
            a="";for x in $(ls $y);do
                    [[ "$x" != "control" ]] && a="$a $x"
            done
            [[ "$a" ]] && echo "ls $y: $a"
        fi
    done
fi
}

###################### DETERMINE PARTNB FROM A PARTNAME ################
determine_partnb() {
local partnbi
#Ex of input: "sda1"
for ((partnbi=1;partnbi<=NBOFPARTITIONS;partnbi++)); do
	[[ "$1" = "${LISTOFPARTITIONS[$partnbi]}" ]] && PARTNB="$partnbi"
done
}

############################ CHECK DISK TYPES ##########################
check_disk_types() {
local d e f TMPDISK
GPT_DISK_WITHOUT_BIOS_BOOT=""
WIN_ON_GPT=""
WIN_ON_DOS=""
MSDOSPRESENT=""
NB_EFIPARTONGPT=0; NB_BISEFIPART=0 #cant move to check_part_types
for ((d=1;d<=NBOFDISKS;d++)); do
    BIOS_BOOT_DISK[$d]=no-BIOSboot
	TMPDISK="${LISTOFDISKS[$d]}"
	if [[ "$(LANGUAGE=C LC_ALL=C fdisk -l "$TMPDISK" 2>/dev/null | grep -i GPT | grep -i Disklabel )" ]] \
	&& [[ ! "$(echo "$PARTEDLM" | grep -i msdos | grep "${TMPDISK}:" )" ]] \
	&& [[ ! "$(echo "$PARTEDLM" | grep -i loop | grep "${TMPDISK}:" )" ]] \
	|| [[ "$(echo "$PARTEDLM" | grep -i gpt | grep "${TMPDISK}:" )" ]];then
		GPT_DISK[$d]=is-GPT
		f=""
		for e in $PARTEDLM;do #no "" !
			if [[ "$e" =~ / ]];then
				[[ "$e" =~ "${TMPDISK}:" ]] && f=ok || f=""
			fi
			[[ "$f" ]] && [[ "$e" =~ bios_grub ]] && BIOS_BOOT_DISK[$d]=hasBIOSboot
		done
        [[ "$(LANGUAGE=C LC_ALL=C fdisk -l "$TMPDISK" 2>/dev/null | grep 'BIOS boot' )" ]] && BIOS_BOOT_DISK[$d]=hasBIOSboot  #security in case parted KO
		[[ "${BIOS_BOOT_DISK[$d]}" != hasBIOSboot ]] && GPT_DISK_WITHOUT_BIOS_BOOT=yes
	else
		GPT_DISK[$d]=notGPT #table may be loop
		MSDOSPRESENT=yes #used by fillin_bootflag_combobox
	fi
	[[ "$(ls -l /dev/disk/by-id 2>/dev/null | grep " usb-" | grep "${LISTOFDISKS[$d]#*/dev/}")" ]] \
	&& USBDISK[$d]=usb-disk || USBDISK[$d]=not-usb

	[[ "$(grep dev/mmc <<< $TMPDISK )" ]] && MMCDISK[$d]=mmc-disk || MMCDISK[$d]=not-mmc

	BOOTFLAG_NEEDED[$d]=""
	if [[ "${GPT_DISK[$d]}" != is-GPT ]];then #some BIOS need a flag on primary partition
		p="$(LANGUAGE=C LC_ALL=C fdisk -l $TMPDISK 2>/dev/null | grep / | grep '*' )"
		if [[ ! "$(echo $p  | grep "${TMPDISK}1 " )" ]] && [[ ! "$(echo $p | grep "${TMPDISK}2 " )" ]] \
		&& [[ ! "$(echo $p | grep "${TMPDISK}3 " )" ]] && [[ ! "$(echo $p | grep "${TMPDISK}4 " )" ]] \
		|| [[ "$(echo $p | grep Empty )" ]];then
			BOOTFLAG_NEEDED[$d]=setflag
		fi
	fi
	
	EFI_DISK[$d]=has-noESP #init
	REALWINONDISC[$d]=no-wind
	for ((i=1;i<=NBOFPARTITIONS;i++)); do
		if [[ "${REALWIN[$i]}" ]] && [[ "${DISKNB_PART[$i]}" = "$d" ]];then
			REALWINONDISC[$d]=has-win
			[[ "${GPT_DISK[$d]}" = is-GPT ]] && WIN_ON_GPT=y || WIN_ON_DOS=y
		fi
	done
done
}


############################ CHECK PART TYPES ##########################
check_part_types() {
local i temp temp2 gg gi gm a b c d e uuidp ENVFILE ENDB line word
QTY_OF_PART_WITH_GRUB=0
QTY_OF_PART_WITH_APTGET=0
QTY_OF_32BITS_PART=0
QTY_OF_64BITS_PART=0
QTY_BOOTPART=0
QTY_WINBOOTTOREPAIR=0
SEP_BOOT_PARTS_PRESENCE=""
SEP_USR_PARTS_PRESENCE=""
EFIFILPRESENT=""
WINEFIFILEPRESENCE=""
BKPFILEPRESENCE=""
WINBKPFILEPRESENCE=""
for ((i=1;i<=NBOFPARTITIONS;i++)); do

	tempd=""
	DOCGRUB[$i]=""
	for z in "${BLKIDMNT_POINT[$i]}"/{,usr/}share/doc/;do
		if [[ -d "$z" ]];then
			check_grubdoc_1
			if [[ -d "$z/packages" ]];then #Suse
				z="$z/packages"
				check_grubdoc_1
			fi
		fi
	done
	for z in "${BLKIDMNT_POINT[$i]}"/{,usr/}share/doc/;do
		if [[ -d "$z" ]];then
			check_grubdoc_2
			if [[ -d "$z/packages" ]];then #Suse
				z="$z/packages"
				check_grubdoc_2
			fi
		fi
	done
	[[ -f "${BLKIDMNT_POINT[$i]}/sbin/grub-crypt" ]] && [[ ! "$(grep efi <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="grub-efi ${DOCGRUB[$i]}" #TODO which distro ?
	for z in "${BLKIDMNT_POINT[$i]}"/{,usr/}share/doc/;do
		if [[ -d "$z" ]];then
			lsz="$(ls $z 2>/dev/null | grep grub)"
			[[ "$lsz" ]] && [[ ! "${DOCGRUB[$i]}" ]] && DOCGRUB[$i]="grub1 ${DOCGRUB[$i]}"
			if [[ "$(grep signed <<< "$lsz" )" ]];then
				[[ ! "$(grep sign <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="signed ${DOCGRUB[$i]}"
			else
				for zz in $lsz;do
					[[ -d "$z$zz" ]] && [[ "$(ls "$z$zz" 2>/dev/null | grep signed)" ]] && [[ ! "$(grep sign <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="${zz}-signed ${DOCGRUB[$i]}"
				done
			fi
		fi
	done
	[[ ! "${DOCGRUB[$i]}" ]] && DOCGRUB[$i]=no-docgrub

	GRUBTYPE_OF_PART[$i]=nogrubinstall
	GRUBVER[$i]=nogrub
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do #not sure "type" is available in all distros
		for gi in grub-install.unsupported grub-install grub2-install;do
			if ( [[ ! -f "${BLKIDMNT_POINT[$i]}${gg}grub" ]] || [[ "${GRUBVER[$i]}" != grub2 ]] ) && [[ -f "${BLKIDMNT_POINT[$i]}$gg$gi" ]];then #prefers grub2
				GRUBTYPE_OF_PART[$i]=$gi
				GRUBTYPE_OF_PARTZ[$i]=$gg$gi
				[[ -f "${BLKIDMNT_POINT[$i]}${gg}grub" ]] && GRUBVER[$i]=grub1 || GRUBVER[$i]=grub2
			fi
		done
	done
	if [[ "${GRUBVER[$i]}" = grub2 ]] && [[ -d "${BLKIDMNT_POINT[$i]}/etc/default" ]] \
	&& [[ ! -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]] \
	|| [[ "${GRUBTYPE_OF_PART[$i]}" =~ unsup ]];then
		GRUBVER[$i]=grub1 #care of sep /usr
		[[ ! -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]] && echo "No ${LISTOFPARTITIONS[$i]}/etc/default/grub"
	fi
	
	UPDATEGRUB_OF_PART[$i]=noupdategrub
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		for gm in grub-mkconfig grub2-mkconfig;do
			[[ -f "${BLKIDMNT_POINT[$i]}$gg$gm" ]] && UPDATEGRUB_OF_PART[$i]="$gm -o /boot/grub" #then complete with 2/grub.cfg or /grub.cfg
		done
	done
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		[[ -f "${BLKIDMNT_POINT[$i]}${gg}update-grub" ]] && UPDATEGRUB_OF_PART[$i]=update-grub #Priority against grub-mkconfig
	done

	GRUBSETUP_OF_PART[$i]=nogrubsetup
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		[[ -f "${BLKIDMNT_POINT[$i]}${gg}grub-setup" ]] && GRUBSETUP_OF_PART[$i]=grub-setup
	done
	
	GRUBOK_OF_PART[$i]=""
	if [[ "${GRUBVER[$i]}" = grub1 ]] || [[ "${UPDATEGRUB_OF_PART[$i]}" != noupdategrub ]] \
	&& [[ "${GRUBTYPE_OF_PART[$i]}" != nogrubinstall ]];then
		GRUBOK_OF_PART[$i]=ok
		(( QTY_OF_PART_WITH_GRUB += 1 ))
		LIST_OF_PART_WITH_GRUB[$QTY_OF_PART_WITH_GRUB]="$i"
	fi
	
	APTTYP[$i]=""
	if [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/yum" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/pacman" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/yum" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/pacman" ]];then
		(( QTY_OF_PART_WITH_APTGET += 1 ))
		LIST_OF_PART_WITH_APTGET[$QTY_OF_PART_WITH_APTGET]="$i"
		if [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/apt-get" ]];then
			APTTYP[$i]=apt-get #Debian
			YESTYP[$i]="-y"
			INSTALLTYP[$i]=install
			PURGETYP[$i]="purge --allow-remove-essential"
			POLICYTYP[$i]="apt-cache policy"
			CANDIDATETYP[$i]="grep Candidate"
			CANDIDATETYP2[$i]="grep -v none"
			UPDATETYP[$i]="-y update"
			PACKVERTYP[$i]='dpkg-query -W -f=${Version}'
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/yum" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/yum" ]];then
			APTTYP[$i]=yum #fedora
			YESTYP[$i]=-y
			INSTALLTYP[$i]=install
			PURGETYP[$i]=erase
			POLICYTYP[$i]="yum info name"
			CANDIDATETYP[$i]="grep Available"
			UPDATETYP[$i]=makecache
			PACKVERTYP[$i]='rpm -q --qf=%{version}'
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/zypper" ]];then
			APTTYP[$i]='zypper --non-interactive' #opensuse
			YESTYP[$i]=''
			INSTALLTYP[$i]=in
			PURGETYP[$i]=rm
			POLICYTYP[$i]="zypper info"
			CANDIDATETYP[$i]="grep Installed"
			UPDATETYP[$i]=refresh
			PACKVERTYP[$i]="zypper se -s --match-exact"
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/pacman" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/pacman" ]];then
			APTTYP[$i]=pacman #arch
			YESTYP[$i]=''
			INSTALLTYP[$i]=-Sy
			PURGETYP[$i]=-R
			POLICYTYP[$i]="pacman -Syw --noconfirm"
			CANDIDATETYP[$i]="grep download"
			UPDATETYP[$i]="-Sy --noconfirm pacman"
			UPDATETYP2[$i]=pacman-db-upgrade
			PACKVERTYP[$i]="pacman -Q"
		#elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/urpmi" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/urpmi" ]];then
		#	APTTYP[$i]=urpmi #http://wiki.mandriva.com/fr/Installer_et_supprimer_des_logiciels
		#	YESTYP[$i]=""
		#	INSTALLTYP[$i]=urpmi
		#	PURGETYP[$i]=urpme
		#	POLICYTYP[$i]=
		#	CANDIDATETYP[$i]="grep Installed"
		#	UPDATETYP[$i]="urpmi.update -a"
		#elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/emerge" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/emerge" ]];then
		#	APTTYP[$i]=emerge #http://en.gentoo-wiki.com/wiki/Emerge
		#	YESTYP[$i]=
		#	INSTALLTYP[$i]=""
		#	PURGETYP[$i]=--unmerge
		#	POLICYTYP[$i]="emerge --search" #http://www.gentoo.org/doc/en/handbook/handbook-amd64.xml?part=2&chap=1
		#	CANDIDATETYP[$i]="grep installed"
		#	CANDIDATETYP2[$i]="grep -v 'Not Installed'"
		#	UPDATETYP[$i]="--sync"
		fi
	else
		APTTYP[$i]=nopakmgr
	fi

	temp="${BLKIDMNT_POINT[$i]}/etc/grub.d/"
	CUSTOMIZER[$i]=std-grub.d
	if [[ -d "$temp" ]];then
		[[ "$(ls "$temp" 2>/dev/null | grep prox)" ]] || [[ -d "${temp}bin" ]] && CUSTOMIZER[$i]=customized
#		if [[ ! "$1" ]];then
#			title_gen "${temp#*boot-sav/} (filtered)"
#			ls -l "${BLKIDMNT_POINT[$i]}/etc" 2>/dev/null | grep grub.d #http://forum.ubuntu-fr.org/viewtopic.php?pid=9698751#p9698751
#			ls -l "$temp" 2>/dev/null | grep -v README | grep -v total
#		fi
#		temp="${temp}40_custom"
#		if [[ -f "$temp" ]];then
#			temp2="$(cat "$temp" | grep -v "# " | grep -v '#!' | grep -v "exec tail")"
#			if [[ "$temp2" ]];then
#				if [[ ! "$1" ]];then
#                   title_gen "${temp#*boot-sav/}"
#                   echo "$temp2"
#                fi
#			fi
#		fi
	else
		CUSTOMIZER[$i]=no--grub.d
	fi

	LIB64[$i]=""
	for z in "${BLKIDMNT_POINT[$i]}"/{,usr/}lib64;do
		if [[ -d "$z" ]];then #http://forum.ubuntu-fr.org/viewtopic.php?pid=10355311#p10355311
			[[ "$(ls "$z" 2>/dev/null | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]] && LIB64[$i]=yes
		fi
	done
	if [[ "${CURRENTSESSIONPARTITION}" = "${LISTOFPARTITIONS[$i]}" ]] && [[ "$(uname -m)" = i686 ]] \
	|| ( [[ "${CURRENTSESSIONPARTITION}" != "${LISTOFPARTITIONS[$i]}" ]] && [[ ! "$LIB64[$i]" ]] ) || [[ "$ARCHIPC" = 32 ]];then
		ARCH_OF_PART[$i]=32
		(( QTY_OF_32BITS_PART += 1 ))
		for z in "${BLKIDMNT_POINT[$i]}"/{,usr/}lib64;do
			if [[ -d "$z" ]];then #debug
				if [[ "$(ls "$z" 2>/dev/null | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]];then
					b=""; for a in $(ls "$z" 2>/dev/null);do b="$a $b";done;echo "$PLEASECONTACT : $z: $b"
				fi
			fi
		done
	else
		ARCH_OF_PART[$i]=64
		(( QTY_OF_64BITS_PART += 1 ))
	fi

	BOOT_AND_KERNEL_IN[$i]=no---boot
	tmp="${BLKIDMNT_POINT[$i]}/boot"
	if [[ -d "$tmp" ]] && [[ ! "$(grep -i /boot/efi <<< "${BLKIDMNT_POINT[$i]}/" )" ]];then
		if [[ "$(ls "$tmp" 2>/dev/null)" ]] && [[ ! "$(ls "$tmp" 2>/dev/null | grep -ix bcd )" ]];then
			if [[ "$(ls "$tmp" 2>/dev/null | grep vmlinuz )" ]] && [[ "$(ls "$tmp" 2>/dev/null | grep initr )" ]];then #initramfs and vmlinuz-linux for Arch
				BOOT_AND_KERNEL_IN[$i]=with-boot
			else #if [[ ! "$(ls "$tmp" 2>/dev/null | grep '.efi' )" ]];then
				BOOT_AND_KERNEL_IN[$i]=no-kernel
				[[ "$DEBBUG" ]] && echo "
$DASH No kernel in ${LISTOFPARTITIONS[$i]}/boot:
$(ls "$tmp" )"
			fi
		fi
	fi


	if [[ ! -d "${BLKIDMNT_POINT[$i]}/usr" ]];then
		USRPRESENCE_OF_PART[$i]=no---usr # REINSTALL_POSSIBLE will be Yes only if a separate /usr exists
	elif [[ ! "$(ls "${BLKIDMNT_POINT[$i]}/usr" 2>/dev/null )" ]];then
		USRPRESENCE_OF_PART[$i]=emptyusr
	else # REINSTALL_POSSIBLE will be Yes
		USRPRESENCE_OF_PART[$i]=with--usr
	fi

	if [[ "${APTTYP[$i]}" != nopakmgr ]] || [[ "${GRUBOK_OF_PART[$i]}" ]] \
	&& [[ "${USRPRESENCE_OF_PART[$i]}" != with--usr ]] && [[ "${PART_WITH_OS[$i]}" != is-os ]];then
		SEPARATE_USR_PART[$i]=is-sep-usr
		SEP_USR_PARTS_PRESENCE=yes
	else
		SEPARATE_USR_PART[$i]=not-sep-usr
	fi
	

	if [[ -f "${BLKIDMNT_POINT[$i]}/etc/fstab" ]];then
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /boot/efi | grep -v '#' )" ]];then
			FSTAB_HASGOODEFI_OFPART[$i]=fstab-has-bad-efi
			ESP_IN_FSTAB_OF_PART[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /boot/efi | grep -v '#' )" #eg. UUID=0EC9-AA63  /boot/efi       vfat    defaults        0       1
				if [[ "$a" ]];then
					b="${a%%/boot/efi*}"	#eg. "UUID=0EC9-AA63	" , or "/dev/sda1	"
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_EFIPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_EFIPART" =~ "${PART_UUID[$uuidp]}" ]];then
						ESP_IN_FSTAB_OF_PART[$i]="$uuidp"
						FSTAB_HASGOODEFI_OFPART[$i]=fstab-has-goodEFI
					fi
				done
			elif [[ "$b" =~ / ]];then
				PARTOF_EFIPART="$b"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_EFIPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]];then
						ESP_IN_FSTAB_OF_PART[$i]="$uuidp"
						FSTAB_HASGOODEFI_OFPART[$i]=fstab-has-goodEFI
					fi
				done
			fi
			[[ "$DEBBUG" ]] && echo "
$DASH /boot/efi detected in the fstab of ${LISTOFPARTITIONS[$i]#*/dev/}: $b (${LISTOFPARTITIONS[${ESP_IN_FSTAB_OF_PART[$i]}]})"
		else
			FSTAB_HASGOODEFI_OFPART[$i]=fstab-without-efi
		fi
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /boot | grep -v /boot/ | grep -v '#' )" ]];then
			FSTAB_HAS_GOOD_BOOT[$i]=fstab-has-bad-boot
			BOOTPART_IN_FSTAB_OF[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /boot | grep -v /boot/ | grep -v '#' )" #eg. UUID=0EC9-AA63  /boot       vfat    defaults        0       1
				if [[ "$a" ]];then
					b="${a%%/boot*}"	#eg. UUID=0EC9-AA63 , or /dev/sda1
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_BOOTPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_BOOTPART" =~ "${PART_UUID[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						BOOTPART_IN_FSTAB_OF[$i]="$uuidp"
						FSTAB_HAS_GOOD_BOOT[$i]=fstab-has-goodBOOT
					fi
				done
			elif [[ "$b" =~ / ]];then
				PARTOF_BOOTPART="$b"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_BOOTPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						BOOTPART_IN_FSTAB_OF[$i]="$uuidp"
						FSTAB_HAS_GOOD_BOOT[$i]=fstab-has-goodBOOT
					fi
				done
			fi
			[[ "$DEBBUG" ]] && echo "
$DASH /boot detected in the fstab of ${LISTOFPARTITIONS[$i]#*/dev/}: $b (${LISTOFPARTITIONS[${BOOTPART_IN_FSTAB_OF[$i]}]})"
		else
			FSTAB_HAS_GOOD_BOOT[$i]=fstab-without-boot
		fi
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /usr | grep -v /usr/ | grep -v '#' | grep -v swap)" ]];then
			USR_IN_FSTAB_OF_PART[$i]=fstab-has-bad-usr
			USR_OF_PART[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /usr | grep -v '#' )" #eg. UUID=0EC9-AA63  /usr       ext4    defaults        0       2
				if [[ "$a" ]];then
					b="${a%%/usr*}"	#eg. UUID=0EC9-AA63 , or /dev/sda1
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_USRPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_USRPART" =~ "${PART_UUID[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						USR_OF_PART[$i]="$uuidp"
						USR_IN_FSTAB_OF_PART[$i]=fstab-has-goodUSR
					fi
				done
			elif [[ "$b" =~ / ]];then
				PARTOF_USRPART="$b"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_USRPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						USR_OF_PART[$i]="$uuidp"
						USR_IN_FSTAB_OF_PART[$i]=fstab-has-goodUSR
					fi
				done
			fi
			[[ "$DEBBUG" ]] && echo "
$DASH /usr detected in the fstab of ${LISTOFPARTITIONS[$i]#*/dev/}: $b (${LISTOFPARTITIONS[${USR_OF_PART[$i]}]})"
		else
			USR_IN_FSTAB_OF_PART[$i]=fstab-without-usr
		fi
	else
		FSTAB_HASGOODEFI_OFPART[$i]=part-has-no-fstab
		FSTAB_HAS_GOOD_BOOT[$i]=part-has-no-fstab
		USR_IN_FSTAB_OF_PART[$i]=part-has-no-fstab
	fi
	
	PART_WITH_SEPARATEBOOT[$i]=not--sepboot
	if [[ "${PART_WITH_OS[$i]}" != no-os ]];then
		PART_WITH_SEPARATEBOOT[$i]=not--sepboot
	elif [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep vmlinuz )" ]] && [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep initr )" ]] \
	&& [[ "$(blkid | grep "${LISTOFPARTITIONS[$i]}:" | grep zfs_member )" ]];then
		PART_WITH_SEPARATEBOOT[$i]=is--zfs-boot
	elif [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep vmlinuz )" ]] && [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep initr )" ]];then
		[[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$i]} contains a kernel, so it is probably a /boot partition."
		(( QTY_BOOTPART += 1 ))
		PART_WITH_SEPARATEBOOT[$i]=is---sepboot
		SEP_BOOT_PARTS_PRESENCE=yes
	elif [[ ! "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="vfat"' )" ]] \
	&& [[ ! "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="ntfs"' )" ]];then
		PART_WITH_SEPARATEBOOT[$i]=maybesepboot
		SEP_BOOT_PARTS_PRESENCE=yes
	fi

	[[ "${PART_WITH_OS[$i]}" = no-os ]] && temp="" || temp=/boot
	GRUB_ENV[$i]=no-grubenv
	if [[ -f "${BLKIDMNT_POINT[$i]}${temp}/grub/grubenv" ]];then
		GRUB_ENV[$i]=grubenv-ok
		temp="$(cat "${BLKIDMNT_POINT[$i]}${temp}/grub/grubenv" | sed "/^#/ d" | sed '/^$/d' )" #remove empty and commented lines
		if [[ "$temp" ]];then
			GRUB_ENV[$i]=grubenv-ng
			[[ "$DEBBUG" ]] && echo "
$DASH ${LISTOFPARTITIONS[$i]}${temp}/grub/grubenv :
$temp"
		fi
	fi


	PART_GRUBLEGACY[$i]=no-legacy-files
	for z in "${BLKIDMNT_POINT[$i]}"/{,boot/}grub/menu.lst;do
		[[ -f "$z" ]] && PART_GRUBLEGACY[$i]=has-legacyfiles && echo "$z detected"
	done

	WINXPTOREPAIR[$i]=""
	WINSETOREPAIR[$i]="" #after xp
	if [[ "${RECOV[$i]}" != recovery-or-hidden ]] && [[ "${WINXP[$i]}" ]];then
	#&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix 'Program Files' )" ]]
		(( QTY_WINBOOTTOREPAIR += 1 ))
		WINXPTOREPAIR[$i]=yes
	elif [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]] || [[ "${WINL[$i]}" = no-winload ]] \
	&& [[ "${RECOV[$i]}" != recovery-or-hidden ]] && [[ "${WINSE[$i]}" ]];then
		(( QTY_WINBOOTTOREPAIR += 1 ))
		WINSETOREPAIR[$i]=yes
	fi

	#Check if partition ends after 100Go
	FARBIOS[$i]=not-far
	part="${LISTOFPARTITIONS[$i]}" #eg /dev/mapper/isw_beaibbhjji_Volume0p1
	while read temp;do
		if [[ "$temp" =~ "$part " ]] && [[ ! "$temp" =~ GPT ]];then #eg: /dev/sda3   *    81922048   163842047    40960000    7  HPFS
			[[ "$temp" =~ '*' ]] && temp="${temp#* \*}" || temp="${temp#* }" #eg:  81922048   163842047    40960000    7  HPFS
			a=0
			for b in $temp; do
				(( a += 1 ))
				if [[ "$a" = 2 ]];then
					e="${BYTES_PER_SECTOR[${DISKNB_PART[$i]}]}"
					if [[ "$b" =~ [0-9][0-9][0-9] ]];then
						c="$(( e * b ))"
						ENDB="$(( c / 1000000000 ))"
						[[ "$ENDB" ]] && check_farbios
					fi
					break
				fi
			done
		fi
	done < <(echo "$FDISKL")
	#doublecheck with parted, in case fdisk bugs
	f=""
	while read line;do #eg 1:1049kB:21.0GB:21.0GB:ext4::;
		if [[ "$line" =~ / ]];then
			[[ "$line" =~ "${DISK_PART[$i]}:" ]] && [[ "$part" =~ "${DISK_PART[$i]}" ]] && f=ok || f=""
		fi
		if [[ "$f" ]] && [[ "${line%%:*}" = "${part##*[a-z]}" ]];then
			ENDB="${line#*B:}" #eg 21.0GB:21.0GB:ext4::;
			ENDBB="${ENDB%%B:*}" #eg 21.0G
			if [[ "$ENDBB" =~ G ]] || [[ "$ENDBB" =~ T ]];then
				ENDBB="${ENDBB%%T*}"; ENDBB="${ENDBB%%G*}" #eg 21.0
				ENDBB="${ENDBB%%.*}" #eg 21
				[[ "$ENDB" =~ T ]] && ENDB="$(( ENDBB * 1000 ))" || ENDB="$ENDBB"
				[[ "$ENDB" ]] && check_farbios
			fi
		fi
	done < <(echo "$PARTEDLM")

	if [[ "$DEBBUG" ]];then
		if [[ -f "${BLKIDMNT_POINT[$i]}/etc/mdadm/mdadm.conf" ]];then
			[[ "$DEBBUG" ]] && echo "
$DASH ${LISTOFPARTITIONS[$i]}/etc/mdadm/mdadm.conf $FILTERED:"
			if [[ ! "$FILTERED" ]];then
				cat "${BLKIDMNT_POINT[$i]}"/etc/mdadm/mdadm.conf | sed "/^#/ d" | sed '/^$/d'  #remove empty and commented lines
			else
				cat "${BLKIDMNT_POINT[$i]}"/etc/mdadm/mdadm.conf
			fi
		fi
		if [[ -f "${BLKIDMNT_POINT[$i]}/proc/mdstat" ]];then
			[[ "$DEBBUG" ]] && echo "
$DASH ${LISTOFPARTITIONS[$i]}/proc/mdstat :"
			if [[ ! "$FILTERED" ]];then
				cat "${BLKIDMNT_POINT[$i]}"/proc/mdstat | sed "/^#/ d" | sed '/^$/d'  #remove empty and commented lines
			else
				cat "${BLKIDMNT_POINT[$i]}"/proc/mdstat
			fi
		fi
	fi

	ddd="${DISKNB_PART[$i]}"
	if [[ -d "${BLKIDMNT_POINT[$i]}/casper" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/preseed" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/autorun.inf" ]] || [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep '.sys' )" ]] \
	&& [[ "${USBDISK[${DISKNB_PART[$i]}]}" = usb-disk ]] || [[ -f "${BLKIDMNT_POINT[$i]}/ldlinux.sys" ]];then
		#eg http://ubuntuforums.org/showpost.php?p=12264795&postcount=574
		USBDISK[$ddd]=liveusb
	fi
	if [[ -d "${BLKIDMNT_POINT[$i]}/casper" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/preseed" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/autorun.inf" ]] || [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep '.sys' )" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/ldlinux.sys" ]] && [[ "${MMCDISK[${DISKNB_PART[$i]}]}" = mmc-disk ]];then
		MMCDISK[$ddd]=livemmc		
	fi
done
efi_scan >/dev/null  #must be after USBDISK[ and MMCDISK[  and GPT_DISK[ fillin
[[ "$DEBBUG" ]] && paragraph_efi
[[ "$DEBBUG" ]] && echo "$ECHO_SUMEFI_SECTION"
}

paragraph_efi(){
################## EFI SCAN
#DASHM5=yes
ECHO_SUMEFI_SECTION=""
[[ "$DEBBUG" ]] && echo "[debug] ECHO_SUMEFI_SECTION"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -d "${BLKIDMNT_POINT[$i]}/efi" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/EFI" ]];then #	&& [[ "${PART_WITH_OS[$i]}" = no-os ]]
#        if [[ "$DASHM5" ]];then
#            DASHM5=""
#            ECHO_SUMEFI_SECTION="EFI files: _____________________________________________________________________
#"
#        fi
		efitmp="$i"
        md5_efi_partition
	fi
#	if [[ "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="vfat"' )" ]] \
#	|| [[ "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="ntfs"' )" ]];then
#		echo "
#$DASH hexdump -n512 -C ${LISTOFPARTITIONS[$i]}"
#		hexdump -n512 -C "${LISTOFPARTITIONS[$i]}"
#	fi
done
}

efi_scan(){
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	EFI_TYPE[$i]=isnotESP #init
	esp_check
	tmp="${DISKNB_PART[$i]}"
	WINEFI[$i]=""
	BOOTEFI[$i]=""
	MACEFI[$i]=""
	if ( [[ -d "${BLKIDMNT_POINT[$i]}/efi" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/EFI" ]] ) \
	&& ( [[ "${USBDISK[$tmp]}" != liveusb ]] && [[ "${MMCDISK[$tmp]}" != livemmc ]] || [[ "${REALWINONDISC[$tmp]}" = has-win ]] );then #exclude liveUSB/MMC except if Windows on it
		d="${DISKNB_PART[$i]}"
		[[ -d "${BLKIDMNT_POINT[$i]}/EFI" ]] && efidoss="${BLKIDMNT_POINT[$i]}/EFI" || efidoss="${BLKIDMNT_POINT[$i]}/efi"
		efitmp="$i"; md5_efi_partition #puts ECHO_SUMEFI_SECTION in memory, to check below if windows efi files are grub copies
		for z in $efidoss/Microsoft/{,*/}*.efi;do #eg /EFI/Microsoft/Boot/bootmgfw.efi or bootx64.efi
			if [[ ! "$z" =~ '*' ]] && [[ ! "$z" =~ bootmgr.efi ]] \
			&& [[ ! "$z" =~ memtest.efi ]] && [[ ! -f "$z".grb ]];then #http://ubuntuforums.org/showpost.php?p=12114780&postcount=18
                #ECHO_SUMEFI_SECTION="$ECHO_SUMEFI_SECTION
				[[ "$DEBBUG" ]] && echo "Presence of EFI/Microsoft file detected: $z"
				[[ -f "$z" ]] && mdmsft="$(md5sum "$z")" || mdmsft=""
				EFI_IS_GRUB=""
				while read line;do
					[[ "$line" =~ "$mdmsft" ]] && [[ "${line%(is grub)*}" =~ grub ]] && EFI_IS_GRUB=y
				done < <(echo "$ECHO_SUMEFI_SECTION")
				if [[ ! "$EFI_IS_GRUB" ]];then
					EFIFILPRESENT=yes #tab-main
					( [[ -f "$efidoss"/Microsoft/Boot/bootmgfw.efi ]] && [[ ! -f "$efidoss"/Microsoft/Boot/bootmgfw.efi.grb ]] ) \
					|| ( [[ -f "$efidoss"/Microsoft/Boot/bootx64.efi ]] && [[ ! -f "$efidoss"/Microsoft/Boot/bootx64.efi.grb ]] ) \
					&& WINEFIFILEPRESENCE=yes && WINEFI[$i]=has-win-efi #efi-fillin
				fi
			fi
		done
		for z in $efidoss/Boot/{,*/}*.efi;do
			if [[ ! "$z" =~ '*' ]] && [[ ! "$z" =~ memtest.efi ]];then
				[[ "$DEBBUG" ]] && echo "Presence of EFI/Boot file detected: $z"
				EFIFILPRESENT=yes #tab-main
			fi
		done
		for z in $efidoss/{,*/}*/*.scap;do
			if [[ ! "$z" =~ '*' ]];then
				[[ "$DEBBUG" ]] && echo "Presence of MacEFI file detected: $z" #File but no OS: http://ubuntuforums.org/showthread.php?t=2077532
				EFIFILPRESENT=yes #tab-main
				MACEFIFILEPRESENCE=yes #tab-loca
				#http://forum.ubuntu-fr.org/viewtopic.php?id=983441
				#MACEFI[$i]="${z#*${BLKIDMNT_POINT[$i]}}" #eg /efi/APPLE/EXTENSIONS/Firmware.scap
			fi
		done
		for z in $efidoss/{,*/}*/*.bkp $efidoss/{,*/}*/bkp*.efi;do
			if [[ ! "$z" =~ '*' ]];then
				BKPFILEPRESENCE=yes
				if [[ "$z" =~ icros ]];then
					[[ ! "$1" ]] && [[ "$DEBBUG" ]] && echo "Presence of winbkp file detected: $z"
					WINBKPFILEPRESENCE=yes
				else
					[[ ! "$1" ]] && [[ "$DEBBUG" ]] && echo "Presence of bkp file detected: $z"
				fi
			fi
		done
	fi
done


################## Refind  https://forum.ubuntu-fr.org/viewtopic.php?pid=22242095#p22242095
#for ((i=1;i<=NBOFPARTITIONS;i++)); do
#    if [[ -d "${BLKIDMNT_POINT[$i]}/boot" ]];then
#        if [[ -f "${BLKIDMNT_POINT[$i]}/boot/refind_linux.conf" ]];then
#            echo "
#$DASH ${LISTOFPARTITIONS[$i]}/boot/refind_linux.conf :
#$(cat ${BLKIDMNT_POINT[$i]}/boot/refind_linux.conf)"
#        fi
#    fi
#    if [[ -f "${BLKIDMNT_POINT[$i]}/refind_linux.conf" ]];then
#        echo "
#$DASH ${LISTOFPARTITIONS[$i]}/refind_linux.conf :
#$(cat ${BLKIDMNT_POINT[$i]}/refind_linux.conf)"
#    fi
#    if [[ -d "${BLKIDMNT_POINT[$i]}/EFI/refind" ]];then
#        if [[ -f "${BLKIDMNT_POINT[$i]}/EFI/refind/refind.conf" ]];then
#            echo "
#$DASH ${LISTOFPARTITIONS[$i]}/EFI/refind/refind.conf (filtered):
#$(sed -e '/^[ ]*#/d' -e '/^[ ]*;/d' -e '/^$/d' ${BLKIDMNT_POINT[$i]}/EFI/refind/refind.conf)"
#        fi
#    fi
#    if [[ -d "${BLKIDMNT_POINT[$i]}/boot/efi/EFI/refind" ]];then
#        if [[ -f "${BLKIDMNT_POINT[$i]}/boot/efi/EFI/refind/refind.conf" ]];then
#            echo "
#$DASH ${LISTOFPARTITIONS[$i]}/boot/efi/EFI/refind/refind.conf (filtered):
#$(sed -e '/^[ ]*#/d' -e '/^[ ]*;/d' -e '/^$/d' ${BLKIDMNT_POINT[$i]}/boot/efi/EFI/refind/refind.conf)"
#        fi
#    fi
#done
}

md5_efi_partition() {
#Used by mount_separate_boot_if_required & reinstall_grubstageone & debug_echo_part_info & efi_scan
EFIDIRE="${BLKIDMNT_POINT[$efitmp]}"
EFIDDD="${LISTOFPARTITIONS[$efitmp]}"
local a="" tmmmp=""
mgfw="$EFIDIRE"/efi/Microsoft/Boot/bootmgfw.efi
mx64="$EFIDIRE"/efi/Microsoft/Boot/bootx64.efi
[[ -f "$mgfw" ]] && mdmgfw="$(md5sum "$mgfw")" || mdmgfw=""
[[ -f "$mx64" ]] && mdmx64="$(md5sum "$mx64")" || mdmx64=""
for xia in efi EFI bkp scap;do #need efi and EFI
	for x in "$EFIDIRE"/efi/{,*/}*/*.$xia "$EFIDIRE"/EFI/{,*/}*/*.$xia;do
		if [[ ! "$x" =~ '*' ]] && [[ ! "$x" =~ memtest ]];then
			[[ "$x" =~ "/EFI/" ]] && tmmmp="${x##*/EFI/}" || tmmmp="${x##*/efi/}"
			tmmmp="$(echo "$tmmmp" | sed 's/EFI/efi/g' )"
			if [[ ! "$a" =~ "$tmmmp" ]];then
				a="$tmmmp $a"
				mdline="$(md5sum $x)"
				SAMEASMGFW=""
				if [[ "$mdline" = "$mdmgfw" ]] && [[ ! "$x" =~ "soft/Boot/bootmgfw.efi" ]] && [[ ! "$x" =~ "oft/Boot/bootx64.efi" ]];then SAMEASMGFW="  (same md5 as Microsoft/Boot/bootmgfw.efi)"
				elif [[ "$mdline" = "$mdmgfw" ]] && [[ ! "$x" =~ "soft/Boot/bootmgfw.efi" ]] && [[ ! "$x" =~ "oft/Boot/bootx64.efi" ]];then SAMEASMGFW="  (same md5 as Microsoft/Boot/bootx64.efi)"
				fi
				[[ -f "$x".grb ]] && FAKEEFI=" (is grub)" || FAKEEFI=""
				ECHO_SUMEFI_SECTION="$ECHO_SUMEFI_SECTION
${mdline%% *}   ${EFIDDD#*/dev/}/$tmmmp${FAKEEFI}${SAMEASMGFW}"
			fi
		fi
	done
done
}

check_grubdoc_1() {
lsz="$(ls $z 2>/dev/null | grep grub)"
for zz in $lsz;do
	if [[ "$(grep efi <<< "$zz" )" ]] || ( [[ -d "$z$zz" ]] && [[ "$(ls "$z$zz" 2>/dev/null | grep efi )" ]] );then
		[[ ! "$(grep efi <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="grub-efi ${DOCGRUB[$i]}"
	elif [[ "$(grep pc <<< "$zz" )" ]] || ( [[ -d "$z$zz" ]] && [[ "$(ls "$z$zz" 2>/dev/null | grep pc )" ]] );then
		[[ ! "$(grep pc <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="grub-pc ${DOCGRUB[$i]}"
	elif [[ "$(grep legacy <<< "$zz" )" ]] || ( [[ -d "$z$zz" ]] && [[ "$(ls "$z$zz" 2>/dev/null | grep legacy )" ]] );then
		[[ ! "$(grep grub1 <<< "${DOCGRUB[$i]}")" ]] && DOCGRUB[$i]="grub1 ${DOCGRUB[$i]}"
	fi
done
}

check_grubdoc_2() {
lsz="$(ls $z | grep grub)"
for zz in $lsz;do
	if [[ ! "$(grep efi <<< "${DOCGRUB[$i]}")" ]] && [[ ! "$(grep pc <<< "${DOCGRUB[$i]}")" ]];then
		if [[ "$(grep grub2 <<< "$zz" )" ]] || ( [[ -d "$z$zz" ]] && [[ "$(ls "$z$zz" 2>/dev/null | grep grub2 )" ]] );then
			DOCGRUB[$i]="grub-pc ${DOCGRUB[$i]}"
		fi
	fi
done
}

check_farbios() {
d="$(( ENDB / 100 ))"
[[ "$d" != 0 ]] && FARBIOS[$i]=end-after-100GB
[[ "$DEBBUG" ]] && echo "[debug] ${LISTOFPARTITIONS[$i]} ends at ${ENDB}GB. ${FARBIOS[$i]}"
}


################## WARNINGS BEFORE DISPLAYING MAIN MENU ################
check_options_warning() {
local FUNCTION
#if [[ "$NB_EFIPARTONGPT" -ge 1 ]] && [[ ! "$MACEFIFILEPRESENCE" ]];then
#	FUNCTION=EFI
#	update_translations
#	zenity --width=400 --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_check_options" 2>/dev/null
#	echo "$FUNCTION_detected $Please_check_options"
#fi
if [[ "$GUI" ]] && [[ "$QTY_BOOTPART" -ge 1 ]] && [[ "$LIVESESSION" = live ]];then
	FUNCTION=/boot
	update_translations
	zenity --width=400 --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_check_options" 2>/dev/null
	echo "
$DASH $FUNCTION_detected $Please_check_options"
fi
if [[ "$GUI" ]] && [[ "$QTY_SEP_USR_PARTS" -ge 1 ]] && [[ "$LIVESESSION" = live ]];then
	FUNCTION=/usr
	update_translations
	zenity --width=400 --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_check_options" 2>/dev/null
	echo "
$DASH $FUNCTION_detected $Please_check_options"
fi
}

warnings_and_show_mainwindow() {
WIOULD=would
end_pulse
[[ ! "$APPNAME" =~ nf ]] && check_options_warning
[[ "$GUI" ]] && echo 'SET@_mainwindow.show()'
}

debug_echo_important_variables() {
[[ "$DEBBUG" ]] && echo "[debug] debug_echo_important_variables"
if [[ "$WIOULD" =~ ld ]] || [[ "$MAIN_MENU" =~ Recomm ]];then
	[[ "$APPNAME" =~ os ]] &&  THISSET="The default settings of $CLEANNAME" || THISSET="The default repair of the Boot-Repair utility"
else
	THISSET="The settings chosen by the user"
fi
IMPVAR="$THISSET $WIOULD"
[[ "$APPNAME" =~ os ]] && IMPVAR="$IMPVAR $FORMAT_OS ($FORMAT_TYPE) wubi($WUBI_TO_DELETE), then"
if [[ "$MBR_ACTION" = restore ]];then
	IMPVAR="$IMPVAR restore the [${MBR_TO_RESTORE#* }] MBR in $DISK_TO_RESTORE_MBR, and make it boot on ${LISTOFPARTITIONS[$TARGET_PARTITION_FOR_MBR]#*/dev/}."
elif [[ "$BOOTFLAG_ACTION" ]] || [[ "$UNHIDEBOOT_ACTION" ]] || [[ "$FSCK_ACTION" ]] || [[ "$WUBI_ACTION" ]] || [[ "$WINBOOT_ACTION" ]] \
|| [[ "$CREATE_BKP_ACTION" ]] || [[ "$RESTORE_BKP_ACTION" ]] && [[ "$MBR_ACTION" = nombraction ]];then
	IMPVAR="$IMPVAR not act on the MBR."
elif [[ "$MBR_ACTION" = nombraction ]];then
	IMPVAR="$IMPVAR not act on the boot."
else
	if [[ "$GRUBPURGE_ACTION" ]];then
		[[ "$PURGREASON" ]] && IMPVAR="$IMPVAR purge ($PURGREASON) and" || IMPVAR="$IMPVAR purge and"
	fi
	IMPVAR="$IMPVAR reinstall the $GRUBPACKAGE of
${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}"
	if [[ ! "$GRUBPACKAGE" =~ efi ]];then
		[[ "$FORCE_GRUB" = place-in-MBR ]] || [[ "$REMOVABLEDISK" ]] && IMPVAR="$IMPVAR into the MBR of ${NOFORCE_DISK#*/dev/}"
		[[ "$FORCE_GRUB" = force-in-PBR ]] && IMPVAR="$IMPVAR into the PBR of ${FORCE_PARTITION#*/dev/}"
		#[[ ! "$REMOVABLEDISK" ]] && 
		[[ "$FORCE_GRUB" = place-in-all-MBRs ]] && IMPVAR="$IMPVAR into the MBRs of all disks without OS (except live-disks and removable disks)"
	fi
	[[ "$LASTGRUB_ACTION" ]] || [[ "$BLANKEXTRA_ACTION" ]] || [[ "$UNCOMMENT_GFXMODE" ]] || [[ "$ATA" ]] \
	|| [[ "$KERNEL_PURGE" ]] || [[ "$USE_SEPARATEBOOTPART" ]] || [[ "$USE_SEPARATEUSRPART" ]] \
	|| [[ "$ADD_KERNEL_OPTION" ]] || [[ "$GRUBPACKAGE" =~ efi ]] || [[ "$DISABLEWEBCHECK" ]] \
	&& IMPVAR="$IMPVAR,
using the following options: $LASTGRUB_ACTION$BLANKEXTRA_ACTION$UNCOMMENT_GFXMODE$KERNEL_PURGE$DISABLEWEBCHECK$ATA" \
	|| IMPVAR="$IMPVAR."
	[[ "$USE_SEPARATEBOOTPART" ]] && IMPVAR="$IMPVAR ${LISTOFPARTITIONS[$BOOTPART_TO_USE]#*/dev/}/boot"
	[[ "$USE_SEPARATEUSRPART" ]] && IMPVAR="$IMPVAR ${LISTOFPARTITIONS[$USRPART_TO_USE]#*/dev/}/usr"
	[[ "$GRUBPACKAGE" =~ efi ]] && IMPVAR="$IMPVAR ${LISTOFPARTITIONS[$EFIPART_TO_USE]#*/dev/}/boot/efi"
	[[ "$ADD_KERNEL_OPTION" ]] && IMPVAR="$IMPVAR $ADD_KERNEL_OPTION ($CHOSEN_KERNEL_OPTION)"
#	[[ "$REMOVABLEDISK" ]] && [[ "$FORCE_GRUB" = place-in-all-MBRs ]] && IMPVAR="$IMPVAR
#It $WIOULD also fix access to other systems (other MBRs) for the situations
#when the removable media is disconnected."
	[[ ! "$GRUBPACKAGE" =~ efi ]] && [[ "$NOTEFIREASON" ]] && IMPVAR="$IMPVAR
Grub-efi $WIOULD not be selected by default because ${NOTEFIREASON}."
fi
[[ "$BOOTFLAG_ACTION" ]] && IMPVAR="$IMPVAR
The boot flag $WIOULD be placed on ${LISTOFPARTITIONS[$BOOTFLAG_TO_USE]#*/dev/}."
[[ "$UNHIDEBOOT_ACTION" ]] || [[ "$FSCK_ACTION" ]] || [[ "$WUBI_ACTION" ]] || [[ "$WINBOOT_ACTION" ]] \
|| [[ "$CREATE_BKP_ACTION" ]] || [[ "$RESTORE_BKP_ACTION" ]] && IMPVAR="$IMPVAR
Additional repair $WIOULD be performed: $UNHIDEBOOT_ACTION$WINBOOT_ACTION$CREATE_BKP_ACTION$WINEFI_BKP_ACTION$RESTORE_BKP_ACTION$WUBI_ACTION$FSCK_ACTION"
[[ "$WIOULD" = will ]] && IMPVAR="$IMPVAR

"
}

################################ PUT THE CURRENT MBRs IN TMP ##################################################
put_the_current_mbr_in_tmp() {
local i
for ((i=1;i<=NBOFDISKS;i++)); do
	if [[ ! -f "$LOGREP/${LISTOFDISKS[$i]#*/dev/}/current_mbr.img" ]]; then
		dd if=${LISTOFDISKS[$i]} of=$LOGREP/${LISTOFDISKS[$i]#*/dev/}/current_mbr.img bs=${BYTES_BEFORE_PART[$i]} count=1 2>/dev/null
	fi
	if [[ ! -f "$LOGREP/${LISTOFDISKS[$i]#*/dev/}/partition_table.dmp" ]] && [[ "$(type -p sfdisk)" ]]; then
		sfdisk -d ${LISTOFDISKS[$i]} > $LOGREP/${LISTOFDISKS[$i]#*/dev/}/partition_table.dmp
		[[ "$DEBBUG" ]] && echo "[debug]$LOGREP/${LISTOFDISKS[$i]#*/dev/}/partition_table.dmp created"
	fi
done
}
