#! /bin/bash
# Copyright 2010-2023 Yann MRN
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

first_translations_extra() {
RECENTUB=noble;RECENTREP=Ubuntu-24.04   ##see also: open_sources_editor in actions-purge
#/// Please do not translate ${RECENTREP}
Warning_lastgrub=$(eval_gettext $'Warning: this will install necessary packages from ${RECENTREP} repositories.')
Use_last_grub=$(eval_gettext $'Upgrade GRUB to its most recent version')
}

lastgrub_extra() {
[[ ! "$GUI" ]] && echo "$Warning_lastgrub $Please_backup_data"
[[ "$GUI" ]] && zenity --width=400 --warning --title="$APPNAME2" --text="$Warning_lastgrub $Please_backup_data" 2>/dev/null
set_checkbutton_lastgrub
}

grub_purge_extra() {
if [[ "$LASTGRUB_ACTION" ]];then
	TMPDEP="${BLKIDMNT_POINT[$REGRUB_PART]}"
	CHECKRECUB="$(cat "$TMPDEP$slist" | grep " $RECENTUB " | grep main | grep -v '#' | grep -v extra )"
	if [[ ! "$CHECKRECUB" ]] && [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] \
	&& [[ -f "$TMPDEP$slist" ]];then
		echo "Install last GRUB version in $TMPDEP$slist"
		echo "deb http://archive.ubuntu.com/ubuntu/ $RECENTUB main" >> $TMPDEP$slist
		cp $TMPDEP$slist $LOGREP/sources.list_after_grubpurge #debug
		update_cattee
		aptget_update_function
	fi
fi
}

activate_hide_lastgrub_if_necessary() {
TMPDEP="${BLKIDMNT_POINT[$REGRUB_PART]}"
unset_checkbutton_lastgrub
if [[ "$GUI" ]];then
	if [[ "$(lsb_release -is)" = Ubuntu ]] || [[ "$DISTRIB_DESCRIPTION" =~ Boot-Repair-Disk ]] \
	&& [[ "${APTTYP[$USRPART]}" = apt-get ]] && [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] \
	&& [[ ! "$(cat "$TMPDEP$slist" | grep $RECENTUB | grep main | grep -v '#')" ]];then
		echo 'SET@_checkbutton_lastgrub.show()'
		echo 'SET@_checkbutton_lastgrub.set_active(False)'
		echo 'SET@_checkbutton_lastgrub.set_sensitive(True)'
	else
		echo 'SET@_checkbutton_lastgrub.hide()'
	fi
fi
[[ "$DEBBUG" ]] && echo "[debug]LASTGRUB_ACTION becomes: $LASTGRUB_ACTION"
}


repair_boot_ini_nonfree() {
if [[ "$(type -p tar)" ]];then
	[[ "$file" =~ l ]] && tmp=2 || tmp=1
	tar -Jxf /usr/share/boot-sav-extra/bin$tmp -C "${BLKIDMNT_POINT[$i]}"
	echo "Fixed ${BLKIDMNT_POINT[$i]}/$file"
fi
}

installpackagelist_extra() {
#if [[ "$INTERNET" = connected ]] && [[ "$MISSINGPACKAGE" ]];then
#	repair_dep;	temp="$($UPDCOM)"; temp2="$($INSCOM)"; restore_dep
#fi
check_missing_packages
}

################## Repair repositories
repair_dep() {
local PARTI="$1" line TEMPUV tempuniv
TMPDEP=""
if [[ "$PARTI" ]];then TMPDEP="${BLKIDMNT_POINT[$PARTI]}";fi #cant minimize
if [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] && [[ -f "${TMPDEP}/usr/bin/apt-get" ]];then
	echo "[debug]Repair repositories in $TMPDEP$slist"
	if [[ -f "$TMPDEP$slist" ]];then
		if [[ ! -f "${LOGREP}/sources.list$PARTI" ]];then
			mv $TMPDEP$slist $LOGREP/sources.list$PARTI #will be restored later
			if [[ -f "$LOGREP/sources.list$PARTI" ]];then #security
				#Avoids useless warnings
				while read line; do
					if [[ "$(echo "$line" | grep cdrom | grep -v '#' )" ]];then
						echo "# $line" >> $TMPDEP$slist
					else
						echo "$line" >> $TMPDEP$slist
					fi
				done < <(echo "$(< $LOGREP/sources.list$PARTI )" )
			fi
		fi
	fi
fi
}

restore_dep() {
#called by force_unmount_and_prepare_chroot & installpackagelist_extra
local PARTI="$1"
TMPDEP=""
if [[ "$PARTI" ]];then TMPDEP="${BLKIDMNT_POINT[$PARTI]}";fi #cant minimize
if [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] && [[ -f "${TMPDEP}/usr/bin/apt-get" ]];then
	#[[ ! -f "$LOGREP/sources_$PARTI" ]] && cp "$LOGREP/sources.list" "$PARTI $LOGREP/sources_$PARTI"
	[[ ! -f "$LOGREP/sources.list$PARTI" ]] && echo "Error: no $LOGREP/sources.list$PARTI" \
	|| mv "$LOGREP/sources.list$PARTI" "${TMPDEP}/etc/apt/sources.list"
fi
}

update_soft() {
PROPOSUPDSOFT=y
PACKAGELIST="$APPNAME boot-sav boot-sav-extra"; update_translations
mkdir -p /var/log/$APPNAME #to avoid issues with ls
if [[ -f /var/log/dpkg.log ]];then
    [[ "$(grep "upgrade $APPNAME:" /var/log/dpkg.log | grep $(date +'%Y-%m-%d')  )" ]] \
    || [[ "$(grep "install $APPNAME:" /var/log/dpkg.log | grep $(date +'%Y-%m-%d')  )" ]] || [[ "$DEBBUG" ]] && PROPOSUPDSOFT="" #don't propose if soft was updated today
fi
if [[ ! "$(ls /var/log/$APPNAME 2>/dev/null | grep $(date +'%Y%m%d') )" ]] && [[ "$PROPOSUPDSOFT" ]];then #propose once a day
    touch /var/log/$APPNAME/$(date +'%Y%m%d').day
    UPDATESW=y
    if [[ ! "$FORCEYES" ]];then
        if [[ "$GUI" ]];then
            UPGTXT="$It_is_recommended_to_use_latest_version

$Do_you_want_to_update"
            end_pulse
            zenity --width=400 --question --title="$APPNAME2" --text="$UPGTXT" 2>/dev/null || UPDATESW=""
            start_pulse
        else
            read -r -p "$It_is_recommended_to_use_latest_version $Do_you_want_to_update [yes/no] " response
            [[ ! "$response" =~ y ]] || UPDATESW=""
        fi
    fi
    if [[ "$UPDATESW" ]];then
        [[ "$GUI" ]] && echo "SET@_label0.set_text('''$Check_internet. $This_may_require_several_minutes''')"
		ADDAPTPPA="add-apt-repository -y ppa:yannubuntu/boot-repair"
		PPAOK=""
		PPABR="https://ppa.launchpadcontent.net/yannubuntu/boot-repair/ubuntu"
        UPDCOM="$PACKMAN $PACKUPD"
        INSCOM="$PACKMAN $PACKINS $PACKYES $PACKAGELIST"
		check_internet_connection
		ask_internet_connection
        if [[ "$INTERNET" = connected ]];then
            [[ "$GUI" ]] && echo "SET@_label0.set_text('''$Checking_updates. $This_may_require_several_minutes''')"
            if [[ -f /usr/bin/add-apt-repository ]];then
				[[ "$DEBBUG" ]] && echo "[debug] $ADDAPTPPA"
				$($ADDAPTPPA) #clean way but fails on Debian
            fi
            if [[ -d /etc/apt/sources.list.d ]];then
				[[ "$(ls /etc/apt/sources.list.d 2>/dev/null | grep yannubuntu-boot-repair- | grep .list)" ]] \
				&& [[ "$(cat /etc/apt/sources.list.d/yannubuntu-boot-repair-*.list | grep 'deb ' | grep -v '#' )" ]] && PPAOK=yes
				[[ -f /etc/apt/sources.list.d/boot-repair.list ]] \
				&& [[ "$(cat /etc/apt/sources.list.d/boot-repair.list | grep 'deb ' | grep -v '#' )" ]] && PPAOK=yes
            fi
            if [[ -d /etc/apt ]] && [[ ! "$PPAOK" ]];then
				#https://stackoverflow.com/questions/68992799/warning-apt-key-is-deprecated-manage-keyring-files-in-trusted-gpg-d-instead/71384057#71384057
				mkdir -p /etc/apt/sources.list.d
				LISTFILE="/etc/apt/sources.list.d/boot-repair.list"
				rm -f $LISTFILE
				rm -f /etc/apt/sources.list.d/yannubuntu*
				rm -f /etc/apt/keyrings/boot-repair.gpg
				rm -f /etc/apt/keyrings/yannubuntu*
				[[ "$DEBBUG" ]] && echo "[debug] add PPA to $LISTFILE and copy key from extra"
				[[ ! -f "$LISTFILE" ]] && touch "$LISTFILE"
				echo "deb [signed-by=/etc/apt/keyrings/boot-repair.gpg] $PPABR $RECENTUB main" >> "$LISTFILE"
				chmod 644 "$LISTFILE"
				[[ ! -d /etc/apt/keyrings ]] && mkdir -m 0755 -p /etc/apt/keyrings/
				cp /usr/share/boot-sav-extra/ppakey /etc/apt/keyrings/boot-repair.gpg
				chmod 644 /etc/apt/keyrings/boot-repair.gpg
            fi
            [[ "$DEBBUG" ]] && echo "[debug] $UPDCOM"
			temp="$($UPDCOM)"
            [[ "$GUI" ]] && echo "SET@_label0.set_text('''$Updating. $This_may_require_several_minutes''')"
            [[ "$DEBBUG" ]] && echo "[debug] $INSCOM  (faked for debug)"
            [[ "$DEBBUG" ]] && temp2=faked || temp2="$($INSCOM)"
		fi
        choice=exit
        if [[ "$INTERNET" != connected ]] || [[ ! "$temp" ]] || [[ ! "$temp2" ]];then
            [[ "$GUI" ]] && end_pulse
			if [[ "$INTERNET" != connected ]];then
                [[ ! "$GUI" ]] && echo "$The_software_could_not_be_updated $No_internet_connection_detected. $If_possible_update_PACKAGELIST_then_restart_APPNAME" \
                || zenity --width=400 --info --title="$APPNAME2" --text="$The_software_could_not_be_updated $No_internet_connection_detected. $If_possible_update_PACKAGELIST_then_restart_APPNAME" 2>/dev/null
			else
				[[ ! "$GUI" ]] && echo "$The_software_could_not_be_updated $If_possible_update_PACKAGELIST_then_restart_APPNAME" \
                || zenity --width=400 --info --title="$APPNAME2" --text="$The_software_could_not_be_updated $If_possible_update_PACKAGELIST_then_restart_APPNAME" 2>/dev/null
			fi
            [[ "$GUI" ]] && echo 'EXIT@@' || exit 1
        else
            [[ "$GUI" ]] && echo "SET@_label0.set_text('''$Updating (OK). $This_may_require_several_minutes''')" && sleep 1 && end_pulse
            echo "[debug] $APPNAME &"
            $APPNAME $* &
            [[ "$GUI" ]] && echo 'EXIT@@' || exit 0
            echo 'Exit0 after (should not be seen)'
        fi
    fi
fi
}
