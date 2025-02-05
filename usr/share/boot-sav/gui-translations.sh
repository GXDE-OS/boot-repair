#! /bin/bash
# Copyright 2017 Yann MRN
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


first_translations() {
#/// About (the software)
About=$(eval_gettext $'About')
Can_you_boot_windows=$(eval_gettext $'When rebooting the computer, can you successfully start Windows?')
Scanning_systems=$(eval_gettext $'Scanning systems')
Operation_aborted=$(eval_gettext $'Operation aborted')
It_is_recommended_to_use_latest_version=$(eval_gettext $'It is strongly recommended to always use the latest version of this software.')
Do_you_want_to_update=$(eval_gettext $'Do you want the software be automatically updated now ?')
this_will_update_from_ppa=$(eval_gettext $'this will download and install last version from its PPA')
No_change_on_your_pc=$(eval_gettext $'No change has been performed on your computer.')
No_OS_found_on_this_pc=$(eval_gettext $'No OS has been found on this computer.')
Please_use_in_live_session=$(eval_gettext $'Please use this software in a live-session (live-CD or live-USB).')
Please_use_in_a_64bits_session=$(eval_gettext $'Please use this software in a 64bits session.')
Ubuntu_installed_in_Windows_via_Wubi=$(eval_gettext $'Ubuntu installed in Windows (via Wubi)')
No_internet_connection_detected=$(eval_gettext $'No internet connection detected')
The_software_could_not_be_updated=$(eval_gettext $'The software could not be updated.')
Please_close_all_your_package_managers=$(eval_gettext $'Please close all your package managers')
Software_Centre=$(eval_gettext $'Software Center')
Update_Manager=$(eval_gettext $'Update Manager')
Do_you_want_to_continue=$(eval_gettext $'Do you want to continue?')
Are_u_sure_u_want_to_continue_anyway=$(eval_gettext $'Are you sure you want to continue anyway?')
Then_try_again=$(eval_gettext $'Then try again.')
Please_connect_internet=$(eval_gettext $'Please connect internet.')
Then_close_this_window=$(eval_gettext $'Then close this window.')
assemble_mdraid_arrays=$(eval_gettext $'Do you want to assemble software raid (MDRaid) arrays?')
activate_dmraid=$(eval_gettext $'Do you want to activate [dmraid] (fakeraid)?')
#/// Make sure the options are ok
Please_check_options=$(eval_gettext $'Please check the options.')
There_may_be_newer_version=$(eval_gettext $'A new version of this software is available, please check its official website.')
#/// Please do not translate [dmraid] and MDraid
dmraid_may_interfere_MDraid_remove=$(eval_gettext $'[dmraid] packages may interfere with MDraid. Do you want to remove them?')
#/// Please do not translate Boot-Repair-Disk
Alternatively_you_can_use=$(eval_gettext $'Alternatively, you can use Boot-Repair-Disk which contains last version of this software.')
BRDISK="Boot-Repair-Disk (www.sourceforge.net/p/boot-repair-cd)"
BRDISK2="notused"
#/// Please do not translate ${BRDISK} nor ${BRDISK2}
Alternatively_you_can_use_BRDISK=$(eval_gettext $'Alternatively, you can use ${BRDISK} or ${BRDISK2} which contain a recent version of this software.')
DISK33="Boot-Repair-Disk-64bit (www.sourceforge.net/p/boot-repair-cd)"
#/// Please do not translate ${DISK33}
Please_use_DISK33_which_is_efi_ok=$(eval_gettext $'Please use ${DISK33} which contains an EFI-compatible version of this software.')
GRUB_reinstallation_has_been_cancelled=$(eval_gettext $'GRUB reinstallation has been cancelled.')
This_will_install_an_obsolete_bootloader=$(eval_gettext $'This will install an obsolete bootloader')
Please_wait=$(eval_gettext $'Please wait few seconds...')
#/// this string must be as short as possible
The_system_now_in_use=$(eval_gettext $'The OS now in use')
Advanced_options=$(eval_gettext $'Advanced options')
Main_options=$(eval_gettext $'Main options')
GRUB_location=$(eval_gettext $'GRUB location')
GRUB_options=$(eval_gettext $'GRUB options')
MBR_options=$(eval_gettext $'MBR options')
Other_options=$(eval_gettext $'Other options')
Reinstall_GRUB=$(eval_gettext $'Reinstall GRUB')
Restore_MBR=$(eval_gettext $'Restore MBR')
Unhide_boot_menu=$(eval_gettext $'Unhide boot menu')
seconds=$(eval_gettext $'seconds')
Restore_the_MBR_of=$(eval_gettext $'Restore the MBR of:')
Partition_booted_by_the_MBR=$(eval_gettext $'Partition booted by the MBR:')
#/// Please make this string as short as possible
OS_to_boot_by_default=$(eval_gettext $'OS to boot by default:')
Purge_and_reinstall_the_grub_of=$(eval_gettext $'Purge and reinstall the GRUB of:')
Purge_before_reinstalling_grub=$(eval_gettext $'Purge GRUB before reinstalling it')
Place_GRUB_in_all_disks=$(eval_gettext $'Place GRUB in all disks')
except_USB_disks_without_OS=$(eval_gettext $'except USB disks without OS')
Place_GRUB_into=$(eval_gettext $'Place GRUB into:')
Force_GRUB_into=$(eval_gettext $'Force GRUB into:')
#/// 1 bootloader loads a 2nd one
for_chainloader=$(eval_gettext $'for chainloader')
Blank_extra_space=$(eval_gettext $'Reset extra space after MBR')
Warning_blankextra=$(eval_gettext $'Warning: some applications using DRM or some OEM system tools may not work afterwards.')
#/// Please do not translate GRUB_GFXMODE
Uncomment_GRUB_GFXMODE=$(eval_gettext $'Uncomment GRUB_GFXMODE')
Ata_disk=$(eval_gettext $'ATA disk support')
Add_a_kernel_option=$(eval_gettext $'Add a kernel option:')
Edit_GRUB_configuration_file=$(eval_gettext $'Edit GRUB configuration file')
Applying_changes=$(eval_gettext $'Applying changes.')
This_may_require_several_minutes=$(eval_gettext $'This may require several minutes...')
This_will_enable_this_feature=$(eval_gettext $'This will enable this feature.')
Checking_updates=$(eval_gettext $'Checking updates')
The_updates_could_not_be_checked=$(eval_gettext $'The updates repository could not be reached.')
Updating=$(eval_gettext $'Updating')
Purge_and_reinstall_kernels=$(eval_gettext $'Purge kernels then reinstall last kernel')
Please_setup_bios_on_removable_disk=$(eval_gettext $'Please do not forget to make your BIOS boot on the removable disk!')
Filesystem_repair_need_unmount_parts=$(eval_gettext $'Filesystem repair requires to unmount partitions.')
Please_close_all_programs=$(eval_gettext $'Please close all your programs.')
Check_internet=$(eval_gettext $'Check internet connection')
Please_backup_data=$(eval_gettext $'Please backup your data before this operation.')
Encryption_detected=$(eval_gettext $'Encrypted partition detected.')
Please_decrypt=$(eval_gettext $'Please retry after mounting your encrypted partitions so that the tool can verify their contents.')
You_may_want_decrypt=$(eval_gettext $'You may want to retry after mounting your encrypted partitions so that the tool can verify their contents.')
Plz_reboot_n_try_again_from_new_livesession=$(eval_gettext $'Please reboot and try again from a new live session.')
#/// Please indicate an equivalent link in your language
Decrypt_links=$(eval_gettext $'https://help.ubuntu.com/community/EncryptedPrivateDirectory')
It_maybe_incompatible_with_pc=$(eval_gettext $'It is probably incompatible with your computer.')
Please_install_efi_comp=$(eval_gettext $'Please install an EFI-compatible system.')
You_may_want_install_64os=$(eval_gettext $'You may want to install a 64-bit Linux instead.')
Continuing_without_internet_would_unbootable=$(eval_gettext $'Warning: continuing without internet would leave your system unbootable.')
PROGRAM6=Refind
#/// Please do not translate ${PROGRAM6}
You_may_also_want_to_install_PROGRAM6=$(eval_gettext $'You may also want to install ${PROGRAM6}.')
#/// Please indicate an equivalent link in your language
BootPartitionDoc=$(eval_gettext $'https://help.ubuntu.com/community/BootPartition')
Backup_and_rename_efi_files=$(eval_gettext $'Use the standard EFI file')
Msefi_too=$(eval_gettext $'Backup and rename Windows EFI files')
Restore_EFI_backups=$(eval_gettext $'Restore EFI backups')
Broken_wubi_detected=$(eval_gettext $'A broken Wubi has been detected. Please fix it this way:')
#/// Please indicate an equivalent link in your language
Missingrootdiskurl=$(eval_gettext $'https://wiki.ubuntu.com/WubiGuide#Cannot_boot_into_Ubuntu')
Translate=$(eval_gettext $'Translate')
#/// Please do not translate ${EMAIL1}
PLEASECONTACT=$(eval_gettext $'Please report this message to ${EMAIL1}')
Thanks=$(eval_gettext $'Credits')
Backup_table=$(eval_gettext $'Backup partition tables, bootsectors and logs')
Participate_stats=$(eval_gettext $'Participate to statistics of use')
Please_choose_folder_to_put_backup=$(eval_gettext $'Please choose a folder to put the backup into.')
USB_disk_recommended=$(eval_gettext $'It is recommended to choose a USB disk.')
start_of_the_disk=$(eval_gettext $'start of the disk')
#/// Please do not translate BootInfo
Create_a_BootInfo_report=$(eval_gettext $'Create a BootInfo summary')
to_get_help_by_email_or_forum=$(eval_gettext $'to get help by email or forum')
requires_internet=$(eval_gettext $'requires internet')
Please_note_the_following_url=$(eval_gettext $'Please note the following URL:')
Please_write_url_on_paper=$(eval_gettext $'Please write on a paper the following URL:')
Indicate_it_in_case_still_pb=$(eval_gettext $'In case you still experience boot problem, indicate this URL to:')
Indicate_its_content_in_case_still_pb=$(eval_gettext $'In case you still experience boot problem, indicate its content to:')
or_to_your_favorite_support_forum=$(eval_gettext $'or to your favorite support forum.')
Indicate_url_if_pb=$(eval_gettext $'If you are experiencing boot issues, indicate this URL to people who help you.')
Indicate_content_if_pb=$(eval_gettext $'If you are experiencing boot issues, indicate the content of this file to people who help you.')
On_forums_eg=$(eval_gettext $'For example on forums or via email.')
Please_open_a_terminal_then_type_the_following_command=$(eval_gettext $'Please open a terminal then type (or copy-paste) the following command:')
Please_open_a_terminal_then_type_the_following_commands=$(eval_gettext $'Please open a terminal then type (or copy-paste) the following commands:')
Then_choose_Yes_when_the_below_window_appears=$(eval_gettext $'Then when a window similar to the one below appear in your terminal, use Tab and Enter keys in order to confirm GRUB removal.')
Then_choose_Yes_if_the_below_window_appears=$(eval_gettext $'If a window similar to the one below appears, use Tab and Enter keys in order to confirm GRUB removal.')
Now_please_type_this_command_in_the_terminal=$(eval_gettext $'Now please type (or copy-paste) the following command in a terminal:')
Then_select_correct_device_when_the_below_window_appears=$(eval_gettext $'Then when menus similar to the one below appear in your terminal, use Tab, Space and Enter keys in order to install GRUB in the disk you wish.')
Then_select_correct_device_if_the_below_window_appears=$(eval_gettext $'If a menu similar to the one below appears, use Tab, Space and Enter keys in order to install GRUB in the disk you wish.')
GRUB_is_still_present=$(eval_gettext $'GRUB is still present.')
GRUB_is_still_absent=$(eval_gettext $'GRUB is still absent.')
Please_try_again=$(eval_gettext $'Please try again.')
Place_bootflag=$(eval_gettext $'Place the boot flag on:')
You_may_want_to_retry_after_converting_SFS=$(eval_gettext $'You may want to retry after converting Windows dynamic partitioning (SFS partitions) to a basic disk.')
No_filesystem=$(eval_gettext $'unformatted filesystem')
Is_there_RAID_on_this_pc=$(eval_gettext $'Is there RAID on this computer?')
If_any_fail_try_other=$(eval_gettext $'(if any choice fails, please retry with the other)')
use_it_from_usb=$(eval_gettext $'(use it from live-USB, not from DVD)') #
Repair_file_systems=$(eval_gettext $'Repair file systems')
Repair_Wubi=$(eval_gettext $'Repair Wubi filesystems')
The_browser_will_access_wubi=$(eval_gettext $'The file browser that just opened will let you access your Wubi (Linux installed into Windows) files.')
Please_backup_data_now=$(eval_gettext $'Please backup your data now!')
This_will_try_repair_wubi=$(eval_gettext $'This will try to repair Wubi filesystem.')
Please_update_main_bootloader=$(eval_gettext $'Please do not forget to update your main bootloader!')
Successfully_processed=$(eval_gettext $'Boot successfully repaired.')
An_error_occurred_during=$(eval_gettext $'An error occurred during the repair.')
You_can_now_reboot=$(eval_gettext $'You can now reboot your computer.')
This_can_prevent_to_start_it=$(eval_gettext $'This can prevent to start it')
Power_manager_error=$(eval_gettext $'e.g. you may get a Power Manager error')
Please_use_the_file_browser=$(eval_gettext $'Please use the file browser that just opened to delete unused files (or transfer them to another disk).')
Close_this_window_when_finished=$(eval_gettext $'Close this window when you have finished.')
Upload_report=$(eval_gettext $'Upload the report to a pastebin')
Via_command_in_win=$(eval_gettext $'For example you can boot into Windows, then type the following command in an admin command prompt:')
Current_session_is_CSM=$(eval_gettext $'The current session is in BIOS-compatibility mode.')
Only_MBR_of_current_OS_was_fixed=$(eval_gettext $'Only the MBR of the current OS was fixed.')
To_fix_other_MBRs_use_again_from_live_session=$(eval_gettext $'To fix other MBRs, please use the tool again from live-session.')
Use_in_live_session_with_your_BIOS_set_in_Legacy_mode=$(eval_gettext $'Please enable BIOS-compatibility/CSM/Legacy mode in your UEFI firmware, and use this software from a live-CD (or live-USB).')
Use_in_live_session_with_your_BIOS_set_in_UEFI_mode=$(eval_gettext $'Please disable BIOS-compatibility/CSM/Legacy mode in your UEFI firmware, and use this software from a live-CD (or live-USB) that is compatible with UEFI booting mode.')
If_boot_win_try_change_firmware_order=$(eval_gettext $'If your computer reboots directly into Windows, try to change the boot order in your UEFI firmware.')
If_firmware_blocked_change_win_order=$(eval_gettext $'If your UEFI firmware does not allow to change the boot order, change the default boot entry of the Windows bootloader.')
Please_check_advanced_options=$(eval_gettext $'Please check the Advanced Options.')
zfs_already_activated_please_retry=$(eval_gettext $'ZFS pools already activated. Please retry from a new live-session, without activating the pools.')
#SF
sf=$(eval_gettext $'Free (GPL open-source license)')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'GET ${APPNAME}:')
sf=$(eval_gettext $'Whatever the systems installed on your disk,')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'boot on a Debian (or derivatives: Ubuntu, Linux Mint...) disk, either normal session, or live-CD, or live-USB. Then install ${APPNAME} in it, either via PPA for Ubuntu/Mint, or DEBs for Debian.')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'USE ${APPNAME}:')
sf=$(eval_gettext $'GET HELP:')
sf=$(eval_gettext $'by Email (boot.repair@gmail.com)')
sf=$(eval_gettext $'HELP THE PROJECT:')
sf=$(eval_gettext $'Translate, Propose patches, or Donate (Paypal account: boot.repair@gmail.com)')
sf=$(eval_gettext $'DISCLAIMER:')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'${APPNAME} is distributed in the hope that it will be useful, but without any warranty.')
#/// Please do not translate ${APPNAME}
sf=$(eval_gettext $'Please be aware that ${APPNAME} writes logs and backups on disks, collects anonymous statistics about its use, and creates Pastebin (if you select that option) containing basic system data such as partition labels, UUIDs and mount points.')
sf=$(eval_gettext $'Just disconnect internet if you want these data remain local.')

first_translations_extra
first_translations_diff
update_translations
[[ ! "$(ls /usr/share 2>/dev/null | grep 't-s')" ]] && choice=exit
}

update_translations() {
[[ "$APPNAME" =~ fo ]] && TOOL3=Boot-Repair || TOOL3="$APPNAME2"
#/// Please do not translate [${OPTION}]
Do_you_want_activate_OPTION=$(eval_gettext $'Do you want to activate [${OPTION}]?')
#/// Please do not translate [${PACKAGELIST}]
You_may_want_to_retry_after_installing_PACKAGELIST=$(eval_gettext $'You may want to retry after installing the [${PACKAGELIST}] packages.')
#/// Please do not translate FUNCTION. Neutral and singular.
FUNCTION_detected=$(eval_gettext $'${FUNCTION} detected.')
#/// Please do not translate [${PACKAGELIST}]
This_will_install_PACKAGELIST=$(eval_gettext $'This will install the [${PACKAGELIST}] packages.')
#/// Please do not translate [${PACKAGELIST}]
Do_you_want_to_install_PACKAGELIST=$(eval_gettext $'Do you want to install the [${PACKAGELIST}] packages?')
#/// Please do not translate [${PACKAGELIST}]
please_install_PACKAGELIST=$(eval_gettext $'Please install the [${PACKAGELIST}] packages.')
#/// Please do not translate [${NEEDEDREP}]
This_may_require_to_enable_NEEDEDREP=$(eval_gettext $'This may require to enable [${NEEDEDREP}] repositories.')
#/// Please do not translate ${FILE}
logs_have_been_saved_into_FILE=$(eval_gettext $'Partition tables, MBRs and logs have been saved into ${FILE}')
#/// Please do not translate [${PACKAGELIST}] nor ${DISTRO}
Please_enable_a_rep_for_PACKAGELIST_pack_in_DISTRO=$(eval_gettext $'Please enable a repository containing the [${PACKAGELIST}] packages in the software sources of ${DISTRO}.')
#/// Please do not translate ${TYPE3}
Separate_TYPE3_partition=$(eval_gettext $'Separate ${TYPE3} partition:')
#/// Please do not translate [${BUG}]
solves_BUG=$(eval_gettext $'solves the [${BUG}] error')
#/// Please do not translate ${FUNCTION}
Enabling_FUNCTION=$(eval_gettext $'Enabling ${FUNCTION}')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_change_to_MODE2=$(eval_gettext $'The boot of your PC is in ${MODE1} mode. Please change it to ${MODE2} mode.')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_may_need_change_to_MODE2=$(eval_gettext $'The boot of your PC is in ${MODE1} mode. You may want to retry after changing it to ${MODE2} mode.')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_but_no_MODE2_part_detected=$(eval_gettext $'The boot of your PC is in ${MODE1} mode, but no ${MODE2} partition was detected.')
#/// Please do not translate ${TYP}
You_may_want_to_retry_after_creating_TYP_part=$(eval_gettext $'You may want to retry after creating a ${TYP} partition')
#/// Please do not translate ${TYP}
Please_create_TYP_part=$(eval_gettext $'Please create a ${TYP} partition')
#/// Please do not translate ${FILENAME}
FILENAME_has_been_created=$(eval_gettext $'A new file (${FILENAME}) will open in your text viewer.')
#/// Please do not translate ${TOOL1}
Via_TOOL1=$(eval_gettext $'This can be performed via tools such as ${TOOL1}.')
#/// Please do not translate ${TOOL1} nor ${TOOL2}
Via_TOOL1_or_TOOL2=$(eval_gettext $'This can be performed via tools such as ${TOOL1} or ${TOOL2}.')
#/// Please do not translate ${DISK1}
Is_DISK1_removable=$(eval_gettext $'Is ${DISK1} a removable disk?')
#/// Please use lower-case letters for "flag" (not "Flag"), and do not translate FLAGTYP
FLAGTYP_flag=$(eval_gettext $'${FLAGTYP} flag')
#/// Please do not translate ${DISK1}
Please_setup_bios_on_DISK1=$(eval_gettext $'Please do not forget to make your BIOS boot on ${DISK1} disk!')
#/// Please do not translate ${FILE1}
Please_setup_firmware_on_FILE1=$(eval_gettext $'Please do not forget to make your UEFI firmware boot on ${FILE1} file!')
#/// Please do not translate ${SYSTEM1} nor ${FILE1}
Please_setup_firmware_on_SYSTEM1_FILE1=$(eval_gettext $'Please do not forget to make your UEFI firmware boot on the ${SYSTEM1} entry (${FILE1} file) !')
#/// Please do not translate [${OPTION}]
You_may_want_to_retry_after_activating_OPTION=$(eval_gettext $'You may want to retry after activating the [${OPTION}] option.')
#/// Please do not translate [${OPTION}]
You_may_want_to_retry_after_deactivating_OPTION=$(eval_gettext $'You may want to retry after deactivating the [${OPTION}] option.')
#/// Please do not translate [${OPTION}]
Alternatively_you_may_want_to_retry_after_deactivating_OPTION=$(eval_gettext $'Alternatively, you may want to retry after deactivating the [${OPTION}] option.')
#/// Please do not translate [${OPTION1}]
Alternatively_you_can_try_OPTION1=$(eval_gettext $'Alternatively, you can retry after activating the [${OPTION1}] option.')
#/// Please do not translate ${SYSTEM1}
Repair_SYSTEM1_bootfiles=$(eval_gettext $'Repair ${SYSTEM1} boot files')
#/// Please do not translate [${SYSTEM2}]
Boot_files_of_SYSTEM2_are_far=$(eval_gettext $'The boot files of [${SYSTEM2}] are far from the start of the disk. Your BIOS may not detect them.')
#/// Please do not translate [${OPTION2}] nor [${TOOL3}]
Then_select_this_part_via_OPTION2_of_TOOL3=$(eval_gettext $'Then select this partition via the [${OPTION2}] option of [${TOOL3}].')
#/// Please do not translate ${PARTITION1}
You_have_installed_on_PARTITION1_EFI_incompat_Linux=$(eval_gettext $'You have installed on ${PARTITION1} a Linux version which is not EFI-compatible.')
#/// Please do not translate ${PARTITION1}
You_have_installed_on_PARTITION1_EFI_incompat=$(eval_gettext $'Your Linux on ${PARTITION1} is 32-bit, so it may be incompatible with your 64-bit UEFI firmware.')
#/// Please do not translate ${SYSTEM1} and ${SYSTEM2}
Eg_SYSTEM1_SYSTEM2_EFI_comp_systems=$(eval_gettext $'For example, ${SYSTEM1} and ${SYSTEM2} are EFI-compatible systems.')
#/// Please do not translate ${DISK44} nor ${FUNCTION44}
Please_use_DISK44_which_is_FUNCTION44_ok=$(eval_gettext $'Please use ${DISK44} which contains a ${FUNCTION44}-compatible version of this software.')
#/// Please do not translate ${SYSTEM3}
SYSTEM3_is_now_without_GRUB=$(eval_gettext $'${SYSTEM3} is now without GRUB.')
#/// Please do not translate ${DISK5}
DISK5_is_a_removable_disk=$(eval_gettext $'${DISK5} is a removable disk.')
#/// Please do not translate ${OPTION5}
Please_disable_OPTION5_in_BIOS=$(eval_gettext $'Please disable ${OPTION5} in the BIOS.')
#/// Please do not translate ${DISK5}
Eg_use_DISK5_usb_efi=$(eval_gettext $'For example, use a live-USB of ${DISK5}, after making sure your BIOS is set up to boot USB in EFI mode.')
#/// Please do not translate ${SYSTEM6} nor ${COMMANDTOTYP5} nor ${SYSTEM8}
Reboot_in_SYSTEM6_and_COMMANDTOTYP5_to_add_SYSTEM8_entry=$(eval_gettext $'Please set your BIOS in Legacy mode in order to start your ${SYSTEM6}, then type command [${COMMANDTOTYP5}] in order to add the ${SYSTEM8} entry to your GRUB menu.')
#/// Please do not translate ${PACKAGELIST} nor ${APPNAME}
If_possible_update_PACKAGELIST_then_restart_APPNAME=$(eval_gettext $'If possible, please update the [${PACKAGELIST}] packages, then restart the ${APPNAME} program.')
#/// Please do not translate ${PATH1}
Do_you_want_to_delete_old_auto_backups_from_PATH1=$(eval_gettext $'Do you want to delete old logs and backups located in ${PATH1} ?')
#/// Please do not translate ${SYSTEM2}
Plz_close_SYSTEM2_installer_then_retry=$(eval_gettext $'Please close the ${SYSTEM2} installer, then retry.')
#/// Please do not translate ${HIDDENESP}
You_may_want_retry_after_remov_hidden_flag_from_HIDDENESP=$(eval_gettext $'You may want to retry after removing the [hidden] flag from the ${HIDDENESP} partition.')
#/// Please do not translate ${PART1}
This_will_mount_PART1_to_new_mountpoint_without_special_characters=$(eval_gettext $'This will modify the mount point of ${PART1} in order to remove spaces and special characters.')
#/// Please do not translate ${PARTB}
Do_u_wanna_remove_hidden_flag_from_PARTB=$(eval_gettext $'Do you want to remove the [hidden] flag of ${PARTB} ?')
#/// Please do not translate ${PACK7}
Please_retry_from_a_live_disc_containing_a_recent_version_of_PACK7=$(eval_gettext $'Please retry from a live disc containing a recent version of ${PACK7}.')
update_translations_diff
}
