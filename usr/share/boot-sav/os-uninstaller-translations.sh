#! /bin/bash
# Copyright 2013-2023 Yann MRN
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

first_translations_diff() {
APPNAME2=$(eval_gettext $'OS-Uninstaller')  #For .desktop & more
remove_any_os_from_your_computer=$(eval_gettext $'Remove any operating system from your computer')  #For .desktop
Wubi_not_supported=$(eval_gettext $'Wubi must be uninstalled from Windows.')
#/// Please translate and, if possible, indicate an equivalent link in your language
Wubi_see_for_more_info=$(eval_gettext $'See https://wiki.ubuntu.com/WubiGuide#Uninstallation for more information.')
Which_os_do_you_want_to_uninstall=$(eval_gettext $'Which operating system do you want to uninstall ?')
We_hope_you_enjoyed_it_and_feedback=$(eval_gettext $'We hope you enjoyed it and look forward to read your feedback.')
Please_update_main_bootloader=$(eval_gettext $'To finish the removal, please do not forget to update your bootloader!')
Wubi_will_be_lost=$(eval_gettext $'(the Linux distribution installed from this Windows via Wubi will be lost)')
This_partition_will_be_formatted=$(eval_gettext $'This partition will be formatted, please backup your documents before proceeding.')
These_partitions_will_be_formatted=$(eval_gettext $'These partitions will be formatted, please backup your documents before proceeding.')
An_error_occurred_during=$(eval_gettext $'An error occurred during the removal.')
Then_you_will_update_bootloader=$(eval_gettext $'Then you will need to update your bootloader.')
Are_you_ok_apply_changes=$(eval_gettext $'Apply changes?')
#SF
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'${APPNAME}, simple tool to remove an operating system in 1 click.')
sf=$(eval_gettext $'Easy-to-use (removal in 1 click)')
sf=$(eval_gettext $'Can remove any Windows (XP, Vista, Windows7, Windows8).')
sf=$(eval_gettext $'Can remove any Linux (Debian, Ubuntu, Mint, Fedora, OpenSuse, ArchLinux...).')
sf=$(eval_gettext $'Remark: if you want to uninstall Wubi (Ubuntu installed inside Windows), please follow this tutorial.')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'Launch ${APPNAME}, choose the system to remove, then click the "Apply" button.')
sf=$(eval_gettext $'When the removal is finished, reboot and check that your system has been removed.')
sf=$(eval_gettext $'Can recover access to Windows (XP, Vista, Windows7, Windows8).')
sf=$(eval_gettext $'Warning: the default settings of the Advanced Options are the recommended ones. Changing them may break your boot. Do not modify them before asking advice.')
#/// Please do not translate ${DISK} and ${APPNAME}
sf=$(eval_gettext $'or: boot on ${DISK}. A software (Boot-Repair) will be launched automatically, close it. Then launch ${APPNAME} from the bottom-left menu.')
}

update_translations_diff() {
#/// Please do not translate ${OS_TO_DELETE_NAME}
Uninstalling_os=$(eval_gettext $'Removing ${OS_TO_DELETE_NAME} ...')
#/// Please do not translate ${OS_TO_DELETE_NAME}
Successfully_processed=$(eval_gettext $'${OS_TO_DELETE_NAME} has been successfully removed.')
#/// Please do not translate ${OS_TO_DELETE_PARTITION}
Format_the_partition=$(eval_gettext $'Format the partition ${OS_TO_DELETE_PARTITION} into :')
#/// Please do not translate ${OS_TO_DELETE_NAME} and ${OS_TO_DELETE_PARTITION}
Do_you_really_want_to_uninstall_OS_TO_DELETE=$(eval_gettext $'Do you really want to uninstall ${OS_TO_DELETE_NAME} (${OS_TO_DELETE_PARTITION})?')
#/// Please do not translate ${OS_TO_DELETE_NAME} and ${OS_TO_DELETE_PARTITION}
This_will_remove_OS_TO_DELETE=$(eval_gettext $'This will remove ${OS_TO_DELETE_NAME} (${OS_TO_DELETE_PARTITION}).')
#/// Please do not translate ${WUBI_TO_DELETE_PARTITION}
This_will_also_delete_Wubi=$(eval_gettext $'(the Linux distribution installed into this Windows via Wubi on ${WUBI_TO_DELETE_PARTITION} will also be erased)')
}
