#! /bin/bash
# Copyright 2011-2023 Yann MRN
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

APPNAME=boot-info
CLEANNAME=Boot-Info
. /usr/share/boot-sav/gui-init.sh
gui_init $*
if [[ "$choice" != exit ]];then
	check_os_and_mount_blkid_partitions_gui
	check_which_mbr_can_be_restored
	[[ "$DEBBUG" ]] && echo_df_and_fdisk
	mainwindow_filling
	warnings_and_show_mainwindow
fi
loop_of_the_glade2script_interface
