# -*- makefile -*-		kit.mk - how to pack up target filesystems and other embedded system assets into useful release kits
#
# Copyright (C) 2001,2002,2003,2004,2005,2006,2007,2008,2009  David Wuertele <dave@crossplex.org>
#
# This file is part of the Crossplex suite of make macros - see http://www.crossplex.com/
#
#    Crossplex is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    Crossplex is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Crossplex.  If not, see <http://www.gnu.org/licenses/>.


ifndef Magic_Tarball_Kit

  include $(CROSSPLEX_BUILD_SYSTEM)/targetfs.mk

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = host-tools targetfs unique name (eg. "host-tools")
  # $3 = kernel build unique name (eg. "davix-vmwarek")
  # $4 = rootfs unique name
  # $5 = build top
  define VMDX_Kit

    $(if $($1_VMDX_KIT_SOURCE_FILES),$(error Called VMDX_Kit with non-unique name $1))

    $1_VMDX_KIT_SOURCE_FILES := crossplex was here

    $5/$1/$1.raw: $($2_qemu_TARGETS) $($2_util-linux_TARGETS) $($1_TARGETFS_TARGETS)
	genext2fs -b 1024 -d src -D device_table.txt flashdisk.img
        #qemu-img create -f raw $$@ 1GB
        #for ldev in /dev/loop0 /dev/loop1 /dev/loop2; do losetup $ldev > /dev/null 2>&1; if [ $? -ne 0 ]; then echo $ldev OK; break; fi; done

    $5/$1/$1.vmdx: $($2_qemu_TARGETS) $5/$1/$1.raw
	touch $$@

    $1/VMDX_FILENAME := $5/$1/$1.vmdx

  endef

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = host-tools targetfs unique name (eg. "host-tools")
  # $3 = kernel build unique name (eg. "davix-vmwarek")
  # $4 = build top
  define LiveCD_Kit

    $(if $($1_KIT_SOURCE_FILES),$(error Called LiveCD_Kit with non-unique name $1))

    $1_KIT_SOURCE_FILES := crossplex was here

    $4/$1/$1-staging/isolinux/isolinux.bin: $($2_TARGETFS_PREFIX)/usr/share/syslinux/isolinux$(ISOLINUXDEBUG).bin
	mkdir -p $$(@D)
	cp -af $$< $$@

    $4/$1/$1-staging/isolinux/isolinux.cfg:
	mkdir -p $$(@D)
	touch $$@

    $4/$1/$1-staging/isolinux/LINUX: $($3_KERNEL_BZIMAGE_FILENAME)
	mkdir -p $$(@D)
	cp -a $$< $$@

    $4/$1/$1.iso: $($2_TARGETFS_PREFIX)/bin/mkisofs $4/$1/$1-staging/isolinux/LINUX $4/$1/$1-staging/isolinux/isolinux.cfg $4/$1/$1-staging/isolinux/isolinux.bin
	mkdir -p $$(@D)
	$($2_TARGETFS_PREFIX)/bin/mkisofs -o $$@ -b isolinux/isolinux.bin -no-emul-boot -boot-info-table $4/$1/$1-staging

    $1_ISO_FILENAME := $4/$1/$1.iso

    $1-livecd-kit-clean:
	rm -rf $4/$1

  endef

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = kernel unique name
  # $3 = rootfs unique name
  # $4 = build top
  define Magic_Tarball_Kit

    $(if $($1_KIT_SOURCE_FILES),$(error Called Magic_Tarball_Kit with non-unique name $1))

    $4/kit-$1/$1-v1.0/vmlinuz: $($2_KERNEL_FILENAME)
	mkdir -p $$(@D)
	cp -af $$< $$@

    $1_KIT_SOURCE_FILES := $($2_KERNEL_FILENAME)

    $1_KIT_SOURCE_FILES += $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/$1-v1.0/rootfs/%,$($3_TARGETFS_TARGETS))

    $1_KIT_SOURCE_FILES_TEST += $($3_TARGETFS_TARGETS)

    $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/$1-v1.0/rootfs/%,$($3_TARGETFS_TARGETS)): $4/kit-$1/$1-v1.0/rootfs/%: $($3_TARGETFS_PREFIX)/%
	mkdir -p $$(@D)
	rm -f $$@
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))

    $4/kit-$1/$1-v1.0.tar.bz2: $4/kit-$1/$1-v1.0/vmlinuz $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/$1-v1.0/rootfs/%,$($3_TARGETFS_TARGETS))
	cd $4/kit-$1 && tar cvjf $$@ $1-v1.0

    default: $4/kit-$1/$1-v1.0.tar.bz2

  endef

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = kernel unique name
  # $3 = rootfs unique name
  # $4 = build top
  define NFS_Boot_Kit

    $(if $($1_KIT_SOURCE_FILES),$(error Called NFS_Boot_Kit with non-unique name $1))

    $4/kit-$1/vmlinuz: $($2_KERNEL_FILENAME)
	mkdir -p $$(@D)
	gzip -cf $$< > $$@

    $1_KIT_SOURCE_FILES := $4/kit-$1/vmlinuz

    $1_KIT_SOURCE_FILES += $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/rootfs/%,$($3_TARGETFS_TARGETS))

    $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/rootfs/%,$($3_TARGETFS_TARGETS)): $4/kit-$1/rootfs/%: $($3_TARGETFS_PREFIX)/% $($3_TARGETFS_SENTINELS)
	mkdir -p $$(@D)
	rm -f $$@
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))

    $1_NFS_KIT_TARGETS := $(patsubst $($3_TARGETFS_PREFIX)/%,$4/kit-$1/rootfs/%,$($3_TARGETFS_TARGETS))

  endef

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = kernel unique name
  # $3 = rootfs unique name
  # $4 = build top
  define NFS_Boot_Kit_Uncontrolled

    $(if $($1_KIT_SOURCE_FILES),$(error Called NFS_Boot_Kit_Uncontrolled with non-unique name $1))

    $4/kit-$1/vmlinuz: $($2_KERNEL_FILENAME)
	mkdir -p $$(@D)
	gzip -cf $$< > $$@

    $4/kit-$1/.installed-uncontrolled-files: $($3_TARGETFS_TARGETS) $($3_TARGETFS_SENTINELS)
	mkdir -p $$(@D) && touch $4/kit-$1/.installing-uncontrolled-files
	$(call Cpio_Findup,$($3_TARGETFS_PREFIX),$4/kit-$1/rootfs)
	mv $4/kit-$1/.installing-uncontrolled-files $$@

    $1_KIT_SOURCE_FILES := $4/kit-$1/vmlinuz

    $1_KIT_SOURCE_FILES += $4/kit-$1/.installed-uncontrolled-files

    $1-kit-clean:
	rm -rf $4/kit-$1

    all-kits-clean: $1-kit-clean

  endef

endif
