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


####################### PURGE GRUB #####################################
grub_purge() {
SEVERALCOMMANDS=""
COMMAND=""
PURGEDONE=""
SOURCERROR=""
echo "Purge the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]}"
grub_purge_extra
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_the_grub_of ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}. $This_may_require_several_minutes''')"
[[ "$GUI" ]] && echo "SET@_purgewindow.set_title('''$APPNAME2''')"
[[ "$GUI" ]] && echo "SET@_purgewindow.set_icon_from_file('''x-$APPNAME.png''')"
#cp "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" $LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]}/grub_before_purge #Security
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_the_grub_of ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (tst). $This_may_require_several_minutes''')"
# Check if $GRUBPACKAGE (grub-efi or grub2 or grub-efi-amd64-signed) is available in the reps
userok=yes
if [[ "$GRUBPACKAGE" =~ efi ]];then
	testvalidsource $GRUBPACKAGE
	if [[ ! "$VALIDSOURCE" ]];then
		testvalidsource grub-efi
		if [[ "$VALIDSOURCE" ]];then
			echo "GRUBPACKAGE becomes grub-efi"
			GRUBPACKAGE=grub-efi
		else
			testvalidsource grub2-efi
			if [[ "$VALIDSOURCE" ]];then
				echo "GRUBPACKAGE becomes grub2-efi"
				GRUBPACKAGE=grub2-efi
			fi
		fi
	fi
elif [[ "$GRUBPACKAGE" = grub ]];then
	testvalidsource grub-legacy
	if [[ "$VALIDSOURCE" ]];then
		echo "GRUBPACKAGE becomes grub-legacy"
		GRUBPACKAGE=grub-legacy
	else
		testvalidsource grub
	fi
else
	testvalidsource grub-pc
	if [[ "$VALIDSOURCE" ]];then
		GRUBPACKAGE=grub-pc #I experienced a case where grub2 install fails but grub-pc works
	else
		testvalidsource grub2
		if [[ ! "$VALIDSOURCE" ]];then
			testvalidsource grub
			if [[ "$VALIDSOURCE" ]];then
				echo "GRUBPACKAGE becomes grub"
				GRUBPACKAGE=grub
                if [[ ! "$FORCEYES" ]];then
                    text="$This_will_install_an_obsolete_bootloader (GRUB Legacy). $Do_you_want_to_continue"
                    if [[ "$GUI" ]];then
                        echo "$text"
                        end_pulse
                        zenity --width=400 --question --title="$APPNAME2" --text="$text" 2>/dev/null || userok=""
                    else
                        read -r -p "$text [yes/no] " response
                        [[ ! "$response" =~ y ]] && userok=""
                    fi
                fi
			fi
		fi
	fi
fi
if [[ "$VALIDSOURCE" ]] && [[ "$userok" ]];then
	[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_the_grub_of ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (dwn). $This_may_require_several_minutes''')"
	# Pre-download the packages before purging them (security in case of internet failure just after purge)
	#if [[ "$GRUBPACKAGE" = grub2 ]] || [[ "$GRUBPACKAGE" = grub-pc ]];then
	#	check_deb_install_feasibility "grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common"
	#elif [[ "$GRUBPACKAGE" =~ efi ]];then
	#	check_deb_install_feasibility "efibootmgr grub-efi-ia32 grub-efi-amd64 grub-efi-ia32-bin grub-efi-amd64-bin"
	#fi
	#check_deb_install_feasibility "$GRUBPACKAGE grub-common ucf debconf"
	check_deb_install_feasibility "$GRUBPACKAGE"
	echo "DEBCHECK $DEBCHECK"
fi
if [[ ! "$VALIDSOURCE" ]] || [[ ! "$userok" ]] || [[ "$DEBCHECK" = debNG ]];then
	end_pulse
	[[ ! "$userok" ]] && echo "User cancelled purge." || purge_cancelled $GRUBPACKAGE
	restore_resolvconf_and_unchroot
	[[ "$GUI" ]] && echo 'SET@_mainwindow.show()'
else
	[[ "$GUI" ]] && echo 'SET@_hbox_kernelpurgebuttons.hide()';
    [[ "$GUI" ]] && echo 'SET@_hbox_grubpurgebuttons.show()'
	if [[ "${GRUBTYPE_OF_PART[$USRPART]}" != nogrubinstall ]];then
		GPURGEPACKS=""
		#on 14.04 , if grub*, then E: Unable to locate package grub-reinstall_programs,
		if [[ "${APTTYP[$USRPART]}" ]];then
			COMMAND=""
			[[ -d "${BLKIDMNT_POINT[$USRPART]}/usr/share/lupin-support" ]] || [[ -d "${BLKIDMNT_POINT[$USRPART]}/share/lupin-support" ]] \
			&& COMMAND="sudo ${CHROOTUSR}${APTTYP[$USRPART]} ${PURGETYP[$USRPART]} ${YESTYP[$USRPART]} lupin-s*\\n$COMMAND"
			for ppack in grub2-common:* grub-common:* shim-signed grub2-com* grub-com* ;do
				#[[ "$(sudo ${CHROOTUSR}${PACKVERTYP[$USRPART]} 'grub-common' 2>/dev/null)" ]] && GPURGEPACKS="$GPURGEPACKS grub-common"
				COMMAND="sudo ${CHROOTUSR}${APTTYP[$USRPART]} ${PURGETYP[$USRPART]} ${YESTYP[$USRPART]} $ppack\\n$COMMAND"
				#[[ "$(sudo ${CHROOTUSR}dpkg -l | grep 'grub2-common:')" ]] && GPURGEPACKS="$GPURGEPACKS grub2-common:*"
			done
			#+ bug#1405174 obsolete since grub-common:i386 absent from xenial https://forum.ubuntu-fr.org/viewtopic.php?id=2049789
			#testvalidsource linux-signed-generic
			#[[ "$VALIDSOURCE" ]] && GPURGEPACKS="$GPURGEPACKS linux-signed*"
			#COMMAND="sudo ${CHROOTUSR}${APTTYP[$USRPART]} ${PURGETYP[$USRPART]} ${YESTYP[$USRPART]}$GPURGEPACKS"
			#[[ "${APTTYP[$USRPART]}" != apt-get ]] && COMMAND="sudo ${CHROOTUSR}${APTTYP[$USRPART]} ${PURGETYP[$USRPART]} ${YESTYP[$USRPART]}grub*-common:i386\\n$COMMAND"
			add_dpkgconf_to_command
			echo "Please type: $COMMAND"
			if [[ "$GUI" ]];then
				echo 'SET@_image_purgegrub.show()'; echo 'SET@_image_installgrub.hide()'
				echo 'SET@_button_cancelpurgegrub.show()'; echo 'SET@_button_nextpurgegrub.show()'
				echo 'SET@_button_abortinstallgrub.hide()'; echo 'SET@_button_nextinstallgrub.hide()'
				[[ "$SEVERALCOMMANDS" ]] && echo "SET@_label8.set_text('''$Please_open_a_terminal_then_type_the_following_commands''')" \
				|| echo "SET@_label8.set_text('''$Please_open_a_terminal_then_type_the_following_command''')"
				echo "SET@_label9.set_text('''$COMMAND''')"
				if [[ "${DOCGRUB[$USRPART]}" =~ pc ]] && [[ "$GRUBPACKAGE" != grub ]];then
					echo "SET@_label10.set_text('''\\n$Then_choose_Yes_if_the_below_window_appears\\n''')"
					echo 'SET@_image_purgegrub.show()'
				else
					echo "SET@_label10.set_text('''\\n''')"
					echo 'SET@_image_purgegrub.hide()'
				fi
			fi
		else
			echo "Please purge grub*-common* packages from ${BLKIDMNT_POINT[$USRPART]}."
			if [[ "$GUI" ]];then
				echo 'SET@_image_purgegrub.show()'; echo 'SET@_image_installgrub.hide()'
				echo 'SET@_button_cancelpurgegrub.show()'; echo 'SET@_button_nextpurgegrub.show()'
				echo 'SET@_button_abortinstallgrub.hide()'; echo 'SET@_button_nextinstallgrub.hide()'
				echo "SET@_label8.set_text('''Please purge grub*-common* packages from ${BLKIDMNT_POINT[$USRPART]}.''')"
				echo "SET@_label9.set_text(''' ''')"
			fi
		fi
		PURGEDONE=yes
	else #GRUB already missing
		then_type_this_purge_command
	fi
	end_pulse
	[[ "$GUI" ]] && echo 'SET@_purgewindow.show()'
fi
}

testvalidsource() {
local PACKTOVALIDATE="$1" temp
temp="$(LANGUAGE=C LC_ALL=C $CHROOTCMD${POLICYTYP[$USRPART]} $PACKTOVALIDATE )"
SOURCEPB1="$(echo "$temp" | ${CANDIDATETYP[$USRPART]} )" #cant use <<<
[[ "${CANDIDATETYP2[$USRPART]}" ]] && SOURCEPB1="$(echo "$SOURCEPB1" | ${CANDIDATETYP2[$USRPART]} )"
[[ "$SOURCEPB1" ]] && SOURCEPB1="" || SOURCEPB1="${POLICYTYP[$USRPART]}"
SOURCEPB2=""
#if [[ "${APTTYP[$USRPART]}" = apt-get ]];then
#	ttemp="${CHROOTCMD}${APTTYP[$USRPART]} ${YESTYP[$USRPART]} download $PACKTOVALIDATE"
#	[[ "$( $ttemp | grep "E:")" ]] && SOURCEPB2=download #Eg when blank sources.list
#fi
if [[ ! "$SOURCEPB1" ]] && [[ ! "$SOURCEPB2" ]];then
	echo "$PACKTOVALIDATE available"
	VALIDSOURCE=ok
else
	VALIDSOURCE=""
	echo "$PACKTOVALIDATE NOT available ($SOURCEPB1 $SOURCEPB2 problem)"
fi
}

## Called by purge_grub and _button_nextpurgegrub
then_type_this_purge_command() {
SEVERALCOMMANDS=""
COMMAND=""
OSPROBERABSENT=yes
EFIBOOTMGRABSENT=yes
for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
	[[ -f "${BLKIDMNT_POINT[$i]}${gg}os-prober" ]] && OSPROBERABSENT=""
	[[ -f "${BLKIDMNT_POINT[$i]}${gg}efibootmgr" ]] && EFIBOOTMGRABSENT=""
done
[[ "$OSPROBERABSENT" ]] && [[ ! "$GRUBPACKAGE" =~ os-prober ]] && GRUBPACKAGE="$GRUBPACKAGE os-prober"
[[ "$EFIBOOTMGRABSENT" ]] && [[ ! "$GRUBPACKAGE" =~ efibootmgr ]] && [[ "$GRUBPACKAGE" =~ -efi ]] && GRUBPACKAGE="$GRUBPACKAGE efibootmgr"
if [[ "$GRUBPACKAGE" =~ signed ]];then
	testvalidsource shim-signed
	[[ "$VALIDSOURCE" ]] && [[ ! "$GRUBPACKAGE" =~ shim-signed ]] && GRUBPACKAGE="$GRUBPACKAGE shim-signed"
	testvalidsource linux-headers-generic
	[[ "$VALIDSOURCE" ]] && [[ ! "$GRUBPACKAGE" =~ linux-headers-generic ]] && GRUBPACKAGE="$GRUBPACKAGE linux-headers-generic" #cf mail Wieger 7nov2016
	testvalidsource linux-signed-generic
	[[ "$VALIDSOURCE" ]] && [[ ! "$GRUBPACKAGE" =~ linux-signed-generic ]] && GRUBPACKAGE="$GRUBPACKAGE linux-signed-generic"
elif [[ "$GPURGEPACKS" =~ linux-signed ]];then
	[[ ! "$GRUBPACKAGE" =~ linux-generic ]] && GRUBPACKAGE="$GRUBPACKAGE linux-generic"
fi

#If the user had modified something manually the folders would have remained.
#Solves Grub-Customizer bug887761
if [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub.bak" ]];then
	rm -rf "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub"
elif [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub" ]];then
	mv -f "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub" "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub.bak"
fi
if [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub2.bak" ]];then
	rm -rf "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub2"
elif [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub2" ]];then
	mv -f "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub2" "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub2.bak"
fi
if [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d.bak" ]];then
	rm -rf "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d"
elif [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d" ]];then
	mv -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d" "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d.bak"
fi

local PURGECOMMAND2="${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} $GRUBPACKAGE"
COMMAND="sudo ${CHROOTUSR}$PURGECOMMAND2"
if [[ "${APTTYP[$USRPART]}" = apt-get ]] && [[ "$GRUBPACKAGE" =~ linux- ]];then #https://bugs.launchpad.net/boot-repair/+bug/2054986
	SEVERALCOMMANDS=yes
	COMMAND="$COMMAND
sudo ${CHROOTUSR}${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} --reinstall ${YESTYP[$USRPART]} $GRUBPACKAGE"
fi
[[ ! "$PURGEDONE" ]] && add_dpkgconf_to_command
echo "Then type: $COMMAND"
if [[ "$GUI" ]];then
    [[ "$SEVERALCOMMANDS" ]] && echo "SET@_label8.set_text('''$Please_open_a_terminal_then_type_the_following_commands''')" \
    || echo "SET@_label8.set_text('''$Now_please_type_this_command_in_the_terminal''')"
    echo "SET@_label9.set_text('''$COMMAND''')"
    if [[ ! "$GRUBPACKAGE" =~ efi ]] && [[ "$GRUBPACKAGE" != grub ]];then
        echo "SET@_label10.set_text('''\\n$Then_select_correct_device_if_the_below_window_appears\\n''')"
        echo 'SET@_image_installgrub.show()'
    else
        echo "SET@_label10.set_text('''\\n''')"
        echo 'SET@_image_installgrub.hide()'
    fi
    echo 'SET@_image_purgegrub.hide()'
    echo 'SET@_button_cancelpurgegrub.hide()'; echo 'SET@_button_nextpurgegrub.hide()'
    echo 'SET@_button_abortinstallgrub.show()';echo 'SET@_button_nextinstallgrub.show()'
fi
}

add_dpkgconf_to_command() {
local gg
if [[ "$BLKID" =~ LVM ]];then
	SEVERALCOMMANDS=yes
	COMMAND="sudo $CHROOTUSR${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} lvm2\\n$COMMAND"
fi
if [[ "$raiduser" = yes ]];then
	if [[ "$(type -p dmraid)" ]];then
		SEVERALCOMMANDS=yes
		COMMAND="sudo ${CHROOTUSR}dmraid -ay\\n$COMMAND"
		COMMAND="sudo $CHROOTUSR${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} dmraid\\n$COMMAND"
	fi
	if [[ "$(type -p mdadm)" ]];then
		SEVERALCOMMANDS=yes
		COMMAND="sudo ${CHROOTUSR}mdadm --assemble --scan\\n${COMMAND}"
		COMMAND="sudo $CHROOTUSR${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} mdadm\\n$COMMAND"
	fi
fi
if [[ "$BLKID" =~ zfs ]];then
	SEVERALCOMMANDS=yes
	COMMAND="sudo $CHROOTUSR${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} zfsutils-linux\\n$COMMAND"
fi
if [[ "${APTTYP[$USRPART]}" = apt-get ]];then
	SEVERALCOMMANDS=yes
	COMMAND="sudo ${CHROOTUSR}apt-get install -fy\\n$COMMAND"
	#sudo apt --fix-broken install
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		if [[ -f "${BLKIDMNT_POINT[$i]}${gg}dpkg" ]];then
			COMMAND="sudo ${CHROOTUSR}dpkg --configure -a\\n$COMMAND"
			break
		fi
	done
fi
}

check_deb_install_feasibility() {
#$1:DEBs
DEBCHECK=debOK
if [[ "${APTTYP[$USRPART]}" = apt-get ]];then
	for DEBTOCHECK in $1;do
		rm -f ${BLKIDMNT_POINT[$REGRUB_PART]}/var/cache/apt/archives/${DEBTOCHECK}_*
		${CHROOTCMD}${APTTYP[$USRPART]} -d ${YESTYP[$USRPART]} install --reinstall $DEBTOCHECK || DEBCHECK=debNG
	done
	echo "DEBCHECK $DEBCHECK, $1"
fi
}

#First cancel button of Purge GRUB process
_button_cancelpurgegrub() {
quit_purge
echo "$GRUB_reinstallation_has_been_cancelled"
[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$GRUB_reinstallation_has_been_cancelled" 2>/dev/null
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r "$TMP_FOLDER_TO_BE_CLEARED"
[[ "$GUI" ]] && echo 'EXIT@@' || exit 1
}

#Second cancel button of Purge GRUB process
_button_abortinstallgrub() {
quit_purge
SYSTEM3="${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}"; update_translations
text="$GRUB_reinstallation_has_been_cancelled\\n $SYSTEM3_is_now_without_GRUB"
echo "$text"
[[ "$GUI" ]] && zenity --width=400 --warning --text="$text" 2>/dev/null
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r "$TMP_FOLDER_TO_BE_CLEARED"
[[ "$GUI" ]] && echo 'EXIT@@' || exit 1
}

#Called by cancel buttons of Purge GRUB process
quit_purge() {
if [[ "$GUI" ]];then
    echo "SET@pulsatewindow.set_title('''$Scanning_systems''')"
    echo 'SET@_purgewindow.hide()'
    start_pulse
fi
sleep 10 # In case an operation in the user terminal was not finished
restore_resolvconf_and_unchroot
#mount_all_blkid_partitions_except_df
#[[ "$DEBBUG" ]] && echo "[debug]Mount all the partitions for the logs"
#save_log_on_disks
#unmount_all_blkid_partitions_except_df
end_pulse
}

#Called by grub_purge & quit_purge
restore_resolvconf_and_unchroot() {
#restore_dep "$REGRUB_PART"
if [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" != "$CURRENTSESSIONPARTITION" ]] \
&& [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf.old" ]];then
	rm -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf"
	mv -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf.old" "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf"
fi
unchroot_linux_to_reinstall
}

#Called by purge GRUB
_button_nextpurgegrub() {
check_part_types
if [[ "${GRUBTYPE_OF_PART[$USRPART]}" != nogrubinstall ]];then
    echo "$GRUB_is_still_present $Please_try_again (purge grub* packages from ${BLKIDMNT_POINT[$USRPART]})"
	[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$GRUB_is_still_present ${Please_try_again}\\n(purge grub* packages from ${BLKIDMNT_POINT[$USRPART]})" 2>/dev/null
	#[[ "$GUI" ]] && echo "SET@_label11.set_text('''\\n$GRUB_is_still_present $Please_try_again''')"
	#echo 'SET@_label11.show()'; sleep 3; echo 'SET@_label11.hide()'
else
	then_type_this_purge_command
fi
}

#Called by purge GRUB
_button_nextinstallgrub() {
check_part_types
if [[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]];then
    echo "$GRUB_is_still_absent $Please_try_again"
	[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$GRUB_is_still_absent $Please_try_again" 2>/dev/null
	#[[ "$GUI" ]] && echo "SET@_label11.set_text('''\\n$GRUB_is_still_absent $Please_try_again''')"
	#echo 'SET@_label11.show()'; sleep 2; echo 'SET@_label11.hide()'
else
	[[ "$GUI" ]] && echo 'SET@_purgewindow.hide()'
	start_pulse
	sleep 20 #Avoid unmount before update is finished
	purge_end
fi
}

purge_end() {
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_the_grub_of ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (fin). $This_may_require_several_minutes''')"
[[ "$UNHIDEBOOT_ACTION" ]] && unhide_boot_menus_etc_default_grub	#Because a new GRUB has been generated
check_part_types #update variables before reinstall_action (eg. GRUBTYPE_OF_PART)
reinstall_grub_from_chosen_linux
unmount_all_and_success
}

############## UPDATE PACKAGES ACTION (USED BY PURGE_GRUB) #############
aptget_update_function() {
#called by prepare_chroot_and_internet & grub_purge & restore_resolvconf_and_unchroot
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_the_grub_of ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (upd). $This_may_require_several_minutes''')"
echo "${CHROOTCMD}${APTTYP[$USRPART]} ${UPDATETYP[$USRPART]}"
APTUPDTMP="$(${CHROOTCMD}${APTTYP[$USRPART]} ${UPDATETYP[$USRPART]})"
if [[ "${UPDATETYP2[$USRPART]}" ]];then
	echo "${CHROOTCMD}${UPDATETYP2[$USRPART]}"
	APTUPDTMP2="$(${CHROOTCMD}${UPDATETYP2[$USRPART]})"
fi
}


############################# PURGE KERNEL #############################
kernel_purge() {
title_gen "dpkg -l | grep linux- before kernel purge"
${CHROOTCMD}dpkg -l | grep linux-
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_kernels ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/}. $This_may_require_several_minutes''')"
title_gen "Purge kernel of ${LISTOFPARTITIONS[$REGRUB_PART]}"
local PACKSTOPURGE COMMAND pack
SOURCERROR=""
testvalidsource linux-generic
# Pre-download the packages before purging them (security in case of internet failure just after purge)
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_kernels ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (dwn). $This_may_require_several_minutes''')"
check_deb_install_feasibility linux-generic
echo "DEBCHECKLINUX $DEBCHECK"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_kernels ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (pur). $This_may_require_several_minutes''')"

if [[ ! "$VALIDSOURCE" ]] || [[ "$DEBCHECK" = debNG ]];then
	end_pulse
	purge_cancelled linux-generic
else
	#echo 'SET@_hbox_kernelpurgebuttons.show()'; echo 'SET@_hbox_grubpurgebuttons.hide()'
	a=""; for b in $(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/" 2>/dev/null);do a="$a $b";done
	echo "ls ${BLKIDMNT_POINT[$REGRUB_PART]}/boot/:$a"
	if [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/" 2>/dev/null | grep vmlinuz )" ]] \
	|| [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/" 2>/dev/null | grep initrd )" ]] \
	|| [[ "$USE_SEPARATEBOOTPART" ]];then
		PACKSTOPURGE="linux-headers-* linux-image-*" #linux-signed*
		COMMAND="${APTTYP[$USRPART]} ${PURGETYP[$USRPART]} ${YESTYP[$USRPART]}"
	#	if [[ "${APTTYP[$REGRUB_PART]}" = apt-get ]];then
	#		echo 'SET@_image_purgegrub.hide()'; echo 'SET@_image_installgrub.hide()'
	#		echo 'SET@_button_cancelpurgekernel.show()'; echo 'SET@_button_nextpurgekernel.show()'
	#		echo 'SET@_button_abortinstalllinux.hide()';echo 'SET@_button_nextinstalllinux.hide()'
	#		[[ "$GUI" ]] && echo "SET@_label8.set_text('''$Please_open_a_terminal_then_type_the_following_command''')"
	#		[[ "$GUI" ]] && echo "SET@_label9.set_text('''sudo ${CHROOTUSR}$COMMAND $PACKSTOPURGE''')"
	#		[[ "$GUI" ]] && echo "SET@_label10.set_text('''\\n${Then_choose_Yes_when_the_below_window_appears}\\n''')"
	#	else
			for pack in $PACKSTOPURGE;do
				echo "${CHROOTCMD}$COMMAND $pack"
				${CHROOTCMD}$COMMAND $pack
			done
			then_type_this_linux_install_command
	#	fi
	else  # Linux already missing
		then_type_this_linux_install_command
	fi
	#if [[ "${APTTYP[$USRPART]}" = apt-get ]];then
	#	end_pulse
	#	echo 'SET@_purgewindow.show()'
	#else
		[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_kernels ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (fin). $This_may_require_several_minutes''')"
	#fi
fi
}


purge_cancelled() {
#when [[ ! "$VALIDSOURCE" ]] or [[ "$DEBCHECK" = debNG ]]
PACKKK=$1 #linux or $GRUBPACKAGE
check_internet_connection
text=""
if [[ "$(cat "$CATTEE" | grep '/var/lib/dpkg' )" ]] && [[ "$LIVESESSION" = installed ]];then
	text="$Please_open_a_terminal_then_type_the_following_command

sudo dpkg --configure -a

$Please_close_all_your_package_managers ($Software_Centre, \
$Update_Manager, Synaptic, ...). $Then_try_again"
elif [[ "$(cat "$CATTEE" | grep '/var/lib/dpkg' )" ]] && [[ "$LIVESESSION" = live ]] || [[ "$(cat "$CATTEE" | grep 'dpkg --configure -a' )" ]];then
	FUNCTION=dpkg-error; update_translations
	text="$FUNCTION_detected $Please_open_a_terminal_then_type_the_following_command

sudo ${CHROOTUSR}dpkg --configure -a

$Then_close_this_window"
elif [[ "$(cat "$CATTEE" | grep 'apt-get -f install' )" ]];then
	FUNCTION=apt-error; update_translations
	text="$FUNCTION_detected $Please_open_a_terminal_then_type_the_following_command

sudo ${CHROOTUSR}apt-get -f install

$Then_close_this_window"
elif [[ ! "$APTUPDTMP" =~ Hit ]] && [[ "$INTERNET" != connected ]];then
	text="$No_internet_connection_detected. $Please_connect_internet $Then_try_again"
elif [[ ! "$VALIDSOURCE" ]];then
	PACKAGELIST="$PACKKK"; DISTRO="${OSNAME[$REGRUB_PART]} (${LISTOFPARTITIONS[$REGRUB_PART]})"; update_translations
	text="$Please_enable_a_rep_for_PACKAGELIST_pack_in_DISTRO $Then_try_again"
	open_sources_editor &
else
	text="$1 purge cancelled."
	[[ "$DEBCHECK" != debNG ]] && text="Strange $text"
fi
echo "
$DASH $1 purge cancelled"
echo "$text"
[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$text" 2>/dev/null
}

open_sources_editor() {
sleep 1 #to wait restore of sources
if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}$slist" ]];then
	echo "
$DASH No valid source for $PACKKK in ${BLKIDMNT_POINT[$REGRUB_PART]}$slist :"
	SOURCESLIST="$(cat "${BLKIDMNT_POINT[$REGRUB_PART]}$slist")"
	echo "$SOURCESLIST"
	if [[ ! "$(echo "$SOURCESLIST" | grep main | grep -v "#" )" ]];then
		xdg-open "${BLKIDMNT_POINT[$REGRUB_PART]}$slist" &
	fi
fi
}

then_type_this_linux_install_command() {
#[[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" ]] && echo "Regenerated ${BLKIDMNT_POINT[$REGRUB_PART]}/boot folder"
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$Purge_and_reinstall_kernels ${LISTOFPARTITIONS[$REGRUB_PART]#*/dev/} (ins). $This_may_require_several_minutes''')"
local COMMAND="${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} linux-generic"
#if [[ "${APTTYP[$REGRUB_PART]}" = apt-get ]];then
#	[[ "$GUI" ]] && echo "SET@_label8.set_text('''$Now_please_type_this_command_in_the_terminal''')"
#	[[ "$GUI" ]] && echo "SET@_label9.set_text('''sudo ${CHROOTUSR}$COMMAND''')"
#	echo 'SET@_button_cancelpurgekernel.hide()'; echo 'SET@_button_nextpurgekernel.hide()'
#	echo 'SET@_button_abortinstalllinux.show()'; echo 'SET@_button_nextinstalllinux.show()'
#else
	echo "
$CHROOTCMD$COMMAND"
	$CHROOTCMD$COMMAND
	COMMAND="${APTTYP[$USRPART]} ${INSTALLTYP[$USRPART]} ${YESTYP[$USRPART]} linux-base" #https://forum.ubuntu-fr.org/viewtopic.php?id=509791&p=76
	echo "
$CHROOTCMD$COMMAND"
	$CHROOTCMD$COMMAND
	echo "
$DASH dpkg -l | grep linux- after kernel reinstall"
	${CHROOTCMD}dpkg -l | grep linux-
	echo " 
"
#fi
}
