#!/bin/bash
################################################################################
#                                                                              #
# Copyright (c) 2009-2010	Ulrich Meierfrankenfeld                            #
# Copyright (c) 2011-2012	Gert Hulselmans                                    #
# Copyright (c) 2013-2018	Andrei Borzenkov                                   #
# Copyright (c) 2019-2023	Yann MRN                                           #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or  #
# sell copies of the Software, and to permit persons to whom the Software is   #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING      #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS #
# IN THE SOFTWARE.                                                             #
#                                                                              #
################################################################################
# bootinfoscript with improvements for inclusion into boot-sav package         #
# Hosted at: https://launchpad.net/~yannubuntu/+archive/ubuntu/boot-repair     #
# Forked from: https://github.com/arvidjaar/bootinfoscript                     #
# Thanks to:   meierfra, caljohnsmith, jsjgruber, Arvidjaar                    #
# and baedacool (https://github.com/arvidjaar/bootinfoscript/issues/5)         #
################################################################################

bootinfoscript() {
. /usr/share/boot-sav/b-i-s-functions.sh

### Umount /boot/efi in order to scan efi files
umount /boot/efi 2>/dev/null

## Check if all necessary programs are available. ##
[[ "$DEBBUG" ]] && echo "[debug] Check_prg"
Programs='basename dirname expr fold pwd tr wc'; Programs_SBIN='filefrag losetup'; Check_Prog=1;
for Program in ${Programs} ${Programs_SBIN}; do
    if [ $(type ${Program} > /dev/null 2>&1 ; echo $?) -ne 0 ] ; then
        Check_Prog=0; echo "\"${Program}\" could not be found." >&2;
    fi
done

## The Grub2 (v1.99-2.00) core_dir string is contained in a LZMA stream. Need xz or lzma installed to decompress the stream.
[ $(type xz > /dev/null 2>&1 ; echo $?) -eq 0 ] && UNLZMA='xz --format=lzma --decompress' || UNLZMA='lzma -cd'

##   If we don't have gawk, look for "mawk v1.3.4" or newer.
[ $(type gawk > /dev/null 2>&1 ; echo $?) -eq 0 ] && AWK=gawk || AWK=mawk

## List of folders which might contain files used for chainloading. ##
Boot_Codes_Dir='
	/
	/NST/
	'

## List of files whose names will be displayed, if found. ##
Boot_Prog_Normal='
	/bootmgr	/BOOTMGR
	/boot/bcd	/BOOT/bcd	/Boot/bcd	/boot/BCD	/BOOT/BCD	/Boot/BCD
	/Windows/System32/winload.exe	/WINDOWS/system32/winload.exe	/WINDOWS/SYSTEM32/winload.exe	/windows/system32/winload.exe
	/Windows/System32/Winload.exe	/WINDOWS/system32/Winload.exe	/WINDOWS/SYSTEM32/Winload.exe	/windows/system32/Winload.exe
	/grldr		/GRLDR		/grldr.mbr	/GRLDR.MBR
	/ntldr		/NTLDR
	/NTDETECT.COM	/ntdetect.com
	/NTBOOTDD.SYS	/ntbootdd.sys
	/wubildr	/ubuntu/winboot/wubildr
	/wubildr.mbr	/ubuntu/winboot/wubildr.mbr
	/ubuntu/disks/root.disk
	/ubuntu/disks/home.disk
	/ubuntu/disks/swap.disk
	/core.img	/grub/core.img	/boot/grub/core.img
	/grub.exe
	/grub/i386-pc/core.img		/boot/grub/i386-pc/core.img
	/grub2/core.img			/boot/grub2/core.img
	/grub2/i386-pc/core.img		/boot/grub2/i386-pc/core.img
	/burg/core.img	/boot/burg/core.img
	/ldlinux.sys	/syslinux/ldlinux.sys	/boot/syslinux/ldlinux.sys
	/extlinux.sys	/extlinux/extlinux.sys	/boot/extlinux/extlinux.sys
	/boot/map	/map
	/DEFAULT.MNU	/default.mnu
	/IO.SYS		/io.sys
	/MSDOS.SYS	/msdos.sys 
	/KERNEL.SYS	/kernel.sys
	/DELLBIO.BIN	/dellbio.bin		/DELLRMK.BIN	/dellrmk.bin
	/COMMAND.COM	/command.com
	'
Boot_Prog_Fat='
	/bootmgr
	/boot/bcd
	/Windows/System32/winload.exe
	/grldr
	/grldr.mbr
	/ntldr
	/freeldr.sys
	/NTDETECT.COM
	/NTBOOTDD.SYS
	/wubildr
	/wubildr.mbr
	/ubuntu/winboot/wubildr
	/ubuntu/winboot/wubildr.mbr
	/ubuntu/disks/root.disk
	/ubuntu/disks/home.disk
	/ubuntu/disks/swap.disk
	/core.img	/grub/core.img		/boot/grub/core.img
	/grub/i386-pc/core.img			/boot/grub/i386-pc/core.img
	/grub2/core.img				/boot/grub2/core.img
	/grub2/i386-pc/core.img			/boot/grub2/i386-pc/core.img
	/grub.exe
	/burg/core.img	/boot/burg/core.img
	/ldlinux.sys	/syslinux/ldlinux.sys	/boot/syslinux/ldlinux.sys
	/extlinux.sys	/extlinux/extlinux.sys	/boot/extlinux/extlinux.sys
	/boot/map	/map
	/DEFAULT.MNU
	/IO.SYS
	/MSDOS.SYS
	/KERNEL.SYS
	/DELLBIO.BIN	/DELLRMK.BIN
	/COMMAND.COM
	'



## List of files whose contents will be displayed. ##
Boot_Files_Normal='
	/menu.lst	/grub/menu.lst	/boot/grub/menu.lst	/NST/menu.lst
	/grub.cfg	/grub/grub.cfg	/boot/grub/grub.cfg
	/grub2/grub.cfg	/boot/grub2/grub.cfg
	/custom.cfg	/grub/custom.cfg	/boot/grub/custom.cfg	/grub2/custom.cfg	/boot/grub2/custom.cfg
	/burg.cfg	/burg/burg.cfg	/boot/burg/burg.cfg
	/grub.conf	/grub/grub.conf	/boot/grub/grub.conf	/grub2/grub.conf	/boot/grub2/grub.conf
	/ubuntu/disks/boot/grub/menu.lst	/ubuntu/disks/install/boot/grub/menu.lst	/ubuntu/winboot/menu.lst
	/boot.ini	/BOOT.INI	/Boot.ini
	/etc/fstab
	/etc/default/grub
	/etc/lilo.conf	/lilo.conf
	/syslinux.cfg	/syslinux/syslinux.cfg	/boot/syslinux/syslinux.cfg
	/extlinux.conf	/extlinux/extlinux.conf	/boot/extlinux/extlinux.conf
	/grldr
	/refind_linux.conf	/boot/refind_linux.conf
	'
Boot_Files_Fat='
	/menu.lst	/grub/menu.lst	/boot/grub/menu.lst	/NST/menu.lst
	/grub.cfg	/grub/grub.cfg	/boot/grub/grub.cfg
	/grub2/grub.cfg	/boot/grub2/grub.cfg
	/custom.cfg	/grub/custom.cfg	/boot/grub/custom.cfg	/grub2/custom.cfg	/boot/grub2/custom.cfg
	/burg.cfg	/burg/burg.cfg	/boot/burg/burg.cfg
	/grub.conf	/grub/grub.conf	/boot/grub/grub.conf	/grub2/grub.conf	/boot/grub2/grub.conf
	/ubuntu/disks/boot/grub/menu.lst	/ubuntu/disks/install/boot/grub/menu.lst	/ubuntu/winboot/menu.lst
	/boot.ini
	/freeldr.ini
	/etc/fstab
	/etc/lilo.conf	/lilo.conf
	/syslinux.cfg	/syslinux/syslinux.cfg	/boot/syslinux/syslinux.cfg
	/extlinux.conf	/extlinux/extlinux.conf	/boot/extlinux/extlinux.conf
	/grldr
	/EFI/refind/refind.conf
	'
#/EFI/ubuntu/grub.cfg	/EFI/grub2/grub.cfg	/EFI/fedora/grub.cfg	/EFI/grub/grub.cfg	/EFI/boot/ubuntu/grub.cfg and all other efi/*/grub.cfg should be displayed already (see l.2990)

## List of files whose end point (in GiB / GB) will be displayed. ##
GrubError18_Files='
	menu.lst	grub/menu.lst	boot/grub/menu.lst	NST/menu.lst
	ubuntu/disks/boot/grub/menu.lst
	grub.conf	grub/grub.conf	boot/grub/grub.conf	grub2/grub.conf	boot/grub2/grub.conf
	grub.cfg	grub/grub.cfg	boot/grub/grub.cfg	grub2/grub.cfg	boot/grub2/grub.cfg
	burg.cfg	burg/burg.cfg	boot/burg/burg.cfg
	core.img	grub/core.img	boot/grub/core.img
	grub/i386-pc/core.img		boot/grub/i386-pc/core.img
	grub2/core.img			boot/grub2/core.img
	grub2/i386-pc/core.img		boot/grub2/i386-pc/core.img
	burg/core.img	boot/burg/core.img
	stage2		grub/stage2	boot/grub/stage2
	boot/vmlinuz*	vmlinuz*	ubuntu/disks/boot/vmlinuz*
	boot/initrd*	initrd*		ubuntu/disks/boot/initrd*
	boot/kernel*.img
	initramfs*	boot/initramfs*
	'
SyslinuxError_Files='
	syslinux.cfg	syslinux/syslinux.cfg	boot/syslinux/syslinux.cfg
	extlinux.conf	extlinux/extlinux.conf	boot/extlinux/extlinux.conf
	ldlinux.sys	syslinux/ldlinux.sys	boot/syslinux/ldlinux.sys
	extlinux.sys	extlinux/extlinux.sys	boot/extlinux/extlinux.sys
	*.c32		syslinux/*.c32			boot/syslinux/*.c32
	extlinux/*.c32	boot/extlinux/*.c32
	'


## Create temporary directory ##
Folder=$(mktemp -t -d b-i-s-XXXXXXXX);


## Create temporary filenames. ##
cd ${Folder}
#Log=${Folder}/Log				# File to record the summary.
Log="${TMP_LOG}b"
Log1=${Folder}/Log1				# Most of the information which is not part of the summary is recorded in this file.
Error_Log=${Folder}/Error_Log			# File to catch all unusal Standar Errors.
Trash=${Folder}/Trash				# File to catch all usual Standard Errors these messagges will not be included in the RESULTS.
Mount_Error=${Folder}/Mount_Error		# File to catch Mounting Errors.
Unknown_MBR=${Folder}/Unknown_MBR		# File to record all unknown MBR and Boot sectors.
Tmp_Log=${Folder}/Tmp_Log			# File to temporarily hold some information.
core_img_file=${Folder}/core_img		# File to temporarily store an embedded core.img of grub2.
core_img_file_unlzma=${Folder}/core_img_unlzma	# File to temporarily store the uncompressed part of core.img of grub2.
core_img_file_type_2=${Folder}/core_img_type_2	# File to temporarily store the core.img module of type 2
PartitionTable=${Folder}/PT			# File to store the Partition Table.
FakeHardDrives=${Folder}/FakeHD			# File to list devices which seem to have  no corresponding drive.
BLKKID=${Folder}/BLKID				# File to store the output of blkid.
GRUB200_Module=${Folder}/GRUB200_Module		# File to store current grub2 module


## Redirect all standard error to the file Error_Log. ##
exec 2> ${Error_Log};


## List of all hard drives ##
All_Hard_Drives=$(ls /dev/hd[a-z] /dev/hd[a-z][a-z] /dev/sd[a-z] /dev/sd[a-z][a-z] /dev/xvd[a-z] /dev/vd[a-z] /dev/vd[a-z][a-z] /dev/nvme[0-9]n[0-9] /dev/nvme[0-9]n[0-9][0-9] /dev/nvme[0-9][0-9]n[0-9] /dev/nvme[0-9][0-9]n[0-9][0-9] /dev/mmcblk[0-9] /dev/mmcblk[0-9][0-9] 2>> ${Trash});


## Add found RAID disks to list of hard drives. ##
[[ "$DEBBUG" ]] && echo "[debug] Add raid if any"
if [ $(type dmraid >> ${Trash} 2>> ${Trash} ; echo $?) -eq 0 ] ; then
  InActiveDMRaid=$(dmraid -si -c);
  [ x"${InActiveDMRaid}" = x"no raid disks" ] || [ x"${InActiveDMRaid}" = x"no block devices found" ] && InActiveDMRaid=''
  [ x"${InActiveDMRaid}" != x'' ] && dmraid -ay ${InActiveDMRaid} >> ${Trash}
  All_DMRaid=$(dmraid -sa -c);
  if [ x"${All_DMRaid}" != x"no raid disks" ] && [ x"${All_DMRaid}" != x"no block devices found" ] ; then
     All_DMRaid=$(echo "{All_DMRaid}" | ${AWK} '{ print "/dev/mapper/"$0 }');
     All_Hard_Drives="${All_Hard_Drives} ${All_DMRaid}";
  fi  
fi



## Arrays to hold information about Partitions: ##
#   name, starting sector, ending sector, size in sector, partition type,
#   filesystem type, UUID, kind(Logical, Primary, Extended), harddrive,
#   boot flag,  parent (for logical partitions), label,
#   system(the partition id according the partition table),
#   the device associated with the partition.
declare -a NamesArray StartArray EndArray SizeArray TypeArray  FileArray UUIDArray KindArray DriveArray BootArray ParentArray LabelArray SystemArray DeviceArray;

## Arrays to hold information about the harddrives. ##
declare -a HDName FirstPartion LastPartition HDSize HDMBR HDHead HDTrack HDCylinder HDPT HDStart HDEnd HDUUID;

## Array for hard drives formatted as filesystem. ##
declare -a FilesystemDrives;


PI=-1;	## Counter for the identification number of a partition.   (each partition gets unique number)   ##
HI=0;	## Counter for the identification number of a hard drive.  (each hard drive gets unique number)  ##
PTFormat='%-10s %4s%14s%14s%14s %3s %s\n';	## standard format (hexdump) to use for partition table. ##


# List of mount points for devices: also allow mount points with spaces.
[[ "$DEBBUG" ]] && echo "[debug] List mount"
MountPoints=$(mount | ${AWK} -F "\t" '{ if ( ($1 ~ "^/dev") || ($1 ~ "pool^/") && ($3 != "/") ) { sub(" on ", "\t", $0); sub(" type ", "\t", $0); print $2 } }' | sort -u);


# Search for hard drives which don't exist, have a corrupted partition table
# or don't have a parition table (whole drive is a filesystem).
# Information on all hard drives which a valid partition table are stored in 
# the hard drives arrays: HD?????

# id for Filesystem Drives.
FSD=0;

# Clear blkid cache
blkid -g;

for drive in ${All_Hard_Drives} ; do
	[[ "$DEBBUG" ]] && echo "[debug] for $drive"
    size=$(fdisks ${drive});
    PrintBlkid ${drive};
    if [ 0 -lt ${size} 2>> ${Trash} ] ; then
        if [ x"$(blkid  ${drive})" = x'' ] || [ x"$(blkid -p -s USAGE ${drive})" = x'' ] ; then #https://github.com/arvidjaar/bootinfoscript/issues/5
       		[[ "$DEBBUG" ]] && echo "[debug] eval $drive"
            # Drive is not a filesytem.
            size=$((2*size));
            HDName[${HI}]=${drive};
            HDSize[${HI}]=${size};
            # Get and set HDHead[${HI}], HDTrack[${HI}] and HDCylinder[${HI}] all at once.
            eval $(fdisk -lu ${drive} 2>> ${Trash} | ${AWK} -F ' ' '$2 ~ "head" { print "HDHead['${HI}']=" $1 "; HDTrack['${HI}']=" $3 "; HDCylinder['${HI}']=" $5 }' );
            # Look at the first 4 bytes of the second sector to identify the partition table type.
            case $(hexdump -v -s 512 -n 4 -e '"%_u"' ${drive}) in
              'EMBR') HDPT[${HI}]='BootIt';;
              'EFI ') HDPT[${HI}]='EFI';;
                   *) HDPT[${HI}]='MSDos';;
            esac
            HI=$((${HI}+1));
        else
            # Drive is a filesystem.
            if [ $( expr match "$(BlkidTag "${drive}" TYPE)" '.*raid') -eq 0 ] || [ x"$(BlkidTag "${drive}" UUID)" != x'' ] ; then
               FilesystemDrives[${FSD}]="${drive}";
               ((FSD++));
            fi
        fi
    else
     printf "$(basename ${drive}) " >> ${FakeHardDrives};
    fi
done



## Identify the MBR of each hard drive. ##
[[ "$DEBBUG" ]] && echo '[debug] Identifying MBRs...';

for HI in ${!HDName[@]} ; do 
  drive="${HDName[${HI}]}";
  [[ "$DEBBUG" ]] && echo "[debug] identify MBR of $drive"
  Message="is installed in the MBR of ${drive}";

  # Read the whole MBR in hexadecimal format.
  MBR_512=$(hexdump -v -n 512 -e '/1 "%02x"' ${drive});

  ## Look at the first 2,3,4 or 8 bytes of the hard drive to identify the boot code installed in the MBR. ##
  #
  #   If it is not enough, look at more bytes.

  MBR_sig2="${MBR_512:0:4}";
  MBR_sig3="${MBR_512:0:6}";
  MBR_sig4="${MBR_512:0:8}";
  MBR_sig8="${MBR_512:0:16}";

  ## Bytes 0x80-0x81 of the MBR. ##
  #
  #   Use it to differentiate between different versions of the same bootloader.

  MBR_bytes80to81="${MBR_512:256:4}";


  BL=;
  case ${MBR_sig2} in

    eb48) ## Grub Legacy is in the MBR. ##
	  BL="Grub Legacy";

	  # 0x44 contains the offset to the next stage.
	  offset=$(hexdump -v -s 68 -n 4 -e '"%u"' ${drive});

	  if [ "${offset}" -ne 1 ] ; then
	     # Grub Legacy is installed without stage1.5 files.
	     stage2_loc ${drive};
	     Message="${Message} and ${Stage2_Msg}";
	  else
	     # Grub is installed with stage1.5 files.
	     Grub_String=$(hexdump -v -s 1042 -n 94 -e '"%_u"' ${drive});
	     Grub_Version="${Grub_String%%nul*}";

	     BL="Grub Legacy (v${Grub_Version})";

	     tmp="/${Grub_String#*/}";
	     tmp="${tmp%%nul*}";

	     eval $(echo ${tmp} | ${AWK} '{ print "stage=" $1 "; menu=" $2 }');

	     [[ x"$menu" = x'' ]] || stage="${stage} and ${menu}";

	     part_info=$((1045 + ${#Grub_Version}));
	     eval $(hexdump -v -s ${part_info} -n 2 -e '1/1 "pa=%u; " 1/1 "dr=%u"' ${drive});
	     
	     dr=$(( ${dr} - 127 ));
	     pa=$(( ${pa} + 1 ));

	     if [ "${dr}" -eq 128 ] ; then
		Message="${Message} and looks on the same drive in partition #${pa} for ${stage}";
	     else
		Message="${Message} and looks on boot drive #${dr} in partition #${pa} for ${stage}";
	     fi
	  fi;;

    eb4c) ## Grub2 (v1.96) is in the MBR. ##
	  BL='Grub2 (v1.96)';

	  grub2_info ${drive} ${drive} '1.96' 'disk';

	  Message="${Message} and ${Grub2_Msg}";;

    eb63) ## Grub2 is in the MBR. ##
	  case ${MBR_bytes80to81} in
		7c3c) grub2_version='1.97-1.98'; BL='Grub2 (v1.97-1.98)';;
		0020) grub2_version='1.99-2.00'; BL='Grub2 (v1.99-2.00)';;
	  esac

	  grub2_info ${drive} ${drive} ${grub2_version} 'disk';

	  # Set a more exact version number (1.99 or 2.00), if '1.99-2.00' was
	  # passed to the grub2_info function.
	  BL="Grub2 (v${grub2_version})";

	  Message="${Message} and ${Grub2_Msg}";;

    0ebe) BL='ThinkPad';;
    31c0) # Look at the first 8 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig8} in
	    31c08ed0bc007c8e) BL='NetBSD/SUSE generic MBR';;
	    31c08ed0bc007cfb) BL='Acer PQService MBR';;
	  esac;;
    33c0) # Look at the first 3 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig3} in
	    33c08e) BL='Windows';
		    case ${MBR_sig8} in
		      33c08ed0bc007cfb) BL='Windows 2000/XP/2003';;
		      33c08ed0bc007c8e)
					# Look at byte 0xF0-F1: different offset for "TCPA" string.
					case "${MBR_512:480:4}" in
					  fb54) BL='Windows Vista';;
					  4350) BL='Windows';; # 7/8/10/11/2012
					esac;;
		    esac;;
	    33c090) BL='DiskCryptor';;
	    33c0fa) # Look at bytes 0x5B-5D: different offsets for jump target
	      case ${MBR_512:182:6} in
		0fb6c6) BL='Syslinux GPTMBR (5.10 and higher)';;
		bb007c) BL='Syslinux GPTMBR (4.04-5.01)';;
		e82101) BL='Syslinux MBR (4.04-4.07)';;
		e83501) BL='Syslinux MBR (5.00 and higher)';;
		e81001) # Syslinux ALTMBR; look at byte 0xd9 for different version and
			# byte 0x1b7 (439) for boot partition
		  case ${MBR_512:434:2} in
		    c3) BL='Syslinux ALTMBR (4.04-4.05)';;
		    c6) BL='Syslinux ALTMBR (4.06 and higher)';;
		  esac;
		  BL="${BL} with boot partition 0x${MBR_512:878:2}";;
	      esac;;
	  esac;;
    33ed) # Look at bytes 0x80-0x81 to be more specific about the Syslinux variant/version.
	  case ${MBR_bytes80to81} in
	    407c) BL='ISOhybrid (Syslinux 4.04)';;
	    83e1) BL='ISOhybrid with partition support (Syslinux 4.04)';;
	    cd13) BL='ISOhybrid with partition support (Syslinux 4.05 and higher)';;
	    f7e1) BL='ISOhybrid (Syslinux 4.05 and higher)';;
	  esac;;
    33ff) BL='HP/Gateway';;
    b800) BL='Plop';;
    ea05)
	  case ${MBR_sig3} in
	    ea0500) BL='OpenBSD generic MBR';;
	    ea0501) BL='XOSL';;
	  esac;;
    ea1e) BL='Truecrypt Boot Loader';;
    eb04) BL='Solaris';;
    eb31) BL='Paragon';;
    eb5e) # Look at the first 3 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig3} in
	    eb5e00) BL='fbinst';;
	    eb5e80) BL='Grub4Dos';;
	    eb5e90) BL='WEE';
		    # Get the embedded menu of WEE.
		    get_embedded_menu "${drive}" "WEE's (${drive})";;
	  esac;;
    fa31) # Look at the first 3 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig3} in
	    fa31c0) # Look at bytes 0x80-0x81 to be more specific about the Syslinux variant/version.
		    case ${MBR_bytes80to81} in
		      0069) BL='ISOhybrid (Syslinux 3.72-3.73)';;
		      7c66) BL='Syslinux MBR (3.61-4.03)';;
		      7cb8) BL='Syslinux MBR (3.36-3.51)';;
		      b442) BL='Syslinux MBR (3.00-3.35)';;
		      bb00) BL='Syslinux MBR (3.52-3.60)';;
		      e2f8) # Syslinux pre-4.04; look at bytes 0x82-0x84
		            case "${MBR_512:260:6}" in
			      31f65f) BL='Syslinux GPTMBR (4.00-4.03)';;
			      5e5974) BL='Syslinux GPTMBR (3.72-3.73)';;
			      5e5958) # look at bytes 0xe-0xf
			              case "${MBR_512:28:4}" in
				        528e) BL='Syslinux GPTMBR (3.70-3.71)';;
				        8ec0) BL='Syslinux GPTMBR (3.74-4.03)';;
				      esac;;
			    esac;;
		      e879) BL='ISOhybrid (Syslinux 3.74-3.80)';;
		    esac;;
	    fa31c9) BL='Master Boot LoaDeR';;   
	    fa31ed) # Look at bytes 0x80-0x81 to be more specific about the Syslinux variant/version.
		    case ${MBR_bytes80to81} in
		      0069) BL='ISOhybrid (Syslinux 3.72-3.73)';;
		      0fb6) BL='ISOhybrid with partition support (Syslinux 3.82-3.86)';;
		      407c) BL='ISOhybrid (Syslinux 3.82-4.03)';;
		      83e1) BL='ISOhybrid with partition support (Syslinux 4.00-4.03)';;
		      b6c6) BL='ISOhybrid with partition support (Syslinux 3.81)';;
		      fbc0) BL='ISOhybrid (Syslinux 3.81)';;
		    esac;;
	  esac;;
    fa33) BL='MS-DOS 3.30 through Windows 95 (A)';;
    fab8) # Look at the first 4 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig4} in
	    fab80000) BL='FreeDOS (eXtended FDisk)';;
	    fab80010) BL="libparted MBR boot code";;
	  esac;;
    faeb) BL='Lilo';; 
    fafc) BL='ReactOS';;
    fc31) # Look at the first 8 bytes of the hard drive to identify the boot code installed in the MBR.
	  case ${MBR_sig8} in
	    fc31c08ed031e48e) BL='install-mbr/Testdisk';;
	    fc31c08ec08ed88e) BL='boot0 (FreeBSD)';;
	  esac;;
    fc33) BL='GAG';;
    fceb) BL='BootIt NG';;
    0000) BL='No boot loader';;
  esac
  if [ x"${BL}" = 'x' ] ; then
     BL='No known boot loader';
     printf "Unknown MBR on ${drive}\n\n" >> ${Unknown_MBR};
     #hexdump -v -n 512 -C ${drive} >> ${Unknown_MBR};
     #echo >> ${Unknown_MBR};
  fi
  ## Output message at beginning of summary that gives MBR info for each drive: ##
  printf ' => ' >> "${Log}";
  printf "${BL} ${Message}.\n" | fold -s -w 75 | sed -e '/^-----\.\?$/ d' -e '2~1s/.*/    &/' >> "${Log}";
  HDMBR[${HI}]=${BL};
done

echo >> "${Log}";



## Store and Display all the partitions tables. ##
[[ "$DEBBUG" ]] && echo "[debug] Store and display partition tables"
for HI in ${!HDName[@]} ; do
    drive=${HDName[${HI}]};
    [[ "$DEBBUG" ]] && echo "[debug] Computing Partition Table of ${drive}...";
    FP=$((PI+1));    # used if non-MS_DOS partition table is not in use.
    FirstPartition[${HI}]=${FP};
    PTType=${HDPT[${HI}]};
    HDPT[${HI}]='MSDos';
    #echo "Drive: $(basename ${drive} ) _____________________________________________________________________" >> ${PartitionTable};
    fdisk -lu ${drive} 2>> ${Trash} | sed '/omitting/ d' | sed '6,$ d' >> ${PartitionTable};
    printf "\n${PTFormat}\n" 'Partition' 'Boot' 'Start Sector' 'End Sector' '# of Sectors' 'Id' 'System' >> ${PartitionTable};
    ReadPT ${HI} 0 4 ${PartitionTable} "${PTFormat}" '' 0;
    echo >> ${PartitionTable};
    LastPartition[${HI}]=${PI};
    LP=${PI};
    CheckPT ${FirstPartition[${HI}]} ${LastPartition[${HI}]} ${PartitionTable} ${HI};
    echo >> ${PartitionTable};
    HDPT[${HI}]=${PTType};
    case ${PTType} in
        BootIt) printf 'BootIt NG Partition Table detected' >> ${PartitionTable};
            [[ "${HDMBR[${HI}]}" = 'BootIt NG' ]] || printf ', but does not seem to be used' >> ${PartitionTable};
            printf '.\n\n' >> ${PartitionTable};
            ReadEMBR  ${HI} ${PartitionTable};
            echo >> ${PartitionTable};
            if [ "${HDMBR[${HI}]}" = 'BootIt NG' ] ; then
                LastPartition[${HI}]=${PI};
                CheckPT ${FirstPartition[${HI}]} ${LastPartition[${HI}]} ${PartitionTable} ${HI}; 
            else
                FirstPartition[${HI}]=${FP};
            fi;;
       EFI) FirstPartition[${HI}]=$((PI+1));
            EFIee=$(hexdump -v -s 450 -n 1 -e '"%x"' ${drive});
            printf 'GUID Partition Table detected' >> ${PartitionTable};
            [[ "${EFIee}" = 'ee' ]] || printf ', but does not seem to be used' >> ${PartitionTable};
            printf '.\n\n' >> ${PartitionTable};
            ReadEFI ${HI} ${PartitionTable};
            echo >> ${PartitionTable};
            if [ "${EFIee}" = 'ee' ] ; then
                LastPartition[${HI}]=${PI};
                CheckPT ${FirstPartition[${HI}]} ${LastPartition[${HI}]} ${PartitionTable} ${HI};
            else
                FirstPartition[${HI}]=${FP};
            fi;;
    esac
done


## Loop through all Hard Drives. ##
for HI in ${!HDName[@]} ; do
  drive=${HDName[${HI}]};
  [[ "$DEBBUG" ]] && echo "[debug] loop through $drive"
  ## And then loop through the partitions on that drive. ##
  for (( PI = FirstPartition[${HI}]; PI <= LastPartition[${HI}]; PI++ )); do
    part_type=${TypeArray[${PI}]};    # Type of the partition according to fdisk
    start=${StartArray[${PI}]};
    size=${SizeArray[${PI}]};
    end=${EndArray[${PI}]};
    kind=${KindArray[${PI}]};
    system=${SystemArray[${PI}]};
    if [[ x"${DeviceArray[${PI}]}" = x'' ]] ; then
       name="${NamesArray[${PI}]}";
       mountname=$(basename ${drive})"_"${PI};
       part=$(losetup -f --show  -o $((start*512)) ${drive});
       # --sizelimit $((size*512))    --sizelimit seems to be a recently added option for losetup. Failed on Hardy.
    else
       part="${DeviceArray[${PI}]}";
       name=$(basename ${part});      # Name of the partition (/dev/sda8 -> sda8).
       mountname=${name};
    fi
    Get_Partition_Info "${Log}" "${Log1}" "${part}" "${name}" "${mountname}" "${kind}" "${start}" "${end}" "${system}" "${PI}";
    [[ "${DeviceArray[${PI}]}" = '' ]] && losetup -d ${part};
  done
done



## Deactivate dmraid's activated by the script. ##
[[ "$DEBBUG" ]] && echo "[debug] deactivate dmraid if activated by the script"
[ x"$InActiveDMRaid" != x'' ] && dmraid -an ${InActiveDMRaid}



## Search LVM partitions for information. ##
[[ "$DEBBUG" ]] && echo "[debug] Search lvm"
#   Only works if the "LVM2"-package is installed.
if [ $(type lvs >> ${Trash} 2>> ${Trash} ; echo $?) -eq 0 ] ; then
  lvs --nameprefixes --noheadings --options lv_name,vg_name,lv_size,lv_attr --units s | \
  while read line ; do 
    LVM2_VG_NAME= LVM2_LV_NAME= LVM2_LV_SIZE= LVM2_LV_ATTR=
    eval "${line}";
    if [ -z "${LVM2_VG_NAME}" ] || [ -z "${LVM2_LV_NAME}" ] || [ -z "${LVM2_LV_SIZE}" ] || [ -z "${LVM2_LV_ATTR}" ] ; then
       continue
    fi
    name="${LVM2_VG_NAME}-${LVM2_LV_NAME}";
    LVM="/dev/mapper/${LVM2_VG_NAME//-/--}-${LVM2_LV_NAME//-/--}";
    LVM_Size=${LVM2_LV_SIZE%s};
    LVM_Status=${LVM2_LV_ATTR:4:1};
    lvchange -ay ${LVM};
    mountname="LVM/${name}";
    kind='LVM';
    start=0;
    end=${LVM_Size};  
    system='';
    PI='';
    Get_Partition_Info "${Log}" "${Log1}" "$LVM" "${name}" "${mountname}" "${kind}" "${start}" "${end}" "${system}" "${PI}";
    # deactivate all LVM's, which were not active.
    [[ "${LVM_Status}" != 'a' ]] && lvchange -an "${LVM}";
  done
fi



## Search MDRaid Partitons for Information ##
[[ "$DEBBUG" ]] && echo "[debug] Search mdraid"
#   Only works if "mdadm" is installed.
if [ $(type mdadm >> ${Trash} 2>> ${Trash} ; echo $?) -eq 0 ] ; then
  # All arrays which are already assembled.
  MD_Active_Array=$(mdadm --detail --scan | ${AWK} '{ print $2 }');
  # Assemble all arrays.
  mdadm --assemble --scan;
  # All arrays.
  MD_Array=$(mdadm --detail --scan | ${AWK} '{ print $2 }');
  for MD in ${MD_Array}; do
    MD_Size=$(fdisks ${MD});     # size in blocks
    MD_Size=$((2*${MD_Size}));   # size in sectors
    MD_Active=0;
    # Check whether MD is active.
    for MDA in ${MD_Active_Array}; do
      if [[ "${MDA}" = "${MD}" ]] ; then
         MD_Active=1;
         break;
      fi
    done
    name=${MD:5};
    mountname="MDRaid/${name}";
    kind="MDRaid";
    start=0;
    end=${MD_Size};
    system='';
    PI='';
    Get_Partition_Info "${Log}" "${Log1}" "${MD}" "${name}" "${mountname}" "${kind}" "${start}" "${end}" "${system}" "${PI}"
    # deactivate all MD_Raid's, which were not active.
    [[ "${MD_Active}" -eq 0 ]] && mdadm --stop "${MD}"
  done
fi



## Search filesystem hard drives for information. ##
[[ "$DEBBUG" ]] && echo "[debug] Search fs hd"
for FD in ${FilesystemDrives[@]} ; do
  FD_Size=$(fdisks ${FD});     # size in blocks
  FD_Size=$((2*${FD_Size}));   # size in sectors
  name=${FD:5};
  mountname="FD/${name}";
  kind="FD";
  start=0;
  end=${FD_Size};
  system='';
  PI='';
  Get_Partition_Info "${Log}" "${Log1}" "${FD}" "${name}" "${mountname}" "${kind}" "${start}" "${end}" "${system}" "${PI}";
done

[[ "$DEBBUG" ]] && echo "[debug] os detected"
paragraph_os_detected >> "${Log}"

[[ "$DEBBUG" ]] && echo "[debug] systinfo"
paragraph_syst_info
echo "$ECHO_ARCH_SECTION" >> "${Log}"

[[ "$DEBBUG" ]] && echo "[debug] check efidmsg"
check_efi_dmesg_and_secureboot
paragraph_efi
title_gen "UEFI" >> "${Log}"
echo "$EFIDMESG
$ECHO_SUMEFI_SECTION" >> "${Log}"

title_gen "Drive/Partition Info" >> "${Log}"
echo "$ECHO_PARTS_INFO" >> "${Log}"
if [[ "$DEBBUG" ]] && [[ ! "$FILTERED" ]];then
    printf "\nbis fdisks : ___________________________________________________________________\n\n" >> "${Log}"
    [ -e ${PartitionTable} ] && cat ${PartitionTable} >> "${Log}" || echo 'no valid partition table found' >> "${Log}"
fi

[[ "$DEBBUG" ]] && echo "[debug] print fdisk"
printf "\nfdisk -l $FILTERED: ___________________________________________________________\n\n" >> "${Log}";
if [[ "$FILTERED" ]];then
	while read line; do
		[[ "$line" ]] && echo "$line" | sed 's|/dev/||g' | sed 's|Device||g' >> "${Log}"
	done < <(LANGUAGE=C LC_ALL=C fdisk -l | grep -v 'Disk model' | grep -v 'Sector size (' | grep -v 'I/O size (' | grep -v Disklabel \
	| grep -v 'Units:' | grep -v 'Disk /dev/loop' 2>/dev/null )
    # 'Disk id' needed for nvram analysis
else
    LANGUAGE=C LC_ALL=C fdisk -l 2>/dev/null >> "${Log}"
fi

[[ "$DEBBUG" ]] && echo "[debug] print parted"
printf "\nparted -lm $FILTERED: _________________________________________________________\n\n" >> "${Log}"
if [[ "$FILTERED" ]];then
	write=yes
	while read line; do
		[[ "$line" =~ 'BYT;' ]] && write=yes
		[[ "$line" =~ "/dev/sr" ]] || [[ "$line" =~ "/dev/zram" ]] || [[ "$line" =~ "pool" ]] && write=""
		[[ "$write" ]] && [[ "$line" ]] && [[ ! "$line" =~ 'BYT;' ]] && echo "$line" | sed 's|/dev/||g' >> "${Log}"
	done < <(echo "$PARTEDLM" )
else
	echo "$PARTEDLM" >> "${Log}"
fi

[[ "$DEBBUG" ]] && echo "[debug] print free space"
t="\nFree space $([ "$FILTERED" ] && echo ">10MiB"): ______________________________________________________________\n\n"
printfreespace=""
for drivez in ${All_Hard_Drives} ; do
	if [[ "$FILTERED" ]];then
		while read line; do
			line="${line%:free*}"; a=${line##*MiB:}; a=${a%.*}
			[ "${a#[0-9]}" ] && t="$t${drivez#/dev/*}: ${line#*:}\n" && printfreespace=y
		done < <(LANGUAGE=C LC_ALL=C parted $drivez -ms unit MiB print free 2>/dev/null | grep ':free;' )
	else
		printfreespace=y
		t="$t
${drivez}
$(LANGUAGE=C LC_ALL=C parted $drivez -ms unit MiB print free | grep ':free;' 2>/dev/null )"
	fi
done
[ "$printfreespace" ] && printf "$t" >> "${Log}"


[[ "$DEBBUG" ]] && echo "[debug] print sgdisk -p"
[[ ! "$FILTERED" ]] && printf "\nsgdisk $FILTERED: ______________________________________________________________\n\n" >> "${Log}"
for drivez in ${All_Hard_Drives} ; do
	#if [[ "$FILTERED" ]];then
	#	while read line; do
	#		[[ "$line" ]] && [[ ! "$line" =~ 'gdisk) version' ]] && [[ ! "$line" =~ 'table scan:' ]] && [[ ! "$line" =~ ': not present' ]] && [[ ! "$line" =~ 'Model: ' ]] \
	#		&& [[ ! "$line" =~ '********' ]] && [[ ! "$line" =~ 'physical): ' ]] && [[ "$line" != 'in memory.' ]] && [[ ! "$line" =~ 'MBR: MBR only' ]] \
	#		&& [[ ! "$line" =~ 'MBR: protective' ]] && [[ ! "$line" =~ 'GPT: present' ]] && echo "$line" >> "${Log}"
	#	done < <(LANGUAGE=C LC_ALL=C sudo gdisk -l $drivez )
	#else
		[[ ! "$FILTERED" ]] && LANGUAGE=C LC_ALL=C sudo sgdisk -p $drivez >> "${Log}"
	#fi
done

[[ "$DEBBUG" ]] && echo "[debug] print blkid"
printf "\nblkid $FILTERED: ______________________________________________________________\n\n" >> "${Log}"
if [[ "$FILTERED" ]];then
	lsblk -o NAME,FSTYPE,UUID,PARTUUID,LABEL,PARTLABEL | grep -v loop | grep -v sr[0-9] | grep -v zram >> "${Log}"
else
	lsblk -o NAME,FSTYPE,UUID,PARTUUID,LABEL,PARTLABEL  >> "${Log}"
fi

if [[ ! "$(blkid)" =~ /dev/ ]] && [[ ! "$(blkid)" =~ pool ]];then #LP1042230 &1216688
	printf '\nstrace blkid: __________________________________________________________________\n\n' >> "${Log}"
	strace blkid >> "${Log}"
fi

## Mount points. ##
[[ "$DEBBUG" ]] && echo "[debug] print df / findmnt"
printf "\nMount points $FILTERED: _______________________________________________________\n\n" >> "${Log}"
#while read line; do
#    [[ "$line" ]] && [[ ! "$line" =~ '/dev/loop' ]] && [[ ! "$line" =~ 'tmpfs' ]] && echo "$line" >> "${Log}"
#done < <(LANGUAGE=C LC_ALL=C df -Th )
if [[ "$FILTERED" ]];then
	LANGUAGE=C LC_ALL=C findmnt -l -o SOURCE,AVAIL,USE%,TARGET | grep USE% | sed 's/SOURCE/      /g' | sed 's/AVAIL/Avail/g' | sed 's/USE/Use/g' | sed 's/TARGET/Mounted on/g' >> "${Log}"
	while read line; do
		#[[ ! "$(echo "$line" | sed -e '/^[ ]*\/dev/d' )" ]] && 
		[[ ! "$(echo "$line" | grep none | grep 0%)" ]] && [[ ! "$(echo "$line" | grep udev | grep 0%)" ]] && [[ ! "$(echo "$line" | grep /var/snap/)" ]] && echo "$line" >> "${Log}"
	done < <(LANGUAGE=C LC_ALL=C findmnt -l -o SOURCE,AVAIL,USE%,TARGET | grep % | sed -e '/USE%/d' -e '/tmpfs/d' -e '/quashfs/d' | grep -v v/loop \
	| grep -v v/fuse | grep -v v/sr[0-9] | grep -v /cow | grep -v /USERDATA | grep -v /var/ | grep -v /usr/ | grep -v /srv | sort)
else
	LANGUAGE=C LC_ALL=C findmnt -l -o SOURCE,AVAIL,USE%,TARGET >> "${Log}"
fi

## Mount options. ##
[[ "$DEBBUG" ]] && echo "[debug] print mount options"
printf "\nMount options $FILTERED: ______________________________________________________\n\n" >> "${Log}"
if [[ "$FILTERED" ]];then
	#fails if '[' instead of '\['
	LANGUAGE=C LC_ALL=C findmnt -l -o SOURCE,FSTYPE,OPTIONS | grep / | sed -e '/tmpfs/d' -e '/quashfs/d' \
	| grep -v v/loop | grep -v v/fuse | grep -v v/sr[0-9] | grep -v /cow | grep -v '\[' | grep -v /USERDATA \
	| grep -v /var/ | grep -v /usr/ | grep -v /srv | sort >> "${Log}"
else
	LANGUAGE=C LC_ALL=C findmnt -l -o SOURCE,FSTYPE,OPTIONS >> "${Log}"
fi

[[ "$DEBBUG" ]] && echo "[debug] by-id"
if [[ "$DEBBUG" ]];then
	if [ $(ls -l /dev/disk/by-id 2>> ${Trash} | wc -l) -gt 1 ] ; then
		title_gen "ls -l /dev/disk/by-id" >> "${Log}";
		LANG=C ls -l /dev/disk/by-id >> "${Log}";
	fi
fi

[[ "$DEBBUG" ]] && echo "[debug] ls mapper"
if [ $(ls -R /dev/mapper 2>> ${Trash} | wc -l) -gt 2 ] ; then
   title_gen "ls -R /dev/mapper/" >> "${Log}";
   LANG=C ls -R /dev/mapper >> "${Log}";
fi


## Write the content of Log1 to the log file. ##
[ -e "${Log1}" ] && cat "${Log1}" >> "${Log}"; 


## Add unknown MBRs/Boot Sectors to the log file, if any. ##
if [[ ! "$FILTERED" ]] || [[ ! "$GRUBPACKAGE" =~ efi ]];then
	[[ "$DEBBUG" ]] && echo "[debug] unknown mbrs"
	if [ -e ${Unknown_MBR} ] ; then
	   title_gen "Unknown MBRs/Boot Sectors/etc" >> "${Log}";
	   cat ${Unknown_MBR} >> "${Log}";
	fi
fi

## Add fake hard drives to the log file, if any. ##
if [[ ! "$FILTERED" ]];then
	if [ -e ${FakeHardDrives} ] ; then 
	   title_gen "Devices which don't seem to have a corresponding hard drive" >> "${Log}";
	   cat ${FakeHardDrives} >> "${Log}";
	   printf "\n" >> "${Log}";
	fi
fi

## Write the Error Log to the log file. ##
if [[ "$DEBBUG" ]] || [[ ! "$FILTERED" ]];then
	if [ -s ${Error_Log} ] ; then
	   title_gen "StdErr Messages" >> "${Log}";
	   cat ${Error_Log} >> "${Log}";
	fi
fi

rm -f ${Folder}
}
