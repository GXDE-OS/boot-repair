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

######################################### 
blkid_fdisk_and_parted_update() {
blkid -g			#Update the UUID cache
BLKID=$(blkid)
PARTEDLM="$(LANGUAGE=C LC_ALL=C parted -lms 2>/dev/null)" #may be with null -l but -lm ok
FDISKL="$(LANGUAGE=C LC_ALL=C fdisk -l 2>/dev/null)"
}

######################################### blkid partitions ###############################
check_blkid_partitions() {
NBOFPARTITIONS=0; NBOFDISKS=0; LISTOFDISKS[0]=0
#Add disks, eg sdb
while read line;do
	disk=""; part=""
	if [[ "$(echo "$line" | grep '/' | grep ':' | grep -iv loop )" ]];then
		disk="${line%%:*}" #eg /dev/sda (parted) or 'Disk /dev/sda' (fdisk)
		disk="${line#Disk *}" #/dev/sda
		if [[ "$disk" ]];then
			if [[ "$(ls $disk 2>/dev/null)" ]];then
				add_disk exclude "a$CURRENTSESSIONPARTITION"
			elif [[ "$DEBBUG" ]];then
				echo "[debug] disk $disk not in ls"
			fi
		fi
	fi
done < <(echo "$PARTEDLM"; echo "$FDISKL" | grep Disk)
#Add current session partition first
if [[ "$LIVESESSION" != live ]];then
	part="$CURRENTSESSIONPARTITION"; disk=""
	determine_disk_from_part
	add_disk "a$CURRENTSESSIONPARTITION" include add_part_too #Put currentsession first
fi
#Add the rpool partition
part="$RTPL"
if [[ "$RTPL" ]];then
	part="$RTPL"
	[[ "$FIRSTZFSDISK" ]] && disk="$FIRSTZFSDISK" || set_default_disk
	add_disk exclude "a$CURRENTSESSIONPARTITION" add_part_too
fi
#Add other partitions
loop_check_blkid_partitions exclude "a$CURRENTSESSIONPARTITION"
}

loop_check_blkid_partitions() {
local lvline line temp part disk raidset temp2
while read line; do
	if [[ "$line" =~ '/' ]] && [[ "$line" =~ ':' ]];then
		part=${line%%:*} 	#e.g. "/dev/sda12" or "/dev/mapper/isw_decghhaeb_Volume0p2" or "/dev/mapper/isw_bcbggbcebj_ARRAY4" or "/dev/mapper/vg_adamant-lv_root"
		disk=""
		#echo "[debug]part : $part"	#Add "squashfs" ?   #sr1
        #Microsoft reserved: https://forum.ubuntu-fr.org/viewtopic.php?pid=22298412#p22298412
        #2022 ubiquity installs grub on:
        #/dev/[hmsv]d[a-z]|/dev/xvd[a-z]|/dev/cciss/c[0-9]d[0-9]*|/dev/ida/c[0-9]d[0-9]*|/dev/rs/c[0-9]d[0-9]*|/dev/mmcblk[0-9]|/dev/ad[0-9]*|/dev/da[0-9]*|/dev/fio[a-z]|/dev/nvme[0-9]n[0-9])
		if [[ "$part" ]] && [[ ! "$line" =~ /dev/loop ]] && [[ ! "$(df "$part")" =~ /cdrom ]] \
		&& [[ ! "$(df "$part")" =~ /live/ ]] && [[ ! "$line" =~ "TYPE=\"iso" ]] && [[ ! "$line" =~ "TYPE=\"udf" ]] && [[ ! "$line" =~ "TYPE=\"crypt" ]] \
		&& [[ ! "$line" =~ "Microsoft reserved partition" ]] && [[ ! "$(echo "$FDISKL" | grep "$part " | grep 'Microsoft reserved' )" ]] \
        && [[ ! "$(echo "$FDISKL" | grep "$part " | grep 'BIOS boot' )" ]];then
			if [[ "$line" =~ LVM2_member ]];then # http://www.linux-sxs.org/storage/fedora2ubuntu.html
				[[ "$DEBBUG" ]] && echo "[debug] $part is LVM2_member"
			elif ([[ "$part" =~ cciss/ ]] || [[ "$part" =~ nvme ]] || [[ "$part" =~ mmcblk ]]) && [[ ! "$(grep "p[0-9]" <<< $part )" ]];then
				[[ "$DEBBUG" ]] && echo "[debug] $part is a disk, eg nvme0n1 , mmcblk0, cciss/c0d0"
			elif [[ "$line" =~ zfs_member ]];then #exclude partitions marked as zfs_member by blkid. Only consider zfs (rpool and bpool) partitions, which are in /mount.
				[[ "$DEBBUG" ]] && echo "[debug] $part is ZFS"
			elif [[ "$line" =~ raid_member ]];then
				[[ "$DEBBUG" ]] && echo "[debug] $part is RAID_member" #eg md0 on sdb & sdc
			elif [[ "$part" = sd[a-z] ]] || [[ "$part" = hd[a-z] ]] || [[ "$part" = vd[a-z] ]] || [[ "$part" = sd[a-z][a-z] ]];then
				echo "$part may have broken partition table."
			elif [[ "$line" =~ swap ]] || [[ "$(grep swap <<< "$line" )" ]];then
				[[ ! "$line" =~ swap ]] && echo "Swap not detected by =~. $PLEASECONTACT"
			elif [[ "$line" =~ "dev/md/" ]];then
				echo "$part avoided"
			else
				determine_disk_from_part
				add_disk $1 $2 add_part_too
			fi
		fi
	fi
done < <(echo "$BLKID")
}

determine_disk_from_part() {
#called by loop_check_blkid_partitions and check_os_detected_by_os-prober
if [[ "$part" =~ mapper ]] || [[ "$(grep mapper <<< $part )" ]];then
	#e.g. "mapper/nvidia_dgicebef12" or "mapper/isw_bcbggbcebj_ARRAY3" (FakeRAID)
	if [[ "$(type -p dmraid)" ]];then
		if [[ "$(dmraid -sa -c)" ]] && [[ "$(dmraid -sa -c)" != "no raid disk" ]];then
			for raidset in $(dmraid -sa -c); do
				echo "[dmraid -sa -c] $raidset"  #http://ubuntuforums.org/showthread.php?t=1559762&page=2
				[[ "$(grep "$raidset" <<< "$part" )" ]] && [[ "$(ls "mapper/$raidset" 2>/dev/null)" ]] && disk="mapper/$raidset"
			done
		fi
	fi
	[[ ! "$disk" ]] && [[ "$(grep "[a-z][0-9]" <<< $part )" ]] && [[ "$(ls ${part%%[0-9]*} 2>/dev/null)" ]] && disk="${part%%[0-9]*}" #eg /dev/mapper/isw_cgefbfjgfc_Ubuntu6 -> /dev/mapper/isw_cgefbfjgfc_Ubuntu
	[[ ! "$disk" ]] && [[ "$(grep "p[0-9]" <<< $part )" ]] && [[ "$(ls "$(a=${part%p[0-9]*};echo /dev${a#*mapper})" 2>/dev/null)" ]] && disk="$(a=${part%p[0-9]*};echo /dev${a#*mapper})" #eg mapper/nvme0n1p6 on disc nvme0n1 (#2077234)
	[[ ! "$disk" ]] && set_default_disk
elif [[ "$(grep "md[0-9]" <<< $part )" ]];then #Software array
	#http://www.howtoforge.com/how-to-set-up-software-raid1-on-a-running-system-incl-grub2-configuration-ubuntu-10.04-p2
	#http://ubuntuforums.org/showthread.php?t=1551087
	set_default_disk
elif [[ "$(grep "p[0-9]" <<< $part )" ]] && [[ "$(ls ${part%p[0-9]*} 2>/dev/null)" ]];then
	disk="${part%p[0-9]*}" # nvme0n1p1, mmcblk0p1, cciss/c1d1p1 -> cciss/c1d1 , https://blueprints.launchpad.net/boot-repair/+spec/check-cciss-support  
elif [[ "$(grep "[a-z][0-9]" <<< $part )" ]] && [[ "$(ls ${part%%[0-9]*} 2>/dev/null)" ]];then
	disk="${part%%[0-9]*}"  ##eg, sda1 , hda1, vda1, sdab1, Add sr[0-9] (memcard)?
elif [[ "$part" =~ "pool/" ]] && [[ "$FIRSTZFSDISK" ]];then #probably useless as we add RTPL in check_blkid_partitions
	disk="$FIRSTZFSDISK"
elif [[ "$line" =~ raid_member ]] && [[ "$(ls $part 2>/dev/null)" ]];then
	disk="$part" #should never happen (filtered before)
else
	set_default_disk
fi
}

set_default_disk() {
#called by loop_check_blkid_partitions and determine_disk_from_part
# Fallback when disk not found in blkid, e.g. /dev/md127 is not in blkid, while /dev/md127p1 is.
[[ "$NBOFDISKS" != 0 ]] && disk="${LISTOFDISKS[1]}" || disk="$part"
[[ "$(ls /dev/sda 2>/dev/null)" ]] && disk=/dev/sda
if [[ "$part" =~ md ]] || [[ "$part" =~ mapper ]] || [[ "$line" =~ raid_member ]] || [[ "$part" =~ "pool/" ]];then
	[[ "$DEBBUG" ]] && echo "Set $disk as corresponding disk of $part"
else
	echo "$part ($disk) has unknown type. $PLEASECONTACT"
fi
}

add_disk() {
if [[ "a$part" = "$1" ]] || [[ "$1" = exclude ]] && [[ "a$part" != "$2" ]] && [[ "$disk" ]] && [[ ! "$(df "$disk")" =~ /cdrom ]] \
&& [[ ! "$(echo "$PARTEDLM" | grep $disk | grep ':loop:' )" ]] \
&& [[ ! "$(lsblk -o FSTYPE $disk | grep iso )" ]];then #exclude iso and loop disks: https://ubuntuforums.org/showthread.php?t=2493456&p=14169467#post14169467
	local ADD_DISK=yes ADD_PART="$3" b
	for ((b=1;b<=NBOFDISKS;b++)); do
		[[ "${LISTOFDISKS[$b]}" = "$disk" ]] && ADD_DISK=""
	done
	if [[ "$ADD_DISK" ]] && [[ "$disk" ]];then
		(( NBOFDISKS += 1 ))
		LISTOFDISKS[$NBOFDISKS]="$disk"
		#echo "[debug]Disk $NBOFDISKS is $disk"
		mkdir -p "$LOGREP/${disk#*/dev/}"
		#For ZFS
		[[ "$(echo "$FDISKL" | grep '^/' | grep -i 'Solaris\|FreeBSD' | grep $disk)" ]] && FIRSTZFSDISK="$disk"
	fi
	for ((b=1;b<=NBOFPARTITIONS;b++)); do
		[[ "${LISTOFPARTITIONS[$b]}" = "$part" ]] && ADD_PART=""
	done
	if [[ "$ADD_PART" ]] && [[ "$part" ]];then
		(( NBOFPARTITIONS += 1 ))
		LISTOFPARTITIONS[$NBOFPARTITIONS]="$part" #sda1
		DISK_PART[$NBOFPARTITIONS]="$disk" #sda
		for ((b=1;b<=NBOFDISKS;b++)); do
			[[ "${LISTOFDISKS[$b]}" = "$disk" ]] && DISKNB_PART[$NBOFPARTITIONS]="$b"
		done
		#echo "[debug]Partition $NBOFPARTITIONS is $part ($disk)"
		mkdir -p "$LOGREP/${part#*/dev/}"
	fi
fi
}


####################### determine_part_uuid ############################
determine_part_uuid() {
local i temp
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	temp="$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:")"; temp=${temp#*UUID=\"}; temp=${temp%%\"*}
	PART_UUID[$i]="$temp"		#e.g. "b3f9b3f2-a0c7-49c1-ae50-f849a02fd52e"
	[[ "$DEBBUG" ]] && echo "[debug]PART_UUID of ${LISTOFPARTITIONS[$i]#*/dev/} is ${PART_UUID[$i]}"
done
}

############################# CHECK BIOS Boot #######################
#determine_bios_boot() {
#avoid mounting BIOS_Boot (bug #1720591)
#for ((i=1;i<=NBOFPARTITIONS;i++)); do
#	BIOS_BOOT[$i]=notbiosboot
#	[[ "$(echo "$FDISKL" | grep "${LISTOFPARTITIONS[$i]}" | grep -i BIOS | grep -i Boot )" ]] && BIOS_BOOT[$i]=is-biosboot
#	[[ "$DEBBUG" ]] && echo "[debug]BIOSBOOT of ${LISTOFPARTITIONS[$i]#*/dev/} is ${BIOS_BOOT[$i]}"
#done
#}

############################# CHECK PART WITH OS #######################
determine_part_with_os() {
local i j n
#used by check_recovery_or_hidden & check_separate_boot_partitions & check_part_types
FEDORA_DETECTED=""
QUANTITY_OF_REAL_WINDOWS=0
for ((i=1;i<=NBOFPARTITIONS;i++)); do
    #First adds the OS detected by os-prober
	PART_WITH_OS[$i]=no-os
	for ((j=1;j<=TOTAL_QUANTITY_OF_OS;j++)); do
		if [[ "${LISTOFPARTITIONS[$i]}" = "${OS__PARTITION[$j]}" ]];then
			PART_WITH_OS[$i]=is-os
			OSNAME[$i]="${OS__NAME[$j]}"
			[[ "${OSNAME[$i]}" =~ Fedora ]] || [[ "${OSNAME[$i]}" =~ Arch ]] && FEDORA_DETECTED=yes
		fi
	done
    #Then adds the OS not detected by os-prober
	scan_windows_parts
    [[ -d "${BLKIDMNT_POINT[$i]}/selinux" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/srv" ]] \
    || [[ -f "${BLKIDMNT_POINT[$i]}/ReactOS/system32/config/SecEvent.Evt" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/etc/issue" ]] \
    || [[ -f "${BLKIDMNT_POINT[$i]}/etc/slackware-version" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/etc/redhat-release" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/etc/os-release" ]] \
    && NEWLINDETECTED=y || NEWLINDETECTED=""
	if [[ "${WINXP[$i]}" ]] || [[ "${WINSE[$i]}" ]] || [[ "$NEWLINDETECTED" ]] && [[ "${PART_WITH_OS[$i]}" = no-os ]];then
        PART_WITH_OS[$i]=is-os
        (( TOTAL_QUANTITY_OF_OS += 1 ))
        OS__PARTITION[$TOTAL_QUANTITY_OF_OS]="${LISTOFPARTITIONS[$i]}"			#e.g. "/dev/sda1"
		OS__DISK[$TOTAL_QUANTITY_OF_OS]="${DISK_PART[$i]}"				#e.g. "/dev/sda"
		if [[ "$NEWLINDETECTED" ]];then
			OSNAME[$i]=Linux
            [ -s "${BLKIDMNT_POINT[$i]}/ReactOS/system32/config/SecEvent.Evt" ] && OSNAME[$i]='ReactOS';
            [ -s "${BLKIDMNT_POINT[$i]}/etc/issue" ] && OSNAME[$i]="$(sed -e 's/\\. //g' -e 's/\\.//g' -e 's/^[ \t]*//' "${BLKIDMNT_POINT[$i]}"/etc/issue)"
            [ -s "${BLKIDMNT_POINT[$i]}/etc/slackware-version" ] && OSNAME[$i]="$(sed -e 's/\\. //g' -e 's/\\.//g' -e 's/^[ \t]*//' "${BLKIDMNT_POINT[$i]}"/etc/slackware-version)"
            [ -s "${BLKIDMNT_POINT[$i]}/etc/redhat-release" ] && OSNAME[$i]="$(cat "${BLKIDMNT_POINT[$i]}"/etc/redhat-release | tr -d '\n')"
            [ -s "${BLKIDMNT_POINT[$i]}/etc/os-release" ] && grep -q '^PRETTY_NAME=' "${BLKIDMNT_POINT[$i]}/etc/os-release" && OSNAME[$i]="$(eval "$(grep '^PRETTY_NAME=' "${BLKIDMNT_POINT[$i]}"/etc/os-release)"; printf '%s' "${PRETTY_NAME}" | tr -d '\n')"
            OS__NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]}"
            OS__COMPLETE_NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]} (not detected by os-prober)"
			[[ "$DEBBUG" ]] && echo "Linux not detected by os-prober on ${LISTOFPARTITIONS[$i]#*/dev/}."
		elif [[ "${WINXP[$i]}" ]];then
			OSNAME[$i]="Windows XP"
            OS__NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]}"
            OS__COMPLETE_NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]} (not detected by os-prober)"
			[[ "$DEBBUG" ]] && echo "XP not detected by os-prober on ${LISTOFPARTITIONS[$i]#*/dev/}."
		elif [[ "${WINSE[$i]}" ]];then
            OS__NAME[$TOTAL_QUANTITY_OF_OS]="Windows"
            grep -q "i.s.t.a"  "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows Vista';
            grep -q "n.1.0" "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows 7 or 10'; #Win7 also contains n.1.0 but not i.n.1.0
            grep -q "n.7" "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows 7';
            grep -q "n.8" "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows 8 or 10';
            grep -q "i.n.1.0" "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows 10 or 11';
            grep -q "n.1.1" "${BLKIDMNT_POINT[$i]}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>>/dev/null && OSNAME[$i]='Windows 11'; #not seen yet
            OS__NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]}"
            OS__COMPLETE_NAME[$TOTAL_QUANTITY_OF_OS]="${OSNAME[$i]} (not detected by os-prober)"
			[[ "$DEBBUG" ]] && echo "Windows not detected by os-prober on ${LISTOFPARTITIONS[$i]#*/dev/}."
		fi
	fi
	[[ "$DEBBUG" ]] && echo "[debug]PART_WITH_OS of ${LISTOFPARTITIONS[$i]#*/dev/} : ${PART_WITH_OS[$i]}"
done

##CHECK THE TYPE OF EACH OS
QUANTITY_OF_DETECTED_LINUX=0; QUANTITY_OF_DETECTED_WINDOWS=0; QUANTITY_OF_DETECTED_MACOS=0; QUANTITY_OF_UNKNOWN_OS=0
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
    if [[ "$(grep -i linux <<< "${OS__COMPLETE_NAME[$i]}" )" ]] || [[ "$(grep -i buntu <<< "${OS__COMPLETE_NAME[$i]}" )" ]]; then #buntu in case no linux in the chain (#2077234)
        (( QUANTITY_OF_DETECTED_LINUX += 1 ))
        OS__TYPE[$i]=linux
    elif [[ "$(grep -i windows <<< "${OS__COMPLETE_NAME[$i]}" )" ]];then
        (( QUANTITY_OF_DETECTED_WINDOWS += 1 ))
        OS__TYPE[$i]=windows
    elif [[ "$(grep -i mac <<< "${OS__COMPLETE_NAME[$i]}" )" ]];then
        (( QUANTITY_OF_DETECTED_MACOS += 1 ))
        OS__TYPE[$i]=macos
    else
        (( QUANTITY_OF_UNKNOWN_OS += 1 ))
        OS__TYPE[$i]=else
    fi
    [[ "$DEBBUG" ]] && echo "[debug]${OS__PARTITION[$i]} contains ${OS__NAME[$i]} (${OS__TYPE[$i]})"
done

for ((n=1;n<=NBOFDISKS;n++)); do
	DISK_HASOS[$n]=no-os
	for ((i=1;i<=NBOFPARTITIONS;i++)); do
		if [[ "${PART_WITH_OS[$i]}" = is-os ]] && [[ "${DISKNB_PART[$i]}" = "$n" ]];then
			[[ "$DEBBUG" ]] && echo "[debug]${LISTOFDISKS[$n]} contains minimum one OS"
			DISK_HASOS[$n]=has-os
			break
		fi
	done
done
###################### Wubi
TOTAL_QTY_OF_OS_INCLUDING_WUBI="$TOTAL_QUANTITY_OF_OS"; QTY_WUBI=0;WUBILDR="";ROOTDISKMISSING=""
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -f "${BLKIDMNT_POINT[$i]}/ubuntu/disks/root.disk" ]] ;then
		[[ "$DEBBUG" ]] && echo "There is Wubi inside ${LISTOFPARTITIONS[$i]#*/dev/}"
		(( TOTAL_QTY_OF_OS_INCLUDING_WUBI += 1 )); (( QTY_WUBI += 1 ))
		OS__PARTITION[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="${LISTOFPARTITIONS[$i]}"
		OS__NAME[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="$Ubuntu_installed_in_Windows_via_Wubi"
		OS__TYPE[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="wubi"
        [[ ! "${OSNAME[$i]}" ]] && OSNAME[$i]="Wubi installed in an undetected Windows" && [[ "$DEBBUG" ]] && echo "
$DASH Wubi installed in an undetected Windows in ${LISTOFPARTITIONS[$i]#*/dev/}."
        OS__COMPLETE_NAME[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="$Ubuntu_installed_in_Windows_via_Wubi"
		WUBI[$QTY_WUBI]="$TOTAL_QTY_OF_OS_INCLUDING_WUBI"
		WUBI_PART[$QTY_WUBI]="$i"
		BLKIDMNT_POINTWUBI[$QTY_WUBI]="${BLKIDMNT_POINT[$i]}"
		MOUNTPOINTWUBI[$QTY_WUBI]="/mnt/boot-sav/wubi$QTY_WUBI"
		mkdir -p "${MOUNTPOINTWUBI[$QTY_WUBI]}"
	fi
	[[ -f "${BLKIDMNT_POINT[$i]}/wubildr" ]] && WUBILDR=yes
done
[[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ "$QTY_WUBI" = 0 ]] && [[ "$WUBILDR" ]] && ROOTDISKMISSING=yes
#http://ubuntu-with-wubi.blogspot.ca/2011/08/missing-rootdisk.html
if [[ "$DEBBUG" ]];then # if is needed
    paragraph_os_detected
fi
}

paragraph_os_detected(){
title_gen "$TOTAL_QTY_OF_OS_INCLUDING_WUBI OS detected"
[[ "$DEBBUG" ]] && echo "[debug] $QTY_WUBI Wubi, $QUANTITY_OF_DETECTED_LINUX other Linux, $QUANTITY_OF_DETECTED_MACOS MacOS, $QUANTITY_OF_DETECTED_WINDOWS Windows, $QUANTITY_OF_UNKNOWN_OS unknown type OS."
for ((n=1;n<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;n++)); do
    echo "OS#$n (${OS__TYPE[$n]}):   ${OS__NAME[$n]} on ${OS__PARTITION[$n]#*/dev/}"
done
}

scan_windows_parts() {
#called by determine_part_with_os and repair_bootmgr
#Vista+
WINBCD[$i]=no-b-bcd
WINBOOT[$i]=""
if [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi boot )" ]];then #may be boot or Boot
	for temp in $(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi boot );do
		WINBOOT[$i]="$temp"
		if [[ "$(ls "${BLKIDMNT_POINT[$i]}/$temp/" 2>/dev/null | grep -xi bcd )" ]];then #may be bcd or BCD
			for temp2 in $(ls "${BLKIDMNT_POINT[$i]}/$temp/" 2>/dev/null | grep -xi bcd );do
				WINBCD[$i]="$temp/$temp2"
				break
			done
			break
		fi
	done
fi
[[ -f "${BLKIDMNT_POINT[$i]}/Windows/System32/winload.exe" ]] && WINL[$i]=haswinload || WINL[$i]=no-winload
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi bootmgr )" ]] \
&& WINMGR[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi bootmgr )" || WINMGR[$i]=no-bmgr
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi grldr )" ]] \
&& WINGRL[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi grldr )" || WINGRL[$i]=no-grldr
[[ "${WINBCD[$i]}" != no-b-bcd ]] && [[ "${WINMGR[$i]}" != no-bmgr ]] \
&& WINBOOTPART[$i]=is-winboot || WINBOOTPART[$i]=notwinboot

#xp
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi ntldr )" ]] \
&& WINNT[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi ntldr )" || WINNT[$i]=no-nt

#all
[[ "${WINBCD[$i]}" != no-b-bcd ]] || [[ "${WINNT[$i]}" != no-nt ]] && WINBN[$i]=bcd-or-nt || WINBN[$i]=""
[[ "${WINBCD[$i]}" != no-b-bcd ]] && [[ "${WINNT[$i]}" != no-nt ]] && WINBN[$i]=bcd-and-nt #XP upgraded to Seven http://ubuntuforums.org/showthread.php?t=2042955&page=3

WINXP[$i]=""
WINSE[$i]=""
if ( [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix 'Documents and Settings' )" ]] \
&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix 'System Volume Information' )" ]] ) \
|| [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix boot.ini )" ]] \
&& [[ "${WINL[$i]}" = no-winload ]] && [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix WINDOWS )" ]] \
|| [ -s "${BLKIDMNT_POINT[$i]}/Windows/System32/config/SecEvent.Evt" ] || [ -s "${BLKIDMNT_POINT[$i]}/WINDOWS/system32/config/SecEvent.Evt" ] \
|| [ -s "${BLKIDMNT_POINT[$i]}/WINDOWS/system32/config/secevent.evt" ] || [ -s "${BLKIDMNT_POINT[$i]}/windows/system32/config/secevent.evt" ];then
#&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -ix 'Program Files' )" ]]
	WINXP[$i]=yes #Win2000 has no WINDOWS folder
	(( QUANTITY_OF_REAL_WINDOWS += 1 ))
elif [[ -d "${BLKIDMNT_POINT[$i]}/Windows/System32" ]];then
	WINSE[$i]=yes
	(( QUANTITY_OF_REAL_WINDOWS += 1 ))
fi
[[ "${WINXP[$i]}" ]] || [[ "${WINSE[$i]}" ]] && REALWIN[$i]=yes || REALWIN[$i]=""
#Attention: Win7 +XP
}


################# CHECK RECOVERY OR HIDDEN PARTS #######################
check_recovery_or_hidden() {
local i part f
[[ "$DEBBUG" ]] && echo "[debug] check_recovery_or_hidden"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	part="${LISTOFPARTITIONS[$i]}" #eg /dev/mapper/isw_beaibbhjji_Volume0p1
	f=""
	RECOV[$i]=no-recov-nor-hid
	while read line;do #eg 1:1049kB:21.0GB:21.0GB:ext4::;
		if [[ "$line" =~ / ]];then
			[[ "$line" =~ "${DISK_PART[$i]}:" ]] && [[ "$part" =~ "${DISK_PART[$i]}" ]] && f=ok || f=""
		fi
		[[ "$line" =~ diag ]] || [[ "$line" =~ hidden ]] && [[ "$f" ]] && [[ "${line%%:*}" = "${part##*[a-z]}" ]] \
		&& RECOV[$i]=recovery-or-hidden #may have hidden ESP
	done < <(echo "$PARTEDLM")
	
	while read line;do #eg 1:1049kB:21.0GB:21.0GB:ext4::;
		if [[ "$line" =~ "${LISTOFPARTITIONS[$i]} " ]];then
			[[ "$line" =~ diag ]] || [[ "$line" =~ hidden ]] && RECOV[$i]=recovery-or-hidden
		fi
	done < <(echo "$FDISKL")
	
	[[ "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]} " | grep -i recovery )" ]] \
	|| [[ "$(grep -i recovery <<< "${OSNAME[$i]}" )" ]] && RECOV[$i]=recovery-or-hidden
	[[ "$DEBBUG" ]] && echo "[debug] ls ${BLKIDMNT_POINT[$i]}/ | grep -xi bootmgr (${LISTOFPARTITIONS[$i]})"
	[[ "$(ls "${BLKIDMNT_POINT[$i]}/" 2>/dev/null | grep -xi bootmgr )" ]] && [[ ! -d "${BLKIDMNT_POINT[$i]}/Windows/System32" ]] \
	&& SEPWINBOOT[$i]=yes || SEPWINBOOT[$i]=""
	[[ "${SEPWINBOOT[$i]}" ]] && OSNAME[$i]="${OSNAME[$i]} (boot)"
done
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	for ((f=1;f<=NBOFPARTITIONS;f++)); do
		if [[ "${LISTOFPARTITIONS[$f]}" = "${OS__PARTITION[$i]}" ]];then
			[[ "${RECOV[$f]}" = recovery-or-hidden ]] && OS__RECOORHID[$i]=yes || OS__RECOORHID[$i]=""
			OS__SEPWINBOOOT[$i]="${SEPWINBOOT[$f]}"
			[[ "${OS__SEPWINBOOOT[$i]}" ]] && OS__NAME[$i]="${OS__NAME[$i]} (boot)"
		fi
	done
done
}

######################################### Check location first partition ###############################
check_location_first_partitions() {
local i partition a
for ((i=1;i<=NBOFDISKS;i++)); do
	SECTORS_BEFORE_PART[$i]=0; [[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f "$TMP_FOLDER_TO_BE_CLEARED/sort"
	for partition in $(ls "/sys/block/${LISTOFDISKS[$i]#*/dev/}/" 2>/dev/null | grep "${LISTOFDISKS[$i]#*/dev/}");do
		echo "$(cat "/sys/block/${LISTOFDISKS[$i]#*/dev/}/${partition#*/dev/}/start" )" >> $TMP_FOLDER_TO_BE_CLEARED/sort
	done
	echo 2048 >> $TMP_FOLDER_TO_BE_CLEARED/sort # Save maximum 2048 sectors (in case the first partition is far)
	a=$(cat "$TMP_FOLDER_TO_BE_CLEARED/sort" | sort -g -r | tail -1 )  #sort the file in the increasing order
	[[ "$(grep "^[0-9]\+$" <<< $a )" ]] && SECTORS_BEFORE_PART[$i]="$a" || SECTORS_BEFORE_PART[$i]="1" # Save minimum 1 sector (the MBR)
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/sort
	echo "$(stat -c %B ${LISTOFDISKS[$i]})" > ${TMP_FOLDER_TO_BE_CLEARED}/sort
	echo 512 >> $TMP_FOLDER_TO_BE_CLEARED/sort # Save minimum 512 bytes/sector (in case there is a problem with stat)
	BYTES_PER_SECTOR[$i]=$(cat "$TMP_FOLDER_TO_BE_CLEARED/sort" | sort -g | tail -1 ) 
	[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/sort
	BYTES_BEFORE_PART[$i]=$((${SECTORS_BEFORE_PART[$i]}*${BYTES_PER_SECTOR[$i]}))
	[[ "$DEBBUG" ]] && echo "[debug] BYTES_BEFORE_PART[$i] (${LISTOFDISKS[$i]}) = ${SECTORS_BEFORE_PART[$i]} sectors * ${BYTES_PER_SECTOR[$i]} bytes = ${BYTES_BEFORE_PART[$i]} bytes."
done
}

######################################### Mount / Unmount functions ###############################
mount_all_blkid_partitions_except_df() {
local i j temp MOUNTCODE
[[ "$DEBBUG" ]] && echo "[debug]Mount all blkid partitions except the ones already mounted and BIOS_Boot"
MOUNTERROR=""
#Define BLKIDMNT_POINT[$i] and try to mount all partitions
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	#already mounted partitions
	if [[ "${LISTOFPARTITIONS[$i]}" = "$CURRENTSESSIONPARTITION" ]];then
		BLKIDMNT_POINT[$i]=""
	elif [[ "$(blkid | grep "${LISTOFPARTITIONS[$i]}:" | grep zfs_member )" ]];then
		if [[ "$(df -Th / | grep zfs )" ]];then
			[[ "$(echo "$FDISKL" | grep "${LISTOFPARTITIONS[$i]} " | grep boot)" ]] && BLKIDMNT_POINT[$i]="/boot" || BLKIDMNT_POINT[$i]=""
		else
			[[ "$(echo "$FDISKL" | grep "${LISTOFPARTITIONS[$i]} " | grep boot)" ]] && BLKIDMNT_POINT[$i]="/mnt/boot-sav/zfs/boot" || BLKIDMNT_POINT[$i]="/mnt/boot-sav/zfs"
		fi
	else
		BLKIDMNT_POINT[$i]="$(findmnt -n -o TARGET "${LISTOFPARTITIONS[$i]}" | grep -v snap)"
	fi
	#Try to unmount in order to remove special mount points
	if [[ "${BLKIDMNT_POINT[$i]}/" =~ " " ]] || [[ "${BLKIDMNT_POINT[$i]}/" =~ "&" ]] || [[ "${BLKIDMNT_POINT[$i]}/" =~ "\\" ]];then
		PART1="${LISTOFPARTITIONS[$i]#*/dev/}"; update_translations
		text="$This_will_mount_PART1_to_new_mountpoint_without_special_characters $Do_you_want_to_continue"
		if [[ "$GUI" ]];then
			echo "$text"
			end_pulse
			zenity --width=400 --question --title="$APPNAME2" --text="$text" 2>/dev/null || userok=""
			start_pulse
		else
			read -r -p "$text [yes/no] " response
			[[ ! "$response" =~ y ]] && userok=""
		fi
		[[ "$userok" ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$text
Unmount ${LISTOFPARTITIONS[$i]#*/dev/} from ${BLKIDMNT_POINT[$i]}/ to avoid special characters (& or \\ or space) incompatibilities
$(umount "${BLKIDMNT_POINT[$i]}")"
		BLKIDMNT_POINT[$i]="$(findmnt -n -o TARGET "${LISTOFPARTITIONS[$i]}" | grep -v snap)"
	fi
	#Mount partitions
	if [[ ! "${BLKIDMNT_POINT[$i]}" ]] && [[ "${LISTOFPARTITIONS[$i]}" != "$CURRENTSESSIONPARTITION" ]];then
		BLKIDMNT_POINT[$i]="/mnt/boot-sav/${LISTOFPARTITIONS[$i]#*/dev/}"
		mkdir -p "${BLKIDMNT_POINT[$i]}/"
		if [[ "$(echo "$BLKID" | grep btrfs | grep "${LISTOFPARTITIONS[$i]}:" )" ]];then
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
BTRFS detected on ${LISTOFPARTITIONS[$i]#*/dev/}
ls ${LISTOFPARTITIONS[$i]}:
$(ls ${BLKIDMNT_POINT[$i]})
---
mount ${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]}/ $(mount ${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]}/ 2>/dev/null)"
			MOUNTCODE="$?"
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
MOUNTCODE=$MOUNTCODE
---
os-prober before @ subvol mount:
$(os-prober)
---"
			if [[ -d "${BLKIDMNT_POINT[$i]}/@" ]];then
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
umount ${BLKIDMNT_POINT[$i]}
$(umount "${BLKIDMNT_POINT[$i]}")
---
mount -t btrfs -o subvol=@ ${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]}/ $(mount -t btrfs -o subvol=@ ${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}/")
---"
				MOUNTCODE="$?"
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
MOUNTCODE=$MOUNTCODE
os-prober after @ subvol mount:
$(os-prober)
---"
			fi
		else
			mount ${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}/" 2>/dev/null
			MOUNTCODE="$?"
		fi
		if [[ "$MOUNTCODE" != 0 ]] && [[ "$(blkid ${LISTOFPARTITIONS[$i]} | grep ntfs)" ]];then #https://bugs.launchpad.net/ubuntu/+source/util-linux/+bug/1064928
			#hiberfile.sys at root of windows disc
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
mount -t ntfs-3g -o remove_hiberfile ${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]} $(mount -t ntfs-3g -o remove_hiberfile ${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}")"
			MOUNTCODE="$?"
		fi
		if [[ "$MOUNTCODE" != 0 ]];then
			mount -r ${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}" 2>/dev/null
			[[ "$DEBBUG" ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Error code $MOUNTCODE
mount -r ${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]} $(mount -r ${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}")" \
			&& MOUNTCODE="$?"
			if [[ "$DEBBUG" ]] && [[ "$MOUNTCODE" != 0 ]];then
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
mount -r ${LISTOFPARTITIONS[$i]} : Error code $MOUNTCODE"
				[[ "$(echo "$BLKID" | grep ext | grep "${LISTOFPARTITIONS[$i]}:" )" ]] && MOUNTERROR="$MOUNTCODE" #http://ubuntuforums.org/showthread.php?t=2068280
			fi
		fi
	fi
	#Define OS__MNT_PATH[$j]
	[[ "$DEBBUG" ]] && echo "[debug]BLKIDMNT_POINT of ${LISTOFPARTITIONS[$i]#*/dev/} is: ${BLKIDMNT_POINT[$i]}"
	for ((j=1;j<=TOTAL_QUANTITY_OF_OS;j++)); do
		if [[ "${LISTOFPARTITIONS[$i]}" = "${OS__PARTITION[$j]}" ]];then
			OS__MNT_PATH[$j]="${BLKIDMNT_POINT[$i]}"
			[[ "$DEBBUG" ]] && echo "[debug]Mount path of ${OS__PARTITION[$j]} is: ${OS__MNT_PATH[$j]}"
		fi
	done
done
}

#start_kill_nautilus() {
#avoid popups when mounting partitions, used in pastebinaction
#local i
#while true; do pkill nautilus; pkill caja; sleep 0.15; done &
#pid_kill_nautilus=$!
#}

#end_kill_nautilus() {
#kill ${pid_kill_nautilus}
#}

#Used by : repair, uninstaller, before, after
unmount_all_blkid_partitions_except_df() {
local i
[[ "$DEBBUG" ]] && echo "[debug]Unmount all blkid partitions except df ones"
pkill pcmanfm	#To avoid it automounts
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ "${BLKIDMNT_POINT[$i]}/" =~ /mnt/boot-sav ]] \
	&& [[ ! "$(mount | grep "${LISTOFPARTITIONS[$i]} " | grep "subvol=" | grep -v 'subvol=/)' | grep -v 'subvol=/,' )" ]];then #&& [[ ! "${BLKIDMNT_POINT[$i]}/" =~ sav/zfs ]]
		[[ "$DEBBUG" ]] && echo "[debug] unmount ${BLKIDMNT_POINT[$i]}"
		umount "${BLKIDMNT_POINT[$i]}"
	fi
done
}



echo_df_and_fdisk() {
#blkid_fdisk_and_parted_update
title_gen "df -Th (filtered)"
while read line; do #dont hide /cdrom to identify live disc more easily
	[[ ! "$line" =~ '/dev/loop' ]] && echo "$line"
done < <(LANGUAGE=C LC_ALL=C df -Th | sed -e '/^$/d' -e '/tmpfs/d' )
title_gen "fdisk -l (filtered)"
while read line; do
    [[ "$line" ]] && [[ ! "$line" =~ 'Sector size (' ]] && [[ ! "$line" =~ 'I/O size (' ]] && [[ ! "$line" =~ 'Units:' ]] && [[ ! "$line" =~ 'Disk /dev/loop' ]] && echo "$line"
done < <(LANGUAGE=C LC_ALL=C fdisk -l 2>/dev/null )
}

echo_blkid() {
title_gen "blkid (filtered)"
LANGUAGE=C LC_ALL=C blkid | sed -e '/^$/d' -e '/quashfs/d'
}

############################# CHECKS IF TMP/MBR IS GRUB TYPE OR NOT #############################################
check_if_tmp_mbr_is_grub_type() {
if [[ -f $1 ]];then
	[[ "$(dd if=$1 bs=446 count=1 | hexdump -e \"%_p\" | grep -i GRUB )" ]] && MBRCONTAINSGRUB=true || MBRCONTAINSGRUB=false
else
	MBRCONTAINSGRUB=error; echo "Error : $1 does not exist, so we cannot check type."
fi
}

