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

#  LINUX_ARCHMAP_linux-2.6.18_i386 := i686-%
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

    $(call TargetFS_Prep_Source,bogus,linux,$2,$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10)),,$(10))

    $1_KERNEL_MAKE_OPTS := ARCH=$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)
    $1_KERNEL_MAKE_OPTS += CROSS_COMPILE=$$($1_KERNEL_TUPLE)-
    $1_KERNEL_MAKE_OPTS += CC=$$($1_KERNEL_TUPLE)-gcc
    $1_KERNEL_MAKE_OPTS += LD=$$($1_KERNEL_TUPLE)-ld
    $1_KERNEL_MAKE_OPTS += NM=$$($1_KERNEL_TUPLE)-nm
    $1_KERNEL_MAKE_OPTS += $(if $4$5,CONFIG_INITRAMFS_SOURCE="$(strip $4 $5)")

    $1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY := $($(firstword $(foreach token,$7,$(if $($(token)_TOOLCHAIN),$(token))))_TARGETFS_TARGETS)

    $1-kernel-source-prepared: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2_SOURCE_PREPARED) 

    $1-kernel-source-clean:
	rm -rf $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))
	rm -rf $3/$1

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/.config: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2_SOURCE_PREPARED) $$($1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY)
	mkdir -p $$(@D)
	cp $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2/.config-build $$@

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/.htmldocs: $$($(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2_SOURCE_PREPARED) $$($1_KERNEL_BUILD_TOOLCHAIN_DEPENDENCY)
	mkdir -p $$(@D)
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) htmldocs

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinux: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/.config $5 $6
	+ yes "" | $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS)
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$$(@D) -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-stage DEPMOD=true modules_install;

    $1_KERNEL_FILENAME := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinux

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/arch/$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)/boot/bzImage: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/.config $5 $6
	+ yes "" | $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) bzImage
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ $$($1_KERNEL_BUILD_ENV) $(MAKE) V=1 O=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build -C $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-stage DEPMOD=true modules_install;

    $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinuz: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinux
	gzip -3fc $$< > $$@

    $1-kernel-compressed-image: $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinuz

    $1_KERNEL_BZIMAGE_FILENAME    := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/arch/$(call Linux_Arch,$(or $(call TargetFS_Search_Definition,$7,TOOLCHAIN_TARGET_TUPLE),$(HOST_TUPLE)),$2)/boot/bzImage

    $1_KERNEL_COMPRESSED_FILENAME := $(patsubst %/,%,$(dir $3/$1))/$(call TargetFS_Decode_Work,$7)/$(call TargetFS_Build_Dir,ignorethisfield,$2 $8 $(10))/$2-build/vmlinuz

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

    $(call Patchify_Rules,$2,$(UNPACKED_SOURCES),$(GPLv2_SOURCES),$3,,$(GPLv2_SOURCES),$(11))

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
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) htmldocs

    $1_KERNEL_FILENAME := $3/$2-build/vmlinux

     $3/$2-build/vmlinux: $3/$2-build/.config $6 $7
	+ yes "" | PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS)
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$3/$2-stage DEPMOD=true modules_install;

     $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage: $3/$2-build/.config $6 $7
	+ yes "" | PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) oldconfig
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) bzImage
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) RELEASE_BUILD="" modules
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_KERNEL_MAKE_OPTS) INSTALL_MOD_PATH=$3/$2-stage DEPMOD=true modules_install;

    $3/$2-build/vmlinuz: $3/$2-build/vmlinux
	gzip -3fc $$< > $$@

    $1-kernel-compressed-image: $3/$2-build/vmlinuz

    $1_KERNEL_BZIMAGE_FILENAME    := $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage

    $1_KERNEL_COMPRESSED_FILENAME := $3/$2-build/vmlinuz

  endef

  # Generate rules for building a Linux Kernel
  # $1 = kernel build name (eg. "some-random-informative-identifier")
  # $2 = kernel version (eg. "linux-2.6.29")
  # $3 = build top (eg. "/path/to/some/build/directory")
  # $4 = kernel tuple (eg. "mipsel-unknown-linux-gnu")
  # $5 = path(s) to (optional) top-level directories for initramfs packaging
  # $6 = path(s) to (optional) top-level files containing listings for initramfs packaging
  # $7 = dependencies to satisfy before trying to pack up $5 or $6
  # $8 = kernel build PATH environment variable
  # $9 = list of patch tags
  # $(10) = kernel build toolchain dependency
  define Linux_Rules

    $(if $($1_Linux_Rules_Args),$(error Called Linux_Rules with non-unique name $1))
    $1_Linux_Rules_Args := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6 , 7=$7 , 8=$8 , 9=$9 , 10=$(10)

    # Linux_Rules (1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6, 7=$7, 8=$8, 9=$9, 10=$(10))

    $(call Patchify_Rules,$2,$(UNPACKED_SOURCES),$(GPLv2_SOURCES),$3,,$(GPLv2_SOURCES),$9)

    $1_LINUX_SRC_DIR := $3/$2
    $1_LINUX_BUILD_DIR := $3/$2-build

    $1_LINUX_MAKE_OPTS := $(if $(filter i686-%,$4),ARCH=x86)
    $1_LINUX_MAKE_OPTS += $(if $(filter mips%,$4),ARCH=mips)
    $1_LINUX_MAKE_OPTS += $(if $5$6,CONFIG_INITRAMFS_SOURCE="$(strip $5 $6)")

ifneq ($4,$(HOST_TUPLE))
    $1_LINUX_MAKE_OPTS += $(if $4,CROSS_COMPILE=$4-)
endif

    # Convenience targets.  If you want to just unpack and patch a kernel, run:
    # make mykernel-linux-source-prepared
    # replace "mykernel" with your kernel build name as passed in as $1
    $1-linux-source-prepared: $$($3/$2_SOURCE_PREPARED) 

    linux-source-prepared: $1-linux-source-prepared

    $1-linux-source-clean:
	rm -rf $3/$2*

    linux-source-clean: $1-linux-source-clean

    # Make it so that Linux_Rules() can be called multiple times with the same build top and kernel version, but different kernel build names.
    $(if $($3/$2-build/.config_RULE_DEFINED),,

      $3/$2-build/.config: DEFAULT_CONFIGS=$$(sort $$(filter $3/$2/.config-default,$$($3/$2_SOURCE_PREPARED)))
      $3/$2-build/.config: MERGE_CONFIGS=$$(sort $$(filter $3/$2/.config-merge%,$$($3/$2_SOURCE_PREPARED)))
      $3/$2-build/.config: $$($3/$2_SOURCE_PREPARED)
	# Default config file for $1 is $$(DEFAULT_CONFIGS)
	# If needed, check for variable merge collisions in $$(MERGE_CONFIGS)
	$$(if $$(MEREGE_CONFIGS),perl -e 'while (<>) { if (/([^=]+)=(.+)/) { die "duplicate $$$$1" if (defined ($$$$a{$$$$1}) || defined($$$$b{$$$$1})); $$$$a{$$$$1} = $$$$2; } elsif (/\# (\S+) is not set/) {die "duplicate $$$$1" if (defined($$$$a{$$$$1}) || defined($$$$b{$$$$1})); $$$$b{$$$$1}++;} } ' $$(MERGE_CONFIGS))
	# Passed merge collision check (or didn't need it)
	mkdir -p $$(@D)
	perl -e 'while (<>) { if (/([^=]+)=(.+)/) { $$$$a{$$$$1} = $$$$2; delete $$$$b{$$$$1}} elsif (/\# (\S+) is not set/) {$$$$b{$$$$1}++; delete $$$$a{$$$$1}} } print join ("\n", map { "$$$$_=$$$$a{$$$$_}" } keys %a), "\n"; print join ("\n", map { "# $$$$_ is not set" } keys %b), "\n";' $$(DEFAULT_CONFIGS) $$(MERGE_CONFIGS) > $$@
	# For every variable needed by kernel config and not defined in the .config-default and .config-merge% files, use the kernel's default
	+ yes "" | PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_LINUX_MAKE_OPTS) oldconfig

      $3/$2-sanitized-headers/.installed: $3/$2-build/.config
	  mkdir -p $$(@D)
	  touch $$(@D)/.installing
  #	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) include/asm include/linux/version.h
	  + $(MAKE) PATH=$8:$(build-tools_TARGETFS_PREFIX)/bin V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_HDR_PATH=$$(@D)/usr headers_install
	  mv $$(@D)/.installing $$@


    $3/$2-dirty-headers/.installed: $3/$2-build/.config
	  mkdir -p $$(@D)
	  touch $$(@D)/.installing
  #	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) include/asm include/linux/version.h
	  + $(MAKE) PATH=$8:$(build-tools_TARGETFS_PREFIX)/bin V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_HDR_PATH=$$(@D)/usr headers_install
	  # ignore errors on the following two lines because they only work for linux-2.6.31
	  -cp -r --update $3/$2/arch/mips/include/asm/* $$(@D)/include/asm
	  cp -r --update $3/$2-build/include/linux/* $$(@D)/include/linux
	  cp -r --update $3/$2-build/include/asm-mips/* $$(@D)/include/asm
	  cp -r --update $3/$2-build/include/config $$(@D)/include
	  cp -r --update $3/$2/include/linux $$(@D)/include
	  # ignore errors on the following two lines because they only work (and are only necessary) for linux-2.6.18
	  -cp -r --update $3/$2/include/asm-mips/* $$(@D)/include/asm
	  mv $$(@D)/.installing $$@

    $3/$2-build/vmlinux: $3/$2-build/.config $6 $7
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_LINUX_MAKE_OPTS)
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_LINUX_MAKE_OPTS) RELEASE_BUILD="" modules
	# The next line breaks uniquification because any version will install to a single path $(INSTALL_ROOT).
	# This would be written better as INSTALL_MOD_PATH=$3/$2-stage so that different kernels don't step on each others' results.
	# Unfortunately there is no easy way to specify copying from $3/$2-stage to the target without a recursive copy, and that does not maintain dependency relationships.
	# PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_MOD_PATH=$(INSTALL_ROOT) DEPMOD=true modules_install;
	+ PATH=$8 $(MAKE) V=1 O=$$(@D) -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_MOD_PATH=$3/2-stage DEPMOD=true modules_install;

     $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage: $3/$2-build/.config $6 $7
	+ yes "" | PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) oldconfig
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) bzImage
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) RELEASE_BUILD="" modules
	# The next line breaks uniquification because any version will install to a single path $(INSTALL_ROOT).
	# This would be written better as INSTALL_MOD_PATH=$3/$2-stage so that different kernels don't step on each others' results.
	# Unfortunately there is no easy way to specify copying from $3/$2-stage to the target without a recursive copy, and that does not maintain dependency relationships.
	# PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_MOD_PATH=$(INSTALL_ROOT) DEPMOD=true modules_install;
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) INSTALL_MOD_PATH=$3/2-stage DEPMOD=true modules_install;

    $3/$2-build/vmlinuz: $3/$2-build/vmlinux
	gzip -3fc $$< > $$@

    $3/$2-build/scripts/kallsyms: $3/$2-build/.config
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$(filter-out CROSS_COMPILE=%,$$($1_LINUX_MAKE_OPTS)) prepare scripts

      $3/$2-build/.config_RULE_DEFINED := crossplexwashere

     )

    $1-linux-config: $3/$2-build/.config

    $1_CONFIG_FILENAME := $3/$2-build/.config

    linux-config: $3/$2-build/.config

    $1-linux-mrproper: $3/$2-build/.config
	+ PATH=$8 $(MAKE) V=1 O=$3/$2-build -C $3/$2 $$($1_LINUX_MAKE_OPTS) mrproper

    linux-mrproper: $1-linux-mrproper

    $1-linux-prepare: $3/$2-build/scripts/kallsyms

    linux-prepare: $3/$2-build/scripts/kallsyms

    $1-linux-sanitized-headers-install: $3/$2-sanitized-headers/.installed

    linux-sanitized-headers-install: $3/$2-sanitized-headers/.installed

    $1_LINUX_SANITIZED_HEADERS := $3/$2-sanitized-headers/include

    $1-linux-dirty-headers-install: $3/$2-dirty-headers/.installed

    linux-dirty-headers-install: $3/$2-dirty-headers/.installed

    $1_LINUX_DIRTY_HEADERS := $3/$2-dirty-headers/include

    $1-linux-compressed-image: $3/$2-build/vmlinuz

    linux-compressed-image: $3/$2-build/vmlinuz

    $1_LINUX_BZIMAGE_FILENAME    := $3/$2-build/arch/$(call Linux_Arch,$4,$2)/boot/bzImage

    $1_LINUX_COMPRESSED_FILENAME := $3/$2-build/vmlinuz

    $1_LINUX_HEADER_DIRS := $3/$2/include $3/$2-build/include $3/$2-build/include2

    $1_LINUX_INCLUDES := $(patsubst %,-I%,$3/$2/include $3/$2-build/include $3/$2-build/include2)

  endef


endif
