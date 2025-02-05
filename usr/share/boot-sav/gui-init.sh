#! /bin/bash
# Copyright 2012-2020 Yann MRN
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

gui_init() {
translat_init
######## Preparation of the first pulsate #########
PID=$$; FIFO=/tmp/FIFO${PID}; mkfifo ${FIFO}   #Initialization of the Glade2script interface
echo "SET@pulsatewindow.set_icon_from_file('''x-$APPNAME.png''')"
echo "SET@pulsatewindow.set_title('''$(eval_gettext "$CLEANNAME")''')" #can't replace by APPNAME2 yet
LAB="$(eval_gettext $'Scanning systems')"
echo "SET@_label0.set_text('''$LAB. $(eval_gettext $'This may require several minutes...')''')"
GUI=yes #before start_pulse
start_pulse
DEBBUG=""; FORCEYES=""; G2SPY_VERSION=-python3; G2SVERBOSE="";
FILTERED="(filtered)"  #[[ "$(blkid | grep zfs)" ]] && FILTERED=""
for arg in $*;do
    case "$arg" in
        -d              ) DEBBUG=" -d";;
        --debug         ) DEBBUG=" -d";;
        -y              ) FORCEYES=force;;
        --force-yes     ) FORCEYES=force;;
        --no-filter     ) FILTERED="";;
        --python2       ) G2SPY_VERSION=-python2;;
        --g2s-debug     ) G2SVERBOSE=" -v";;
    esac
done
lib_init
}

translat_init(){
######## Initialization of translations ######
set -a
source gettext.sh
set +a
export TEXTDOMAIN=boot-sav    # same .mo for boot-repair and os-uninstaller
export TEXTDOMAINDIR="/usr/share/locale"
. /usr/bin/gettext.sh
}

lib_init() {
. /usr/share/boot-sav/gui-translations.sh			#Dialogs common to os-uninstaller and boot-repair
. /usr/share/boot-sav/${APPNAME}-translations.sh	#Translations specific to the app
######## During first pulsate ########
if [[ -d /usr/share/boot-sav-extra ]];then
	. /usr/share/boot-sav-extra/gui-extra.sh	#Extra librairies
else
	. /usr/share/boot-sav/gui-dummy.sh				#Dummy librairies
fi
. /usr/share/boot-sav/bs-cmd_terminal.sh			#Librairies common to os-uninstaller, boot-repair, and boot-info
. /usr/share/boot-sav/gui-raid-lvm.sh				#Init librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-tab-other.sh				#Glade librairies common to os-uninstaller and boot-repair
DASH="==================="
EMAIL1="boot.repair@gmail.com"
PLEASECONTACT="Please report this message to $EMAIL1"
check_appname_version
first_translations
check_if_live_session				#after first_translations (for 'os currently used'), and before activate lvm for log order purpose
[[ -d /var/log/$APPNAME ]] && NEWUSER="" || NEWUSER=y  #bef update_soft
update_soft $* #after first_translations and check_if_live, and before mktemp
if [[ "$choice" != exit ]];then
    USERCHOICES="" #will be displayed in summary
    DATE="$(date +'%Y%m%d_%H%M')"; SECOND="$(date +'%S')"
    [[ "$(LANGUAGE=C LC_ALL=C lscpu | grep op- | grep 64-bit)" ]] && ARCHIPC=64 || ARCHIPC=32
    WGETTIM=10
    slist='/etc/apt/sources.list'
    NVRAMLOCKED=""
    NVRAMUNCHANGED=""
    if [[ -d /var/log/$APPNAME ]];then
        if [[ "$(ls /var/log/$APPNAME 2>/dev/null | grep -v day | wc -l)" > 2 ]];then # when 3 old logs or more
            DELETEOLDBACKUPS=y
            if [[ ! "$FORCEYES" ]];then
                PATH1="/var/log/$APPNAME"; update_translations
                if [[ "$GUI" ]];then
                    end_pulse
                    zenity --width=400 --question --title="$APPNAME2" --text="$Do_you_want_to_delete_old_auto_backups_from_PATH1" 2>/dev/null || DELETEOLDBACKUPS=""
                    start_pulse
                else
                    read -r -p "$Do_you_want_to_delete_old_auto_backups_from_PATH1 [yes/no] " response
                    [[ ! "$response" =~ y ]] || DELETEOLDBACKUPS=""
                fi
            fi
            [[ ! "$DEBBUG" ]] && [[ "$DELETEOLDBACKUPS" ]] && [[ "$APPNAME" ]] && rm -rf /var/log/$APPNAME/*
        fi
    fi
    LOGREP="/var/log/$APPNAME/$DATE$SECOND"; mkdir -p "$LOGREP"
    TMP_LOG="$LOGREP/$DATE_$APPNAME.log"
    TMP_LOG2="$LOGREP/$DATE_$APPNAME.log2"
    TMP_FOLDER_TO_BE_CLEARED="$(mktemp -td ${APPNAME}-XXXXX)"
    exec >& >(tee "$TMP_LOG")
    #fi
    propose_decrypt
    activate_lvm_if_needed
    [[ "$choice" != exit ]] && activate_raid_if_needed
    [[ "$choice" != exit ]] && activate_zfs_if_needed
    if [[ "$choice" = exit ]];then
        end_pulse
        echo "$No_change_on_your_pc"
        [[ "$GUI" ]] && zenity --width=400 --info --title="$APPNAME2" --text="$No_change_on_your_pc" 2>/dev/null
        [[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -r $TMP_FOLDER_TO_BE_CLEARED
        [[ "$GUI" ]] && echo 'EXIT@@' || exit 0
    else
        LAB="$Scanning_systems"
        [[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB. $This_may_require_several_minutes''')"
    fi
    . /usr/share/boot-sav/bs-common.sh					#Librairies common to os-uninstaller, boot-repair, and boot-info
    . /usr/share/boot-sav/gui-scan.sh					#Scan librairies common to os-uninstaller and boot-repair
    . /usr/share/boot-sav/gui-tab-main.sh				#Glade librairies common to os-uninstaller and boot-repair
    . /usr/share/boot-sav/gui-tab-loca.sh
    . /usr/share/boot-sav/gui-tab-grub.sh
    . /usr/share/boot-sav/gui-tab-mbr.sh
    . /usr/share/boot-sav/gui-actions.sh				#Action librairies common to os-uninstaller and boot-repair
    . /usr/share/boot-sav/gui-actions-grub.sh
    . /usr/share/boot-sav/gui-actions-purge.sh
    . /usr/share/boot-sav/${APPNAME}-actions.sh			#Action librairies specific to the app
    . /usr/share/boot-sav/${APPNAME}-gui.sh				#GUI librairies specific to the app
fi
}

######################################### Pulsate ###############################

start_pulse() {
if [[ "$GUI" ]];then
    echo 'SET@pulsatewindow.show()';
    while true; do 
        echo 'SET@_progressbar1.pulse()';
        sleep 0.2;
    done &
    pid_pulse=$!
fi
}

end_pulse() {
if [[ "$GUI" ]];then
    kill ${pid_pulse};
    echo 'SET@pulsatewindow.hide()'
fi
}

