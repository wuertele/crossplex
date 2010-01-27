# -*- makefile -*-		linux-kernel.mk - how to build the linux kernel
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


ifndef Configure_Kernel

  include $(CROSSPLEX_BUILD_SYSTEM)/targetfs.mk

  LINUX_ARCHMAP_linux-2.6.18_i386 := i686-%
  LINUX_ARCHMAP_x86    := i686-%
  LINUX_ARCHMAP_mips   := mips%

  Linux_Arch = $(firstword $(foreach arch, $(if $2,$(patsubst LINUX_ARCHMAP_$2_%,%,$(filter LINUX_ARCHMAP_$2%,$(.VARIABLES)))) $(patsubst LINUX_ARCHMAP_%,%,$(filter LINUX_ARCHMAP%,$(.VARIABLES))),$(if $(filter $(LINUX_ARCHMAP_$2_$(arch)),$1),$(arch)) $(if $(filter $(LINUX_ARCHMAP_$(arch)),$1),$(arch))))

  # $1 = unique kernel name (eg. "davix/kernels/linux")
  # $2 = linux kernel version (eg "linux-2.6.24")
  # $3 = build top (eg "/path/to/build")
  # $4 = path(s) to (optional) top-level directories for initramfs packaging
  # $5 = path(s) to (optional) top-level files containing listings for initramfs packaging
  # $6 = dependencies to satisfy before trying to pack up $4 or $5
  # $7 = tool path code
  # $8 = list of build tags
  # $9 = list of install tags
  # $(10) = list of patch tags
  define Build_Linux_Kernel

    $(if $($1_Build_Linux_Kernel_Args),$(error Called Build_Linux_Kernel with non-unique name $1))

    $1_Build_Linux_Kernel_Args := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6 , 7=$7 , 8=$8 , 9=$9

    $1_KERNEL_SAFENAME   := $(subst /,.,$(subst =,_,$1))
    $1_KERNEL_PARENT_DIR := $3
    $1_KERNEL_PREFIX     := $3/$1
    $1_KERNEL_PATH_CODE  := $7
    $1_KERNEL_BUILD_PATH := $(call TargetFS_Decode_Path,$7)
    $1_KERNEL_BUILD_ENV  := PATH=$(call TargetFS_Decode_Path,$7)
    $1_KERNEL_TOOLCHAIN  := $(call TargetFS_Search_Definer,$7,TOOLCHAIN)
    $1_KERNEL_TUPLE      := $(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE))

    $(call TargetFS_Prep_Source,bogus,linux,$2,$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10)),,$(10))

    $1_KERNEL_MAKE_OPTS := ARCH=$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)
    $1_KERNEL_MAKE_OPTS += CROSS_COMPILE=$$($1_KERNEL_TUPLE)-
    $1_KERNEL_MAKE_OPTS += CC=$$($1_KERNEL_TUPLE)-gcc
    $1_KERNEL_MAKE_OPTS += LD=$$($1_KERNEL_TUPLE)-ld
    $1_KERNEL_MAKE_OPTS += NM=$$($1_KERNEL_TUPLE)-nm
    $1_KERNEL_MAKE_OPTS += $(if $4$5,CONFIG_INITRAMFS_SOURCE="$(strip $4 $5)")

    $1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY := $($(firstword $(foreach token,$7,$(if $($(token)_TOOLCHAIN),$(token))))_TARGETFS_TARGETS)

    $1-kernel-source-prepared: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2_SOURCE_PREPARED) 

    $1-kernel-source-clean:
	rm -rf $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))
	rm -rf $3/$1

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/.config: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2_SOURCE_PREPARED) $$($1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY)
	mkdir -p $$(@D)
	cp $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2/.config-build $$@

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/.htmldocs: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2_SOURCE_PREPARED) $$($1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY)
	mkdir -p $$(@D)
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) htmldocs

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinux: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/.config $5 $6
	+ yes "" | $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS)
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-stage DEPMOD=true modules_install;

    $1_KERNEL_FILENAME := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinux

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/arch/$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)/boot/bzImage: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/.config $5 $6
	+ yes "" | $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) bzImage
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-stage DEPMOD=true modules_install;

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinuz: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinux
	gzip -3fc $$< > $$@

    $1-kernel-compressed-image: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinuz

    $1_KERNEL_BZIMAGE_FILENAME    := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/arch/$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)/boot/bzImage

    $1_KERNEL_COMPRESSED_FILENAME := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,$2 $8 $(10))/$2-build/vmlinuz

  endef


  # $1 = unique kernel name (eg. "davix/kernels/linux")
  # $2 = linux kernel version (eg "linux-2.6.24")
  # $3 = build top (eg "/path/to/build")
  # $4 = kernel tuple (was "$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE))")
  # $5 = path(s) to (optional) top-level directories for initramfs packaging
  # $6 = path(s) to (optional) top-level files containing listings for initramfs packaging
  # $7 = dependencies to satisfy before trying to pack up $5 or $6
  # $8 = kernel build PATH environment variable
  # $9 = list of build tags
  # $(10) = list of install tags
  # $(11) = list of patch tags
  # $(12) = kernel build toolchain dependency (was "$($(firstword $(foreach token,$8,$(if $($(token)_TOOLCHAIN),$(token))))_TARGETFS_TARGETS)")
  define Build_Linux_Kernel_No_TFS

    $(if $($1_Build_Linux_Kernel_No_TFS_Args),$(error Called Build_Linux_Kernel_No_TFS with non-unique name $1))

    $1_Build_Linux_Kernel_No_TFS_Args := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6 , 7=$7 , 8=$8 , 9=$9 10=$(10) 11=$(11) 12=$(12)

    $1_KERNEL_SAFENAME   := $(subst /,.,$(subst =,_,$1))
    $1_KERNEL_PARENT_DIR := $3
    $1_KERNEL_PREFIX     := $3/$1

    $(call Patchify_Rules,$2,$(UNPACKED_SOURCES),$(THIRD_PARTY)/GPL,$3,,$(PATCHES)/GPL,$(11))

    $1_KERNEL_MAKE_OPTS := ARCH=$(call Linux_Arch,$4,$2)
    $1_KERNEL_MAKE_OPTS += CROSS_COMPILE=$4-
    $1_KERNEL_MAKE_OPTS += CC=$4-gcc
    $1_KERNEL_MAKE_OPTS += LD=$4-ld
    $1_KERNEL_MAKE_OPTS += NM=$4-nm
    $1_KERNEL_MAKE_OPTS += $(if $5$6,CONFIG_INITRAMFS_SOURCE="$(strip $5 $6)")

    $1-kernel-source-prepared: $$($3/$2_SOURCE_PREPARED) 

    $1-kernel-source-clean:
	rm -rf $3

    $3/$2-build/.config: $$($3/$2_SOURCE_PREPARED) $(12)
	mkdir -p $$(@D)
	cp $3/$2/.config-build $$@

    $3/$2-build/.htmldocs: $$($3/$2_SOURCE_PREPARED) $(12)
	mkdir -p $$(@D)
	+ $8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) htmldocs

    $1_KERNEL_FILENAME := $3/$2-build/vmlinux

     $3/$2-build/vmlinux: $3/$2-build/.config $6 $7
	+ yes "" | $8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS)
	+ $8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$3/$2-stage DEPMOD=true modules_install;

     $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage: $3/$2-build/.config $6 $7
	+ yes "" | $8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) bzImage
	+ $8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$3/$2-stage DEPMOD=true modules_install;

    $3/$2-build/vmlinuz: $3/$2-build/vmlinux
	gzip -3fc $$< > $$@

    $1-kernel-compressed-image: $3/$2-build/vmlinuz

    $1_KERNEL_BZIMAGE_FILENAME    := $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage

    $1_KERNEL_COMPRESSED_FILENAME := $3/$2-build/vmlinuz

  endef


endif
