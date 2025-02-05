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

## Get total number of blocks on a device. ##
fdisks () {
#   Sometimes "fdisk -s" seems to malfunction or isn't supported (busybox fdisk),
#   so use "sfdisk -s" if available.
#   If sfdisk isn't available, calculate the number of blocks from the number of
#   sectors (divide by 2).
  if [ $(type sfdisk >> ${Trash} 2>> ${Trash} ; echo $?) -eq 0 ] ; then
     sfdisk -s "$1" 2>> ${Trash};
  else
     # Calculate the number of blocks from the number of sectors (divide by 2).
     fdisk -lu "$1" 2>> ${Trash} | ${AWK} '$0 ~ /, .*, .*, .*/ { print $(NF - 1) / 2 }';
  fi
}

##  A function which checks whether a file is on a mounted partition. ##
FileNotMounted () {	
  local File=$1 curmp=$2;
  IFS_OLD="${IFS}";  # Save original IFS.
  IFS=$'\012';       # Set IFS temporarily to newline only, so mount points with spaces can be processed too.
  for mp in ${MountPoints}; do 
    if [ $(expr match "${File}" "${mp}/" ) -ne 0 ] && [ "${mp}" != "${curmp}" ] ; then
       IFS="${IFS_OLD}";  # Restore original IFS.
       return 1;
    fi
  done
  IFS="${IFS_OLD}";       # Restore original IFS.
  return 0;
}

## Function which converts the two digit hexcode to the partition type. ##
HexToSystem () {
#   The following list is taken from sfdisk -T and 
#   http://www.win.tue.nl/~aeb/partitions/partition_types-1.html
#   is work in progress.
  local type=$1 system;
  case ${type} in
    0)  system='Empty';;
    1)  system='FAT12';;
    2)  system='XENIX root';;
    3)  system='XENIX /usr';;
    4)  system='FAT16 <32M';;
    5)  system='Extended';;
    6)  system='FAT16';;
    7)  system='NTFS / exFAT / HPFS';;
    8)  system='AIX bootable';;
    9)  system='AIX data';;
    a)  system='OS/2 Boot Manager';;
    b)  system='W95 FAT32';;
    c)  system='W95 FAT32 (LBA)';;
    e)  system='W95 FAT16 (LBA)';;
    f)  system='W95 Extended (LBA)';;
    10) system='OPUS';;
    11) system='Hidden FAT12';;
    12) system='Compaq diagnostics';;
    14) system='Hidden FAT16 < 32M';;
    16) system='Hidden FAT16';;
    17) system='Hidden NTFS / HPFS';;
    18) system='AST SmartSleep';;
    1b) system='Hidden W95 FAT32';;
    1c) system='Hidden W95 FAT32 (LBA)';;
    1e) system='Hidden W95 FAT16 (LBA)';;
    24) system='NEC DOS';;
    27) system='Hidden NTFS (Recovery Environment)';;
    2a) system='AtheOS File System';;
    2b) system='SyllableSecure';;
    32) system='NOS';;
    35) system='JFS on OS/2';;
    38) system='THEOS';;
    39) system='Plan 9';;
    3a) system='THEOS';;
    3b) system='THEOS Extended';;
    3c) system='PartitionMagic recovery';;
    3d) system='Hidden NetWare';;
    40) system='Venix 80286';;
    41) system='PPC PReP Boot';;
    42) system='SFS';;
    44) system='GoBack';;
    45) system='Boot-US boot manager';;
    4d) system='QNX4.x';;
    4e) system='QNX4.x 2nd part';;
    4f) system='QNX4.x 3rd part';;
    50) system='OnTrack DM';;
    51) system='OnTrack DM6 Aux1';;
    52) system='CP/M';;
    53) system='OnTrack DM6 Aux3';;
    54) system='OnTrack DM6 DDO';;
    55) system='EZ-Drive';;
    56) system='Golden Bow';;
    57) system='DrivePro';;
    5c) system='Priam Edisk';;
    61) system='SpeedStor';;
    63) system='GNU HURD or SysV';;
    64) system='Novell Netware 286';;
    65) system='Novell Netware 386';;
    70) system='DiskSecure Multi-Boot';;
    74) system='Scramdisk';;
    75) system='IBM PC/IX';;
    78) system='XOSL filesystem';;
    80) system='Old Minix';;
    81) system='Minix / old Linux';;
    82) system='Linux swap / Solaris';;
    83) system='Linux';;
    84) system='OS/2 hidden C: drive';;
    85) system='Linux extended';;
    86) system='NTFS volume set';;
    87) system='NTFS volume set';;
    88) system='Linux plaintext';;
    8a) system='Linux Kernel (AiR-BOOT)';;
    8d) system='Free FDISK hidden Primary FAT12';;
    8e) system='Linux LVM';;
    90) system='Free FDISK hidden Primary FAT16 <32M';;
    91) system='Free FDISK hidden Extended';;
    92) system='Free FDISK hidden Primary FAT16';;
    93) system='Amoeba/Accidently Hidden Linux';;
    94) system='Amoeba bad block table';;
    97) system='Free FDISK hidden Primary FAT32';;
    98) system='Free FDISK hidden Primary FAT32 (LBA)';;
    9a) system='Free FDISK hidden Primary FAT16 (LBA)';;
    9b) system='Free FDISK hidden Extended (LBA)';;
    9f) system='BSD/OS';;
    a0) system='IBM Thinkpad hibernation';;
    a1) system='Laptop hibernation';;
    a5) system='FreeBSD';;
    a6) system='OpenBSD';;
    a7) system='NeXTSTEP';;
    a8) system='Darwin UFS';;
    a9) system='NetBSD';;
    ab) system='Darwin boot';;
    af) system='HFS / HFS+';;
    b0) system='BootStar';;
    b1 | b3) system='SpeedStor / QNX Neutrino Power-Safe';;
    b2) system='QNX Neutrino Power-Safe';;
    b4 | b6) system='SpeedStor';; 
    b7) system='BSDI fs';;
    b8) system='BSDI swap';;
    bb) system='Boot Wizard hidden';;
    bc) system='Acronis BackUp';;
    be) system='Solaris boot';;
    bf) system='Solaris';;
    c0) system='CTOS';;
    c1) system='DRDOS / secured (FAT-12)';;
    c2) system='Hidden Linux (PowerBoot)';;
    c3) system='Hidden Linux Swap (PowerBoot)';;
    c4) system='DRDOS secured FAT16 < 32M';;
    c5) system='DRDOS secured Extended';;
    c6) system='DRDOS secured FAT16';;
    c7) system='Syrinx';;
    cb) system='DR-DOS secured FAT32 (CHS)';;
    cc) system='DR-DOS secured FAT32 (LBA)';;
    cd) system='CTOS Memdump?';;
    ce) system='DR-DOS FAT16X (LBA)';;
    cf) system='DR-DOS secured EXT DOS (LBA)';;
    d0) system='REAL/32 secure big partition';;
    da) system='Non-FS data / Powercopy Backup';;
    db) system='CP/M / CTOS / ...';;
    dd) system='Dell Media Direct';;
    de) system='Dell Utility';;
    df) system='BootIt';;
    e1) system='DOS access';;
    e3) system='DOS R/O';;
    e4) system='SpeedStor';;
    e8) system='LUKS';;
    eb) system='BeOS BFS';;
    ec) system='SkyOS';;
    ee) system='GPT';;
    ef) system='EFI (FAT-12/16/32)';;
    f0) system='Linux/PA-RISC boot';;
    f1) system='SpeedStor';;
    f2) system='DOS secondary';;
    f4) system='SpeedStor';;
    fb) system='VMware VMFS';;
    fc) system='VMware VMswap';;
    fd) system='Linux raid autodetect';;
    fe) system='LANstep';;
    ff) system='Xenix Bad Block Table';;
     *) system='Unknown';;
  esac
  echo "${system}";
}

## Function to convert GPT's Partition Type. ##
UUIDToSystem () {
#   List from http://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
#
#   ABCDEFGH-IJKL-MNOP-QRST-UVWXYZabcdef is stored as
#   GHEFCDAB-KLIJ-OPMN-QRST-UVWXYZabcdef (without the dashes)
#
#   For easy generation of the following list:
#    - Save list in a file "Partition_type_GUIDs.txt" in the folowing format: 
#
#	 Partition Type (OS) <TAB> GUID
#	 Partition Type (OS) <TAB> GUID
#	 Partition Type (OS) <TAB> GUID
#
#    - Then run the following:
#
#	 gawk -F '\t' '{ GUID=tolower($2); printf "    %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s)  system=\"%s\";;\n", substr(GUID,7,1), substr(GUID,8,1), substr(GUID,5,1), substr(GUID,6,1), substr(GUID,3,1), substr(GUID,4,1), substr(GUID,1,1), substr(GUID,2,1), substr(GUID,12,1), substr(GUID,13,1), substr(GUID,10,1), substr(GUID,11,1), substr(GUID,17,1), substr(GUID,18,1), substr(GUID,15,1), substr(GUID,16,1), substr(GUID,20,4), substr(GUID,25,12), $1 } END { print "				   *)  system='-';" }' Partition_type_GUIDs.txt
#
#    - Some GUIDs are not unique for one OS. To find them, you can run:
#
#	 gawk -F "\t" '{print $2}' GUID_Partition_Table_list.txt | sort | uniq -d | grep -f - GUID_Partition_Table_list.txt
#
#		Basic data partition (Windows)	EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
#		Data partition (Linux)		EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
#		ZFS (Mac OS X)			6A898CC3-1DD2-11B2-99A6-080020736631
#		/usr partition (Solaris)	6A898CC3-1DD2-11B2-99A6-080020736631
#
  local type=$1 system;

  case ${type} in
    00000000000000000000000000000000)  system='Unused entry';;
    41ee4d02e733d3119d690008c781f39f)  system='MBR partition scheme';;
    28732ac11ff8d211ba4b00a0c93ec93b)  system='EFI System partition';;
    4861682149646f6e744e656564454649)  system='BIOS Boot partition';;
    dee2bfd3af3ddf11ba40e3a556d89593)  system='Intel Fast Flash (iFFS) partition (for Intel Rapid Start technology)';;
    329701f46e06124e8273346c5641494f)  system='Sony boot partition';;
    e7afbfbf4fa38a449a5b6213eb736c22)  system='Lenovo boot partition';;

    ## GUIDs that are not unique for one OS ##
    a2a0d0ebe5b9334487c068b6b72699c7)  system='Data partition (Windows/Linux)';;
    c38c896ad21db21199a6080020736631)  system='ZFS (Mac OS X) or /usr partition (Solaris)';;
    af3dc60f838472478e793d69d8477de4)  system='Data partition (Linux or GNU/Hurd)';;
    6dfd5706aba4c44384e50933c84b4f4f)  system="Swap partition (Linux or GNU/Hurd)";;

    ## Windows GUIDs ##
    16e3c9e35c0bb84d817df92df00215ae)  system='Microsoft Reserved Partition (Windows)';;
    # Same GUID as old GUID for "Basic data partition (Linux)"
  # a2a0d0ebe5b9334487c068b6b72699c7)  system='Basic data partition (Windows)';;
    aac808588f7ee04285d2e1e90434cfb3)  system='Logical Disk Manager (LDM) metadata partition (Windows)';;
    a0609baf3114624fbc683311714a69ad)  system='Logical Disk Manager (LDM) data partition (Windows)';;
    a4bb94ded106404da16abfd50179d6ac)  system='Windows Recovery Environment (Windows)';;
    90fcaf377def964e91c32d7ae055b174)  system='IBM General Parallel File System (GPFS) partition (Windows)';;
    8faf5ce780f6ee4cafa3b001e56efc2d)  system='Storage Spaces partition (Windows)';;
    c5438d55aca1c043aac8d1472b2923d1)  system='Storage Replica partition (Windows)';;

    ## HP-UX GUIDs ##
    1e4c8975eb3ad311b7c17b03a0000000)  system='Data partition (HP-UX)';;
    28e7a1e2e332d611a6827b03a0000000)  system='Service Partition (HP-UX)';;

    ## Linux GUIDs ##
    # Same GUID as "Basic data partition (Windows)" GUID
  # a2a0d0ebe5b9334487c068b6b72699c7)  system='Data partition (Linux)';;
    # New GUID to avoid that Linux partitions show up as unformatted partitions in Windows.
    0f889da1fc053b4da006743f0f84911e)  system='RAID partition (Linux)';;
    aef82365b13e2a4ea05a18b695ae656f)  system="Root partition (Alpha)";;
    ed467fd21929b84cbd259531f3c16534)  system="Root partition (ARC)";;
    10d7da69e42c3c4eb16c21a1d49abed3)  system="Root partition (ARM 32‐bit)";;
    45b021b9f01dc341af444c6f280d3fae)  system="Root partition (AArch64)";;
    3d8d3d990ef82542855a9daf8ed7ea97)  system="Root partition (IA-64)";;
    005805772c79944fb39a98c91b762bb6)  system="Root partition (LoongArch 64‐bit)";;
    8a8cc53713d95641a25f48b1b64e07f0)  system="Root partition (mipsel: 32‐bit MIPS little‐endian)";;
    43da0b70347a0745b179eeb93d7a7ca3)  system="Root partition (mips64el: 64‐bit MIPS little‐endian)";;
    3bdbac1a44543841bd9ee5c2239b2346)  system="Root partition (PA-RISC)";;
    eff1e31d98fab5478dcd4a860a654d78)  system="Root partition (32‐bit PowerPC)";;
    1dde2a9139a813498964a10eee08fbd2)  system="Root partition (64‐bit PowerPC big‐endian)";;
    e6451cc3393f2e4180fb4809c4980599)  system="Root partition (64‐bit PowerPC little‐endian)";;
    fea7d5607d8e5c43b7143dd8162144e1)  system="Root partition (RISC-V 32‐bit)";;
    a670ec7274cfe640bd494bda08e8f224)  system="Root partition (RISC-V 64‐bit)";;
    eaaca7084c62204a91e86e0fa67d23f9)  system="Root partition (s390)";;
    a9d9ea5e09fe1e4aa1d7520d00531306)  system="Root partition (s390x)";;
    70dd0cc56238c34c90e1809a8c93ee2c)  system="Root partition (TILE-Gx)";;
    4095474497f2b2419af7d131d5f0458a)  system="Root partition (x86)";;
    e3bc684fcde8b14d96e7fbcaf984b709)  system="Root partition (x86-64)";;
    8cf08ce1ec330d4c8246c6c6fb3da024)  system="/usr partition (Alpha)";;
    83a6787916632249bbee38bff5a2fecc)  system="/usr partition (ARC)";;
    a359037db3020a4f865c654403e70625)  system="/usr partition (ARM 32‐bit)";;
    5010e0b05fee9043949a9101b17104e9)  system="/usr partition (AArch64)";;
    a6d201433b4e2a4bbb949e0b2c4225ea)  system="/usr partition (IA-64)";;
    02c711e65c57be4c9a46434fa0bf7e3f)  system="/usr partition (LoongArch 64‐bit)";;
    e968480f52990647979f3ed3a473e947)  system="/usr partition (mipsel: 32‐bit MIPS little‐endian)";;
    321f7cc906bab4409f22236061b08aa8)  system="/usr partition (mips64el: 64‐bit MIPS little‐endian)";;
    80444adc17696242a4ecdb9384949f25)  system="/usr partition (PA-RISC)";;
    c5fe147d71cc5d419d6c06bf0b3c3eaf)  system="/usr partition (32‐bit PowerPC)";;
    e239972c68f0b3469fd001c5a9afbcca)  system="/usr partition (64‐bit PowerPC big‐endian)";;
    af03bb15e7774a4db12bc0d084f7491c)  system="/usr partition (64‐bit PowerPC little‐endian)";;
    22fb33b93f5c914faf90e2bb0fa50702)  system="/usr partition (RISC-V 32‐bit)";;
    4bc3aebe42849b43a40b984381ed097d)  system="/usr partition (RISC-V 64‐bit)";;
    9b860fcdfbd0a04cb1419ea87cc78d66)  system="/usr partition (s390)";;
    70574f8aaa50d34e874a99b710db6fea)  system="/usr partition (s390x)";;
    29704955c1c7cc44aa39815ed1558630)  system="/usr partition (TILE-Gx)";;
    760d2575c68c8e45bd66bd47cc81a812)  system="/usr partition (x86)";;
    0c6884842195c6489c11b0720656f69e)  system="/usr partition (x86-64)";;
    e9d956fce5e6064cbe32e74407ce09a5)  system="Root verity partition for dm-verity (Alpha)";;
    75d9b224970f2145afa1cd531e421b8d)  system="Root verity partition for dm-verity (ARC)";;
    f2cd86733c20a947a498f2ecce45a2d6)  system="Root verity partition for dm-verity (ARM 32‐bit)";;
    ce0033df9fd6924c978c9bfb0f38d820)  system="Root verity partition for dm-verity (AArch64)";;
    d510ed8607b6bb458957d350f23d0571)  system="Root verity partition for dm-verity (IA-64)";;
    223b39f3afe91346a9489d3bfbd0c535)  system="Root verity partition for dm-verity (LoongArch 64‐bit)";;
    d250d1d7042a334a8f1216651205ff7b)  system="Root verity partition for dm-verity (mipsel: 32‐bit MIPS little‐endian)";;
    f817b416063e574f8dd29b5232f41aa6)  system="Root verity partition for dm-verity (mips64el: 64‐bit MIPS little‐endian)";;
    30a412d2c5fbf949a983a7feef2b8d0e)  system="Root verity partition for dm-verity (PA-RISC)";;
    44d96b908945ae4aa4e4dd983917446a)  system="Root verity partition for dm-verity (64‐bit PowerPC little‐endian)";;
    a3a92592193c894db4f6eeff88f17631)  system="Root verity partition for dm-verity (64‐bit PowerPC big‐endian)";;
    49e6cf988815dc46b2f0add147424925)  system="Root verity partition for dm-verity (32‐bit PowerPC)";;
    be5302ae67110740ac6843926c14c5de)  system="Root verity partition for dm-verity (RISC-V 32‐bit)";;
    8255edb60b440942b8da5ff7c419ea3d)  system="Root verity partition for dm-verity (RISC-V 64‐bit)";;
    473bc67a5cb23b468df8b4a94e6c90e1)  system="Root verity partition for dm-verity (s390)";;
    bebf25b3bec7b84a8357139e652d2f6b)  system="Root verity partition for dm-verity (s390x)";;
    ec616096e4282e4bb4a51f0a825a1d84)  system="Root verity partition for dm-verity (TILE-Gx)";;
    ed57732cd2ebd946aec123d437ec2bf5)  system="Root verity partition for dm-verity (x86-64)";;
    3b5d3cd1d1b52a42b29f9454fdc89d76)  system="Root verity partition for dm-verity (x86)";;
    250dce8cd0c0444abd8746331bf1df67)  system="/usr verity partition for dm-verity (Alpha)";;
    8c59a0fc80d891458c164eda05c7347c)  system="/usr verity partition for dm-verity (ARC)";;
    51d715c2cd7b4946be906627490a4c05)  system="/usr verity partition for dm-verity (ARM 32‐bit)";;
    e7a4116ecafbed4db9e9e1a512bb664e)  system="/usr verity partition for dm-verity (AArch64)";;
    031e496ae73b45458e3883320e0ea880)  system="/usr verity partition for dm-verity (IA-64)";;
    262c6bf4ae59f0489106c50ed47f673d)  system="/usr verity partition for dm-verity (LoongArch 64‐bit)";;
    8d8db9465cb58f4eaab337fca7f80752)  system="/usr verity partition for dm-verity (mipsel: 32‐bit MIPS little‐endian)";;
    fe613d3cf3b54d41bb718739a694a4ef)  system="/usr verity partition for dm-verity (mips64el: 64‐bit MIPS little‐endian)";;
    18d6435837ecd7489f12cea8e08768b2)  system="/usr verity partition for dm-verity (PA-RISC)";;
    83992beee821534186d9b6901a54d1ce)  system="/usr verity partition for dm-verity (64‐bit PowerPC little‐endian)";;
    a528b5bd59a25f47a87dda53fa736a07)  system="/usr verity partition for dm-verity (64‐bit PowerPC big‐endian)";;
    005d76df0e27e549bc75f47bb2118b09)  system="/usr verity partition for dm-verity (32‐bit PowerPC)";;
    e3e41ecbd08c3641a0a4aa61a32e8730)  system="/usr verity partition for dm-verity (RISC-V 32‐bit)";;
    be56108f059bc44781d6be53128e5b54)  system="/usr verity partition for dm-verity (RISC-V 64‐bit)";;
    18c663b6bce76d4d90aa11b756bb1797)  system="/usr verity partition for dm-verity (s390)";;
    c41c74312a1a1141a581e00b447d2d06)  system="/usr verity partition for dm-verity (s390x)";;
    56bfb42ffa07da4281326b139f2026ae)  system="/usr verity partition for dm-verity (TILE-Gx)";;
    635fff77b6e73346acf41565b864c0e6)  system="/usr verity partition for dm-verity (x86-64)";;
    0d1b468fee14814e9aa9049b6fb97abd)  system="/usr verity partition for dm-verity (x86)";;
    b79564d453a04f4180f7700c99921ef8)  system="Root verity signature partition for dm-verity (Alpha)";;
    ba703a14d3cb064f919f6c05683a78bc)  system="Root verity signature partition for dm-verity (ARC)";;
    5f45b04211eb1d4998d356145ba9d037)  system="Root verity signature partition for dm-verity (ARM 32‐bit)";;
    e69db66df4295847a7a5962190f00ce3)  system="Root verity signature partition for dm-verity (AArch64)";;
    ee368be9ba3282489b120ce14655f46a)  system="Root verity signature partition for dm-verity (IA-64)";;
    eb67fb5ac8ec854fae8eac1e7c50e7d0)  system="Root verity signature partition for dm-verity (LoongArch 64‐bit)";;
    1fcc19c95644ff4e918cf75e94525ca5)  system="Root verity signature partition for dm-verity (mipsel: 32‐bit MIPS little‐endian)";;
    ef584e90655c314a9c576af5fc7c5de7)  system="Root verity signature partition for dm-verity (mips64el: 64‐bit MIPS little‐endian)";;
    7061de15d3651c43916eb0dcd8393f25)  system="Root verity signature partition for dm-verity (PA-RISC)";;
    e736a2d473e8074cbf1dbf6cf7f1c3c6)  system="Root verity signature partition for dm-verity (64‐bit PowerPC little‐endian)";;
    0cc2e2f5b245fa4fbce92a60737e1aaf)  system="Root verity signature partition for dm-verity (64‐bit PowerPC big‐endian)";;
    aab5311bd9ad3a46b2edbd467fc857e7)  system="Root verity signature partition for dm-verity (32‐bit PowerPC)";;
    752a113a29878043b4cf764d79934448)  system="Root verity signature partition for dm-verity (RISC-V 32‐bit)";;
    87f0e0ef8dea6944821a4c2a96a8386a)  system="Root verity signature partition for dm-verity (RISC-V 64‐bit)";;
    8e38823454425a43a241766a065f9960)  system="Root verity signature partition for dm-verity (s390)";;
    a58701c8a3731a49901a017c3fa953e9)  system="Root verity signature partition for dm-verity (s390x)";;
    391467b3b097534a90f72d5a8f3ad47b)  system="Root verity signature partition for dm-verity (TILE-Gx)";;
    052b0941c89f2345994f2def0408b176)  system="Root verity signature partition for dm-verity (x86-64)";;
    05fc96599c10de48808b23fa0830b676)  system="Root verity signature partition for dm-verity (x86)";;
    761c6e5c6a077a45a0fef3b4cd21ce6e)  system="/usr verity signature partition for dm-verity (Alpha)";;
    a1a9f99471997a42a40050cb297f0f35)  system="/usr verity signature partition for dm-verity (ARC)";;
    2f81ffd7d1370249a810d76ba57b975a)  system="/usr verity signature partition for dm-verity (ARM 32‐bit)";;
    ffe43cc2bd44004bb2d4b41b3419e02a)  system="/usr verity signature partition for dm-verity (AArch64)";;
    c28be58d432a0d46b14ea76e4a17b47f)  system="/usr verity signature partition for dm-verity (IA-64)";;
    15f324b030d34c44846144bbde524e99)  system="/usr verity signature partition for dm-verity (LoongArch 64‐bit)";;
    0bca233ebca44e4b80875ab6a26aa8a9)  system="/usr verity signature partition for dm-verity (mipsel: 32‐bit MIPS little‐endian)";;
    eec7c2f2ccad5143b5c6ee9816b66e16)  system="/usr verity signature partition for dm-verity (mips64el: 64‐bit MIPS little‐endian)";;
    d1d70d452432ec459cf2a43a346d71ee)  system="/usr verity signature partition for dm-verity (PA-RISC)";;
    1ebdbfc88e2621458bbabf314c399557)  system="/usr verity signature partition for dm-verity (64‐bit PowerPC little‐endian)";;
    6388880bf8d79e4d9766239fce4d58af)  system="/usr verity signature partition for dm-verity (64‐bit PowerPC big‐endian)";;
    1d89077071d3804a86a45cb875b9302e)  system="/usr verity signature partition for dm-verity (32‐bit PowerPC)";;
    136a83c33731ba45b583b16c50fe5eb4)  system="/usr verity signature partition for dm-verity (RISC-V 32‐bit)";;
    0a00f9d2187a3f45b5cd4d32f77a7b32)  system="/usr verity signature partition for dm-verity (RISC-V 64‐bit)";;
    4f0e4417d0a87f46a46e3912ae6ef2c5)  system="/usr verity signature partition for dm-verity (s390)";;
    1648323f7b66ae4686ee9b0c0c6c11b4)  system="/usr verity signature partition for dm-verity (s390x)";;
    e275de4ecc6cc84cb9c770334b087510)  system="/usr verity signature partition for dm-verity (TILE-Gx)";;
    fb33bbe7cf06814e8273e543b413e2e2)  system="/usr verity signature partition for dm-verity (x86-64)";;
    c0714a9741dec343be5d5c5ccd1ad2c0)  system="/usr verity signature partition for dm-verity (x86)";;
    #ffc213bce6596242a352b275fd6f7172)  system="/boot, as an Extended Boot Loader (XBOOTLDR) partition (Linux)";;
    79d3d6e607f5c244a23c238f2a3df928)  system="Logical Volume Manager (LVM) partition (Linux)";;
    e1c73a93b42e134fb8440e14e2aef915)  system="/home partition (Linux)";;
    25848f3be0203b4f907f1a25a76f98e8)  system="/srv (server data) partition (Linux)";;
    ef913f77d466b549bd83d683bf40ad16)  system="Per‐user home partition (Linux)";;
    c9c5fe7f002db74989413ea10a5586b7)  system="Plain dm-crypt partition (Linux)";;
    cb7c7dcaed63534c861c1742536059cc)  system="LUKS partition (Linux)";;
    3933a68d0700c060c436083ac8230908)  system="Reserved (Linux)";;

    ## GNU/Hurd GUIDs (same as Linux)##
    #af3dc60f838472478e793d69d8477de4)  system="Linux filesystem data (GNU/Hurd)";;
    #6dfd5706aba4c44384e50933c84b4f4f)  system="Linux Swap partition (GNU/Hurd)";;

    ## FreeBSD GUIDs ##
    9d6bbd83417fdc11be0b001560b84f0f)  system='Boot partition (FreeBSD)';;
    b47c6e51cf6ed6118ff800022d09712b)  system='BSD disklabel (Data) partition (FreeBSD)';;
    b57c6e51cf6ed6118ff800022d09712b)  system='Swap partition (FreeBSD)';;
    b67c6e51cf6ed6118ff800022d09712b)  system='Unix File System (UFS) partition (FreeBSD)';;
    b87c6e51cf6ed6118ff800022d09712b)  system='Vinum volume manager partition (FreeBSD)';;
    ba7c6e51cf6ed6118ff800022d09712b)  system='ZFS partition (FreeBSD)';;
    d97dba7489a6e111bd0400e081286acf)  system="nandfs partition";;

    ## Mac OS X GUIDs ##
    005346480000aa11aa1100306543ecac)  system='Hierarchical File System Plus (HFS+) partition (MacOS)';;
    ef57347c0000aa11aa1100306543ecac)  system="Apple APFS container (MacOS)";;
    005346550000aa11aa1100306543ecac)  system='Apple UFS (MacOS)';;
  # c38c896ad21db21199a6080020736631)  system='ZFS (Mac OS X)';;
    444941520000aa11aa1100306543ecac)  system='Apple RAID partition (MacOS)';;
    444941524f5faa11aa1100306543ecac)  system='Apple RAID partition offline (MacOS)';;
    746f6f420000aa11aa1100306543ecac)  system='Apple Boot partition - Recovery HD (MacOS)';;
    6562614c006caa11aa1100306543ecac)  system='Apple Label (MacOS)';;
    6f6365526576aa11aa1100306543ecac)  system='Apple TV Recovery partition (MacOS)';;
    726f74536761aa11aa1100306543ecac)  system="Apple Core Storage (i.e. Lion FileVault) partition (MacOS)";;
    616964690067aa11aa1100306543ecac)  system="Apple APFS Preboot partition ";;
    727663520079aa11aa1100306543ecac)  system="Apple APFS Recovery partition ";;

    ## Solaris GUIDs ##
    45cb826ad21db21199a6080020736631)  system='Boot partition (Solaris)';;
    4dcf856ad21db21199a6080020736631)  system='Root partition (Solaris)';;
    6fc4876ad21db21199a6080020736631)  system='Swap partition (Solaris)';;
    2b648b6ad21db21199a6080020736631)  system='Backup partition (Solaris)';;
  # c38c896ad21db21199a6080020736631)  system='/usr partition (Solaris)';;
    e9f28e6ad21db21199a6080020736631)  system='/var partition (Solaris)';;
    39ba906ad21db21199a6080020736631)  system='/home partition (Solaris)';;
    a583926ad21db21199a6080020736631)  system='Alternate sector (Solaris)';;
    3b5a946ad21db21199a6080020736631)  system='Reserved partition (Solaris)';;
    d130966ad21db21199a6080020736631)  system='Reserved partition (Solaris)';;
    6707986ad21db21199a6080020736631)  system='Reserved partition (Solaris)';;
    7f23966ad21db21199a6080020736631)  system='Reserved partition (Solaris)';;
    c72a8d6ad21db21199a6080020736631)  system='Reserved partition (Solaris)';;

    ## NetBSD GUIDs ##
    328df4490eb1dc11b99b0019d1879648)  system='Swap partition (NetBSD)';;
    5a8df4490eb1dc11b99b0019d1879648)  system='FFS partition (NetBSD)';;
    828df4490eb1dc11b99b0019d1879648)  system='LFS partition (NetBSD)';;
    aa8df4490eb1dc11b99b0019d1879648)  system='RAID partition (NetBSD)';;
    c419b52d0fb1dc11b99b0019d1879648)  system='Concatenated partition (NetBSD)';;
    ec19b52d0fb1dc11b99b0019d1879648)  system='Encrypted partition (NetBSD)';;

    ## ChromeOS GUIDs ##
    5d2a3afe324fa741b725accc3285a309)  system="ChromeOS kernel ";;
    02e2b83c7e3bdd478a3c7ff2a13cfcec)  system="ChromeOS rootfs ";;
    8ee8b6caf3ab0241a07ad4bb9be3c1d3)  system="ChromeOS firmware ";;
    3d750a2e489eb0438337b15192cb1b5e)  system="ChromeOS future use ";;
    605884095f70b54bb16c8a8a099caf52)  system="ChromeOS miniOS ";;
    18830f3f46f16b4e8222c28c8f02e0d5)  system="ChromeOS hibernate ";;

    ## Haiku GUIDs ##
    31534642a33bf110802a4861696b7521)  system="Haiku BFS (Haiku)";;

    ## MidnightBSD GUIDs ##
    5ee4d5857c23e111b4b3e89a8f7fc3a7)  system="Boot partition (MidnightBSD) ";;
    5ae4d5857c23e111b4b3e89a8f7fc3a7)  system="Data partition (MidnightBSD)";;
    5be4d5857c23e111b4b3e89a8f7fc3a7)  system="Swap partition (MidnightBSD)";;
    8bef94037e23e111b4b3e89a8f7fc3a7)  system="Unix File System (UFS) partition (MidnightBSD)";;
    5ce4d5857c23e111b4b3e89a8f7fc3a7)  system="Vinum volume manager partition (MidnightBSD)";;
    5de4d5857c23e111b4b3e89a8f7fc3a7)  system="ZFS partition (MidnightBSD)";;

    ## Ceph GUIDs ##
    9e96b045039b304fb4c6b4b80ceff106)  system="Journal (Ceph)";;
    9e96b045039b304fb4c65ec00ceff106)  system="dm-crypt journal (Ceph)";;
    297ebd4f259db841afd0062c0ceff05d)  system="OSD Ceph)";;
    297ebd4f259db841afd05ec00ceff05d)  system="dm-crypt OSD Ceph)";;
    987fc589e52fc04d89c1f3ad0ceff2be)  system="Disk in creation Ceph)";;
    987fc589e52fc04d89c15ec00ceff2be)  system="dm-crypt disk in creation Ceph)";;
    fecafeca039b304fb4c6b4b80ceff106)  system="Block Ceph)";;
    0908cd30b2c29c4988792d6b78529876)  system="Block DB Ceph)";;
    ce7fe15c87406941b7ff056cc58473f9)  system="Block write-ahead log Ceph)";;
    f9ab3afb5fd2cc47bf5e721d1816496b)  system="Lockbox for dm-crypt keys Ceph)";;
    297ebd4fe08a8249bf9d5a8d867af560)  system="Multipath OSD Ceph)";;
    9e96b045e08a8249bf9d5a8d867af560)  system="Multipath journal Ceph)";;
    fecafecae08a8249bf9d5a8d867af560)  system="Multipath block Ceph)";;
    6a664a7ff316a2478445152ef4d03f6c)  system="Multipath block Ceph)";;
    85636dec46e3dc45be91da2a7c8b3261)  system="Multipath block DB Ceph)";;
    1b1eb4012a003c459f1788793989ff8f)  system="Multipath block write-ahead log Ceph)";;
    fecafeca039b304fb4c65ec00ceff106)  system="dm-crypt block Ceph)";;
    2d05b093d9028a4da43b33a3ee4dfbc3)  system="dm-crypt block DB Ceph)";;
    83866e30e24f3043b7c000a917c16966)  system="dm-crypt block write-ahead log Ceph)";;
    9e96b045039b304fb4c635865ceff106)  system="dm-crypt LUKS journal Ceph)";;
    fecafeca039b304fb4c635865ceff106)  system="dm-crypt LUKS block Ceph)";;
    da18641669c42240adf4b30afd37f176)  system="dm-crypt LUKS block DB Ceph)";;
    9020a3864736b940bbbd38d8c573aa86)  system="dm-crypt LUKS block write-ahead log Ceph)";;
    297ebd4f259db841afd035865ceff05d)  system="dm-crypt LUKS OSD Ceph)";;

    ## OpenBSD GUIDs ##
    a0c74c82a836e311890a952519ad3f61)  system="Data partition (OpenBSD)";;

    ## QNX GUIDs ##
    ada9f5cebc73014689f3cdeeeee321a1)  system="Power-safe (QNX6) file system";;

    ## Plan9 GUIDs ##
    f91818c92580af4789d2f030d7000c2c)  system="Plan 9 partition ";;

	## VMware ESX GUIDs ##
    8053279dad40db11bf97000c2911d1b8)  system="vmkcore (coredump partition) ";;
    2ae031aa0f40db119590000c2911d1b8)  system="VMFS filesystem partition ";;
    fcef9891c031db118f78000c2911d1b8)  system="VMware Reserved ";;

	## Android-IA GUIDs ##
    5d84682532237546bc398fa5a4748d15)  system="Bootloader (Android-IA)";;
    feaf4e1152152240b26e9b053604cf84)  system="Bootloader2 (Android-IA)";;
    7fd1a449a393c145a0def50b2ebe2599)  system="Boot (Android-IA)";;
    22c77741929eab4a864443502bfd5506)  system="Recovery (Android-IA)";;
    3ba332ef09a46c4891419ffb711f6266)  system="Misc (Android-IA)";;
    be26ac20b720e31184c56cfdb94711e9)  system="Metadata (Android-IA)";;
    e628f43826d35d4291406e0ea133647c)  system="System (Android-IA)";;
    21ef93a828e40a479e550668fd91a2d9)  system="Cache (Android-IA)";;
    a9dd76dcc15a1c49af42a82591580c0d)  system="Data (Android-IA)";;
    d097c5eb5320154b8b64e0aac75f4db1)  system="Persistent (Android-IA)";;
    ecaea0c5ea13e511a1b1001e67ca0c3c)  system="Vendor (Android-IA)";;
    8b4059bd14450d49bf129878d963f378)  system="Config (Android-IA)";;
    74cc688fe5c5da48be91a0c8c15e9c80)  system="Factory (Android-IA)";;
    efa6da9f3f4bd240ba8dbff16bfb887b)  system="Factory (alt) (Android-IA)";;
    d04179768520e311ad3b6cfdb94711e9)  system="Fastboot / Tertiary (Android-IA)";;
    24796dac71ebf84db48de267b27148ff)  system="OEM (Android-IA)";;

	## Android 6.0+ ARM GUIDs ##
    a210a719cab3e411b02610604b889dcf)  system="Android Meta (Android 6.0+ ARM)";;
    a41e3d19cab3e411b07510604b889dcf)  system="Android EXT (Android 6.0+ ARM)";;

	## Open Network Install Environment GUIDs ##
    d5f7127456a1134b81dc867174929325)  system="Boot (ONIE)";;
    cde2e6d46944f346b5cb1bff57afc149)  system="Config (ONIE)";;

	## PowerPC GUIDs ##
    382d1a9e12c61643aa268b49521e5a8b)  system="PReP boot (PowerPC)";;

	## freedesktop.org OSes (Linux, etc.) GUIDs ##
    ffc213bce6596242a352b275fd6f7172)  system="Shared boot loader configuration (freedesktop.org OSes)";;

	## VeraCrypt GUIDs ##
    ff8e8f8c95ac7047814a21994f2dbc8f)  system="Encrypted data partition (VeraCrypt)";;
   
	## Storage Performance Development Kit (SPDK) GUIDs ##
	bd22527c5d8f87409c00bf9843c7b58c)  system="SPDK block device";;

	## barebox bootloader  GUIDs ##
    65ed784742bffa459c5b287a1dc4aab1)  system="barebox-state (barebox bootloader)";;

	## U-Boot bootloader  GUIDs ##
    6417e23dbd95bd54a5c34abe786f38a8)  system="U-Boot environment";;
   
	## SoftRAID GUIDs ##
    da30fab6d2929a4a96f1871ec6486200)  system="SoftRAID_Status ";;
    6534312eb9193f4681268a7993773801)  system="SoftRAID_Scratch ";;
    7e9c70fab1659345bfd5e71d61de9b02)  system="SoftRAID_Volume ";;
    f56dbabb6ff4894a8f598765b2727503)  system="SoftRAID_Cache ";;

	## Fuchsia standard partitions GUIDs ##
    34268afe2e5eba4699e33a192091a350)  system="Bootloader (slot A/B/R) (Fuchsia)";;
    3545fdd96c10ec4c8d37dfc020ca87cb)  system="Durable mutable encrypted system data (Fuchsia)";;
    6be109a4aa78cc4a995c302352621a41)  system="Durable mutable bootloader data (including A/B/R metadata) (Fuchsia)";;
    0e945df9baca78459b93bb6c90f29d3e)  system="Factory-provisioned read-only system data (Fuchsia)";;
    aadbb810bfd2a94298c6a7c5db3701e7)  system="Factory-provisioned read-only bootloader data (Fuchsia)";;
    b87cfd4915df734eb9d9992070127f0f)  system="Fuchsia Volume Manager (Fuchsia)";;
    fc8b1a42d985854dacdab64eec0133e9)  system="Verified boot metadata (slot A/B/R) (Fuchsia)";;
    f6ff379b582e6a46983af7926d0b04e0)  system="Zircon boot image (slot A/B/R) (Fuchsia)";;
	
				   *)  system='-';
				       echo 'Unknown GPT Partiton Type' >> ${Unknown_MBR};
				       echo  ${type} >> ${Unknown_MBR};;   
  esac

  echo "${system}";
}

## Function which inserts a comma every third digit of a number. ##
InsertComma () {
  echo $1 | sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta';
}

## Function to read 4 bytes starting at $1 of device $2 and convert result to decimal. ##
Read4Bytes () {
  local start=$1 device=$2;
  echo $(hexdump -v -s ${start} -n 4 -e '4 "%u"' ${device});
}

## Function to read 8 bytes starting at $1 of device $2 and convert result to decimal. ##
Read8Bytes () {
  local start=$1 device=$2;
  local first4 second4;
  # Get ${first4} and ${second4} bytes at once.
  eval $(hexdump -v -s ${start} -n 8 -e '1/4 "first4=%u; " 1/4 "second4=%u"' ${device});
  echo $(( ${second4} * 4294967296 + ${first4} ));
}

## Functions to pretty print blkid output. ##
BlkidTag () {
  echo $(blkid -s $2 -o value $1 2>> ${Trash});
}

PrintBlkid () {
  local part=$1 suffix=$2;
    ## Function to pretty print blkid output. ##
    BlkidFormat='%-16s %-38s %-10s %s\n';
  if [ x"$(blkid ${part} 2> ${Tmp_Log})" != x'' ] ; then
     printf "${BlkidFormat}" "${part#*dev/}" "$(BlkidTag ${part} UUID)" "$(BlkidTag ${part} PARTUUID)" "$(BlkidTag ${part} TYPE)" "$(BlkidTag ${part} LABEL)" >> ${BLKKID}${suffix};
  else
     # blkid -p is not available on all systems.
     # This contructs makes sure the "usage" message is not displayed, but catches the "ambivalent" error.
     blkid -p "${part}" 2>&1 | grep "^${part}" >> ${BLKKID}${suffix};
  fi
}

## Read and display the partition table and check the partition table for errors. ##
ReadPT () {
#   This function can be applied iteratively so extended partiton tables can also be processed.
#   Function arguments:
#   - arg 1: HI         = HI of hard drive
#   - arg 2: StartEx    = start sector of the extended Partition
#   - arg 3: N          = number of partitions in table (4 for regular PT, 2 for logical
#   - arg 4: PT_file    = file for storing the partition table
#   - arg 5: format     = display format to use for displaying the partition table
#   - arg 6: EPI        = PI of the primary extended partition containing the extended partition.( equals ""  for hard drive)
#   - arg 7: LinuxIndex = Last linux index assigned (the number in sdXY).
local HI=$1 StartEx=$2 N=$3 PT_file=$4 format=$5 EPI=$6 Base_Sector;
local LinuxIndex=$7 boot size start end type drive system;
local i=0 boot_hex label limit MBRSig;
local LinuxIndexExt;
drive=${HDName[${HI}]};
limit=${HDSize[${HI}]};
dd if=${drive} skip=${StartEx} of=${Tmp_Log} count=1 2>> ${Trash};
MBRSig=$(hexdump -v -s 510 -n 2 -e '"%04x"' ${Tmp_Log});
[[ "${MBRSig}" != 'aa55' ]] && echo 'Invalid MBR Signature found.' >> ${PT_file};
if [[ ${StartEx} -lt ${limit} ]] ; then
    # set Base_Sector to 0 for hard drive, and to the start sector of the
    # primary extended partition otherwise.
    [[ x"${EPI}" = x'' ]] && Base_Sector=0 || Base_Sector=${StartArray[${EPI}]};
    for (( i=0; i < N; i++ )) ; do
        dd if=${drive} skip=${StartEx} of=${Tmp_Log} count=1 2>> ${Trash};
        boot_hex=$(hexdump -v -s $((446+16*${i})) -n 1 -e '"%02x"' ${Tmp_Log});
        case ${boot_hex} in
            00) boot=' ';;
            80) boot='* ';;
             *) boot='?';;
        esac
        # Get amd set: partition type, partition start, and partition size.
        eval $(hexdump -v -s $((450+16*${i})) -n 12 -e '1/1 "type=%x; " 3/1 "tmp=%x; " 1/4 "start=%u; " 1/4 "size=%u"' ${Tmp_Log});

        if [[ ${size} -ne 0 ]] ; then
            if ( ( [ "${type}" = '5' ] || [ "${type}" = 'f' ] ) && [ ${Base_Sector} -ne 0 ] ) ; then
                # start sector of an extended partition is relative to the
                # start sector of an primary extended partition.
                start=$((${start}+${Base_Sector}));
                [[ ${i} -eq 0 ]] && echo 'Extended partition linking to another extended partition.' >> ${PT_file}
                ReadPT ${HI} ${start} 2 ${PT_file} "${format}" ${EPI} ${LinuxIndex};
            else  
                ((PI++));
                if [[ "${type}" = '5' || "${type}" = 'f' ]] ; then
                    KindArray[${PI}]='E';
                else
                    # Start sector of a logical partition is relative to the
                    # start sector of directly assocated extented partition.
                    start=$((${start}+${StartEx}));
                    [[ ${Base_Sector} -eq 0 ]] && KindArray[${PI}]='P' || KindArray[${PI}]='L';
                fi
                LinuxIndex=$((${LinuxIndex}+1));
                [[ "${drive}" =~ "/dev/nvme" ]] || [[ "${drive}" =~ "/dev/mmcblk" ]] && LinuxIndexExt="p$LinuxIndex" || LinuxIndexExt="$LinuxIndex" #https://github.com/arvidjaar/bootinfoscript/issues/5
                end=$((${start}+${size}-1));
                [[ "${HDPT[${HI}]}" = 'BootIt' ]] && label="${NamesArray[${EPI}]}_" || label=${drive};
                system=$(HexToSystem ${type});
                printf "${format}" "${label}${LinuxIndexExt}" "${boot}" $(InsertComma ${start}) "$(InsertComma ${end})" "$(InsertComma ${size})" "${type}" "${system}" >> ${PT_file};
                NamesArray[${PI}]="${label}${LinuxIndexExt}";
                StartArray[${PI}]=${start};
                EndArray[${PI}]=${end};
                TypeArray[${PI}]=${type};
                SystemArray[${PI}]="${system}";
                SizeArray[${PI}]=${size};
                BootArray[${PI}]="${boot}";
                DriveArray[${PI}]=${HI};
                ParentArray[${PI}]=${EPI};
                ( [[ x"${EPI}" = x'' ]] || [[ x"${DeviceArray[${EPI}]}" != x'' ]] ) && DeviceArray[${PI}]=${drive}${LinuxIndexExt};
                [[ "${type}" = '5' || "${type}" = 'f' ]] && ReadPT ${HI} ${start} 2 ${PT_file} "${format}" ${PI} 4
            fi
        elif ( [ ${Base_Sector} -ne 0 ]  && [ ${i} -eq 0 ] ) ; then
            echo 'Empty Partition.' >> ${PT_file};
        else 
            LinuxIndex=$((${LinuxIndex}+1));
        fi
    done
else
    echo 'EBR refers to a location outside the hard drive.' >> ${PT_file};
fi
}

## Read the GPT partition table (GUID, EFI) ##
ReadEFI () {
#   Function arguments:
#   - arg 1: HI       = HI of hard drive
#   - arg 2: GPT_file = file for storing the GPT partition table
local HI=$1 GPT_file=$2 drive size N=0 i=0 format label PRStart start end type size system;
local attrs attrstr attrs_other j;
drive="${HDName[${HI}]}";
format='%-10s %5s %14s%14s%14s %s\n';
printf "${format}" 'Partition' 'Attrs' 'Start Sector' 'End Sector' '# of Sectors' 'System' >> ${GPT_file};
HDStart[${HI}]=$( Read8Bytes 552 ${drive});
HDEnd[${HI}]=$(   Read8Bytes 560 ${drive});
HDUUID[${HI}]=$(  hexdump -v -s 568 -n 16 -e '/1 "%02x"' ${drive});
PRStart=$(        Read8Bytes 584 ${drive});
N=$(              Read4Bytes 592 ${drive});
PRStart=$((       ${PRStart}*512));
PRSize=$(         Read4Bytes 596 ${drive});
for (( i = 0; i < N; i++ )) ; do
    type=$(hexdump -v -s $((${PRStart}+${PRSize}*${i})) -n 16 -e '/1 "%02x"' ${drive});
    if [ "${type}" != '00000000000000000000000000000000' ] ; then
        ((PI++));
        start=$(Read8Bytes $((${PRStart}+32+${PRSize}*${i})) ${drive});
        end=$(  Read8Bytes $((${PRStart}+40+${PRSize}*${i})) ${drive});
        size=$((${end}-${start}+1));
        system=$(UUIDToSystem ${type});
        [[ "${drive}" =~ "/dev/nvme" ]] || [[ "${drive}" =~ "/dev/mmcblk" ]] && label="${drive}p$((${i}+1))" || label="${drive}$((${i}+1))"
        # Partition attributes are 8 bytes long and bash arithmetic is signed.
        # High bits are used by Windows which automatically overflows computed
        # 64 bit number. As we are interested in low bits only, just check it
        # and output the rest verbatim if present.
        attrs=$(hexdump -v -s $((${PRStart}+48+${PRSize}*${i})) -n 1 -e '/1 "%02x"' ${drive});
        attrs_other=$(hexdump -v -s $((${PRStart}+49+${PRSize}*${i})) -n 7 -e '/1 "%02x"' ${drive});
        (( 0x${attrs} & 1 )) && attrstr='R' || attrstr=' '
        (( 0x${attrs} & 2 )) && attrstr="N${attrstr}" || attrstr=" ${attrstr}"
        (( 0x${attrs} & 4 )) && attrstr="B${attrstr}" || attrstr=" ${attrstr}"
        if (( 0x${attrs} & 8 )) || [ ${attrs_other} != '00000000000000' ] ; then
            attrstr="+$attrstr";
            echo                                     >> ${Unknown_MBR};
            echo  "${label}: unknown GPT attributes" >> ${Unknown_MBR};
            for (( j = 12; j >= 0; j -= 2 )) ; do
                printf '%s' ${attrs_other:j:2}        >> ${Unknown_MBR}
            done
            echo ${attrs}                            >> ${Unknown_MBR}
        fi
        printf "${format}" "${label}" "${attrstr}" "$(InsertComma ${start})" "$(InsertComma ${end})" "$(InsertComma ${size})" "${system}"  >> ${GPT_file};
        NamesArray[${PI}]=${label};
        DeviceArray[${PI}]=${label};
        StartArray[${PI}]=${start};
        TypeArray[${PI}]=${type};
        SizeArray[${PI}]=${size};
        SystemArray[${PI}]=${system};
        EndArray[${PI}]=${end};
        DriveArray[${PI}]=${HI};
        KindArray[${PI}]='P';
        ParentArray[${PI}]='';
    fi
done
echo >> ${GPT_file};
echo 'Attributes: R=Required, N=No Block IO, B=Legacy BIOS Bootable, +=More bits set' >> ${GPT_file};
}

## Read the Master Partition Table of BootIt NG. ##
ReadEMBR () {
#   Function arguments:
#   - arg 1: HI       = HI of hard drive
#   - arg 2: MPT_file = file for storing the MPT
local HI=$1 MPT_file=$2 drive size N=0 i=0 BINGIndex label start end type format;
local BINGUnknown system StoredPI FirstPI=${FirstPartition[$1]} LastPI=${PI} New;
drive="${HDName[${HI}]}";
format='%-18s %4s%14s%14s%14s %3s %-15s %3s %2s\n';
printf "${format}" 'Partition' 'Boot' 'Start Sector' 'End Sector' '# of Sectors' 'Id' 'System' 'Ind' '?' >> ${MPT_file};
N=$(hexdump -v -s 534 -n 1 -e '"%u"' ${drive});
for (( i = 0;  i < N; i++ )) ; do
    New=1;
    BINGUnknown=$(hexdump -v -s $((541+28*${i})) -n 1 -e '"%x"' ${drive});
    start=$(      hexdump -v -s $((542+28*${i})) -n 4 -e '4 "%u"' ${drive});
    end=$(        hexdump -v -s $((546+28*${i})) -n 4 -e '4 "%u"' ${drive});
    BINGIndex=$(  hexdump -v -s $((550+28*${i})) -n 1 -e '"%u"' ${drive});
    type=$(       hexdump -v -s $((551+28*${i})) -n 1 -e '"%x"' ${drive});
    size=$((      ${end}-${start}+1));
    label=$(      hexdump -v -s $((552+28*${i})) -n 15 -e '"%_u"' ${drive}| sed -e 's/nul[^$]*//');
    system=$(     HexToSystem ${type});
    printf "${format}" "${label}" "-" "$(InsertComma ${start})" "$(InsertComma ${end})" "$(InsertComma ${size})" "${type}" "${system}" "${BINGIndex}" "${BINGUnknown}" >> ${MPT_file};
    StoredPI=${PI};
    for (( j = FirstPI; j <= LastPI; j++ )); do
      if (( ${StartArray[${j}]} == ${start} )) ; then 
        PI=${j};
        New=0;
        break;
      fi
    done
    if [ ${New} -eq 1 ] ; then
       ((PI++));
       StoredPI=${PI};
       StartArray[${PI}]=${start};
       TypeArray[${PI}]=${type};
       SizeArray[${PI}]=${size};
       SystemArray[${PI}]=${system};
       EndArray[${PI}]=${end};
       DriveArray[${PI}]=${HI};
    fi
    NamesArray[${PI}]=${label};
    if ( [ ${type} = 'f' ] || [ ${type} = '5' ] ) ; then
       KindArray[${PI}]='E';
       ParentArray[${PI}]=${PI};
       ReadPT ${HI} ${start} 2 ${MPT_file} "${format}" ${PI} 4;  
    else
       KindArray[${PI}]='P';
       ParentArray[${PI}]='';
    fi
    PI=${StoredPI};
done
}

## Check partition table for errors. ##
CheckPT () {
#  This function checks whether:
#    - there are any overlapping partitions
#    - the logical partitions are inside the extended partition
#
#   Function arguments:
#
#   - arg 1: PI_first  = PI of first partition to consider
#   - arg 2: PI_last   = PI of last partition to consider
#   - arg 3: CHK_file  = file for the error messages
#   - arg 4: HI        = HI of containing hard drive
  local PI_first=$1 PI_last=$2 CHK_file=$3 HI=$4;
  local Si Ei Sj Ej Ki Kj i j k cyl track head cyl_bound sec_bound;

  cyl=${HDCylinder[${HI}]};
  track=${HDTrack[${HI}]};
  head=${HDHead[${HI}]};
  cyl_bound=$((cyl * track * head));
  sec_bound=${HDSize[${HI}]};

  for (( i = PI_first; i <= PI_last; i++ )); do
    Si=${StartArray[${i}]};
    Ei=${EndArray[${i}]};
    Ki=${KindArray[${i}]};
    Ni=${NamesArray[${i}]};

    if [[ "${Ei}" -gt "${sec_bound}" ]] ; then
       echo "${Ni} ends after the last sector of ${HDName[${HI}]}" >> ${CHK_file};
    elif [[ "${Ei}" -gt "${cyl_bound}" ]] ; then
       echo "${Ni} ends after the last cylinder of ${HDName[${HI}]}" >> ${Trash};
    fi

    if [[ ${Ki} = "L" ]] ; then
       k=${ParentArray[${i}]};
       Sk=${StartArray[${k}]};
       Ek=${EndArray[${k}]};
       Nk=${NamesArray[${k}]};
       [[ ${Si} -le ${Sk} || ${Ei} -gt ${Ek} ]] &&  echo "the logical partition ${Ni} is not contained in the extended partition ${Nk}" >> ${CHK_file};
    fi

    for (( j = i+1; j <= PI_last; j++ )); do
      Sj=${StartArray[${j}]};
      Ej=${EndArray[${j}]};
      Kj=${KindArray[${j}]};
      Nj=${NamesArray[${j}]};

      ( !( ( [ "${Ki}" = 'L' ] && [ "${Kj}" = 'E' ] )  || ( [ "${Ki}" = 'E' ] && [ "${Kj}" = 'L' ] ) )  \
	&& ( ( [ "${Si}" -lt "${Sj}" ] && [ "${Sj}" -lt "${Ei}" ] )  || ( [ "${Sj}" -lt "${Si}" ] && [ "${Si}" -lt "${Ej}" ] ) ) )  \
	&& echo "${Ni} overlaps with ${Nj}" >> ${CHK_file};

    done
  done
}

## Syslinux ##
syslinux_info () {
#   Determine the exact Syslinux version ("SYSLINUX - version - date"), display
#   the offset to the second stage, check the internal checksum (if not correct,
#   the ldlinux.sys file, probably moved), display the directory to which
#   Syslinux is installed.
  local partition=$1;

  # Magic number used by Syslinux:
  local LDLINUX_MAGIC='fe02b23e';

  local LDLINUX_BSS LDLINUX_SECTOR2 ADV_2SECTORS;
  local sect1ptr0_offset sect1ptr0 sect1ptr1 tmp;
  local magic_offset syslinux_version syslinux_dir;

  # Patch area variables:
  local pa_version pa_size pa_hexdump_format pa_magic pa_instance pa_data_sectors;
  local pa_adv_sectors pa_dwords pa_checksum pa_maxtransfer pa_epaoffset;
  local pa_ldl_sectors pa_dir_inode;

  # Extended patch area variables:
  local epa_size epa_hexdump_format epa_advptroffset epa_diroffset epa_dirlen;
  local epa_subvoloffset epa_subvollen epa_secptroffset epa_secptrcnt;
  local epa_sect1ptr0 epa_sect1ptr1 epa_raidpatch epa_syslinuxbanner;

  # ADV magic numbers:
  local ADV_MAGIC_HEAD='a52f2d5a';		# Head signature
  local ADV_MAGIC_TAIL='64bf28dd';		# Tail signature
  local ADV_MAGIC_CHECKSUM=$((0xa3041767));	# Magic used for calculation ADV checksum

  # ADV variables:
  local ADVoffset ADV_calculated_checksum ADV_read_checksum ADVentry_offset;
  local tag='999' tag_len label;

  local csum;



  # Clear previous Syslinux message string.
  Syslinux_Msg='';

  # Read first 512 bytes of partition and convert to hex (ldlinux.bss)
  LDLINUX_BSS=$(hexdump -v -n512 -e '/1 "%02x"' ${partition});

  # Look for LDLINUX_MAGIC: bytes 504-507
  if [ "${LDLINUX_BSS:1008:8}" = "${LDLINUX_MAGIC}" ] ; then
     # Syslinux 4.04-pre5 and higher.
     pa_version=4;	 # Syslinux 4.xx patch area

     # The offset of Sect1Load in LDLINUX_BSS can be found by doing a
     # bitwise XOR of bytes 508-509 (little endian) with 0x1b << 9.
     # sect1ptr0_offset starts 2 bytes furter than Sect1Load.
     sect1ptr0_offset=$(( ( 0x${LDLINUX_BSS:1018:2}${LDLINUX_BSS:1016:2} ^ ( 0x1b << 9 ) ) + 2 ));

     # Get "boot sector offset" (in sectors) of sector 1 ptr LSW: sect1ptr0
     # Get "boot sector offset" (in sectors) of sector 1 ptr MSW: sect1ptr1
     eval $(hexdump -v -s ${sect1ptr0_offset} -n 10 -e '1/4 "sect1ptr0=%u; " 1/2 "tmp=%u; " 1/4 "sect1ptr1=%u;"' ${partition});

  else
     # Check if bytes 508-509 = "7f00".
     if [ "${LDLINUX_BSS:1016:4}" = '7f00' ] ; then
	# Syslinux 3.xx
	pa_version=3;	 # Syslinux 3.xx patch area

	# Get "boot sector offset" (in sectors) of sector 1 ptr LSW: sect1ptr0
	eval $(hexdump -v -s 504 -n 4 -e '1/4 "sect1ptr0=%u;"' ${partition});
     else
	# Syslinux 4.00 - Syslinux 4.04-pre4.
	pa_version=4;	 # Syslinux 4.xx patch area

	# Search for offset to sect1ptr0 (only found in Syslinux 4.xx)
	#   66 b8 xx xx xx xx 66 ba xx xx xx xx bb 00
	#         [sect1ptr0]       [sect1ptr1]
	#
	# Start searching for this hex string after the DOS superblock: byte 0x5a = 90
	eval $(echo ${LDLINUX_BSS:180:844} \
		| ${AWK} '{ mask_offset=match($0,"66b8........66ba........bb00"); \
		if (mask_offset == "0") { print "sect1ptr0_offset=0;" } \
		else { print "sect1ptr0_offset=" (mask_offset -1 ) / 2 + 2 + 90 } }');

	if [ ${sect1ptr0_offset} -ne 0 ] ; then
	   # Syslinux 4.00 - Syslinux 4.04-pre4.

	   # Get "boot sector offset" (in sectors) of sector 1 ptr LSW: sect1ptr0
	   # Get "boot sector offset" (in sectors) of sector 1 ptr MSW: sect1ptr1
	   eval $(hexdump -v -s ${sect1ptr0_offset} -n 10 -e '1/4 "sect1ptr0=%u; " 1/2 "tmp=%u; " 1/4 "sect1ptr1=%u;"' ${partition});
	else
	   Syslinux_Msg='No evidence that this is realy a Syslinux boot sector.';
	   return;
	fi
     fi
  fi

  Syslinux_Msg="Syslinux looks at sector ${sect1ptr0} of ${partition} for its second stage.";

  # Start reading 0.5MiB (more than enough) from second sector of the Syslinux
  # bootloader (= first sector of ldlinux.sys).
  dd if=${partition} of=${Tmp_Log} skip=${sect1ptr0} count=1000 bs=512 2>> ${Trash};

  # Get second sector of the Syslinux bootloader (= first sector of ldlinux.sys)
  # and convert to hex.
  LDLINUX_SECTOR2=$(hexdump -v -n 512 -e '/1 "%02x"' ${Tmp_Log});

  # Look for LDLINUX_MAGIC (8 bytes aligned) in sector 2 of the Syslinux bootloader.
  for (( magic_offset = $((0x10)); magic_offset < $((0x50)); magic_offset = magic_offset + 8 )); do
    if [ "${LDLINUX_SECTOR2:$(( ${magic_offset} * 2 )):8}" = ${LDLINUX_MAGIC} ] ; then

       if [ ${pa_version} -eq 4 ] ; then
	  # Syslinux 4.xx patch area.

	  # Patch area size: 4+4+2+2+4+4+2+2 = 4*4 + 4*2 = 24 bytes
	  pa_size='24';

	  # Get pa_magic, pa_instance, pa_data_sectors, pa_adv_sectors, pa_dwords, pa_checksum, pa_maxtransfer and pa_epaoffset.
	  pa_hexdump_format='1/4 "pa_magic=0x%04x; " 1/4 "pa_instance=0x%04x; " 1/2 "pa_data_sectors=%u; " 1/2 "pa_adv_sectors=%u; " 1/4 "pa_dwords=0x%u; " 1/4 "pa_checksum=0x%04x; " 1/2 "pa_maxtransfer=%u; " 1/2 "pa_epaoffset=%u;"';

	  eval $(hexdump -v -s ${magic_offset} -n ${pa_size} -e "${pa_hexdump_format}" ${Tmp_Log});

       else
	  # Syslinux 3.xx patch area.

	  # Patch area size: 4+4+2+2+4+4 = 4*4 + 2*2 = 20 bytes
	  pa_size='20';

	  # Get pa_magic, pa_instance, pa_dwords, pa_ldl_sectors and pa_checksum.
	  #  - pa_dwords:	Total dwords starting at ldlinux_sys not including ADVs.
	  #  - pa_ldl_sectors:	Number of sectors - (bootsec + sector2) but including any ADVs.
	  pa_hexdump_format='1/4 "pa_magic=0x%04x; " 1/4 "pa_instance=0x%04x; " 1/2 "pa_dwords=%u; " 1/2 "pa_ldl_sectors=%u; " 1/4 "pa_checksum=0x%04x; " 1/4 "pa_dir_inode=%u;"';

	  eval $(hexdump -v -s ${magic_offset} -n ${pa_size} -e "${pa_hexdump_format}" ${Tmp_Log});

	  # Calulate pa_data_sectors: number of sectors (not including ldlinux.bss = first sector of Syslinux).
	  #  - divide by 128 (128 dwords / 512 byte sector)
	  pa_data_sectors=$(( ${pa_dwords} / 128 ));

	  # If total dwords is not exactly a multiple of 128, round up the number of sectors (add 1).
	  if [ $(( ${pa_dwords}%128 )) -ne 0 ] ; then
	     pa_data_sectors=$(( ${pa_data_sectors} + 1 ));
	  fi


	  # Some Syslinux 4.00-pre?? releases are different:
	  #  - have Syslinux 3.xx signature: bytes 508-509 = "7f00".
	  #  - have the "boot sector offset" (in sectors) of sector 1 ptr LSW (bytes 504-507)
	  #    for sect1ptr0, like Syslinux 3.xx.
	  #  - have like Syslinux 4.xx, the same location for pa_data_sectors.
	  #
	  # If pa_dwords is less than 1024, it contains the value of pa_data_sectors:
	  #  - if less and pa_words would really be pa_words:		ldlinux.sys would be smaller than 4 kiB
	  #  - if more and pa_words would really be pa_data_sectors:	ldlinux.sys would be more than 500 kiB

	  if [ ${pa_dwords} -lt 1024 ] ; then
	     pa_data_sectors=${pa_dwords};
	  fi

       fi       


       # Get the "SYSLINUX - version - date" string.
       syslinux_version=$(hexdump -v -e '"%_p"' -s 2 -n $(( ${magic_offset} - 2 )) ${Tmp_Log});
       syslinux_version="${syslinux_version% \.*}";

       # Overwrite the "boot sector type" variable, which was set before calling this function,
       # with a more exact Syslinux version number.
       BST="${syslinux_version}";


       # Check integrity of Syslinux:
       #  - Checksum starting at ldlinux.sys, stopping before the ADV part.
       #  - checksum start = LDLINUX_MAGIC - [sum of dwords].
       #  - add each dword to the checksum value.
       #  - the value of the checksum after adding all dwords of ldlinux.sys should be 0.

       csum=$(hexdump -v -n $(( ${pa_data_sectors} * 512)) -e '/4 "%u\n"' ${Tmp_Log} \
	    | ${AWK} 'BEGIN { csum=4294967296-1051853566 } { csum=(csum + $1)%4294967296 } END {print csum}' );

       if [ ${csum} -ne 0 ] ; then
	  Syslinux_Msg="${Syslinux_Msg} The integrity check of Syslinux failed.";
	  return;
       fi


       if [ ${pa_version} -eq 4 ] ; then
	  # Extended patch area size: 11*2 = 22 bytes
	  epa_size='22';

	  # Get epa_advptroffset, epa_diroffset, epa_dirlen, epa_subvoloffset, epa_subvollen,
	  # epa_secptroffset, epa_secptrcnt, epa_sect1ptr0, epa_sect1ptr1 and epa_raidpatch.
	  epa_hexdump_format='1/2 "epa_advptroffset=%u; " 1/2 "epa_diroffset=%u; " 1/2 "epa_dirlen=%u; " 1/2 "epa_subvoloffset=%u; " 1/2 "epa_subvollen=%u; " 1/2 "epa_secptroffset=%u; " 1/2 "epa_secptrcnt=%u; " 1/2 "epa_sect1ptr0=%u; " 1/2 "epa_sect1ptr1=%u; " 1/2 "epa_raidpatch=%u; " 1/2 "epa_syslinuxbanner=%u;"';

	  eval $(hexdump -v -s ${pa_epaoffset} -n ${epa_size} -e "${epa_hexdump_format}" ${Tmp_Log});

	  # Get the Syslinux install directory.
	  syslinux_dir=$(hexdump -v -e '"%_p"' -s ${epa_diroffset} -n ${epa_dirlen} ${Tmp_Log});
	  syslinux_dir=${syslinux_dir%%\.*};

	  Syslinux_Msg="${Syslinux_Msg} ${syslinux_version:0:8} is installed in the ${syslinux_dir} directory.";


	  # In Syslinux 4.04 and higher, the whole Syslinux banner is not in the first sector of ldlinux.sys.
	  # Only the "SYSLINUX - version" string is still located in the first sector.
	  # epa_syslinuxbanner points to the whole "SYSLINUX - version - date" string.

	  if [ ${epa_syslinuxbanner} -lt $(( ${pa_data_sectors} * 512 )) ] ; then
	     # Get the "SYSLINUX - version - date" string.
	     tmp=$(hexdump -v -e '"%_p"' -s $(( ${epa_syslinuxbanner} + 2 )) -n 100 ${Tmp_Log});


	     # Check if we have Syslinux 4.04 or higher, which suppport the epa_syslinuxbanner field
	     # by comparing the first 8 bytes ("SYSLINUX") of the Syslinux banner from sector 1 with
	     # the 8 bytes to which epa_syslinuxbanner points.

	     if [ x"${tmp:0:8}" = x"${syslinux_version:0:8}" ] ; then
	        syslinux_version="${tmp%%\.No DEFAULT*}";

	        # Overwrite the "boot sector type" variable, which was set before calling this function,
	        # with a more exact Syslinux version number.
	        BST="${syslinux_version}";
	     fi
	  fi



	  # ADV stuff starts here.

	  if [ ${pa_adv_sectors} -ne 2 ] ; then
	     Syslinux_Msg="${Syslinux_Msg} There are ${pa_adv_sectors} ADV sectors instead of 2.";
	     return;
	  fi

	  # Get the ADV offset.
	  ADVoffset=$(( pa_data_sectors * 512 ));

	  # Get the ADV.
	  ADV_2SECTORS=$(hexdump -v -s ${ADVoffset} -n 1024 -e '/1 "%02x"' ${Tmp_Log});

	  # Check if the 2 ADV sectors are exactly the same.
	  if [ "${ADV_2SECTORS:0:1024}" != "${ADV_2SECTORS:1024:1024}" ] ; then
	     Syslinux_Msg="${Syslinux_Msg} The 2 ADV sectors are not the same (corrupt).";
	     return;
	  fi

	  # Check if the ADV area contains the ADV head and tail magic.
	  if ( [ "${ADV_2SECTORS:0:8}" = "${ADV_MAGIC_HEAD}" ] && [ "${ADV_2SECTORS:1016:8}" = "${ADV_MAGIC_TAIL}" ] ) ; then

	     # Caculate the ADV checksum.
	     ADV_calculated_checksum=$(hexdump -v -s $(( ${ADVoffset} + 8 )) -n $((512 - 3*4)) -e '/4 "%u\n"' ${Tmp_Log} \
				     | ${AWK} 'BEGIN { csum='${ADV_MAGIC_CHECKSUM}' } { csum=(csum - $1 + 4294967296)%4294967296 } END { print csum }');

	     ADV_read_checksum=$(hexdump -s $(( ${ADVoffset} + 4 )) -n 4 -e '/4 "%u\n"' ${Tmp_Log});


	     if [ ${ADV_calculated_checksum} -eq ${ADV_read_checksum} ] ; then 

		# Get the info stored in the ADV area:
		#
		# maximum 2 entries can be stored in the ADV, which have the following layout:
		#   - byte 1		     : tag	==> 0 = no entry, 1 = boot-once entry, 2 = menu-save entry
		#   - byte 2		     : tag_len	==> length of label string
		#   - byte 3 - (3 + tag_len) : label	==> label name that will be used

		# First entry starts a offset 8.
		ADVentry_offset=8;

		until eval $(hexdump -s $(( ${ADVoffset} + ${ADVentry_offset} )) -n $((512 - 3*4)) \
			     -e '1/1 "tag=%u; " 1/1 "tag_len=%u; label='\''" 498 "%_p"' ${Tmp_Log};
			   printf "'");
		      [ ${tag} -eq 0 ] ; do


		  if [ ${tag_len} -gt 0 ] ; then
		     label=${label:0:${tag_len}};
		  fi		   

		  case ${tag} in
			1) Syslinux_Msg="${Syslinux_Msg} ${syslinux_version:0:8}'s ADV is set to boot label \"${label}\" next boot only.";;
			2) Syslinux_Msg="${Syslinux_Msg} ${syslinux_version:0:8}'s ADV is set to boot label \"${label}\" by default.";;
		  esac

		  # Adjust the ADVentry_offset, so it points to the next entry.
		  ADVentry_offset=$(( ${ADVentry_offset} + ${tag_len} + 2 ));

		done
	     else
		Syslinux_Msg="${Syslinux_Msg} The integrity check of the ADV area failed.";
	     fi
	  else
	     Syslinux_Msg="${Syslinux_Msg} The ADV head and tail magic bytes were not found.";
	  fi
       fi

       return;
    fi
  done

  # LDLINUX_MAGIC not found.
  Syslinux_Msg="${Syslinux_Msg} It is very unlikely that Syslinux is (still) installed. The second stage could not be found.";

}

## Grub Legacy ##
stage2_loc () {
#   Determine the embeded location of stage 2 in a stage 1 file,
#   look for the stage 2 and, if found, determine the
#   the location and the path of the embedded menu.lst.
  local stage1="$1" HI;

  offset=$(hexdump -v -s 68 -n 4 -e '4 "%u"' "${stage1}");
  dr=$(hexdump -v -s 64 -n 1 -e '1/1 "%u"' "${stage1}");
  pa='T';
  Grub_Version='';

  for HI in ${!HDName[@]}; do
    hdd=${HDName[${HI}]};

    if [ ${offset} -lt  ${HDSize[HI]} ] ; then
       tmp=$(dd if=${hdd} skip=${offset} count=1 2>> ${Trash} | hexdump -v -n 4 -e '"%x"');

       if [[ "${tmp}" = '3be5652' || "${tmp}" = 'bf5e5652' ]] ; then
	  # stage2 files were found.
	  dd if=${hdd} skip=$((offset+1)) count=1 of=${Tmp_Log} 2>> ${Trash};
	  pa=$(hexdump -v -s 10 -n 1 -e '"%d"' ${Tmp_Log});
	  stage2_hdd=${hdd};
	  Grub_String=$(hexdump -v -s 18 -n 94 -e '"%_u"' ${Tmp_Log});
	  Grub_Version=$(echo ${Grub_String} | sed -e 's/nul[^$]*//');
	  BL=${BL}${Grub_Version};
	  menu=$(echo ${Grub_String} | sed -e 's/[^\/]*//' -e 's/nul[^$]*//');
	  menu=${menu%% *};
       fi
    fi
  done

  dr=$((${dr}-127));
  Stage2_Msg="looks at sector ${offset}";       

  if [ "${dr}" -eq 128 ] ; then
     Stage2_Msg="${Stage2_Msg} of the same hard drive";
  else
     Stage2_Msg="${Stage2_Msg} on boot drive #${dr}";
  fi

  Stage2_Msg="${Stage2_Msg} for the stage2 file";
                    
  if [ "${pa}" = "T" ] ; then
     # no stage 2 file found.
     Stage2_Msg="${Stage2_Msg}, but no stage2 files can be found at this location.";
  else
     pa=$((${pa}+1));
     Stage2_Msg="${Stage2_Msg}.  A stage2 file is at this location on ${stage2_hdd}.  Stage2 looks on";
                  
     if [ "${pa}" -eq 256 ] ; then
	Stage2_Msg="${Stage2_Msg} the same partition";
     else
	Stage2_Msg="${Stage2_Msg} partition #${pa}";
     fi

     Stage2_Msg="${Stage2_Msg} for ${menu}.";
  fi
}

## Grub2 ##
grub2_read_blocklist () {
#   Collect fragments of core.img using information encoded in the first
#   block (diskboot.img)
  local hdd="$1";
  local core_img_file="$2";

  local sector_nr_low sector_nr_high sector_nr fragment_size;
  local fragment_offset=1 block_list=500;

  # Assemble fragments from "hdd" passed to grub2_info.
  # Each block list entry is 12 bytes long and consists of
  #   8 bytes = fragment start absolute disk offset in sectors of 512 bytes
  #   2 bytes = fragment size in sectors of 512 bytes
  #   2 bytes = memory segment to load fragment into
  # Entries start at the end of the first sector of core.img and
  # go down. End marker is all zeroes.
  #
  # Blocklists were changed to 64 bit in 2006, so all versions BIS detects
  # should have it.
  #
  # Older versions of hexdump do not support 8 byte integers, so read
  # high and low words separately.
  
  while [ ${block_list} -gt 12 ] ; do
     sector_nr_low=$(hexdump -v -n 4 -s ${block_list} -e '1/4 "%u"' ${core_img_file});
     sector_nr_high=$(hexdump -v -n 4 -s $((block_list+4)) -e '1/4 "%u"' ${core_img_file});
     let "sector_nr = (sector_nr_high << 32) + sector_nr_low";
     if [ ${sector_nr} -eq 0 ] ; then
	return;
     fi

     fragment_size=$(hexdump -v -n 2 -s $((block_list+8)) -e '1/2 "%u"' ${core_img_file});

     dd if="${hdd}" of=${core_img_file} skip=${sector_nr} seek=${fragment_offset} count=${fragment_size} 2>> ${Trash} || return;
     let "fragment_offset += fragment_size";
     let "block_list -= 12";
  done
}

## Grub2 ##
grub2_modname () {
#   Determine the embeded module name. This function implements manual
#   parsing of ELF information to avoid dependency on binutils or similar.
  local modfile=$1;
  local file_size=$2;
  local e_ehsize sht_offset sht_entsize sht_num sht_shdrndx sht_strtab;
  local sht_strtabsize s_nameidx s_type s_name m_offset m_size;
  local i=0;

  # ELF header is at least 52 bytes in size
  if [ "${file_size}" -lt 52 ] ; then
    return;
  fi

  # ELF Magic + CLASS32 + LSB + VERSION
  if [ "$(hexdump -n 7 -e '4/1 "%02x" 3/1 "%x"' "${modfile}")" != '7f454c46111' ] ; then
    return;
  fi

  # RELOCATABLE + MACHINE + VERSION
  if [ "$(hexdump -s 16 -n 8 -e '2/2 "%x" 1/4 "%x"' "${modfile}")" != '131' ] ; then
    return;
  fi

  # ELF header size
  e_ehsize=$(hexdump -s 40 -n 2 -e '"%u"' "${modfile}")
  if [ "${e_ehsize}" -lt 52 -o "${e_ehsize}" -gt "${file_size}" ] ; then
    return;
  fi

  # Offset of section headers table
  sht_offset=$(hexdump -s 32 -n 4 -e '"%u"' "${modfile}")
  if [ "${sht_offset}" -lt "${e_ehsize}" -o "${sht_offset}" -ge "${file_size}" ] ; then
    return;
  fi

  # Size of section header
  sht_entsize=$(hexdump -s 46 -n 2 -e '"%u"' "${modfile}")

  # Number of section headers
  sht_num=$(hexdump -s 48 -n 2 -e '"%u"' "${modfile}")
  if [ "${sht_entsize}" -eq 0 -o "${sht_num}" -eq 0 -o $((sht_offset + sht_entsize*sht_num)) -gt "${file_size}" ] ; then
    return;
  fi

  # Index of section names string table
  sht_shdrndx=$(hexdump -s 50 -n 2 -e '"%u"' "${modfile}")
  if [ "${sht_shdrndx}" -ge "${sht_num}" ] ; then
    return;
  fi

  # Offset of section names string table
  sht_strtab=$(hexdump -s $((sht_offset + $((sht_shdrndx*sht_entsize)) + 16))  -n 4 -e '"%u"' "${modfile}");
  if [ "${sht_strtab}" -lt "${e_ehsize}" -o "${sht_strtab}" -ge "${file_size}" ] ; then
    return;
  fi

  # Size of section names string table
  sht_strtabsize=$(hexdump -s $((sht_offset + $((sht_shdrndx*sht_entsize)) + 20))  -n 4 -e '"%u"' "${modfile}");
  if [ "${sht_strtabsize}" -eq 0 -o "${sht_strtabsize}" -gt "$((file_size-sht_strtab))" ] ; then
    return;
  fi

  while [ "${i}" -lt $((sht_entsize*sht_num)) ] ; do
    s_nameidx=$(hexdump -s $((sht_offset + i))  -n 4 -e '"%u"' "${modfile}");
    if [ "${s_nameidx}" -lt "${sht_strtabsize}" ] ; then
      s_type=$(hexdump -s $((sht_offset + i + 4))  -n 4 -e '"%u"' "${modfile}");
      # PROGBITS
      if [ "${s_type}" -eq 1 ] ; then
	s_name=$(hexdump -s $((sht_strtab + s_nameidx))  -n "${sht_strtabsize}" -e "1/${sht_strtabsize} \"%s\"" "${modfile}");
	if [ "${s_name}" = '.modname' ] ; then
	  m_offset=$(hexdump -s $((sht_offset + i + 16))  -n 4 -e '"%u"' "${modfile}");
	  m_size=$(hexdump -s $((sht_offset + i + 20))  -n 4 -e '"%u"' "${modfile}");
	  if [ $((m_offset + m_size)) -lt "${file_size}" ] ; then
	    hexdump -s "${m_offset}"  -n "${m_size}" -e "/${m_size} \"%s\"" "${modfile}";
	    return
	  fi
	fi
      fi
    fi
    : $((i+=sht_entsize))
  done

  # Display "???" as indication that parsing failed
  printf '%s' '???'
  return
}

## Grub2 ##
grub2_info () {
# Determine the (embeded) location of core.img for a Grub2 boot.img file, determine the path of the grub2 directory and look for an embedded config file.
  local stage1="$1" hdd="$2";

  # When $grub2_version is "1.99-2.00", we want to override this value with a more exact value later (needs to be a global variable).
  grub2_version="$3";

  # Have we got plain file or need to collect full core.img from blocklists?
  local core_source="$4";
  local sector_offset drive_offset directory_offset sector_nr drive_nr drive_nr_hex;
  local partition core_dir embedded_config HI magic core_img_found=0 embedded_config_found=0;
  local total_module_size kernel_image_size compressed_size offset_lzma lzma_uncompressed_size;
  local grub_module_info_offset grub_module_magic grub_modules_offset grub_modules_size;
  local grub_module_type grub_module_size grub_module_header_offset grub_modules_end_offset;
  local lzma_compressed_size reed_solomon_redundancy reed_solomon_length boot_dev boot_drive;
  local core_img_flavour='detect' modname all_modules need_core_prologue=0;
  local grub_module_header_next;

  > ${core_img_file_type_2}

  case "${grub2_version}" in
    1.96) sector_offset='68';  drive_offset='76'; directory_offset='553';;
    1.97-1.98) sector_offset='92';  drive_offset='100'; directory_offset='540';;
    1.99|1.99-2.00|2.00) sector_offset='92';  drive_offset='100';;
  esac

  # Offset to core.img (in sectors).
  sector_nr=$(hexdump -v -s ${sector_offset} -n 4 -e '4 "%u"' "${stage1}" 2>> ${Trash});

  # BIOS drive number on which grub2 looks for its second stage (=core.img):
  #   - "0xff" means that grub2 will use the BIOS drive number passed via the DL register.
  #   - if this value isn't "0xff", that value will used instead.
  # Since version 1.97 GRUB2 is using only 0xff. We cannot reliably determine BIOS numbers
  # anyway, so just skip core.img detection in this case.
  drive_nr_hex=$(hexdump -v -s ${drive_offset} -n 1 -e '"0x%02x"' "${stage1}" 2>> ${Trash});
  drive_nr=$(( ${drive_nr_hex} - 127 ));

  if [ "${drive_nr_hex}" != '0xff' ] ; then
    Grub2_Msg="is configured to load core.img from BIOS drive ${drive_nr} (${drive_nr_hex}) instead of using the boot drive passed by the BIOS";
    return
  fi

  Grub2_Msg="looks at sector ${sector_nr} of the same hard drive for core.img";


  for HI in ${!HDName[@]} ; do
    # If the drive name passed to grub2_info matches the drive name of the current
    # value of HDName, see if the sector offset to core.img is smaller than the
    # total number of sectors of that drive.

    if [ ${hdd} = ${HDName[${HI}]} ] ; then
       if [ ${sector_nr} -lt ${HDSize[HI]} ] ; then

	  if [ "${core_source}" = 'file' ] ; then
	     # Use "file" passed to grub2_info directly.
	     dd if="${stage1}" of=${core_img_file} skip=${sector_nr} count=1024 2>> ${Trash};
	  else
	     # Use "hdd" passed to grub2_info.
	     # First make sure to collect core.img fragments. Read the first block of
	     # core.img and assemble it further from blocklists
	     dd if="${hdd}" of=${core_img_file} skip=${sector_nr} count=1 2>> ${Trash};
	     grub2_read_blocklist "${hdd}" ${core_img_file};
	  fi

	  magic=$(hexdump -v -n 4 -e '/1 "%02x"' ${core_img_file});

	  # 5256be1b - upstream diskboot.S
	  # 5256be6f - unknown
	  # 52e82801 - Ubuntu diskboot.S with conditional message
	  # 52bff481 - RHEL7 diskboot.S with patched out message
	  # 5256be63 - trustedgrub2 1.4
	  # 5256be56 - diskboot.S with mjg TPM patches (e.g. in openSUSE Tumbleweed)

	  case "${magic}" in
	     '5256be1b'|'5256be6f'|'52e82801'|'52bff481'|'5256be63'|'5256be56')
	        core_img_found=1;;
	  esac

	  if [ ${core_img_found} -eq 1 ] ; then

	     if ( [ "${grub2_version}" = '1.99' ] || [ "${grub2_version}" = '1.99-2.00' ] || [ "${grub2_version}" = '2.00' ] ) ; then
		# Find the last 8 bytes of lzma_decode to find the offset of the lzma_stream:
		#   - v1.99: "d1 e9 df fe ff ff 00 00"
		#   - v2.00: "d1 e9 df fe ff ff 66 90" (pad bytes NOP)
		#            "d1 e9 df fe ff ff 8d"    (pad bytes LEA ...)
		#
		# arvidjaar@gmail.com:
		#   final directive in startup_raw.S is .p2align 4 which
		#   (at least using current GCC/GAS) adds lea instructions
		#   (8d...). Exact format and length apparently depend on pad
		#   size and may be on toolkit version. So just accept anything
		#   starting with lea.
		#
		# FIXME what if it ends on exact 16 byte boundary?

		eval $(hexdump -v -n 10000 -e '1/1 "%02x"' ${core_img_file} | \
		     ${AWK} '{ found_at=match($0, "d1e9dffeffff" ); if (found_at == "0") { print "offset_lzma=0" } \
			    else { print "offset_lzma=" ((found_at - 1 ) / 2 ) + 8 "; lzma_decode_last8bytes=" substr($0,found_at,16) ";" } }');

		if [ "${grub2_version}" = '1.99-2.00' ] ; then
		   if ( [ "${lzma_decode_last8bytes}" = "d1e9dffeffff6690" ] || [ "${lzma_decode_last8bytes:0:14}" = "d1e9dffeffff8d" ] || [ "${lzma_decode_last8bytes}" = "d1e9dffeffff8d76" ] ) ; then  #bug 1318381
		      grub2_version='2.00';
		   else
		      grub2_version='1.99';
		   fi
		fi
	     else
		# Grub2 (v1.96 and v1.97-1.98).
		partition=$(hexdump -v -s 532 -n 1 -e '"%d"' ${core_img_file});
		core_dir=$(hexdump -v -s ${directory_offset} -n 64 -e '"%_u"' ${core_img_file} | sed 's/nul[^$]*//');
	     fi

	     if [ "${grub2_version}" = '1.99' ] ; then

		# For Grub2 (v1.99), the core_dir is just at the beginning of the compressed part of core.img.
		
		# Get grub_total_module_size	: byte 0x208-0x20b of embedded core.img ==> byte 520
		# Get grub_kernel_image_size	: byte 0x20c-0x20f of embedded core.img ==> byte 524
		# Get grub_compressed_size	: byte 0x210-0x213 of embedded core.img ==> byte 528
		# Get grub_install_dos_part	: byte 0x214-0x218 of embedded core.img ==> byte 532 --> only 1 byte needed (partition)

		eval $(hexdump -v -s 520 -n 13 -e '1/4 "total_module_size=%u; " 1/4 "kernel_image_size=%u; " 1/4 "compressed_size=%u; " 1 "partition=%d;"' ${core_img_file});



		   if [ ${offset_lzma} -ne 0 ] ; then
		      # Correct the offset to the lzma stream, when 8 subsequent bytes of zeros are at the start of this offset.
		      [ $(hexdump -v -s ${offset_lzma} -n 8 -e '1/1 "%02x"'  ${core_img_file}) = '0000000000000000' ] && offset_lzma=$(( ${offset_lzma} + 8 ))
		      # Calculate the uncompressed size to which the compressed lzma stream needs to be expanded. 
		      lzma_uncompressed_size=$(( ${total_module_size} + ${kernel_image_size} - ${offset_lzma} + 512 ));
		      # Make lzma header (13 bytes): ${lzma_uncompressed_size} must be displayed in little endian format.
		      printf '\x5d\x00\x00\x01\x00'$( printf '%08x' $((${lzma_uncompressed_size} - ${offset_lzma} + 512 )) \
			 | ${AWK} '{printf "\\x%s\\x%s\\x%s\\x%s", substr($0,7,2), substr($0,5,2), substr($0,3,2), substr($0,1,2)}' )'\x00\x00\x00\x00' > ${Tmp_Log};
		      # Get lzma_stream, add it after the lzma header and decompress it.
		      dd if=${core_img_file} bs=${offset_lzma} skip=1 count=$((${lzma_uncompressed_size} / ${offset_lzma} + 1)) 2>> ${Trash} \
			 | cat ${Tmp_Log} - | ${UNLZMA} 2>> ${Trash} > ${core_img_file_unlzma};
		      # Get core dir.
		      core_dir=$( hexdump -v -n 64 -e '"%_c"' ${core_img_file_unlzma} );
		      # Remove "\0"s at the end.
		      core_dir="${core_dir%%\\0*}"
		      # Offset of the grub_module_info structure in the uncompressed part.
		      grub_module_info_offset=$(( ${kernel_image_size} - ${offset_lzma} + 512 ));
		      eval $(hexdump -v -n 12 -s ${grub_module_info_offset} -e '"grub_module_magic=" 4/1 "%_c" 1/4 "; grub_modules_offset=%u; " 1/4 "grub_modules_size=%u;"' ${core_img_file_unlzma});
		      # Check for the existence of the grub_module_magic.
		      if [ x"${grub_module_magic}" = x'mimg' ] ; then
			 # Embedded grub modules found.
			 grub_modules_end_offset=$(( ${grub_module_info_offset} + ${grub_modules_size} ));
			 grub_module_header_offset=$(( ${grub_module_info_offset} + ${grub_modules_offset} ));
			 # Traverse through the list of modules and check if it is a config module.
			 while [ ${grub_module_header_offset} -lt ${grub_modules_end_offset} ] ; do
			   eval $(hexdump -v -n 8 -s ${grub_module_header_offset} -e '1/4 "grub_module_type=%u; " 1/4 "grub_module_size=%u;"' ${core_img_file_unlzma});
			   if [ ${grub_module_type} -eq 2 ] ; then
			      # This module is an embedded config file.
			      embedded_config_found=1;
			      embedded_config=$( hexdump -v -n $(( ${grub_module_size} - 8 )) -s $(( ${grub_module_header_offset} + 8 )) -e '"%_c"' ${core_img_file_unlzma} );
			      # Remove "\0" at the end.
			      embedded_config=$( printf "${embedded_config%\\0}" );
			      break;
			   fi
			   grub_module_header_offset=$(( ${grub_module_header_offset} + ${grub_module_size} ));
			 done
		     fi
		   fi

	     elif [ "${grub2_version}" = '2.00' ] ; then
		# For Grub2 (v2.00), the core_dir is stored in the compressed part of core.img in the same
		# way as the modules and embedded config file.
		# Get grub_compressed_size	   : byte 0x208-0x20b of embedded core.img ==> byte 520
		# Get grub_uncompressed_size	   : byte 0x20c-0x20f of embedded core.img ==> byte 524
		# Get grub_reed_solomon_redundancy : byte 0x210-0x213 of embedded core.img ==> byte 528
		# Get grub_no_reed_solomon_length  : byte 0x214-0x217 of embedded core.img ==> byte 532
		# Get grub_boot_dev		   : byte 0x218-0x21a of embedded core.img ==> byte 536 ( should also contain the grub_boot_drive field )
		# Get grub_boot_drive		   : byte 0x21b of embedded core.img ==> byte 539
		eval $(hexdump -v -s 520 -n 20 -e '1/4 "lzma_compressed_size=%u; " 1/4 "lzma_uncompressed_size=%u; " 1/4 "reed_solomon_redundancy=%u; " 1/4 "reed_solomon_length=%u; boot_dev=" 3/1 "%x" 1 "; boot_drive=%d;"' ${core_img_file});



		   if [ ${offset_lzma} -ne 0 ] ; then
		      # Grub2 pads the start of the lzma stream to a 16 bytes boundary.
		      # Correct the offset to the lzma stream if necessary
		      # Current GCC adds lea instructions as pad bytes
		      offset_lzma=$(( ${offset_lzma} - 2 )); #bug 1318381
		      padsize=$(( (((${offset_lzma} + 15) >> 4) << 4) - ${offset_lzma} )); 
		      [ ${padsize} -gt 0 ] && offset_lzma=$(( ${offset_lzma} + ${padsize} ))
		      # Make lzma header (13 bytes): ${lzma_uncompressed_size} must be displayed in little endian format.
		      printf '\x5d\x00\x00\x01\x00'$( printf '%08x' ${lzma_uncompressed_size} \
			 | ${AWK} '{printf "\\x%s\\x%s\\x%s\\x%s", substr($0,7,2), substr($0,5,2), substr($0,3,2), substr($0,1,2)}' )'\x00\x00\x00\x00' > ${Tmp_Log};
		      # Get lzma_stream, add it after the lzma header and decompress it.
		      dd if=${core_img_file} bs=${offset_lzma} skip=1 count=${lzma_compressed_size} 2>> ${Trash} \
			 | cat ${Tmp_Log} - | ${UNLZMA} 2>> ${Trash} > ${core_img_file_unlzma};
		      # Get offset to the grub_module_info structure in the uncompressed part.
		      eval $(hexdump -v -s 19 -n 4 -e '1/4 "grub_module_info_offset=%u;"' ${core_img_file_unlzma});
		      eval $(hexdump -v -n 12 -s ${grub_module_info_offset} -e '"grub_module_magic=" 4/1 "%_c" 1/4 "; grub_modules_offset=%u; " 1/4 "grub_modules_size=%u;"' ${core_img_file_unlzma});
		      # Check for the existence of the grub_module_magic.
		      if [ x"${grub_module_magic}" = x'mimg' ] ; then
			 # Embedded grub modules found.
			 grub_modules_end_offset=$(( ${grub_module_info_offset} + ${grub_modules_size} ));
			 grub_module_header_offset=$(( ${grub_module_info_offset} + ${grub_modules_offset} ));
			 # Traverse through the list of modules and check if it is a config module.
			 # Upstream GRUB2 supports following module types:
			 #   0 - ELF modules; may be included multiple times
			 #   1 - memory disk image; should be included just once
			 #   2 - embedded initial configuration code; should be included just once
			 #   3 - initial value of ${prefix} variable. Device part may be omitted,
			 #       in which case device is guessed at startup
			 #   4 - public GPG keyring used for file signature checking;
			 #       may be included multiple times
			 # All parts are optional (although in practice
			 # at least drivers for disk and filesystem must be
			 # present).
			 # Since RPM version 2.00-10 fedora includes patch that
			 # inserts additional module type after the first one,
			 # thus shifting all numbers starting with 1. So
			 # embedded config and prefix become 3 and 4 on fedora.
			 while [ ${grub_module_header_offset} -lt ${grub_modules_end_offset} ] ; do
			   if [ $(( ${grub_modules_end_offset} - ${grub_module_header_offset} )) -lt 8 ] ; then
			      echo 'Remaining space in GRUB2 module list too short for a module' >&2;
			      all_modules="${all_modules} <short>";
			      need_core_prologue=1;
			      break
			   fi
			   eval $( hexdump -v -n 8 -s ${grub_module_header_offset} -e '1/4 "grub_module_type=%u; " 1/4 "grub_module_size=%u;"' ${core_img_file_unlzma} );
			   # Next module is always aligned on 4 bytes boundary on i386,
			   # but sometimes grub stores shorter size. Make sure to adjust it.
			   grub_module_header_next=$(( ${grub_module_header_offset} + 8 + (((${grub_module_size} - 8 + 3) >> 2) << 2) ));
			   if [ ${grub_module_header_next} -gt ${grub_modules_end_offset} ] ; then
			      printf 'GRUB2 module size too large; skipping remaining modules. Size left: %d\n' $(( {grub_modules_end_offset} - ${grub_module_header_offset} )) >&2;
			      all_modules="${all_modules} <skipped>";
			      need_core_prologue=1;
			      break
			   fi
			   if [ ${grub_module_type} -eq 0 ] ; then
			      # Regular ELF module
			      dd count=$(( grub_module_size - 8 )) skip=$(( grub_module_header_offset + 8 )) if=${core_img_file_unlzma} of=${GRUB200_Module} bs=1 2>> ${Trash};
			      modname=$(grub2_modname ${GRUB200_Module} $(( grub_module_size - 8 )));
			      if [ -n "${modname}" ] ; then
			        all_modules="${all_modules} ${modname}";
				need_core_prologue=1;
			      fi
			   elif [ ${grub_module_type} -eq 1 ] ; then
			      # "stale" ELF module on fedora or memory disk everywhere else
			      if [ ${core_img_flavour} = 'detect' ] ; then
				 if [ "$(hexdump -v -n 4 -s $((grub_module_header_offset+8)) -e '"%c"' ${core_img_file_unlzma})" = $'\x7f''ELF' ] ; then
				    # fedora "stale" ELF module
				    # TODO display Fedora stale modules
				    core_img_flavour='fedora';
				 else
				    core_img_flavour='upstream';
				 fi
			      fi
			   elif [ ${grub_module_type} -eq 2 ] ; then
			      # memory disk on fedora or embedded config everywhere else
			      if [ ${core_img_flavour} = 'detect' ] ; then
			         # Normally core.img will have prefix which is easier to detect,
			         # so leave detection as last resort.
			         dd if=${core_img_file_unlzma} of=${core_img_file_type_2} bs=1 skip=$((grub_module_header_offset+8)) count=$((grub_module_size-8)) 2>> ${Trash};
			      fi
			      if [ ${core_img_flavour} = 'upstream' ] ; then
				 # This module is an embedded config file.
				 embedded_config_found=1;
				 need_core_prologue=1;
				 # Remove padding starting with the first "\0" at the end.
				 embedded_config=$( hexdump -v -n $(( ${grub_module_size} - 8 )) -s $(( ${grub_module_header_offset} + 8 )) -e '"%_c"' ${core_img_file_unlzma} | sed -e 's/\(\\0\).*$//');
			      fi
			   elif [ ${grub_module_type} -eq 3 ] ; then
			      # embedded config on fedora or prefix everywhere else
			      if [ ${core_img_flavour} = 'detect' ] ; then
				 # if it looks like file name, assume prefix
				 if [[ "$(hexdump -v -n 1 -s $(( grub_module_header_offset + 8 )) -e '"%c"' ${core_img_file_unlzma})" == [/\(] ]] ; then
				    core_img_flavour='upstream';
				 else
				    core_img_flavour='fedora';
				 fi
			      fi
			      if [ ${core_img_flavour} = 'upstream' ] ; then
				 # This module contains the prefix.
				 # Get core dir.
				 # Remove padding "\0"'s at the end.
				 core_dir=$( hexdump -v -n $(( ${grub_module_size} - 8 )) -s $(( ${grub_module_header_offset} + 8 )) -e '"%_c"' ${core_img_file_unlzma} | sed -e 's/\(\\0\)\+$//');
			      elif [ ${core_img_flavour} = 'fedora' ] ; then
				 # This module is an embedded config file.
				 embedded_config_found=1;
				 need_core_prologue=1;
				 # Remove padding starting with the first "\0" at the end.
				 embedded_config=$( hexdump -v -n $(( ${grub_module_size} - 8 )) -s $(( ${grub_module_header_offset} + 8 )) -e '"%_c"' ${core_img_file_unlzma} | sed -e 's/\(\\0\).*$//');
			      fi
			   elif [ ${grub_module_type} -eq 4 ] ; then
			      # prefix on fedora or GPG keyring everywhere else
			      if [ ${core_img_flavour} = 'detect' ] ; then
				 # if it looks like file name, assume prefix
			         # GPG ring normall has \x99 as first byte
				 if [[ "$(hexdump -v -n 1 -s $(( grub_module_header_offset + 8 )) -e '"%c"' ${core_img_file_unlzma})" == [/\(] ]] ; then
				    core_img_flavour='fedora';
				 else
				    core_img_flavour='upstream';
				 fi
			      fi
			      if [ ${core_img_flavour} = 'fedora' ] ; then
				 # This module contains the prefix.
				 # Get core dir.
				 # Remove padding "\0"'s at the end.
				 core_dir=$( hexdump -v -n $(( ${grub_module_size} - 8 )) -s $(( ${grub_module_header_offset} + 8 )) -e '"%_c"' ${core_img_file_unlzma} | sed -e 's/\(\\0\)\+$//');
			      elif [ ${core_img_flavour} = 'upstream' ] ; then
				 # TODO list GPG keyring
				 :
			      fi
			   fi
			   grub_module_header_offset=${grub_module_header_next};
			 done
		      fi
		   fi
	     fi
	  fi
       fi
    fi
  done

if [ "${grub2_version}" = '2.00' ] ; then
    if [ -s ${core_img_file_type_2} ] ; then
        if [ "${core_img_flavour}" = 'detect' ] ; then
            # Neither type 1, 3 or 4 modules were present. So we have either embedded config or memory disk. 
            if type file > /dev/null 2>&1 ; then
                [[ "$(LC_ALL=C file ${core_img_file_type_2})" == *"ASCII text"* ]] && core_img_flavour='upstream' # upstream embedded config
            fi
        fi
        if [ ${core_img_flavour} = 'upstream' ] ; then
            embedded_config_found=1;
            need_core_prologue=1;
            # Remove padding starting with the first "\0" at the end.
            embedded_config=$( hexdump -v -e '"%_c"' ${core_img_file_type_2} | sed -e 's/\(\\0\).*$//' );
        fi
    fi
fi


if [ ${core_img_found} -eq 0 ] ; then # core.img not found.
    Grub2_Msg="${Grub2_Msg}, but core.img can not be found at this location";
else # core.img found.
    Grub2_Msg="${Grub2_Msg}. core.img is at this location";
    # In GRUB 2.00 core.img prefix is optional
    if [ -n "${core_dir}" ]; then
        Grub2_Msg="${Grub2_Msg} and looks for ${core_dir}";
        if [ -n "${partition}" ]; then
           partition=$(( ${partition} + 1 ));
           [ ${partition} -eq 255 ] && Grub2_Msg="${Grub2_Msg} on this drive" || Grub2_Msg="${Grub2_Msg} in partition ${partition}"
        fi
    fi
    [ ${need_core_prologue} -eq 1 ] && Grub2_Msg=$(printf "${Grub2_Msg}. It also embeds following components:")
    if [ -n "${all_modules}" ] ; then
        all_modules="${all_modules# }";
        Grub2_Msg=$(printf "${Grub2_Msg}\n\nmodules\n--------------------------------------------------------------------------------\n${all_modules}\n--------------------------------------------------------------------------------");
    fi
    if [ ${embedded_config_found} -eq 1 ] ; then # Embedded config file found
        Grub2_Msg=$(printf "${Grub2_Msg}\n\nconfig script\n--------------------------------------------------------------------------------\n${embedded_config}\n--------------------------------------------------------------------------------");
    fi
fi
}

## Get embedded menu for grub4dos (grldr/grub.exe) and wee (installed in the MBR). ##
get_embedded_menu () {
#   Function arguments:
#
#   - arg 1:  source     = file (grub4dos) / device (WEE)
#   - arg 2:  titlename  = first part of the title that needs to be displayed
  local source=$1 titlename=$2;

  # Check if magic bytes that go before the embedded menu, are present.
  offset_menu=$(dd if="${source}" count=4 bs=128k 2>> ${Trash} | hexdump -v -e '/1 "%02x"' | grep -b -o 'b0021ace000000000000000000000000');

  if [ -n "${offset_menu}" ] ; then
     # Magic found.
     title_gen "${titlename}" " embedded menu" >> "${Log1}"
     # Calcutate the exact offset to the embedded menu.
     offset_menu=$(( ( ${offset_menu%:*} / 2 ) + 16 ));
	 dd if="${source}" count=1 skip=1 bs=${offset_menu} 2>> ${Trash} | ${AWK} 'BEGIN { RS="\0" } { if (NR == 1) print $0 }' >> "${Log1}";
  fi
}

## Show the location (offset) of a file on a disk ##
last_block_of_file () {
#   Function arguments:
#
#   - arg 1:  filename1
#   - arg 2:  filename2
#   - arg 3:  filename3
#   - ......
#
#   Return values:
#
#   - 0:  None of the provided filenames was found.
#   - 1:  At least one of the provided filenames was found.
  local display='0';
  local BlockSize Fragments Filefrag_Format EndGiByte EndGByte;

  # Remove an existing ${Tmp_Log} log.
  rm -f ${Tmp_Log};

  # "$@" contains all function arguments (filenames).
  for file in "$@" ; do
    if [[ -f "${file}" ]] && [[ -s "${file}" ]] && FileNotMounted "${mountname}/${file}" "${mountname}" ; then

       # There are 4 versions of e2fsprogs filefrag output.
       # In all cases final line could be "1 extent" instead.
       #
       # v1
       #  Blocksize of file %s is %d
       #  File size of %s is %lld (%d blocks)
       #  %s: %d extents found[, perfection would be %d extent%s]
       #
       # v2
       #  Blocksize of file %s is %d
       #  File size of %s is %lld (%d blocks)
       #  First block: %ld
       #  Last block: %ld
       #  %s: %d extents found[, perfection would be %d extent%s]
       #
       # v3
       #  File size of %s is %lld (%ld block%s, blocksize %d)
       #   ext logical physical expected length flags
       #     0     nnn      nnn             nnn xxx
       #     1     nnn      nnn      nnn    nnn xxx
       #   ...
       #  %s: %d extents found[, perfection would be %d extent%s]
       #
       # v4
       #  File size of %s is %llu (%lu block%s of %d bytes)
       #   ext: logical_offset: physical_offset: length: expected: flags:
       #     0:    nnn..   nnn:     nnn..   nnn:    nnn:           xxx
       #     1:    nnn..   nnn:     nnn..   nnn:    nnn:      nnn: xxx
       #   ...
       #  %s: %d extents found[, perfection would be %d extent%s]
       #
       # FIXME e2fsprogs filefrag output "Last block:", not "Last Block:".
       #       Was there yet another filefrag implementation?
       #
       # XXX Original code metioned filefrag output that can show last
       #     block but not number of extents. Unless there was some other
       #     implementation of filefrag, it does not match e2fsprogs sources.
       #
       # XXX Can we hit files with spaces (field count is wrong then)?

       eval $(filefrag -v "${file}" \
	     | ${AWK} -F ' ' 'BEGIN { blocksize=0; expected=0; extents=0; ext_ind=0; last_ext_loc=0; ext_length=0; filefrag_format=""; last_block=0 } \
		{ if ( $1 == "Blocksize" ) { blocksize=$6; filefrag_format="v1"; }; \
		if ( filefrag_format == "v1" ) { \
			if ( $1$2 ~ "LastBlock:" ) { last_block = $3 }; \
		} else if ( $(NF-1) == "blocksize" ) { \
		  blocksize = substr($NF,0,length($NF) - 1); \
		  filefrag_format = "v3"; \
		} else if ( $(NF) == "bytes)" ) { \
		  blocksize = $(NF-1); \
		  filefrag_format = "v4"; \
		  FS=" *|: *|[.][.] *"; \
		} \
		if ( expected != 0 ) { \
		   if ( filefrag_format == "v3" && ext_ind == $1 ) { \
		     if ( last_ext_loc < $3 ) { \
			last_ext_loc = $3; \
			if ( substr($0, expected, 1) == " " ) { \
			   ext_length = $4; } \
			else { \
			   ext_length = $5; \
			} \
		      } \
		   } else if ( filefrag_format == "v4" && ext_ind == $2 ) { \
		    if ( last_block < $6 ) { \
		      last_block = $6; \
		    } \
		   } \
		   ext_ind += 1; \
		} else { \
		  if ( filefrag_format == "v3" && $4 == "expected" ) { \
		     expected= index($0,"expected") + 7; \
		  } else if ( filefrag_format == "v4" && $2 == "ext" ) { \
		    expected = 1; \
		  } \
		} \
		if ( $3 == "extents" ) { \
		  extents = $2; \
		} else if ( $3 == "extent" ) { \
		  extents = 1; \
		} \
		} \
	       	END { \
			if ( filefrag_format == "v3" ) { \
				last_block = last_ext_loc + ext_length; \
			} \
			printf "BlockSize=" blocksize "; Fragments=" extents "; Filefrag_Format=" filefrag_format "; "; \
			if ( last_block == 0 ) { \
				printf "EndGiByte=??; EndGByte=??;" \
			} else { \
				EndByte = last_block * blocksize + 512 * '${start}'; \
				printf "EndGiByte=%.9f; EndGByte=%.9f;", EndByte / 1024 ^ 3, EndByte / 1000 ^ 3; \
			} \
		}');

       if [ "${Filefrag_Format}" = '' ] ; then
	  echo "Unknown filefrag output format" >&2;
	  return 0;
       fi

       if [ "${BlockSize}" -ne 0 ] ; then
	  if [ "${Fragments}" -eq 0 ] ; then
	     printf "%14s = %-14s %s\n" "${EndGiByte}" "${EndGByte}" "${file}" >> ${Tmp_Log};
	  else
	     printf "%14s = %-14s %-45s %2s\n" "${EndGiByte}" "${EndGByte}" "${file}" "${Fragments}" >> ${Tmp_Log};
	  fi
       fi

       # Return 1, when we find at least one of the provided filenames,
       # so we know that we need to display the content of ${Tmp_Log} later.
       display=1;
    fi
  done

  return ${display};
}

## search a partition for information relevant for booting. ##
Get_Partition_Info() {
#   - arg 1:  log        = local version of RESULT.txt
#   - arg 2:  log1       = local version of log1
#   - arg 3:  part       = device for the partition
#   - arg 4:  name       = descriptive name for the partition
#   - arg 5:  mountname  = path where  partition will be mounted.
#   - arg 6:  kind       = kind of the partition
#   - arg 7:  start      = starting sector of the partition
#   - arg 8:  end        = ending sector of the partition
#   - arg 9:  system     = system of the partition
#   - arg 10: PI         = PI of the partition, (equal to "", if not a regular partition) 
local Log="$1" Log1="$2" part="$3" name="$4" mountname="$5"  kind="$6"  start="$7"  end="$8" system="$9" PI="${10}";
local line size=$((end-start)) BST='' BSI='' BFI='' OS='' BootFiles='' Bytes80_to_83='' Bytes80_to_81='' offset='';
local offset_menu='' part_no_mount=0 com32='' com32_version='';

[[ "$DEBBUG" ]] && echo "Searching ${name} for information... ";
PrintBlkid ${part};

# Type of filesystem according to blkid.
type=$(BlkidTag ${part} TYPE);

[ "${system}" = 'BIOS Boot partition' ] && type='BIOS Boot partition';
[ -n ${PI} ] && FileArray[${PI}]=${type};

# Display partition subtitle of 80 characters width.
line='________________________________________________________________________________';
line=${line:$(( ${#name} + 2 ))};

printf '%s: %s\n\n' "${name}" "${line}" >> "${Log}";

# Check for extended partion.
if ( [ "${kind}" = 'E' ] && [ x"${type}" = x'' ] ) ; then
 type='Extended Partition';

 # Don't display the error message from blkid for extended partition.
 cat ${Tmp_Log} >> ${Trash};
else
 cat ${Tmp_Log} >&2;
fi

# Display the File System Type.
echo "    File system:       ${type}" >> "${Log}";

# Get bytes 0x80-0x83 of the Volume Boot Record (VBR).
Bytes80_to_83=$(hexdump -v -n 4 -s $((0x80)) -e '4/1 "%02x"' ${part});

# Get bytes 0x80-0x81 of the Volume Boot Record (VBR).
Bytes80_to_81="${Bytes80_to_83:0:4}";


case ${Bytes80_to_81} in
	0069) BST='ISOhybrid (Syslinux 3.72-3.73)';;
	010f) BST='HP Recovery';;
	019d) BST='BSD4.4: FAT32';;
	0211) BST='Dell Utility: FAT16';;
	0488) BST="Grub2's core.img";;
	0689) BST='Syslinux 3.00-3.52';
	      syslinux_info ${part};
	      BSI="${BSI} ${Syslinux_Msg}";;
	0734) BST='Dos_1.0';;
	0745) BST='Windows Vista: FAT32';;
	089e) BST='MSDOS5.0: FAT16';;
	08cd) BST='Windows 2000/XP: NTFS';;
	0b60) BST='Dell Utility: FAT16';; 
	0bd0) BST='MSWIN4.1: FAT32';;
	0e00) BST='Dell Utility: FAT16';;
	0fb6) BST='ISOhybrid with partition support (Syslinux 3.82-3.86)';;
	2a00) BST='ReactOS';;
	2d5e) BST='Dos 1.1';;
	31c0) BST='Syslinux 4.03 or higher';
	      syslinux_info ${part} '4.03';
	      BSI="${BSI} ${Syslinux_Msg}";;
	31d2) BST="Grub2's core.img";;
	3a5e) BST='Recovery: FAT32';;
	407c) BST='ISOhybrid (Syslinux 3.82-4.04)';;
	4216) BST='Grub4Dos: NTFS';;
	4445) BST='Dell Restore: FAT32';;
	55aa) case ${Bytes80_to_83} in
		55aa750a) BST='Grub4Dos: FAT32';;
		55aa7506) # Get bytes 0x110-0x111 of the Volume Boot Record (VBR).
			  Bytes110_to_111=$(hexdump -v -n 2 -s $((0x110)) -e '2/1 "%02x"' ${part});
			  case "${Bytes110_to_111}" in
			    9090) BST='Windows Vista: NTFS';;
			    2810) BST='Windows 7/2008: NTFS';;
			    0a13) BST='NTFS';; #Windows 8/10/11/2012
			  esac;;
	      esac;;
	55cd) BST='FAT32';;
	5626) BST='Grub4Dos: EXT2/3/4';;
	638b) BST='Freedos: FAT32';;
	6616) BST='Windows 7/2008: FAT16';;
	696e) BST='FAT16';;
	6974) BST='BootIt: FAT16';;
	6f65) BST='BootIt: FAT16';;
	6f6e) BST='-';;		# 'MSWIN4.1: Fat 32'
	6f74) BST='FAT32';;
	7405) BST='Windows 7/2008: FAT32';;
	7815) case ${Bytes80_to_83} in
		7815b106) BST='Syslinux 3.53-3.86';
			  syslinux_info ${part};
			  BSI="${BSI} ${Syslinux_Msg}";;
		7815*   ) BST='FAT32';;
	      esac;;
	7cc6) BST='MSWIN4.1: FAT32';;
      # 7cc6) BST='Win_98';;
	7e1e) BST='Grub4Dos: FAT12/16';;
	8a56) BST='Acronis SZ: FAT32';;
	83e1) BST='ISOhybrid with partition support (Syslinux 4.00-4.04)';;
	8ec0) BST='Windows XP: NTFS';;
	8ed0) BST='Dell Recovery: FAT32';;
	b106) BST='Syslinux 4.00-4.02';
	      syslinux_info ${part};
	      BSI="${BSI} ${Syslinux_Msg}";;
	b600) BST='Dell Utility: FAT16';;
	b6c6) BST='ISOhybrid with partition support (Syslinux 3.81)';;
	b6d1) BST='Windows XP: FAT32';;
	e2f7) BST='FAT32, Non Bootable';;
	e879) BST='ISOhybrid (Syslinux 3.74-3.80)';;
	e9d8) BST='Windows Vista/7: NTFS';;
	f6c1) BST='FAT32';; #Windows 8/10/11/2012
	f6f6) BST='- (cleared BS by FDISK)';;
	fa33) BST='Windows XP: NTFS';;
	fbc0) BST='ISOhybrid (Syslinux 3.81)';;

	## If Grub or Grub 2 is in the boot sector, investigate the embedded information. ##
	48b4) BST='Grub2 (v1.96)';
	      grub2_info ${part} ${drive} '1.96' 'partition';
	      BSI="${BSI} Grub2 (v1.96) is installed in the boot sector of ${name} and ${Grub2_Msg}.";;
	7c3c) BST='Grub2 (v1.97-1.98)';
	      grub2_info ${part} ${drive} '1.97-1.98' 'partition';
	      BSI="${BSI} Grub2 (v1.97-1.98) is installed in the boot sector of ${name} and ${Grub2_Msg}.";;
	0020) BST='Grub2 (v1.99-2.00)';
	      grub2_info ${part} ${drive} '1.99-2.00' 'partition';
	      BSI="${BSI} Grub2 (v${grub2_version}) is installed in the boot sector of ${name} and ${Grub2_Msg}.";;
 aa75 | 5272) BST='Grub Legacy';
	      stage2_loc ${part};
	      BSI="${BSI} Grub Legacy (v${Grub_Version}) is installed in the boot sector of ${name} and ${Stage2_Msg}";;

	## If Lilo is in the VBR, look for map file ##
	8053) BST='LILO';
	      # 0x20-0x23 contains the offset of /boot/map.
	      offset=$(hexdump -v -s 32 -n 4 -e '"%u"' ${part});

	      BSI="${BSI} LILO is installed in boot sector of ${part} and looks at sector ${offset} of ${drive} for the \"map\" file,";

	      # check whether offset is on the hard drive.
	      if [ ${offset} -lt  ${size} ] ; then
		 tmp=$(dd if=${drive} skip=${offset} count=1 2>> ${Trash} | hexdump -v -s 508 -n 4 -e '"%_p"');	
		 
		 if [ "${tmp}" = 'LILO' ] ; then
		    BSI="${BSI} and the \"map\" file was found at this location.";
		 else
		    BSI="${BSI} but the \"map\" file was not found at this location.";
		 fi
	      else
		 BSI="${BSI} but the \"map\" file was not found at this location.";
	      fi;;

	0000) # If the first two bytes are zero, the boot sector does not contain any boot loader.
	      BST='-';;

esac

if [ x"${BST}" = 'x' ] ; then
     BST='Unknown';
     [[ "$type" != 'Extended Partition' ]] && printf "Unknown BootLoader on ${name}\n\n" >> ${Unknown_MBR};
     #hexdump -n 512 -C ${part} >> ${Unknown_MBR};
     #echo >> ${Unknown_MBR};
fi

# Display the boot sector type.
echo "    Boot sector type:  ${BST}" >> "${Log}";



## Investigate the Boot Parameter Block (BPB) of a NTFS partition. ##

if [ "${type}" = 'ntfs' ] ; then
     offset=$(hexdump -v -s 28 -n 4 -e '"%u"' ${part});
     BPB_Part_Size=$(hexdump -v -s 40 -n 4 -e '"%u"' ${part})
     Comp_Size=$(( (${BPB_Part_Size} - ${size}) / 256 ))
     SectorsPerCluster=$(hexdump -v -s 13 -n 1 -e '"%d"' ${part});
     MFT_Cluster=$(hexdump -v -s 48 -n 4 -e '"%d"' ${part});
     MFT_Sector=$(( ${MFT_Cluster} * ${SectorsPerCluster} ));

     #  Track=$(hexdump -v -s 24 -n 2 -e '"%u"' ${part})''    # Number of sectors per track.
     #  Heads=$(hexdump -v -s 26 -n 2 -e '"%u"' ${part})''    # Number of heads.
     #
     #  if [ "${Heads}" -ne 255 ] || [ "${Track}" -ne 63 ] ; then
     #     BSI="${BSI} Geometry: ${Heads} Heads and ${Track} sectors per Track."
     #  fi

    if [[ "${MFT_Sector}" -lt "${size}" ]] ; then
        MFT_FILE=$(dd if=${part} skip=${MFT_Sector} count=1 2>> ${Trash} | hexdump -v -n 4 -e '"%_u"');         
    else 
        MFT_FILE='';
    fi

    MFT_Mirr_Cluster=$(hexdump -v -s 56 -n 4 -e '"%d"' ${part});
    MFT_Mirr_Sector=$(( ${MFT_Mirr_Cluster} * ${SectorsPerCluster} ));
     
    if [[ "${MFT_Mirr_Sector}" -lt "${size}" ]] ; then
        MFT_Mirr_FILE=$(dd if=${part} skip=${MFT_Mirr_Sector} count=1 2>> ${Trash} | hexdump -v -n 4 -e '"%_u"');
    else 
        MFT_Mirr_FILE='';
    fi

    if ( [ "${offset}" -eq "${start}" ] && [ "${MFT_FILE}" = 'FILE' ] && [ "${MFT_Mirr_FILE}" = 'FILE' ] && [ "${Comp_Size}" -eq 0 ] ) ; then
        BSI="${BSI} No errors found in the Boot Parameter Block.";
    else
        if [[ "${offset}" -ne "${start}" ]] ; then
           BSI="${BSI} According to the info in the boot sector, ${name} starts at sector ${offset}.";
           if [[ "${offset}" -ne 63 && "${offset}" -ne 2048  && "${offset}" -ne 0 || "${kind}" != 'L' ]] ; then
              BSI="${BSI} But according to the info from fdisk, ${name} starts at sector ${start}.";
           fi
        fi
        if [[ "${MFT_FILE}" != "FILE" ]] ; then 
           BSI="${BSI} The info in boot sector on the starting sector of the MFT is wrong.";
           printf "MFT Sector of ${name}\n\n" >> ${Unknown_MBR};
           dd if=${part} skip=${MFT_Sector} count=1 2>> ${Trash} | hexdump -C >> ${Unknown_MBR};
        fi
        if [[ "${MFT_Mirr_FILE}" != 'FILE' ]] ; then
           BSI="${BSI} The info in the boot sector on the starting sector of the MFT Mirror is wrong.";
        fi
        if [[ "${Comp_Size}" -ne 0 ]] ; then  
           BSI="${BSI} According to the info in the boot sector, ${name} has ${BPB_Part_Size} sectors, but according to the info from fdisk, it has ${size} sectors.";
        fi
    fi
fi



## Investigate the Boot Parameter Block (BPB) of (some) FAT partition. ##

#  Identifies Fat Bootsectors which are used for booting.
#    if [[ "${Bytes80_to_81}" = '7cc6' || "${Bytes80_to_81}" = '7815' || "${Bytes80_to_81}" = 'b6d1' || "${Bytes80_to_81}" = '7405' || "${Bytes80_to_81}" = '6974' || "${Bytes80_to_81}" = '0bd0' || "${Bytes80_to_81}" = '089e' ]] ;

if [[ "${type}" = 'vfat' ]] ; then
     offset=$(hexdump -v -s 28 -n 4 -e '"%d\n"' ${part});	# Starting sector the partition according to BPB.
     BPB_Part_Size=$(hexdump -v -s 32 -n 4 -e '"%d"' ${part});	# Partition size in sectors according to BPB.
     Comp_Size=$(( (BPB_Part_Size - size)/256 ))		# This number will be unequal to zero, if the 2
								# partions sizes differ by more than 255 sectors.  

     #Track=$(hexdump -v -s 24 -n 2 -e '"%u"' ${part})''	# Number of sectors per track.
     #Heads=$(hexdump -v -s 26 -n 2 -e '"%u"' ${part})''	# Number of heads
     #if [[ "${Heads}" -ne 255  || "${Track}" -ne 63 ]] ; then	# Checks for an usual geometry. 
     #   BSI=$(echo ${BSI}" "Geometry: ${Heads} Heads and ${Track} sectors per Track.)  ### Report unusal geometry
     #fi;     

     # Check whether Partitons starting sector and the Partition Size of BPB and fdisk agree. 
    if [[ "${offset}" -eq "${start}" && "${Comp_Size}" -eq "0"  ]] ; then
        BSI="${BSI} No errors found in the Boot Parameter Block.";	# If they agree.
    else	# If they don't agree.
        if [[ "${offset}" -ne "${start}" ]] ; then			# If partition starting sector disagrees. 
           # Display the starting sector according to the BPB.
           BSI="${BSI} According to the info in the boot sector, ${name} starts at sector ${offset}.";

           # Check whether partition is a logcial partition and if its starting sector value is a 63 or 2048.
           if [[ "${offset}" -ne "63" && "${offset}" -ne "2048" || "${kind}" != "L" ]] ; then
              # If not, display starting sector according to fdisk.
              BSI="${BSI} But according to the info from fdisk, ${name} starts at sector ${start}.";
           else
              # This is quite common occurence, and only matters if one tries to boot Windows from a logical partition.
              BSI="${BSI} But according to the info from fdisk, ${name} starts at sector ${start}. \"63\" and \"2048\" are quite common values for the starting sector of a logical partition and they only need to be fixed when you want to boot Windows from a logical partition.";
           fi
        fi

        # If partition sizes from BPB and FDISK differ by more than 255 sector, display both sizes.       
        if [[ "${Comp_Size}" -ne "0" ]] ; then    
           BSI="${BSI} According to the info in the boot sector, ${name} has ${BPB_Part_Size} sectors.";

           if [[ "$BPB_Part_Size" -ne 0 ]] ; then 
              BSI="${BSI}. But according to the info from the partition table, it has ${size} sectors.";
           fi	# Don't display a warning message in the common case BPB_Part_Size=0. 
        fi
    fi		# End of BPB Error if-then-else.
fi		# End of Investigation of the BPB of vfat partitions.



## Display boot sector info. ##
printf '    Boot sector info: ' >> "${Log}";
printf "${BSI}\n" | fold -s -w 55 | sed -e '/^-------------------------\.\?$/ d' -e '2~1s/.*/                       &/' >> "${Log}";




## Exclude partitions which contain no information, or which we (currently) don't know how to accces. ##
case "${type}" in
	'BIOS Boot partition'	) part_no_mount=1;;
    'BitLocker'             ) part_no_mount=1;;
	'crypto_LUKS'		    ) part_no_mount=1;;
	'Extended Partition'	) part_no_mount=1;;
	'linux_raid_member'	    ) part_no_mount=1;;
	'LVM2_member'		    ) part_no_mount=1;;
	'swap'			        ) part_no_mount=1;;
	'unknown volume type'	) part_no_mount=1;;
	'zfs_member'		    ) part_no_mount=1;;
	''			            ) part_no_mount=1;;
esac

if [ "${part_no_mount}" -eq 0 ] ; then
     # Look for a mount point of the current partition.
     # If multiple mount points are found, use the one with the shortest pathname.
     CheckMount=$(mount | ${AWK} -F "\t" '$0 ~ "^'${part}' " { sub(" on ", "\t", $0); sub(" type ", "\t", $0); print $2 }' | sort | ${AWK} '{ print $0; exit}');
     # Check whether partition is already mounted.
     if [ x"${CheckMount}" = x'' ]; then
        mountname=/mnt/BootInfo/${mountname}
        # Directory where the partition will be mounted.
        mkdir -p "${mountname}";
     else
        if [ "${CheckMount}" = "/" ] ; then
           mountname='';
        else
           # If yes, use the existing mount point.
           mountname="${CheckMount}";
        fi
     fi
     # Clear mount errors for previous partition
     > ${Mount_Error}
     # Try to mount the partition.
     if [ x"${CheckMount}" != x'' ] || mount -r  -t "${type}" ${part} "${mountname}" 2>> ${Mount_Error} \
	|| ( [ "${type}" = ntfs ] &&  ntfs-3g -o ro  ${part} "${mountname}" 2>> ${Mount_Error} ) ; then
		BIS_Scan_Partition
      
        # If partition was mounted by the script.
        if [ x"${CheckMount}" = x'' ] ; then
            umount "${mountname}" || umount -l "${mountname}";          
        fi
    # If partition failed to mount.
    else
        printf "    Mounting failed:   " >> "${Log}";  
        cat ${Mount_Error} >> "${Log}"; 
    fi		# End of Mounting "if then else".
elif [ "$type" = zfs_member ];then
	if [[ "$(df -Th / | grep zfs )" ]];then
		[[ "$(LANG=C fdisk -l | grep "$part " | grep boot)" ]] && mountname=/boot || mountname=""
		BIS_Scan_Partition
	elif [[ "$( mount | grep /mnt/boot-sav/zfs)" ]];then
		[[ "$(LANG=C fdisk -l | grep "$part " | grep boot)" ]] && mountname=/mnt/boot-sav/zfs/boot || mountname=/mnt/boot-sav/zfs
		BIS_Scan_Partition
	fi
fi		# End of Partition Type "if then else".
echo >> "${Log}";
if [[ -e "${Log}"x ]] ; then
    cat "${Log}"x >> "${Log}";
    rm "${Log}"x;
fi
if [[ -e "${Log1}"x ]] ; then
    cat "${Log1}"x >> "${Log1}";
    rm "${Log1}"x;
fi
}	# End Get_Partition_Info function

BIS_Scan_Partition() {
        #  If partition is mounted, try to identify the Operating System (OS) by looking for files specific to the OS.
        OS='';
        ls "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 1>>$Trash 2>>$Trash && OS='Windows';
        for WinOS in 'MS-DOS' 'MS-DOS 6.22' 'MS-DOS 6.21' 'MS-DOS 6.0' 'MS-DOS 5.0' 'MS-DOS 4.01' 'MS-DOS 3.3' 'Windows 98' 'Windows 95'; do
            grep -q "${WinOS}" "${mountname}"/{IO.SYS,io.sys} 2>> ${Trash} && OS="${WinOS}";
        done
        [ -s "${mountname}/Windows/System32/config/SecEvent.Evt" ] || [ -s "${mountname}/WINDOWS/system32/config/SecEvent.Evt" ] \
        || [ -s "${mountname}/WINDOWS/system32/config/secevent.evt" ] || [ -s "${mountname}/windows/system32/config/secevent.evt" ] && OS='Windows XP';
        grep -q "i.s.t.a"  "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows Vista';
        grep -q "n.1.0" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 7 or 10'; #Win7 also contains n.1.0 but not i.n.1.0
        grep -q "n.7" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 7';
        grep -q "n.8" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 8 or 10'; #Win10 in May2020
        grep -q "i.n.1.0" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 10 or 11'; #Win11 in Jan2022
        grep -q "n.1.1" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 11'; #not seen yet
        grep -q "n.1.2" "${mountname}"/{windows,Windows,WINDOWS}/{System32,system32}/{Winload,winload}.exe 2>> ${Trash} && OS='Windows 12'; #not seen yet
        [ -s "${mountname}/ReactOS/system32/config/SecEvent.Evt" ] && OS='ReactOS';
        [ -s "${mountname}/etc/issue" ] && OS=$(sed -e 's/\\. //g' -e 's/\\.//g' -e 's/^[ \t]*//' "${mountname}"/etc/issue);
        [ -s "${mountname}/etc/slackware-version" ] && OS=$(sed -e 's/\\. //g' -e 's/\\.//g' -e 's/^[ \t]*//' "${mountname}"/etc/slackware-version);
        [ -s "${mountname}/etc/redhat-release" ] && OS=$(cat "${mountname}"/etc/redhat-release | tr -d '\n');
        [ -s "${mountname}/etc/os-release" ] && grep -q '^PRETTY_NAME=' "${mountname}/etc/os-release" && OS=$(eval "$(grep '^PRETTY_NAME=' "${mountname}"/etc/os-release)"; printf '%s' "${PRETTY_NAME}" | tr -d '\n');


        ## Search for the files in ${Bootfiles} ##  If found, display their content.
        BootFiles='';
        [ "${type}" = 'vfat' ] && Boot_Files=${Boot_Files_Fat} || Boot_Files=${Boot_Files_Normal};  
        for file in ${Boot_Files} ; do
            if [ -f "${mountname}${file}" ] && [ -s "${mountname}${file}" ] && FileNotMounted "${mountname}${file}" "${mountname}" ; then
                BootFiles="${BootFiles} ${file}";
                # Check whether the file is a symlink.
                if ! [ -h "${mountname}${file}" ] ; then
                    # if not a symlink, display content.
                    if ( [ ${file} = '/grldr' ] || [ ${file} = '/grub.exe' ] ) ; then
                       # Display the embedded menu of grub4dos.
                       get_embedded_menu "${mountname}${file}" "${name}${file}";
                    else
                       title_gen "${name}" "${file} $FILTERED" >> "${Log1}" 			# Generates a titlebar above each file listed.
                       if [[ "$FILTERED" ]];then
                           if [ ${file##*/} = 'fstab' ];then #removes empty lines. Keep commented lines with '/' to see "was on /dev/xxx during installation"
                               while read line; do
                                    if [[ ! "$line" =~ '#' ]] || [[ "$line" =~ 'was on' ]] || [[ "$line" =~ '<file' ]];then
										[[ "$line" =~ password ]] && line="${line%%password*}password****[filtered]****"
										echo "$line" >> "${Log1}"
									fi
                               done < <(sed -e '/^$/d' ${mountname}${file} )
                           elif [[ "$file" =~ 'grub.cfg' ]];then
								prevline=""
								while read line; do
                                    if [[ "$line" =~ "menuentry " ]] || [[ "$line" =~ "### END /etc/grub.d/30_" ]] \
                                    && [[ ! "$line" =~ memtest ]] && [[ ! "$line" =~ "(recovery mode)" ]];then
                                        if [[ "$line" =~ "menuentry " ]];then
                                            line="${line#*menuentry \'}"; line="${line#*menuentry \"}";
                                            line2="${line##* \'}"; line2="${line2#* \"}"; line2="${line2%%\' *}"; line2="${line2%%\" *}"
                                            [[ "$line2" =~ '.efi' ]] && line2="efi${line2#*.efi}" || line2="${line2#*--}";
                                            line2="${line2#*simple-}"; line2="${line2#*anced-}"; line2="${line2#*chain-}"
                                            line="${line%%\' *}"; line="${line%%\" *}";
                                            [[ "$line" != "$line2" ]] && line="$line   $line2" #displays uuid when possible
                                            line="$(echo "$line" | sed 's|/dev/||g' )"
                                        fi
                                        if [[ "$line" != "$prevline" ]];then #avoids consecutive identic lines (e.g. geole)
											if [[ "${prevline##*-}" != "${line##*-}" ]];then ##remove sub-entries
												echo "$line" >> "${Log1}"
												prevline="$line"
											fi
                                        fi
                                    fi
                                done < <(sed -e '/^[ ]*# /d' -e '/^$/d' ${mountname}${file} ) #removes empty lines. Remove '# 'lines but keep # lines to see ### BEGIN /etc/grub.d/40_custom ###
                           elif [ ${file##*/} = 'refind.conf' ] || [ ${file##*/} = 'extlinux.conf' ] || [ ${file##*/} = 'grub' ];then
                               sed -e '/^[ ]*#/d' -e '/^$/d' ${mountname}${file}  >> "${Log1}"; #removes empty lines and commented lines (add   -e '/^[ ]*;/d'   to remove lines starting by ;)
                           else
                               sed -e '/^$/d' ${mountname}${file}  >> "${Log1}"; #just remove empty lines
                           fi
                       else
                            cat ${mountname}${file} >> "${Log1}"
                       fi
                    fi
                fi
            fi
        done

        ## Search for Wubi partitions. ##
        if [ -f "${mountname}/ubuntu/disks/root.disk" ] ; then          
           Wubi=$(losetup -a | ${AWK} '$3 ~ "(/host/ubuntu/disks/root.disk)" { print $1; exit }' | sed 's/.$//' );
           # check whether Wubi already has a loop device.
           if [[ x"${Wubi}" = x'' ]] ; then
              Wubi=$(losetup -f --show  "${mountname}/ubuntu/disks/root.disk" );
              WubiDev=0;
           else
              WubiDev=1;
           fi
           if [ x"${Wubi}" != x'' ] ; then
              Get_Partition_Info "${Log}"x "${Log1}"x "${Wubi}" "${name}/Wubi" "Wubi/${mountname}" 'Wubi' 0 0 'Wubi' '';
              # Remove Wubu loop device, if created by BIS.
              [[ ${WubiDev} -eq 0 ]] && losetup -d "${Wubi}";
           else 
              echo "Found Wubi on ${name}. But could not create a loop device." >&2;
           fi
        fi

        ## Search for the filenames in ${Boot_Prog}. ## If found displays their names.
        if [ "${type}" = 'vfat' ] ; then
           # Check FAT filesystems for EFI boot files.
           for file in "${mountname}"/efi/{,*/}*/{*.efi,grub.cfg}; do
             file="${file#${mountname}}"; # Remove "${mountname}" part of the filename.
             if [ -f "${mountname}${file}" ] && [ -s "${mountname}${file}" ] && FileNotMounted "${mountname}${file}" "${mountname}"; then 
                [[ ! "${file}" =~ memtest ]] && BootFiles="${BootFiles} ${file}";          
                if [ ${file##*/} = 'grub.cfg' ] ; then # display content.
                   title_gen "${name}${file} $FILTERED" >> "${Log1}"			# Generates a titlebar above each file listed.
                    if [[ "$FILTERED" ]];then
                           if [[ "$(cat ${mountname}${file} )" =~ menuentry ]];then
                                while read line; do
                                    if [[ "$line" =~ "menuentry " ]] || [[ "$line" =~ "### END /etc/grub.d/30_" ]] \
                                    && [[ ! "$line" =~ memtest ]] && [[ ! "$line" =~ "(recovery mode)" ]];then
                                        if [[ "$line" =~ "menuentry " ]];then
                                            line="${line#*menuentry \'}"; line="${line#*menuentry \"}";
                                            line2="${line##* \'}"; line2="${line2#* \"}"; line2="${line2%%\' *}"; line2="${line2%%\" *}"
                                            [[ "$line2" =~ '.efi' ]] && line2="efi${line2#*.efi}" || line2="${line2#*--}";
                                            line2="${line2#*simple-}"; line2="${line2#*anced-}"; line2="${line2#*chain-}"
                                            line="${line%%\' *}"; line="${line%%\" *}";
                                            [[ "$line" != "$line2" ]] && line="$line   $line2" #displays uuid when possible
                                            echo "$line" | sed 's|/dev/||g' >> "${Log1}"
                                        else
                                            echo "$line" >> "${Log1}"
                                        fi
                                    fi
                                done < <(sed -e '/^[ ]*# /d' -e '/^$/d' ${mountname}${file} ) #removes empty lines. Remove '# 'lines but keep # lines
                            else
                                sed -e '/^[ ]*# /d' -e '/^$/d' ${mountname}${file}  >> "${Log1}"; #removes empty lines. Remove # lines but keep ### lines to see ### BEGIN /etc/grub.d/40_custom ###
                            fi
                    else
                        cat ${mountname}${file}  >> "${Log1}"
                    fi
                fi
             fi
           done

           # Other boot program files.
           Boot_Prog=${Boot_Prog_Fat};
        else
           Boot_Prog=${Boot_Prog_Normal};  
        fi

        for file in ${Boot_Prog} ; do
            if [ -f "${mountname}${file}" ] && [ -s "${mountname}${file}" ] && FileNotMounted "${mountname}${file}" "${mountname}" ; then 
                BootFiles="${BootFiles}  ${file}";          
            fi
        done



        ## Search for files containing boot codes. ##

        # Loop through all directories which might contain boot_code files.
        for file in ${Boot_Codes_Dir} ; do

          # If such directory exist ...
          if [ -d "${mountname}${file}" ] && FileNotMounted "${mountname}${file}" "${mountname}" ; then
             # Look at the content of that directory.
             for loader in $( ls  "${mountname}${file}" ) ; do
               # If it is a file ...
               if [ -f "${mountname}${file}${loader}" ] && [ -s "${mountname}${file}${loader}" ] ; then

              # Bootpart code has "BootPart" written at 0x101     
              sig=$(hexdump -v -s 257 -n 8  -e '8/1 "%_p"' "${mountname}${file}${loader}");

              if [ "${sig}" = 'BootPart' ] ; then
                 offset=$(hexdump -v -s 241 -n 4 -e '"%d"' "${mountname}${file}${loader}");
                 dr=$(hexdump -v -s 111 -n 1 -e '"%d"' "${mountname}${file}${loader}");
                 dr=$((dr - 127));
                 BFI="${BFI} BootPart in the file ${file}${loader} is trying to chainload sector #${offset} on boot drive #${dr}";
              fi

              # Grub Legacy, Grub2 (v1.96) and Grub2 (v1.99) have "GRUB" written at 0x17f.
              sig=$(hexdump -v -s 383 -n 4 -e '4/1 "%_p"' "${mountname}${file}${loader}");

              if [ "${sig}" = 'GRUB' ] ; then
                 sig2=$(hexdump -v -n 2 -e '/1 "%02x"' "${mountname}${file}${loader}");

                 # Distinguish Grub Legacy and Grub2 (v1.96) by the first two bytes.
                 case "${sig2}" in
                   eb48) stage2_loc "${mountname}${file}${loader}";
                     BFI="${BFI} Grub Legacy (v${Grub_Version}) in the file ${file}${loader} ${Stage2_Msg}";;
                   eb4c) grub2_info "${mountname}${file}${loader}" ${drive} 1.96 'file';
                     BFI="${BFI} Grub2 (v1.96) in the file ${file}${loader} ${Grub2_Msg}.";;
                   eb63) grub2_info "${mountname}${file}${loader}" ${drive} 1.99 'file';
                     BFI="${BFI} Grub2 (v1.99) in the file ${file}${loader} ${Grub2_Msg}.";;
                 esac
              fi

              # Grub2 (v1.97-1.98) has "GRUB" written at 0x188.
              sig=$(hexdump -v -s 392 -n 4  -e '4/1 "%_p"' "${mountname}${file}${loader}");

              if [ "${sig}" = 'GRUB' ]; then
                 grub2_info "${mountname}${file}${loader}" ${drive} 1.97-1.98 'file';
                 BFI="${BFI} Grub2 (v1.97-1.98) in the file ${file}${loader} ${Grub2_Msg}."; 
              fi

              # Grub2 (v2.00) has "GRUB" written at 0x180.
              sig=$(hexdump -v -s 384 -n 4  -e '4/1 "%_p"' "${mountname}${file}${loader}");

              if [ "${sig}" = 'GRUB' ]; then
                 grub2_info "${mountname}${file}${loader}" ${drive} 2.00 'file';
                 BFI="${BFI} Grub2 (v2.00) in the file ${file}${loader} ${Grub2_Msg}."; 
              fi
               fi
             done	# End of loop through the files in a particular Boot_Code_Directory.
          fi
        done		# End of the loop through the Boot_Code_Directories.



        ## Show the location (offset on disk) of all files in: ##
        #   - the GrubError18_Files list
        #   - the SyslinuxError_Files list

        cd "${mountname}/";

        if [ $( last_block_of_file ${GrubError18_Files} ; echo $? ) -ne 0 ] \
        && [ -e ${Tmp_Log} ] ; then #bug 1318381
           title_gen "${name}" ': Location of files loaded by Grub' >> "${Log1}"
           printf "%11sGiB - GB%13sFile%33sFragment(s)\n" ' ' ' ' ' ' >> "${Log1}";
           cat ${Tmp_Log} >> "${Log1}";
        fi

        if [ $( last_block_of_file ${SyslinuxError_Files} ; echo $? ) -ne 0 ] \
        && [ -e ${Tmp_Log} ] ; then #bug 1318381
           title_gen "${name}" ': Location of files loaded by Syslinux' >> "${Log1}"
           printf "%11sGiB - GB%13sFile%33sFragment(s)\n" ' ' ' ' ' ' >> "${Log1}";
           cat ${Tmp_Log} >> "${Log1}";
        fi

        rm -f ${Tmp_Log};

        # Display the version of the COM32(R) modules of Syslinux.
        for com32 in *.c32 syslinux/*.c32 extlinux/*.c32 boot/syslinux/*.c32 boot/extlinux/*.c32 ; do
              if [ -f "${com32}" ] ; then
                 # First 5 bytes of the COM32(R) module are a magic number (used by Syslinux too).
                 com32_version=$(hexdump -n 5 -e '/1 "%02x"' "${com32}");

                 case ${com32_version} in
                b8fe4ccd21)  printf ' %-35s:  COM32R module (v4.xx)\n' "${com32}" >> ${Tmp_Log};;
                b8ff4ccd21)  printf ' %-35s:  COM32R module (v3.xx)\n' "${com32}" >> ${Tmp_Log};;
                     *)  printf ' %-35s:  not a COM32/COM32R module\n' "${com32}" >> ${Tmp_Log};;
                 esac
              fi
        done
        if [ -f ${Tmp_Log} ] ; then
           title_gen "${name}" ': Version of COM32(R) files used by Syslinux' >> "${Log1}"
           cat ${Tmp_Log} >> "${Log1}";
        fi
        cd "${Folder}";
        echo > ${Tmp_Log};
        if [[ x"${BFI}" != x'' ]] ; then
           printf "    Boot file info:     " >> "${Log}";
           printf "${BFI}\n" | fold -s -w 55 | sed -e '/^-------------------------$/ d' -e '2~1s/.*/                       &/' >> "${Log}";
        fi
        printf "    Operating System:  " >> "${Log}";
        echo "${OS}" | fold -s -w 55 | sed -e '2~1s/.*/                       &/' >> "${Log}";
        printf "    Boot files:        " >> "${Log}";
        echo ${BootFiles} | fold -s -w 55 | sed -e '2~1s/.*/                       &/' >> "${Log}";

        temp="${mountname}/etc/grub.d/"
        if [[ -d "$temp" ]];then
            title_gen "${name}: ls -l /etc/grub.d/ $FILTERED" >> "${Log1}"
            if [[ "$FILTERED" ]];then
                LANG=C ls -l "$temp" | grep -v README | grep -v total | grep -v 00_header | grep -v 05_debian | grep -v 20_memtest >> "${Log1}"
                for temp3 in $(ls $temp);do
                    if [[ "$(echo $temp3 | grep -v README | grep -v 00_header | grep -v 05_debian | grep -v 10_linux | \
                    grep -v 20_linux | grep -v 25_bli | grep -v memtest | grep -v 30_os-prober | grep -v 30_uefi-firmware | grep -v 35_fwupd | \
                    grep -v 41_snapshots-btrfs )" ]] \
                    && [[ -f "$temp$temp3" ]];then
                        temp2="$(cat "$temp$temp3" | sed '/^$/d' )" #remove empty lines
                        if [[ "$(echo "$temp2" | sed "/^#/ d" | grep -v "exec tail" | grep -v EOF | grep -v config_dir | grep -v 'fix/cust' | grep -v fi )" ]];then
                            title_gen "${name}/etc/grub.d/$temp3 $FILTERED" >> "${Log1}"
                            echo "$temp2" >> "${Log1}"
                        fi
                    fi
                done
            else
                LANG=C ls -l "$temp" >> "${Log1}"
                for temp3 in $(ls $temp);do
                    if [[ -f "$temp$temp3" ]];then
                        title_gen "${name}/etc/grub.d/$temp3" >> "${Log1}"
                        cat "$temp$temp3" >> "${Log1}"
                    fi
                done
            fi

        fi
}
