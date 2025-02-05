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


######################### CHECK INTERNET CONNECTION ####################
check_internet_connection() {
[[ "$DISABLEWEBCHECK" ]] || [[ "$(ping -c1 google.com)" ]] && INTERNET=connected || INTERNET=no-internet
#[[ "$(wget -T $WGETTIM -q -O - checkip.dyndns.org)" =~ "Current IP Address:" ]]
[[ "$DEBBUG" ]] && echo "[debug]internet: $INTERNET"
}

ask_internet_connection() {
if [[ "$INTERNET" != connected ]];then
    if [[ ! "$FORCEYES" ]];then
        if [[ "$GUI" ]];then
            end_pulse
            zenity --width=400 --info --title="$APPNAME2" --text="$Please_connect_internet $Then_close_this_window" 2>/dev/null
            start_pulse
        else
            read -r -p "$Please_connect_internet [Enter]"
        fi
    fi
	check_internet_connection
fi
}

exit_as_packagelist_is_missing() {
end_pulse
update_translations
echo "$please_install_PACKAGELIST"
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r $TMP_FOLDER_TO_BE_CLEARED
choice=exit; [[ "$GUI" ]] && echo 'EXIT@@' || exit 0
}

################################# CRYPT ##################################
#http://ubuntuforums.org/showthread.php?p=4530641
propose_decrypt() {
CRYPTPART="$(blkid | grep crypto_LUKS | grep -vi swap)"
if [[ "$CRYPTPART" ]];then
	ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$(title_gen "blkid (filtered) with crypto_LUKS")

$(blkid | sed -e '/^$/d' -e '/quashfs/d' )" #remove blank / squash lines
	FUNCTION=LUKS; PACKAGELIST=cryptsetup; FILETOTEST=cryptsetup
	CRYPTPART="${CRYPTPART%%:*}" #eg /dev/sda3
	update_translations
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	if [[ ! "$(type -p $FILETOTEST)" ]];then
		text="$Encryption_detected $You_may_want_to_retry_after_installing_PACKAGELIST"
		echo "$text"
		end_pulse
		[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$text" 2>/dev/null
		start_pulse
	fi
	modprobe dm-crypt #maybe not necessary on recent live discs
	#try to propose decrypt only when necessary
	#vgubuntu-root is frequent case (default for encrypted lvm). Might want to add other frequent cases (eg default for other distribs)
	if [[ "$(type -p $FILETOTEST)" ]] && [[ ! "$(os-prober | grep -v Windows | grep -vi Mac)" ]] \
	&& [[ ! "$(cryptsetup status /dev/mapper/vgubuntu-root | grep 'is activ' )" ]];then
		text="$You_may_want_decrypt (cryptsetup open)" #https://ubuntuforums.org/showthread.php?t=2470405&p=14081645#post14081645
		echo "$text"
		end_pulse
		[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$text" 2>/dev/null
		start_pulse
	fi
fi
}


################################# LVM ##################################
activate_lvm_if_needed() {
#After fresh lvm install, in installed session blkid returns sda1: PARTLABEL="EFI System Partition", sda2 TYPE="LVM2_member",
# /dev/mapper/vgubuntu-root: UUID="..." TYPE="ext4", and /dev/mapper/vgubuntu-swap_1
#parted -lms returns sda1=esp, sda2=lvm, /dev/mapper/vgubuntu-root (and swap) are considered as loop disks
#fdisk returns sda1 =EFI, sda2= LVM Linux, /dev/mapper/vgubuntu-root is disk
local FUNCTION=LVM PACKAGELIST=lvm2 FILETOTEST=vgchange
BLKID=$(blkid)
ECHO_LVM_RAID_PREPAR=""
if [[ "$DISTRIB_DESCRIPTION" =~ Unknown ]] || [[ "$(lsb_release -cs)" =~ squeeze ]] && [[ "$BLKID" =~ LVM ]];then
	FUNCTION=LVM; FUNCTION44=LVM; DISK44="Boot-Repair-Disk (www.sourceforge.net/p/boot-repair-cd/home)"; update_translations
	end_pulse
    echo "$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok"
	[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok" 2>/dev/null
	choice=exit
elif [[ "$BLKID" =~ LVM ]];then
	BEFLVMBLKID="$BLKID"
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	if [[ ! "$(type -p $FILETOTEST)" ]];then
        choice=exit
    else
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$(title_gen "blkid (filtered) before lvm activation")

$(blkid | sed -e '/^$/d' -e '/quashfs/d' )" #remove blank / squash lines
        # Not sure if modprobe and vgscan are necessary
        ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(title_gen "LVM activation")

modprobe dm-mod  $(modprobe dm-mod)
vgscan --mknodes
$(vgscan --mknodes)
vgchange -ay
$(vgchange -ay)
lvscan
$(LANGUAGE=C LC_ALL=C lvscan)
blkid -g
$(blkid -g)"
        BLKID=$(blkid)
        [[ "$BEFLVMBLKID" != "$BLKID" ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Successfully activated LVM.

$(title_gen "blkid (filtered) after lvm activation")

$(blkid | sed -e '/^$/d' -e '/quashfs/d' )" #remove blank / squash lines
    fi
fi
}

################################# RAID #################################
activate_raid_if_needed() {
raiduser=no
if [[ "$DISTRIB_DESCRIPTION" =~ Unknown ]] || [[ "$(lsb_release -cs)" =~ squeeze ]] && [[ "$BLKID" =~ raid ]];then #|| [[ "$DISTRIB_DESCRIPTION" =~ Boot-Repair-Disk ]]
	FUNCTION=RAID; FUNCTION44=RAID; DISK44="Boot-Repair-Disk (www.sourceforge.net/p/boot-repair-cd/home)"; update_translations
	end_pulse
    echo "$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok"
	[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok" 2>/dev/null
	choice=exit
elif [[ "$BLKID" =~ raid ]] || [[ "$(echo "$BLKID" | grep /dev/mapper/ | grep -v swap  | grep -vi LVM | grep -v mapper/vg)" ]];then
	raiduser=yes
	if [[ ! "$BLKID" =~ raid ]];then
        if [[ ! "$FORCEYES" ]];then
            if [[ "$GUI" ]];then
                end_pulse
                zenity --width=400 --question --title="$APPNAME2" --text="$Is_there_RAID_on_this_pc" 2>/dev/null || raiduser=no
            else
                read -r -p "$Is_there_RAID_on_this_pc [yes/no] " response
                [[ ! "$response" =~ y ]] && raiduser=no
            fi
        fi
        [[ "$DEBBUG" ]] && echo "$Is_there_RAID_on_this_pc $raiduser"
        USERCHOICES="$USERCHOICES
Is there RAID on this computer? $raiduser"
		[[ "$raiduser" = yes ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Unusual RAID (no raid in blkid)." #zenity --width=400 --warning --title="$APPNAME2" --text="Unusual RAID. $PLEASECONTACT" 2>/dev/null
		start_pulse
	fi
	if [[ "$raiduser" = yes ]];then
		local FUNCTION=RAID PACKAGELIST=mdadm; FILETOTEST=mdadm removedmraid=yes
		DMRAID=""
		MD_ARRAY=""
		BEFRAIDBLKID="$BLKID"
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$(title_gen "blkid (filtered) before raid activation")

$(blkid | sed -e '/^$/d' -e '/quashfs/d' )" #remove blank / squash lines
		[[ "$(type -p dmraid)" ]] && INIT_DMR=y || INIT_DMR=""
		if [[ "$INIT_DMR" ]];then
			assemble_dmraid
			[[ ! "$DMRAID" ]] && propose_remove_dmraid #mdadm & dmraid interfere: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=534274
		fi
		[[ ! "$(type -p mdadm)" ]] && installpackagelist
		assemble_mdadm #software raid
		if [[ ! "$INIT_DMR" ]] && [[ ! "$MD_ARRAY" ]];then
			[[ "$(type -p mdadm)" ]] && PACKAGELIST=dmraid || PACKAGELIST="dmraid/mdadm"
			update_translations
			text="$FUNCTION_detected $You_may_want_to_retry_after_installing_PACKAGELIST"
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$text"
			end_pulse
			[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$text" 2>/dev/null
			start_pulse
		fi
		[[ ! "$INIT_DMR" ]] && assemble_dmraid
		
		[[ "$DEBBUG" ]] && echo "[debug]$(type -p dmraid) , MDADM $(type -p mdadm)"
		[[ "$BLKID" =~ raid ]] || [[ ! "$BLKID" =~ LVM ]] && [[ ! "$(type -p dmraid)" ]] && [[ ! "$(type -p mdadm)" ]] && choice=exit
		if [[ ! "$DMRAID" ]] && [[ ! "$MD_ARRAY" ]] && [[ "$choice" != exit ]];then
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Warning: no active raid (DMRAID nor MD_ARRAY)."
			[[ ! "$BLKID" =~ LVM ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
No active RAID." && [[ "$GUI" ]] && zenity --width=400 --warning --text="No active RAID." 2>/dev/null
		fi
		BLKID=$(blkid)
		[[ "$BEFRAIDBLKID" != "$BLKID" ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Successfully activated RAID.

$(title_gen "blkid (filtered) after raid activation")

$(blkid | sed -e '/^$/d' -e '/quashfs/d' )" #remove blank / squash lines
	fi
fi
}

propose_remove_dmraid() {
if [[ "$(type -p dmraid)" ]] && [[ "$APPNAME" =~ re ]];then	#http://ubuntuforums.org/showthread.php?t=1551087
    if [[ ! "$FORCEYES" ]];then
        if [[ "$GUI" ]];then
            end_pulse
            zenity --width=400 --question --title="$APPNAME2" --text="$dmraid_may_interfere_MDraid_remove" 2>/dev/null || removedmraid=no
            start_pulse
        else
            read -r -p "$dmraid_may_interfere_MDraid_remove [yes/no] " response
            [[ ! "$response" =~ y ]] && removedmraid=no
        fi
    fi
	[[ "$DEBBUG" ]] && echo "$dmraid_may_interfere_MDraid_remove $removedmraid"
    USERCHOICES="$USERCHOICES
[dmraid] packages may interfere with MDraid. Do you want to remove them? $removedmraid"
	if [[ "$removedmraid" = no ]];then
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
User chose to keep dmraid. It may interfere with mdadm."
	else
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
$PACKMAN remove $PACKYES dmraid
$($PACKMAN remove $PACKYES dmraid)"
		if [[ "$(type -p mdadm)" ]];then
			text="It is now recommended to reinstall mdadm. Please continue when done."
            if [[ ! "$FORCEYES" ]];then
                if [[ "$GUI" ]];then
                    echo "$text"
                    end_pulse
                    zenity --width=400 --info --title="$APPNAME2" --text="$text" 2>/dev/null
                    start_pulse
                else
                    read -r -p "$text [Enter]"
                fi
            else
                ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
It is recommended to reinstall mdadm after removing dmraid. You can check in interactive mode."
            fi
		fi
	fi
fi
}

assemble_dmraid() {
if [[ "$(type -p dmraid)" ]];then
	#end_pulse
	#zenity --width=400 --question --title="$APPNAME2" --text="${FUNCTION_detected} ${activate_dmraid} (dmraid -ay; dmraid -sa -c)" 2>/dev/null || dmraidenable="no"
	#start_pulse
	#if [[ ! "$dmraidenable" ]]; then
		DMRAID="$(dmraid -si -c)"
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(title_gen "dmraid")

dmraid -si -c
$DMRAID"
		if [[ "$DMRAID" =~ "no raid disk" ]];then
			DMRAID=""
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
No DMRAID disk."
		else
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
dmraid -ay:
$(dmraid -ay)"	#Activate RAID
			DMRAID="$(dmraid -sa -c)"
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
dmraid -sa -c:
$DMRAID"	#e.g. isw_bcbggbcebj_ARRAY
		fi
	#fi
fi
}	

assemble_mdadm() {
if [[ "$(type -p mdadm)" ]];then
    #Assemble all arrays
	ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(title_gen "mdadm")
mdadm --assemble --scan
$(mdadm --assemble --scan)"
	# All arrays.
	MD_ARRAY=$(mdadm --detail --scan) #TODO  | ${AWK} '{ print $2 }')
	ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
mdadm --detail --scan
$MD_ARRAY"
	#for MD in ${MD_ARRAY}; do
	#	MD_SIZE=$(fdisks ${MD})     # size in blocks
	#	MD_SIZE=$((2*${MD_SIZE}))   # size in sectors
	#	MDNAME=${MD:5}
	#	MDMOUNTNAME="MDRaid/${name}"
	#	echo "MD${MD}: ${MDNAME}, ${MDMOUNTNAME}, ${MD_SIZE}"
	#done
fi
}


################################# ZFS ##################################
activate_zfs_if_needed() {
#example blkid:  /dev/sda6        12215859673123677634                   zfs_member bpool
#ex2:			 /dev/sda7        9932272560944743958                    zfs_member rpool
#https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Stretch%20Root%20on%20ZFS.html#rescuing-using-a-live-cd
local FUNCTION=ZFS PACKAGELIST=zfsutils-linux FILETOTEST=zpool
if [[ "$BLKID" =~ zfs ]];then
	BEFZFSMOUNT="$(findmnt -n -o TARGET | grep zfs | grep -v snap)"
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	if [[ ! "$(type -p $FILETOTEST)" ]];then
		choice=exit
	elif [[ "$LIVESESSION" != live ]] && [[ "$(findmnt -n -o FSTYPE / | grep zfs | grep -v snap )" ]];then #Root in zfs pool
		SUCCESSACTZFS=yes
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(title_gen "Installed session with Root on ZFS")

zpool list $(LANGUAGE=C LC_ALL=C zpool list)

$(LANGUAGE=C LC_ALL=C findmnt -D | grep % | sed -e '/tmpfs/d' -e '/loop/d' | grep -v snap )

"
	else
		ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(title_gen "ZFS activation")

$PACKVERSION zfsutils-linux : $($PACKVERSION zfsutils-linux )
zpool export -f -a $(zpool export -f -a)
"
		if [[ ! "$(LANGUAGE=C LC_ALL=C zpool list)" =~ 'o pools available' ]];then
			SUCCESSACTZFS=no
			echo "$zfs_already_activated_please_retry"
			if [[ "$GUI" ]];then
				end_pulse
				zenity --width=400 --error --text="$zfs_already_activated_please_retry" 2>/dev/null
			fi
			choice=exit
		else
			SUCCESSACTZFS=yes #default
			[[ "$DEBBUG" ]] && ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR

$(LANGUAGE=C LC_ALL=C findmnt -D | grep % | sed -e '/tmpfs/d' -e '/loop/d' | grep -v snap )

zpool list before activation $(LANGUAGE=C LC_ALL=C zpool list)
zfs list $(LANGUAGE=C LC_ALL=C zfs list)
"
			#mkdir -p /mnt/boot-sav/zfs/boot/efi
			#mkdir -p /mnt/boot-sav/zfs/boot/grub
			#https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bullseye%20Root%20on%20ZFS.html#rescuing-using-a-live-cd
			#https://ubuntuforums.org/showthread.php?t=2470405&p=14117568#post14117568
			rpool_name="$(lsblk -o NAME,FSTYPE,LABEL | grep -v '/snap/\|loop\|sr0' | grep 'zfs_member' | grep 'rpool' | awk '{print $3}' )"
			bpool_name="$(lsblk -o NAME,FSTYPE,LABEL | grep -v '/snap/\|loop\|sr0' | grep 'zfs_member' | grep 'bpool' | awk '{print $3}' )"
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
zpool import -N -R /mnt $rpool_name $(zpool import -N -R /mnt $rpool_name)
zpool import -N -R /mnt $bpool_name $(zpool import -N -R /mnt $bpool_name)"

			#probably redundant with above, but ensures cases where label does not contain rpool nor bpool
			POOLLIST=""
			for i in $(LANGUAGE=C LC_ALL=C zpool import | grep 'pool:' | sed 's/pool: //g'); do
				POOLLIST="$i $POOLLIST"
#				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
#zpool import -f -D $i tmp$i $(LANGUAGE=C LC_ALL=C zpool import -f -D $i tmp$i)
#zpool import -f $i tmp$i $(LANGUAGE=C LC_ALL=C zpool import -f $i tmp$i)
#zfs set mountpoint=/mnt/boot-sav/zfs tmp$i $(LANGUAGE=C LC_ALL=C zfs set mountpoint=/mnt/boot-sav/zfs tmp$i)
#zfs mount tmp$i $(LANGUAGE=C LC_ALL=C zfs mount tmp$i)"
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
zpool import -N -f -R /mnt/boot-sav/zfs $i $(zpool import -N -f -R /mnt/boot-sav/zfs $i)"
			done
			
			#https://ubuntuforums.org/showthread.php?t=2488546&p=14151714#post14151714 
			#before zfs load-key: https://forum.ubuntu-fr.org/viewtopic.php?pid=22546884#p22546884
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
cryptsetup -v open /dev/zvol/rpool/keystore zfskey $(cryptsetup -v open /dev/zvol/rpool/keystore zfskey)"
			#https://ubuntuforums.org/showthread.php?t=2488546&p=14151714#post14151714
			if  [[ "$(ls /dev/mapper 2>/dev/null | grep zfskey)" ]];then
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
sudo mount /dev/mapper/zfskey $(sudo mount /dev/mapper/zfskey)"
				for key in $(ls /media 2>/dev/null | grep '.key');do
					ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
cat /media/${key} | zfs load-key -L prompt rpool $(cat /media/${key} | zfs load-key -L prompt rpool)"
				done
			fi
			#https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bullseye%20Root%20on%20ZFS.html#rescuing-using-a-live-cd
			#probably redundant with above zfs load-key -L prompt rpool $(cat /media/${key}
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
zfs load-key -a $(zfs load-key -a)"
#			if [[ "$GUI" ]];then
#				end_pulse
#				zenity --width=400 --info --text="If needed, type 'sudo zfs load-key -a' in a terminal, then close this window." 2>/dev/null
#				start_pulse
#			else
#				read -r -p "If needed, type 'sudo zfs load-key -a' in another terminal, then press [Enter] here to proceed."
#			fi

			RTPL="$(zfs list | grep ROOT/ | grep v/zfs | grep -v zfs/ )"
			RTPL="${RTPL%% *}" # eg. tmprpool/ROOT/ubuntu_64fs0l
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
zfs mount $RTPL $(zfs mount $RTPL)
zfs mount -a $(zfs mount -a)"
			AFTZFSMOUNT="$(findmnt -n -o TARGET | grep zfs | grep -v snap)"
			for i in $POOLLIST;do #bpool rpool
				[[ "$DEBBUG" ]] && echo "[debug] Checking if $i is mounted."
				[[ ! "$(findmnt -n -o SOURCE | grep -v snap )" =~ "${i}/" ]] && echo "$i missing in findmnt." && SUCCESSACTZFS=no
			done
			[[ "$AFTZFSMOUNT" = "$BEFZFSMOUNT" ]] && SUCCESSACTZFS=no
			if [[ "$SUCCESSACTZFS" = yes ]];then
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Successfully activated ZFS."
			else
				ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
Error: could not activate ZFS. $PLEASECONTACT"
			fi
			ECHO_LVM_RAID_PREPAR="$ECHO_LVM_RAID_PREPAR
zpool list after activation
$(LANGUAGE=C LC_ALL=C zpool list)

zfs list
$(LANGUAGE=C LC_ALL=C zfs list)
$(title_gen "findmnt (filtered) after ZFS activation")

$(LANGUAGE=C LC_ALL=C findmnt -D | grep % | sed -e '/tmpfs/d' -e '/loop/d' | grep -v snap )

"
		fi
	fi
fi
}
