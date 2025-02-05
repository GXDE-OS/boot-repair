#! /bin/bash
# Copyright 2014 Yann MRN
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
#/// TRANSLATORS: this will appear as the application name
APPNAME2=$(eval_gettext $'Boot Repair')  #for the .desktop & more
#/// TRANSLATORS: this is the short description of the application
Repair_the_boot_of_the_computer=$(eval_gettext $'Repair the boot of the computer')  #for the .desktop
Recommended_repair=$(eval_gettext $'Recommended repair')
repairs_most_frequent_problems=$(eval_gettext $'repairs most frequent problems')
#SF
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'${APPNAME}, simple tool to recover access to your Operating Systems.')
sf=$(eval_gettext $'Easy-to-use (repair in 1 click ! )')
sf=$(eval_gettext $'Helpful (Boot-Info summary to get help by email or on your favorite forum)')
sf=$(eval_gettext $'Whatever the systems installed on your disk,')
sf=$(eval_gettext $'Safe (automatic backups)')
sf=$(eval_gettext $'Reliable (300.000 users per year)')
sf=$(eval_gettext $'Can recover access to Windows (XP, Vista, Windows7, Windows8).')
sf=$(eval_gettext $'Can recover access to Debian, Ubuntu, Mint, Fedora, OpenSuse, ArchLinux...')
sf=$(eval_gettext $'Can recover access to any OS (Windows, MacOS, Linux..) if your PC contains Debian, Ubuntu, Mint, Fedora, OpenSuse, ArchLinux, or derivative.')
sf=$(eval_gettext $'Can repair the boot when you have the "GRUB Recovery" error message')
sf=$(eval_gettext $'Options to reinstall GRUB2/GRUB1 bootloader easily (OS by default, purge, unhide, kernel options..)')
sf=$(eval_gettext $'and much more ! (UEFI, SecureBoot, RAID, LVM, Wubi, filesystem repair...)')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'or: boot on a Boot-Repair-Disk. ${APPNAME} will be launched automatically.')
sf=$(eval_gettext $'Launch Boot-Repair, then click the "Recommended repair" button. When repair is finished, write on a paper the URL (paste.ubuntu.com/XXXXX) that appears on the screen, then reboot and check if you recovered access to your OSs.')
sf=$(eval_gettext $'If the repair did not succeed, indicate the URL to boot.repair@gmail.com in order to get help.')
sf=$(eval_gettext $'Warning: the default settings of the Advanced Options are the ones used by the "Recommended Repair". Changing them may worsen your problem. Do not modify them before asking advice.')
#/// Please do not translate ${RESCUEDISK}
sf=$(eval_gettext $'${RESCUEDISK}, the 'must-have' rescue CD !')
sf=$(eval_gettext $'Here is THE Rescue Disk that you should keep close to your computer !')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'runs automatically ${APPNAME} rescue tool at start-up')
#/// Please do not translate ${TOOL1} and ${TOOL2}
sf=$(eval_gettext $'also contains the ${TOOL1} and ${TOOL2} tools.')
sf=$(eval_gettext $'repairs recent (UEFI) computers as well as old PCs')
#/// Please do not translate ${RESCUEDISK}
sf=$(eval_gettext $'DOWNLOAD ${RESCUEDISK}')
#/// Please do not translate ${TOOL1} and ${TOOL2}
sf=$(eval_gettext $'Then burn it on a live-USB key via ${TOOL1} or ${TOOL2}.')
sf=$(eval_gettext $'do not burn it on CD/DVD if your PC came with Windows8')
#/// Please do not translate ${RESCUEDISK}
sf=$(eval_gettext $'Insert ${RESCUEDISK} and reboot the computer')
sf=$(eval_gettext $'Choose your language')
sf=$(eval_gettext $'Connect internet if possible')
sf=$(eval_gettext $'Click "Recommended repair"')
sf=$(eval_gettext $'Reboot the computer')
sf=$(eval_gettext $'solves the majority of bootsector/GRUB/MBR problems')
sf=$(eval_gettext $'HOW TO GET AND USE THE DISK')
}

update_translations_diff() {
#/// Please do not translate ${THISPARTITION}
THISPARTITION_is_nearly_full=$(eval_gettext $'The ${THISPARTITION} partition is nearly full.')
#/// Please do not translate ${THISPARTITION}
THISPARTITION_is_still_full=$(eval_gettext $'The ${THISPARTITION} partition is still full.')
#/// Please do not translate ${PARTBS}
Please_fix_bs_of_PARTBS=$(eval_gettext $'Please repair the bootsector of the ${PARTBS} partition.')
}

