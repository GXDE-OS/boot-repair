#! /bin/bash
# Copyright 2014-2021 Yann MRN
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


_button_open_etc_default_grub() {
if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" ]];then
	echo "[debug]xdg-open ${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
	xdg-open "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" &
else
	echo "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub does not exist. Please choose the [Purge and reinstall] option."
	[[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub does not exist. Please choose the [Purge and reinstall] option." 2>/dev/null
fi
}

_checkbutton_signed() {
if [[ "${@}" = True ]];then
	set_signed
else
	unset_signed
fi
[[ "$DEBBUG" ]] && echo "[debug]GRUBPACKAGE becomes: $GRUBPACKAGE"
}

set_signed() {
GRUBPACKAGE=grub-efi-amd64-signed
activate_hide_lastgrub_if_necessary
}

unset_signed() {
GRUBPACKAGE=grub-efi
activate_hide_lastgrub_if_necessary
}

_checkbutton_purge_grub() {
if [[ "${@}" = True ]];then
	set_purgegrub
else
	unset_purgegrub
fi
[[ "$DEBBUG" ]] && echo "[debug]GRUBPURGE_ACTION becomes: $GRUBPURGE_ACTION"
}

activate_grubpurge_if_necessary() {
local BLOCKONPURGE="" RAIDREASON=""
if [[ "$raiduser" = yes ]] && ( [[ "$(type -p dmraid)" ]] || [[ "$(type -p mdadm)" ]] ) ;then
	RAIDREASON=yes
fi
#|| ( [[ ! "$GRUBPACKAGE" =~ signed ]] && [[ "${DOCGRUB[$USRPART]}" =~ signed ]] ) 
if ( [[ "$GRUBPACKAGE" =~ efi ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ efi ]] ) \
|| ( [[ "$GRUBPACKAGE" = grub2 ]] && [[ "${DOCGRUB[$USRPART]}" =~ efi ]] && [[ -d /sys/firmware/efi ]] ) \
|| ( [[ "$GRUBPACKAGE" = grub2 ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ pc ]] ) \
|| ( [[ "$GRUBPACKAGE" =~ signed ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ signed ]] ) \
|| [[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]] || [[ "$LASTGRUB_ACTION" ]] || [[ "$GRUBPACKAGE" = grub ]] \
|| [[ "${PART_GRUBLEGACY[$BOOTPART]}" = has-legacyfiles ]] || [[ "${PART_GRUBLEGACY[$REGRUB_PART]}" = has-legacyfiles ]];then
	BLOCKONPURGE=yes
	[[ "$GUI" ]] && echo 'SET@_checkbutton_purge_grub.set_sensitive(False)'
fi
if [[ "$BLOCKONPURGE" ]] || [[ "${CUSTOMIZER[$REGRUB_PART]}" != std-grub.d ]] || [[ "${GRUB_ENV[$REGRUB_PART]}" = grubenv-ng ]] \
|| [[ "$RAIDREASON" ]] || [[ "$BLKID" =~ LVM ]];then
	PURGREASON="in order to"
	if ( [[ "$GRUBPACKAGE" =~ efi ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ efi ]] ) || ( [[ "$GRUBPACKAGE" = grub2 ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ pc ]] );then
		PURGREASON="$PURGREASON fix packages"
	elif [[ "$GRUBPACKAGE" = grub2 ]] && [[ "${DOCGRUB[$USRPART]}" =~ efi ]] && [[ -d /sys/firmware/efi ]];then
		PURGREASON="$PURGREASON remove grub-efi"
	elif [[ "$GRUBPACKAGE" =~ signed ]];then
		PURGREASON="$PURGREASON sign-grub"
#	elif [[ "$GRUBPACKAGE" =~ efi ]];then
#		PURGREASON="$PURGREASON unsign-grub"
	elif [[ "$RAIDREASON" ]];then
		PURGREASON="$PURGREASON enable-raid"
	elif [[ "$BLKID" =~ LVM ]];then
		PURGREASON="$PURGREASON enable-lvm"
	elif [[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]];then
		PURGREASON="$PURGREASON fix executable"
	elif [[ "$LASTGRUB_ACTION" ]];then
		PURGREASON="$PURGREASON upgrade version"
	elif [[ "$LEGACY_ACTION" ]];then
		PURGREASON="$PURGREASON downgrade version"
	elif [[ "$GRUBPACKAGE" =~ efi ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ efi ]];then
		PURGREASON="$PURGREASON help with efi"
	elif [[ "$GRUBPACKAGE" = grub2 ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ pc ]];then
		PURGREASON="$PURGREASON fix grub files"
	elif [[ "$GRUBPACKAGE" =~ signed ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ signed ]];then
		PURGREASON="$PURGREASON sign"
	elif [[ ! "$GRUBPACKAGE" =~ signed ]] && [[ "${DOCGRUB[$USRPART]}" =~ signed ]];then
		PURGREASON="$PURGREASON unsign"
	elif [[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]];then
		PURGREASON="$PURGREASON re-download"
	elif [[ "$LASTGRUB_ACTION" ]];then
		PURGREASON="$PURGREASON download recent version"
	elif [[ "${PART_GRUBLEGACY[$BOOTPART]}" = has-legacyfiles ]];then
		PURGREASON="$PURGREASON cleanup legacy in /boot"
	elif [[ "${PART_GRUBLEGACY[$REGRUB_PART]}" = has-legacyfiles ]];then
		PURGREASON="$PURGREASON clean-up legacy"
	elif [[ "$GRUBPACKAGE" = grub ]];then
		PURGREASON="$PURGREASON download legacy"
	elif [[ "${CUSTOMIZER[$REGRUB_PART]}" != std-grub.d ]];then
		PURGREASON="$PURGREASON fix grub.d"
    elif [[ "${GRUB_ENV[$REGRUB_PART]}" = grubenv-ng ]];then
        PURGREASON="$PURGREASON reset grubenv"
	fi
	if [[ "${APTTYP[$USRPART]}" != nopakmgr ]];then
		set_purgegrub
		[[ "$GUI" ]] && echo 'SET@_checkbutton_purge_grub.set_active(True)'
	else
		echo "Error: no package mgt for purge. $PLEASECONTACT"
	fi
else
	unset_purgegrub
	[[ "$GUI" ]] && echo 'SET@_checkbutton_purge_grub.set_active(False)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_purge_grub.set_sensitive(True)'
fi
}

set_purgegrub() {
GRUBPURGE_ACTION=purge-grub
[[ "$GUI" ]] && echo 'SET@_button_open_etc_default_grub.hide()'
}

unset_purgegrub() {
GRUBPURGE_ACTION=""
[[ "$GUI" ]] && echo 'SET@_button_open_etc_default_grub.show()'
}

_checkbutton_lastgrub() {
if [[ "${@}" = True ]];then
	lastgrub_extra
else
	unset_checkbutton_lastgrub
fi
[[ "$DEBBUG" ]] && echo "[debug]LASTGRUB_ACTION becomes: $LASTGRUB_ACTION"
}

set_checkbutton_lastgrub() {
LASTGRUB_ACTION=" upgrade-grub"
[[ "$GUI" ]] && echo 'SET@_checkbutton_legacy.set_sensitive(False)'
activate_grubpurge_if_necessary
}

unset_checkbutton_lastgrub() {
LASTGRUB_ACTION=""
[[ "$GUI" ]] && [[ ! "$GRUBPACKAGE" =~ efi ]] && echo 'SET@_checkbutton_legacy.set_sensitive(True)'
activate_grubpurge_if_necessary
}

_checkbutton_legacy() {
if [[ "${@}" = True ]];then
	GRUBPACKAGE=grub
    UNCOMMENT_GFXMODE=""; ATA="";
    unset_kerneloption;
    echo "$This_will_install_an_obsolete_bootloader (GRUB Legacy). ${Please_backup_data}"
    if [[ "$GUI" ]];then
        zenity --width=400 --warning --title="$APPNAME2" --text="$This_will_install_an_obsolete_bootloader (GRUB Legacy). ${Please_backup_data}" 2>/dev/null
        echo 'SET@_hbox_efi.set_sensitive(False)'
        echo 'SET@_hbox_unhide.hide()'
        echo 'SET@_checkbutton_uncomment_gfxmode.set_active(False)'; echo 'SET@_checkbutton_uncomment_gfxmode.set_sensitive(False)'
        echo 'SET@_checkbutton_ata.set_active(False)'; echo 'SET@_checkbutton_ata.set_sensitive(False)'
        echo 'SET@_checkbutton_add_kernel_option.set_active(False)'; echo 'SET@_checkbutton_add_kernel_option.set_sensitive(False)'
    fi
else
	unset_checkbutton_legacy
fi
activate_hide_lastgrub_if_necessary #includes activate_grubpurge_if_necessary
[[ "$DEBBUG" ]] && echo "[debug]LEGACY GRUBPACKAGE becomes: $GRUBPACKAGE"
}

unset_checkbutton_legacy() {
GRUBPACKAGE=grub2
if [[ "$GUI" ]];then
    [[ "$QTY_EFIPART" != 0 ]] && echo 'SET@_hbox_efi.set_sensitive(True)'
    echo 'SET@_hbox_unhide.show()'
    echo 'SET@_checkbutton_uncomment_gfxmode.set_sensitive(True)'
    echo 'SET@_checkbutton_ata.set_sensitive(True)'
    echo 'SET@_checkbutton_add_kernel_option.set_sensitive(True)'
fi
}

_checkbutton_blankextraspace() {
if [[ "${@}" = True ]];then
    echo "$Warning_blankextra $Please_backup_data"
	[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$Warning_blankextra $Please_backup_data" 2>/dev/null
	BLANKEXTRA_ACTION=" flexnet"
else
	BLANKEXTRA_ACTION=""
fi
[[ "$DEBBUG" ]] && echo "[debug]BLANKEXTRA_ACTION becomes : $BLANKEXTRA_ACTION"
}

_checkbutton_uncomment_gfxmode() {
[[ "${@}" = True ]] && UNCOMMENT_GFXMODE=" uncomment-gfxmode" || UNCOMMENT_GFXMODE=""
[[ "$DEBBUG" ]] && echo "[debug]UNCOMMENT_GFXMODE becomes : $UNCOMMENT_GFXMODE"
}

_checkbutton_ata() {
[[ "${@}" = True ]] && ATA=" --disk-module=ata" || ATA=""
[[ "$DEBBUG" ]] && echo "[debug]ATA becomes : $ATA"
}

_checkbutton_add_kernel_option() {
if [[ "${@}" = True ]];then
	ADD_KERNEL_OPTION=add-kernel-option;
    [[ "$GUI" ]] && echo 'SET@_combobox_add_kernel_option.set_sensitive(True)'
else 
	unset_kerneloption
fi
[[ "$DEBBUG" ]] && echo "[debug]ADD_KERNEL_OPTION becomes : $ADD_KERNEL_OPTION"
}

unset_kerneloption() {
ADD_KERNEL_OPTION="";
[[ "$GUI" ]] && echo 'SET@_combobox_add_kernel_option.set_sensitive(False)'
}

_combobox_add_kernel_option() {
CHOSEN_KERNEL_OPTION="${@}"
[[ "$DEBBUG" ]] && echo "[debug]CHOSEN_KERNEL_OPTION becomes : $CHOSEN_KERNEL_OPTION"
}

_checkbutton_kernelpurge() {
[[ "${@}" = True ]] && KERNEL_PURGE=" kernel-purge" || KERNEL_PURGE=""
echo "[debug]KERNEL_PURGE becomes : $KERNEL_PURGE"
}

activate_kernelpurge_if_necessary() {
if ( [[ ! "$USE_SEPARATEBOOTPART" ]] && [[ "${BOOT_AND_KERNEL_IN[$REGRUB_PART]}" != with-boot ]] ) \
|| ( [[ "$USE_SEPARATEBOOTPART" ]] && [[ "${PART_WITH_SEPARATEBOOT[$BOOTPART_TO_USE]}" != is---sepboot ]] );then #in order to populate/boot
	KERNEL_PURGE=" kernel-purge"
	[[ "$GUI" ]] && echo 'SET@_checkbutton_kernelpurge.set_active(True)'
#	echo 'SET@_checkbutton_kernelpurge.set_sensitive(False)'
else
	KERNEL_PURGE=""
	[[ "$GUI" ]] && echo 'SET@_checkbutton_kernelpurge.set_active(False)'
	[[ "$GUI" ]] && echo 'SET@_checkbutton_kernelpurge.set_sensitive(True)'
fi
}

show_tab_grub_options() {
if [[ "$GUI" ]];then
    if [[ "$1" = on ]];then
        echo 'SET@_tab_grub_options.set_sensitive(True)'; echo 'SET@_vbox_grub_options.show()'
    else
        echo 'SET@_tab_grub_options.set_sensitive(False)'; echo 'SET@_vbox_grub_options.hide()'
    fi
fi
}

