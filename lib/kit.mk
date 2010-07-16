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

  GRUB_MODULES := biosdisk part_msdos ext2

  # $1 = unique kit name (eg. "my-super-duper-kit")
  # $2 = host-tools targetfs unique name (eg. "host-tools")
  # $3 = kernel build unique name (eg. "davix-vmwarek")
  # $4 = rootfs unique name
  # $5 = build top
  # $6 = extra kit dependencies
  define VMDK_Kit

    $(if $($1_VMDK_KIT_SOURCE_FILES),$(error Called VMDK_Kit with non-unique name $1))

    $(eval $(call Configure_TargetFS,$1/playerkit,$5,PATH,STRIP LDD))
    $(eval $(call TargetFS_Template,$1/playerkit,$(shell pwd)/fs-template/VMDK))

    $1_VMDK_KIT_SOURCE_FILES := crossplex was here

#    $5/$1/$1.raw: LOOPBACK_DEV := $(shell for ldev in /dev/loop*; do sudo /sbin/losetup $$ldev > /dev/null 2>&1; if [ $$? -ne 0 ]; then echo $$ldev; break; fi; done)

    $5/$1/$1.raw: $($2_TARGETFS_PREFIX)/bin/qemu-img $($2_TARGETFS_PREFIX)/sbin/sfdisk
	# Clean up any previous builds
	rm -rf $$@
	# Create a blank image of a disk
	$($2_TARGETFS_PREFIX)/bin/qemu-img create -f raw $$@ 1GB
	# Create one Linux partition on the whole device
	(echo "0,130,83,*" ; echo ";") | $($2_TARGETFS_PREFIX)/sbin/sfdisk -D $$@ -H 255 -S 63

    $5/$1/$1.partition: $($2_TARGETFS_PREFIX)/sbin/kpartx

    $5/$1/$1.partition: $5/$1/$1.raw
	# Tell the kernel about the partitions
	sudo $($2_TARGETFS_PREFIX)/sbin/kpartx -s -v -a $$< | cut -f3 -d" " > $$@

    $5/$1/$1.loop: $5/$1/$1.partition
	# Discover the name of the loopback device this partition is on
	cut -f1,2 -dp < $$< > $$@

    $5/$1/$1.ext2fs: $($2_TARGETFS_PREFIX)/bin/genext2fs

    $(sort $(dir $(call Complete_Targetfs_Target_List,$4))): $(call Complete_Targetfs_Target_List,$4)

    $(call Targetfs_Prefix_Of,$4)/boot/vmlinuz: $($3_KERNEL_BZIMAGE_FILENAME)
	# Install the kernel in the target filesystem
	mkdir -p $$(@D)
	cp -f $$< $$@
	chmod +x $$@

    $5/$1/$1.ext2fs: $(call Complete_Targetfs_Target_List,$4) | $(sort $(dir $(call Complete_Targetfs_Target_List,$4)))
    $5/$1/$1.ext2fs: $(call Targetfs_Prefix_Of,$4)/boot/vmlinuz

    $(call Targetfs_Prefix_Of,$4)/boot/grub/device.map: $5/$1/$1.loop
	# Tell grub where the disk image is looped
	mkdir -p $$(@D)
	echo "(hd0) /dev/`cat $5/$1/$1.loop`" > $$@

    $(call Targetfs_Prefix_Of,$4)/boot/grub/core.img: $($2_grub_TARGETS)
#	# Copy the grub2 module files
	mkdir -p $$(@D)
	cp -f $($2_TARGETFS_PREFIX)/lib/grub/i386-pc/*[.mod,.img,.lst] $(call Targetfs_Prefix_Of,$4)/boot/grub
	# Build grub2's core.img file
	sudo $($2_TARGETFS_PREFIX)/bin/grub-mkimage --output=$$@ --prefix=/boot/grub $(GRUB_MODULES)

    $5/$1/$1.ext2fs: $5/$1/$1.partition $6 $(call Targetfs_Prefix_Of,$4)/boot/grub/core.img $($2_grub_TARGETS)
	# Create an ext2fs filesystem on the mapped partition
	sudo $($2_TARGETFS_PREFIX)/bin/genext2fs -b 8192 -d $(call Targetfs_Prefix_Of,$4) /dev/mapper/`cat $$<`

    $5/$1/$1.grub-setup: $($2_grub_TARGETS)
    $5/$1/$1.grub-setup: $(call Targetfs_Prefix_Of,$4)/boot/grub/core.img
    $5/$1/$1.grub-setup: $(call Targetfs_Prefix_Of,$4)/boot/grub/device.map 
    $5/$1/$1.grub-setup: $5/$1/$1.ext2fs $5/$1/$1.partition $5/$1/$1.loop 
	# Install grub2 the disk image's MBR
	sudo $($2_TARGETFS_PREFIX)/sbin/grub-setup -v --directory=$(call Targetfs_Prefix_Of,$4)/boot/grub --device-map=$(call Targetfs_Prefix_Of,$4)/boot/grub/device.map --root-device='(hd0,1)' '(hd0)'
	touch $$@

    $5/$1/$1.grub-install: $($2_grub_TARGETS) $5/$1/$1.ext2fs $5/$1/$1.partition $5/$1/$1.loop
	# Install grub2 the disk image's MBR
	sudo $($2_TARGETFS_PREFIX)/sbin/grub-install -v --modules=$(GRUB_MODULES) --root-directory=$(call Targetfs_Prefix_Of,$4) '(hd0)'
	touch $$@

    $5/$1/$1.cleanup: 
	# Tell the kernel to remove the partitions
	-if [ -f $5/$1/$1.raw ] ; then sudo $($2_TARGETFS_PREFIX)/sbin/kpartx -s -v -d $5/$1/$1.raw ; fi
	-if [ -f $5/$1/$1 ] ; then sudo $($2_TARGETFS_PREFIX)/sbin/kpartx -s -v -d /dev/mapper`cat $5/$1/$1` ; fi
	-if [ -f $5/$1/$1.loop ] ; then sudo $($2_TARGETFS_PREFIX)/sbin/kpartx -s -v -d /dev/`cat $5/$1/$1.loop` ; fi
	-if [ -f $5/$1/$1.loop ] ; then sudo $($2_TARGETFS_PREFIX)/sbin/losetup -d /dev/`cat $5/$1/$1.loop` ; fi

    $5/$1/$1-clean: $5/$1/$1.cleanup
	rm -f $5/$1/$1.loop $5/$1/$1.partition $5/$1/$1.grub-setup $5/$1/$1.grub-install $5/$1/$1.raw $5/$1/$1.ext2fs

    $5/$1/playerkit/$1.vmdk: $($1/playerkit_TARGETFS_TARGETS)

    $5/$1/playerkit/$1.vmdk: $($2_TARGETFS_PREFIX)/bin/qemu-img

    $5/$1/playerkit/$1.vmdk: $5/$1/$1.raw $5/$1/$1.grub-setup
	# Convert the raw image to a VMware image
	$($2_TARGETFS_PREFIX)/bin/qemu-img convert -O vmdk $$< $$@ 

    $1/VMDK_FILENAME := $5/$1/playerkit/$1.vmdk

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
