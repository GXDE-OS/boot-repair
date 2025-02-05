#! /bin/bash
# Copyright 2020 Yann MRN
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

#Called from /usr/sbin/$APPNAME-bin
cmd_start() {
GUI=""; BLOCK_GUI=""
DEBBUG=""; G2SVERBOSE=""; FORCEYES=""; FILTERED="(filtered)";PY=python3;
. /usr/share/boot-sav/bs-cmd_terminal.sh
for arg in $*;do
    case "$arg" in
        -d              ) DEBBUG=" -d";;
        --debug         ) DEBBUG=" -d";;
        -y              ) FORCEYES=force;;
        --force-yes     ) FORCEYES=force;;
        -v              ) BLOCK_GUI=yes;;
        --version       ) BLOCK_GUI=yes;;
        --g2s-debug     ) G2SVERBOSE=" -v";;
        --esp           ) BLOCK_GUI=yes;;
        --no-filter     ) FILTERED="";;
        --python2       ) PY=python2;;
        -b              ) BLOCK_GUI=yes;;
        --bootinfo      ) BLOCK_GUI=yes;;
        -u            ) BLOCK_GUI=yes;;
        --bootinfo-url  ) BLOCK_GUI=yes;;
        *               ) 
            if [[ ! "$arg" =~ "-t=" ]];then
                BLOCK_GUI=yes; echo "Invalid option '${arg}', please check 'man ${APPNAME}'."
                exit 1
            fi
            ;;
    esac
done
for arg in $*;do
    case "$arg" in
        -d              ) DEBBUG=" -d";;
        --debug         ) DEBBUG=" -d";;
        -y              ) FORCEYES=force;;
        --force-yes     ) FORCEYES=force;;
        -v              ) BLOCK_GUI=yes;check_appname_version and_echo;;
        --version       ) BLOCK_GUI=yes;check_appname_version and_echo;;
        --g2s-debug     ) G2SVERBOSE=" -v";;
        --esp           ) BLOCK_GUI=yes;[[ $EUID -ne 0 ]] && echo "Root privileges are required to run $APPNAME --esp" || esp_detect;;
        --no-filter     ) FILTERED="";;
        --python2       ) PY=python2;;
        -b              ) BLOCK_GUI=yes;[[ $EUID -ne 0 ]] && echo "Root privileges are required to run $APPNAME -i" || bootinfo-cli;;
        --bootinfo      ) BLOCK_GUI=yes;[[ $EUID -ne 0 ]] && echo "Root privileges are required to run $APPNAME -i" || bootinfo-cli;;
        -u           ) BLOCK_GUI=yes;[[ $EUID -ne 0 ]] && echo "Root privileges are required to run $APPNAME -i" || bootinfo-cli pastebin;;
        --bootinfo-url  ) BLOCK_GUI=yes;[[ $EUID -ne 0 ]] && echo "Root privileges are required to run $APPNAME -i" || bootinfo-cli pastebin;;
        *               ) 
            if [[ "$arg" =~ "-t=" ]];then #https://bugs.launchpad.net/boot-info/+bug/1719537
                BLOCK_GUI=yes
                if [[ $EUID -ne 0 ]];then
                    echo "Root privileges are required to run $APPNAME -t"
                else
                    TINT="${arg#-t=}"
                    if [[ "$(echo $TINT | grep "^[ [:digit:] ]*$")" ]];then
                        . /usr/share/boot-sav/gui-init.sh
                        translat_init
                        lib_init
                        check_os_and_mount_blkid_partitions_gui
                        tail_common_logs -$TINT
                        unmount_all_blkid_partitions_except_df
                    else
                        echo "-t= must be followed by an integer, e.g. $APPNAME -t=30"
                    fi
                fi
            fi
            ;;
    esac
done
if [[ ! "$BLOCK_GUI" ]];then
	# Ask root privileges
	if [[ $EUID -ne 0 ]];then
		if [[ "$1" ]];then
			echo "Root privileges are required to run $APPNAME $*"; exit
		fi
		if hash xhost && ! xhost | grep -qi 'SI:localuser:root';then #workaround bug#1713313
			xhost +SI:localuser:root > /dev/null
		fi
#		if hash pkexec;then
#			pkexec $APPNAME-bin
#		elif hash gksudo;then
#			gksudo $APPNAME-bin #gksu and su dont work in Kubuntu
#		elif hash gksu;then
#			gksu $APPNAME-bin
#		elif hash kdesudo;then
#			kdesudo $APPNAME-bin
#		elif hash xdg-su;then
#			xdg-su -c $APPNAME-bin
		if hash sudo;then
			sudo $APPNAME-bin $*
		elif hash su;then
			su -c $APPNAME-bin $*
		else
			echo "Root privileges are required to run $APPNAME."
		fi
		exit 1
	fi
	# Launch the Glade window via glade2script
    G2S=error
	if [[ -f "/usr/bin/glade2script-$PY" ]];then
        G2S="glade2script-$PY"
    elif [[ -f "/usr/bin/glade2script" ]];then
        [[ "$(cat /usr/bin/glade2script | grep "/usr/bin/$PY" )" ]] && G2S=glade2script || echo "Please install the glade2script-$PY package."
    elif [[ "$*" =~ -python2 ]];then
        echo "Please install the glade2script-python2 package."
    elif [[ "$*" =~ -python3 ]];then
        echo "Please install the glade2script-python3 package."
    else
        PY=python2
        if [[ -f "/usr/bin/glade2script-$PY" ]];then
            G2S="glade2script-$PY"
        elif [[ "$(cat /usr/bin/glade2script | grep "/usr/bin/$PY" )" ]];then
            G2S="glade2script"
        else
            zenity --width=400 --error --title="$APPNAME" --text="Please reinstall $APPNAME, boot-sav, and glade2script packages." 2>/dev/null
        fi
	fi

    if [[ "$G2S" =~ glade ]];then
		[[ ! "$(type -p $G2S)" ]] && echo "Warning: type -p $G2S is false."
		
		${G2S}${DEBBUG}${G2SVERBOSE} -g /usr/share/boot-sav/boot-sav.glade -s "/usr/share/boot-sav/$APPNAME.sh $*" \
		--combobox="@@_combobox_format_partition@@col" \
		--combobox="@@_combobox_bootflag@@col" \
		--combobox="@@_combobox_ostoboot_bydefault@@col" \
		--combobox="@@_combobox_purge_grub@@col" \
		--combobox="@@_combobox_separateboot@@col" \
		--combobox="@@_combobox_efi@@col" \
		--combobox="@@_combobox_sepusr@@col" \
		--combobox="@@_combobox_place_grub@@col" \
		--combobox="@@_combobox_add_kernel_option@@col" \
		--combobox="@@_combobox_restore_mbrof@@col" \
		--combobox="@@_combobox_partition_booted_bymbr@@col"
	fi
	if hash xhost && xhost | grep -qi 'SI:localuser:root';then
		xhost -SI:localuser:root > /dev/null
	fi
fi
exit 0
}


