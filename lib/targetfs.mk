# -*- makefile -*-		targetfs.mk - rules for unpacking, patching, building, staging, and installing third-party packages into a target filesystem
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


# A few words about how Crossplex organizes builds
#
# The central object in Crossplex is the "TargetFS".  A TargetFS is a
# directory structure in which all building is done.  A build usually
# consists of multiple intermediate TargetFSes that cumulate in one or
# more final TargetFSes that get "kitted" into a deployable object.
# There is no distinction between an intermediate TargetFS and a final
# one other than that a developer chooses one of the TargetFSes to
# deploy.
#
# A TargetFS has:
#
# 1.  a NAME, which is also used as the path (relative to BUILD_TOP)
#     of the TargetFS root (or "prefix" in autoconf terms)
#
# 2.  a PATH, which is an arbitrary list of TargetFS bin directories
#     to search for build tools, and optionally a host path
#
# 3.  a list of TAGS, which are interpreted by rules that install
#     files in that TargetFS
#
# A TargetFS might be intended for deploying on a target, it might be
# intended as an intermediate step in a build, it might be both.  The
# semantics of any given TargetFS are not known to the TargetFS.
#
# A TargetFS can be used to assemble a host environment used to
# insulate a build from the actual host's environment.  This is how
# Crossplex can acheive builds that are completely specified by
# sources.  That means the deployable object is bit identical no
# matter where or when it was compiled.  I know of no other build
# system that can acheive this goal.
#
# TargetFSes can be grouped according to the path used in their names
# (i.e. their roots are sibling directories).  Grouping enables
# sharing of intermediate objects.  In order for two TargetFSes to
# share intermediate objects, their roots must be sibling directories,
# their PATH and their list of TAGS must be identical, and they must
# specify software packages with similar configurations.  Crossplex
# allows you to leverage commonality between platforms in your build
# while guaranteeing correctness.
#
# Since a TargetFS can search other TargetFSes for build tools, it was
# natural to create a toolchain builder that uses TargetFSes as
# sysroots.


ifndef Configure_TargetFS

  MKNOD := /bin/mknod

  # Some basic definitions useful to all
  include $(CROSSPLEX_BUILD_SYSTEM)/common.mk

  # How to unpack and patch packages
  include $(CROSSPLEX_BUILD_SYSTEM)/patch.mk

  # How to build specific packages
  include $(CROSSPLEX_BUILD_SYSTEM)/module-details.mk

  # Given a path "/some/path", expand it into a list of common executable paths like "/some/path/bin /some/path/sbin", etc.
  TargetFS_Subpaths = $(if $1,$(foreach subdir,bin sbin usr/bin usr/sbin usr/local/bin,$1/$(subdir)))

  # Given a list of targetfs names and potentially a special token "PATH", expand into a colon-separated path of common executable paths rooted at each targetfs dir.
  # The special "PATH" token gets replaced by the host PATH environment variable.
  TargetFS_Decode_Path = $(call cmerge,:,$(foreach token,$1,$(if $(filter PATH,$(token)),$(PATH),$(if $(filter $2,$(token)),$(call TargetFS_Subpaths,$3/$2),$(call TargetFS_Subpaths,$($(token)_TARGETFS_PREFIX))))))

  # Given a path "/some/path", expand it into a list of common include paths like "/some/path/include /some/path/usr/include", etc.
  TargetFS_Subincludes = $(if $1,$(foreach subdir,include usr/include usr/local/include,-I$1/$(subdir)))

  # Given a list of targetfs names, expand into a list of compiler include directives rooted at each targetfs dir.
  TargetFS_Decode_Includes = $(foreach token,$1,$(call TargetFS_Subincludes,$($(token)_TARGETFS_PREFIX)))

  # Given a path "/some/path", expand it into a list of common library paths like "/some/path/lib /some/path/usr/lib", etc.
  TargetFS_Sublibraries = $(if $1,$(foreach subdir,lib usr/lib usr/local/lib,-L$1/$(subdir)))

  # Given a list of targetfs names, expand into a list of compiler linker search dirs rooted at each targetfs dir.
  TargetFS_Decode_Libraries = $(foreach token,$1,$(call TargetFS_Sublibraries,$($(token)_TARGETFS_PREFIX)))

  # Given a list of targetfs names and potentially a special token "PATH", compute a unique string that can be used as a directory for building with that path
  TargetFS_Decode_Work = $(call cmerge,_,work $(foreach token,$1,$(if $(filter PATH,$(token)),PATH,$($(token)_TARGETFS_SAFENAME))))

  # Given a targetfs name and a module name, return the dependency list for the first token in the targetfs path for which the module is defined as having dependencies
  TargetFS_Decode_Dependency = $($(firstword $(foreach token,$(filter-out PATH,$($1_TARGETFS_PATH_CODE)),$(if $($(token)_$2_TARGETS),$(token))))_$2_TARGETS)

  TargetFS_Search_Definer = $(firstword $(foreach token,$(filter-out PATH,$1),$(if $($(token)_$2),$(token))))

  TargetFS_Search_Definition = $($(firstword $(foreach token,$(filter-out PATH,$1),$(if $($(token)_$2),$(token))))_$2)

  TargetFS_All_Definitions = $($(foreach token,$1,$(if $($(token)_$2),$(token)))_$2)

  # $1 = unique targetfs name (eg. "my-group/my-rootfs")
  # $2 = build top (eg "/path/to/build-top")
  # $3 = path code (eg "mipsel-glibc/toolchain host/tools PATH")
  # $4 = optional default install tags
  # $5 = optional toolchain target tuple
  define Configure_TargetFS

    # Configure_Targetfs (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)

    $(if $($1_Configure_TargetFS_Args),$(error Called Configure_TargetFS with non-unique name $1))

    $1_Configure_TargetFS_Args := 1=$1 , 2=$2 , 3=$3 , 4=$4

    $1_TARGETFS_SAFENAME   := $(subst /,.,$(subst =,_,$1))

    $1_TARGETFS_PARENT_DIR := $2

    $1_TARGETFS_PREFIX     := $2/$1

    $1_TARGETFS_PATH_CODE  := $3

    $1_TARGETFS_WORK       := $(patsubst %/,%,$(dir $2/$1))/$(call TargetFS_Decode_Work,$3)

    $1_TARGETFS_PKGCONFIG  := $(patsubst %/,%,$(dir $2/$1))/pkgconfig/$(notdir $2/$1)

    $1_TARGETFS_BUILD_PATH := $(call TargetFS_Decode_Path,$3,$1,$2)

    $1_TARGETFS_BUILD_ENV  := PATH=$(call TargetFS_Decode_Path,$3,$1,$2)
    $1_TARGETFS_BUILD_ENV  += PKG_CONFIG_PATH=$(patsubst %/,%,$(dir $2/$1))/pkgconfig/$(notdir $2/$1)
    $1_TARGETFS_BUILD_ENV  += CFLAGS="$(call TargetFS_Decode_Includes,$3)"
    $1_TARGETFS_BUILD_ENV  += LDFLAGS="$(call TargetFS_Decode_Libraries,$3)"

    $1_TARGETFS_RUNTIMES         := $(call TargetFS_Search_Definition,$3,RUNTIMES)
    $1_TARGETFS_RUNTIMES_TARGETS := $($(firstword $(foreach token,$3,$(if $($(token)_RUNTIMES),$(token))))_$($(firstword $(foreach token,$3,$(if $($(token)_RUNTIMES),$(token))))_RUNTIMES)_TARGETS)

    $1_TARGETFS_TOOLCHAIN         := $(call TargetFS_Search_Definition,$3,TOOLCHAIN)

    $1_TARGETFS_TOOLCHAIN_TARGETS := $($(call TargetFS_Search_Definer,$3,TOOLCHAIN)_TARGETFS_TARGETS)

    $1_TARGETFS_TUPLE             := $(or $(call TargetFS_Search_Definition,$3,TOOLCHAIN_TARGET_TUPLE),$5,$(HOST_TUPLE))

    $1_TARGETFS_DEFAULT_INSTALL_TAGS += $4

    $(if $5,$1_TOOLCHAIN_TARGET_TUPLE := $5)

    $1_TargetFS_Tool_DESTDIR = $$(call TargetFS_Search_Definition,$3,$$1_DESTDIR)

    $1_TargetFS_Tool_SENTINEL = $$(call TargetFS_Search_Definition,$3,$$1_INSTALLED_SENTINEL)

    $$($1_TARGETFS_PREFIX)/dev/loop0:   ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ b 7 0
    $$($1_TARGETFS_PREFIX)/dev/tty:     ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 5 0
    $$($1_TARGETFS_PREFIX)/dev/tty0:    ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 4 0
    $$($1_TARGETFS_PREFIX)/dev/console: ; mkdir -vp $$(@D); sudo $(MKNOD) -m 600 $$@ c 5 1
    $$($1_TARGETFS_PREFIX)/dev/ptmx:    ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 5 2
    $$($1_TARGETFS_PREFIX)/dev/null:    ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 1 3
    $$($1_TARGETFS_PREFIX)/dev/zero:    ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 1 5
    $$($1_TARGETFS_PREFIX)/dev/random:  ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 1 8
    $$($1_TARGETFS_PREFIX)/dev/urandom: ; mkdir -vp $$(@D); sudo $(MKNOD) -m 666 $$@ c 1 9
    $$($1_TARGETFS_PREFIX)/dev/pts:     ; mkdir -vp $$@; touch $$@
    $$($1_TARGETFS_PREFIX)/proc:        ; mkdir -vp $$@; touch $$@
    $$($1_TARGETFS_PREFIX)/var/log:     ; mkdir -vp $$@; touch $$@
    $$($1_TARGETFS_PREFIX)/tmp:         ; mkdir -ma+rwx -vp $$@; touch $$@

    $(foreach device_file_path, dev/console dev/tty dev/tty0 dev/null dev/random dev/zero dev/ptmx dev/pts proc var/log tmp,
      $1_$(device_file_path): $2/$1/$(device_file_path)
      $1_$(device_file_path)_TARGETS := $2/$1/$(device_file_path)
    )

    # How to copy installable runtimes from the appropriate toolchain into our targetfs prefix
    $(foreach component,$(sort $(foreach targetfs,$3,$($(targetfs)_TARGETFS_INSTALLABLE_COMPONENT))),

      $(patsubst %,$2/$1/%,$(call TargetFS_Search_Definition,$3,$(component)_INSTALLABLE_FILE)): $2/$1/%: $($(call TargetFS_Search_Definer,$3,$(component)_INSTALLABLE_FILE)_TARGETFS_PREFIX)/%; rm -rf $$@; $$(call Cpio_DupOne_WithLinks,$$(<D),$$(<F),$$(@D))

      $1_$(component)_TARGETS := $(patsubst %,$2/$1/%,$(call TargetFS_Search_Definition,$3,$(component)_INSTALLABLE_FILE))

     )

    # Various aliases for subsets of components whose install rules are already defined
    $(foreach component,$(sort $(foreach targetfs,$3,$($(targetfs)_TARGETFS_ALIASED_COMPONENT))),

      $1_$(component)_TARGETS := $(patsubst %,$2/$1/%,$(call TargetFS_Search_Definition,$3,$(component)_INSTALLABLE_FILE))

     )

    $1-clean:
	rm -rf $$($1_TARGETFS_PREFIX)
	rm -rf $$($1_TARGETFS_PKGCONFIG)

  endef


  # $1 = unique targetfs name (eg. "my-group/my-rootfs")
  # $2 = build top (eg "/path/to/build-top")
  # $3 = series of targetfs names to overlay, in order of default first
  define Configure_Composite_TargetFS

    $(call Configure_Targetfs,$1,$2,$(patsubst %,$(%_TARGETFS_PATH_CODE),$3),$(patsubst %,$(%_TARGETFS_DEFAULT_INSTALL_TAGS),$3))

    $(foreach targetfs,$3,

       $(patsubst $($(targetfs)_TARGETFS_PREFIX)/%,$2/$1/%,$($(targetfs)_TARGETFS_TARGETS)): $2/$1/%: $($(targetfs)_TARGETFS_PREFIX)/%
	mkdir -p $$(@D)
	rm -rf $$@
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))

     )

  endef


  # $1 = unique targetfs name (eg. "my-rootfs")
  # $2 = list of relative paths of runtime files (like devices), or names of runtime libraries to resolve and install
  define TargetFS_Install_Runtime_Dependencies

    $(foreach target_name,$2,
      $1_TARGETFS_TARGETS := $$(sort $$($1_TARGETFS_TARGETS) $$($1_$(target_name)_TARGETS))
    )

  endef

# $1 = unique targetfs name (eg. "my-rootfs")
# $2 = list of relative paths of target files
# $3 = optional default install tags
define TargetFS_Install_App_Files

    $$(patsubst %,$($1_TARGETFS_PREFIX)/%,$2): $($1_TARGETFS_PREFIX)/%: $($1_TOOL_SYSTEM_DIR)/%
	mkdir -p $$(@D)
	rm -rf $$@
	@echo installing $$< in $$@
	@echo d=$$(<D)
	@echo f=$$(<F)
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))
	$(if $(filter STRIP,$3 $($1_TARGETFS_DEFAULT_INSTALL_TAGS)), if [ -f $$@ -a -x $$@ -a ! -h $$@ ] ; then $$($1_TARGETFS_BUILD_ENV) $$($1_TARGETFS_TUPLE)-strip $$@ || echo WARNING CANT STRIP $$@; fi)

    $1_TARGETFS_TARGETS += $$(patsubst %,$($1_TARGETFS_PREFIX)/%,$2)

endef

# $1 = unique targetfs name (eg. "my-rootfs")
# $2 = list of relative paths of target files
# $3 = optional default install tags
define TargetFS_Install_App_Dev_Files

    $$(patsubst %,$($1_TARGETFS_BUILDLIB)/%,$2): $($1_TARGETFS_BUILDLIB)/%: $($1_TOOL_SYSTEM_DIR)/%
	mkdir -p $$(@D)
	rm -rf $$@
	@echo installing $$< in $$@
	@echo d=$$(<D)
	@echo f=$$(<F)
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))
	$(if $(filter STRIP,$3 $($1_TARGETFS_DEFAULT_INSTALL_TAGS)), if [ -f $$@ -a -x $$@ -a ! -h $$@ ] ; then $$($1_TARGETFS_BUILD_ENV) $$($1_TARGETFS_TUPLE)-strip $$@ || echo WARNING CANT STRIP $$@; fi)

    $1_TARGETFS_TARGETS += $$(patsubst %,$($1_TARGETFS_BUILDLIB)/%,$2)

endef

# $1 = unique targetfs name (eg. "my-rootfs")
# $2 = path to staging root of target files
# $($1_TOOL_SYSTEM_DIR) = paths to any files that this installation depends upon
define TargetFS_Install_Uncontrolled_App_Files

    $2$($1_TARGETFS_PREFIX)/.installed: $($1_TOOL_SYSTEM_DIR)
	mkdir -p $$(@D) && touch $$(@D)/.installing
	$(call Cpio_Findup,$2,$($1_TARGETFS_PREFIX))
	mv $$(@D)/.installing $$@

    $1_TARGETFS_SENTINELS += $2$($1_TARGETFS_PREFIX)/.installed

endef

# $1 = unique targetfs name (eg. "my-rootfs")
# $2 = path to staging root of target files
# $($1_TOOL_SYSTEM_DIR) = paths to any files that this installation depends upon
define TargetFS_Install_Uncontrolled_App_Dev_Files

    $2$($1_TARGETFS_PREFIX)/.devinstalled: $($1_TOOL_SYSTEM_DIR)
	mkdir -p $$(@D) && touch $$(@D)/.installing
	$(call Cpio_Findup,$2,$($1_TARGETFS_BUILDLIB))
	mv $$(@D)/.installing $$@

    $1_TARGETFS_SENTINELS += $2$($1_TARGETFS_PREFIX)/.devinstalled

endef

# $1 = unique targetfs name (eg. "my-rootfs")
define TargetFS_Install_Gdbserver
   $1_TARGETFS_TARGETS += $$($1_TARGETFS_PREFIX)/usr/local/bin/$$($1_TARGETFS_TUPLE)-gdbserver

   $(call TargetFS_Install_Runtime_Dependencies,$1,libthread_db)
endef

# $1 = unique targetfs name (eg. "my-rootfs")
define TargetFS_Install_Glibc_Apps
   $1_TARGETFS_TARGETS += $($1_TARGETFS_GLIBC_APPS)

   $(call TargetFS_Install_Runtime_Dependencies,$1,dev/null)
endef

# $1 = unique targetfs name (eg. "my-rootfs")
# $2 = path to template dir (eg. "fs-template/BASIC")
define TargetFS_Template

  $(if $($1_$2_TARGETS),,

    $1_$2_TARGETS := $(patsubst $2/%,$($1_TARGETFS_PREFIX)/%,$(shell if [ -d $2 ]; then find $2 -mindepth 1 -type f -o -type l -o -type d; fi))

    $(patsubst $2/%,$($1_TARGETFS_PREFIX)/%,$(shell if [ -d $2 ]; then find $2 -mindepth 1 -type f; fi)): $($1_TARGETFS_PREFIX)/%: $2/%
	mkdir -p $$(@D)
	rm -f $$@
	cp -a $$< $$@
	touch $$@

    $(patsubst $2/%,$($1_TARGETFS_PREFIX)/%,$(shell if [ -d $2 ]; then find $2 -mindepth 1 -type l; fi)): $($1_TARGETFS_PREFIX)/%:
	$$(shell if [ ! -L $$@ ]; then mkdir -p $$(@D); cp -a $2/$$* $$@; fi)

    $(patsubst $2/%,$($1_TARGETFS_PREFIX)/%,$(shell if [ -d $2 ]; then find $2 -mindepth 1 -type d; fi)): $($1_TARGETFS_PREFIX)/%:
	mkdir -p $$@

    $1_TARGETFS_TARGETS += $(patsubst $2/%,$($1_TARGETFS_PREFIX)/%,$(shell if [ -d $2 ]; then find $2 -mindepth 1 -type f -o -type l -o -type d; fi))

  )

endef

  # $1 targetfs name (eg "daves_favorite_targetfs")
  # $2 software module name
  # $3 software version to install
  # $4 path to working dir
  # $5 build nickname
  # $6 patch tags
  # $7 source plugins
  define TargetFS_Prep_Source

    # TargetFS_Prep_Source (1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6 , 7=$7)

    $(if $($4/$5/$3_SOURCEPREPPED),,

      $(if $($($2_LICENSE)_SOURCES),,$(error $2 has license $($2_LICENSE) but source locations are undefined!))

      $(call Patchify_Rules,$3,$(UNPACKED_SOURCES),$($($2_LICENSE)_SOURCES),$4,$5,$($($2_LICENSE)_SOURCES),$6)

      $(foreach module,$(CONFIGURE_TOOLS_KNOWN_SRC_PLUGINS),
                $(if $(filter $(module)%,$7),
                     $(if $(filter $(module)_LICENSE,$(.VARIABLES)),
                          $(call Patchify_Rules,$(filter $(module)%,$7),$(UNPACKED_SOURCES),$($($(module)_LICENSE)_SOURCES),$4,$5,$($($(module)_LICENSE)_SOURCES),$6)

      $4/$5/$3_SOURCE_PREPARED += $4/$5/$3/.src_plugin_$(module)_linked

      $4/$5/$3/.src_plugin_$(module)_linked: $4/$5/$3/.repliduplicated $$($4/$5/$(filter $(module)%,$7)_SOURCE_PREPARED)
	rm -f $$@
	cd $4/$5/$(filter $(module)%,$7) $(foreach path,$(or $($(module)_COPY_PATHS),.),&& find $(path) | grep -v .repliduplicated | grep -v .unpacked | cpio -aplmdu $$(@D)/$(or $($(module)_COPY_TARGET),.))
	touch $$@

)))

      $4/$5/$3_SOURCEPREPPED := yes

    )

  endef


  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = path to unpacked and patched package source directory
  # $4 = OPTIONAL extension of directory name where to actually build
  # $5 = OPTIONAL pre-configure steps
  # $6 = value of AUTORECONF flag
  # $7 = OPTIONAL specific configure arguments
  # $8 = list of build tags
  # $9 = software version
  define TargetFS_Build_Autoconf

    $(if $($3$4_BUILD_TARGET),,

      TargetFS_Build_Autoconf_$1_$2 := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6 , 7=$7

      $3$4_CONFIGURE_OPTS := --prefix=$(if $(filter NOSTAGE,$8),$($1_TARGETFS_PREFIX),/)
      $3$4_CONFIGURE_OPTS += --build=$(HOST_TUPLE)
      $3$4_CONFIGURE_OPTS += --host=$($1_TARGETFS_TUPLE)
      $3$4_CONFIGURE_OPTS += $(if $(filter MALLOC0RETURNSNULL,$8),--enable-malloc0returnsnull)

      .PHONY: $1_$2-build-dependencies

      $(patsubst %/,%,$(dir $3))/CONFIG_DETAILS:							# How to capture configuration information for build in a file
	mkdir -p $$(@D)
	@echo $($(notdir $(patsubst %/,%,$(dir $3)))_CONFIG_DETAILS) > $$@

      $1_$2-build-dependencies $3$4/.built: $(patsubst %/,%,$(dir $3))/CONFIG_DETAILS			# Capture configuration information for build in a file

      $1_$2-build-dependencies $3$4/.built: $($1_TARGETFS_TOOLCHAIN_TARGETS)				# can't build without a toolchain
      $1_$2-build-dependencies $3$4/.built: $$($3_SOURCE_PREPARED)					# this variable contains the sentinels that are touched when this source is completely untarred and patched
      $1_$2-build-dependencies $3$4/.building: $$($3_SOURCE_PREPARED)					# this variable contains the sentinels that are touched when this source is completely untarred and patched

      $1_$2-build-dependencies $3$4/.built: $(patsubst %,$$($1_%_DEV_TARGETS),$($2_BUILD_DEPENDENCIES))	# these are the **_DEV_TARGETS (staged files) for each package that must be built before this one
      #this next line is a better version of the previous line.  maybe delete the previous line...
      $1_$2-build-dependencies $3$4/.built: $(foreach dependency,$($2_BUILD_DEPENDENCIES),$(call $1_TargetFS_Tool_SENTINEL,$(dependency))) 

      $1_$2-build-dependencies $3$4/.built: $(if $(filter SYSROOT=%,$8),$(patsubst SYSROOT=%,$$(%_TARGETFS_TARGETS),$(filter SYSROOT=%,$8))) # these are the **_TARGETS (installed files) for each package that must be built before this one

      # the following dependency is necessary because f**ing libtool can't deal with libraries in the staging directory for some reason
      $1_$2-build-dependencies $3$4/.built: $(patsubst %,$$($1_%_TARGETS),$($2_RUNTIME_DEPENDENCIES))	# these are the **_TARGETS (runtime installed files) for each package that this one might dynamically link to
      $1_$2-build-dependencies $3$4/.built: $(foreach dependency,$($2_TOOL_DEPENDENCIES),$(call TargetFS_Decode_Dependency,$1,$(dependency)))  # these are the special-built host tools that we need to have before building this package

      $3$4/TAGS: $3$4/.built
	mkdir -p $$(@D)
	+env $(subst ENV=,,$(filter ENV=%,$8)) $(if $($2_BUILD_ENVIRONMENT),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $(MAKE) -C $$(@D) TAGS

      $3$4/.built:
	mkdir -p $$(@D)
	if [ -f $$(@D)/.building ]; then false; fi
	touch $$(@D)/.building
	$(if $5,$5,@echo no pre-configure steps)
	$(if $6,cd $3 && env -i $($1_TARGETFS_BUILD_ENV) $($2_AUTORECONF_ENV) autoreconf -v --install --force,@echo skipping autoreconf)
	$(if $(filter NOCONFIGURE,$8),@echo skipping configure,cd $$(@D) && env $(subst ENV=,,$(filter ENV=%,$8)) $(if $($2_BUILD_ENVIRONMENT),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $3/configure $(if $7,$7,$$($3$4_CONFIGURE_OPTS)))
	$(if $(filter $2_MAKE_ARGS%,$(.VARIABLES)),,
	+env $(subst ENV=,,$(filter ENV=%,$8)) $(if $($2_BUILD_ENVIRONMENT),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $(MAKE) -C $$(@D))
	$(foreach arglist,$(sort $(filter $2_MAKE_ARGS%,$(.VARIABLES))),
	+env $(subst ENV=,,$(filter ENV=%,$8)) $(if $($2_BUILD_ENVIRONMENT),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $(MAKE) -C $$(@D) $(call $(arglist),$1,$8,$9))
	$(call $2_POST_BUILD_STEPS,$1,$8,$3,$4,$9)
	mv $$(@D)/.building $$@
	touch $$@

      $3$4_BUILD_TARGET := $3$4/.built

      $1_$2_BUILD_DIR := $3$4

    )

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = path to unpacked and patched package source directory
  # $4 = OPTIONAL extension of directory name where to actually build
  # $5 = "staging complete" sentinel filename (eg ".staged-a-b-c")
  # $6 = DESTDIR for make install
  # $7 = list of target paths (RELATIVE to $6)
  # $8 = build tags
  # $9 = install tags
  define TargetFS_Make_Install

    $(if $($3$4/$5_STAGE_SENTINEL_TARGET),,

      $(if $(filter UNIQUIFY,$9),

      $3$4/$5: $3$4/.built
	mkdir -p $$(@D)
	$(call Cpio_Findup,$3$4,$3$4$5)
	+env $(subst ENV=,,$(filter ENV=%,$8)) $(if $(call $2_BUILD_ENVIRONMENT,$1,$8),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $(MAKE) -C $3$4$5 $(if $(call $2_MAKE_INSTALL_ARGS,$1,$8,$6),$(call $2_MAKE_INSTALL_ARGS,$1,$8,$6),install) $(call TagCond,NODESTDIR,,DESTDIR=$6,$8)
	$(call $2_POST_INSTALL_STEPS,$1,$8,$3,$4$5,$6)
	touch $$@

      ,

      $3$4/$5: $3$4/.built
	mkdir -p $$(@D)
	# The following command simulates a lock.  But there is still a possible race condition!
	# while [ -f $$(@D)/.??*-in-progress ]; do perl -e '$$$$a=$$$$$$$$; @b=split(//,$$$$a); sleep ($$$$b[$$$$#b]);'; done
	touch $$@-in-progress
	+env $(subst ENV=,,$(filter ENV=%,$8)) $(if $(call $2_BUILD_ENVIRONMENT,$1,$8),$(call $2_BUILD_ENVIRONMENT,$1,$8),$($1_TARGETFS_BUILD_ENV)) $(MAKE) -C $$(@D) $(if $(call $2_MAKE_INSTALL_ARGS,$1,$8,$6),$(call $2_MAKE_INSTALL_ARGS,$1,$8,$6),install) $(call TagCond,NODESTDIR,,DESTDIR=$6,$8)
	$(call $2_POST_INSTALL_STEPS,$1,$8,$3,$4,$6)
	mv $$@-in-progress $$@

      )

      $(patsubst %,$6/%,$7): $3$4/$5

      $3$4/$5_STAGE_SENTINEL_TARGET := $3$4/$5

    )

    $1_MODULES += $2
    $1_$2_DESTDIR := $6
    $1_$2_INSTALLED_SENTINEL := $3$4/$5

  endef

  # $1 = list of install tags
  # $2 = software module name (eg "syslinux")
  # $3 = list of build tags (to get the CROSS tuple if any)
  TargetFS_Package_Installables = $(sort $(foreach set-of-targets,$(if $1,$(foreach tag,$1,$(patsubst %,$2_INSTALLABLE_%,$(tag))),$(filter $2_INSTALLABLE_%,$(.VARIABLES))),$(call $(set-of-targets),$(if $(filter TARGET=%,$3),$(subst TARGET=,,$(filter TARGET=%,$3))),$(if $(filter TARGET=%,$3),-))))

  # Generate a variable name for storing a unique targetfs build dir
  # $1 = targetfs
  # $2 = space-separated list of fields to filter and concatenate
  TargetFS_Build_Dir_Var = $(call cmerge,-,$(subst /,.,buildsdir-name-$(foreach word,$2,$(subst UNIQBUILD,UNIQBUILD.$1,$(lastword $(subst =, ,$(word)))))))

  # Count the number of TargetFS_Build_Dir_Var variables defined with the first field in $2
  # $1 = targetfs
  # $2 = space-separated list of fields to filter and concatenate
  TargetFS_Build_Dir_Var_Count = $(words $(filter $(call cmerge,-,$(subst /,.,$(subst UNIQBUILD,UNIQBUILD.$1,buildsdir-name-$(firstword $2))))%,$(.VARIABLES)))

  # Generate a directory name unique to the list of fields in $2, but using an incrementing "confX" string
  # $1 = targetfs
  # $2 = space-separated list of fields to filter and concatenate
  TargetFS_Build_Dir_Counting = $(or $($(call TargetFS_Build_Dir_Var,$1,$2)),$(firstword $2)-conf$(call TargetFS_Build_Dir_Var_Count,$1,$2))

  # Discover the directory name specifically defined to be unique to the list of fields in $2
  # Create a new one if one doesn't exist yet.
  # $1 = targetfs
  # $2 = space-separated list of fields to filter and concatenate
  TargetFS_Build_Dir = $(or $($(call TargetFS_Build_Dir_Var,$1,$2)),$(eval $(call TargetFS_Build_Dir_Var,$1,$2) := $(call TargetFS_Build_Dir_Counting,$1,$2))$(eval $(call TargetFS_Build_Dir_Counting,$1,$2)_CONFIG_DETAILS = $1 $2)$($(call TargetFS_Build_Dir_Var,$1,$2)))


  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = software version
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_NoStage

    $1_$2_STAGE         := $($1_TARGETFS_PREFIX)

    # How to install files if we're NOT staging:  install direct to this targetfs' prefix and create an .installed-$1-$5 sentinel unique to this targetfs
    $(call TargetFS_Make_Install,$1,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3,$(if $(filter BUILDINSRC,$4),,-build),$(call cmerge,-,.installed $($1_TARGETFS_SAFENAME) $5),$($1_TARGETFS_PREFIX),$(call TargetFS_Package_Installables,$5,$2,$4) $($2_PKGCONFIG),$4,$5 UNIQUIFY)

    # Add to the lists of targets JUST the sentinel file
    $1_TARGETFS_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3$(if $(filter BUILDINSRC,$4),,-build)/$(call cmerge,-,.installed $($1_TARGETFS_SAFENAME) $5)
    $1_$2_TARGETS       += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3$(if $(filter BUILDINSRC,$4),,-build)/$(call cmerge,-,.installed $($1_TARGETFS_SAFENAME) $5)

    $1_$2:                 $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3$(if $(filter BUILDINSRC,$4),,-build)/$(call cmerge,-,.installed $($1_TARGETFS_SAFENAME) $5)

    # Add to the lists of targets the pkgconfig file
    $1_TARGETFS_TARGETS += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))
    $1_$2_TARGETS       += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    $1_$2:                 $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    # For doing software development based on this package, we need to install into the targetfs prefix, and we need the .pc file.
    $1_$2_DEV_TARGETS   += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3$(if $(filter BUILDINSRC,$4),,-build)/$(call cmerge,-,.installed $($1_TARGETFS_SAFENAME) $5)
    $1_$2_DEV_TARGETS   += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    # The packageconfig file comes from the target prefix.  Make sure references to prefix in that file point to the absolute install prefix for dependent builds.
    $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG)): $($1_TARGETFS_PKGCONFIG)/%: $($1_TARGETFS_PREFIX)/lib/pkgconfig/%
	mkdir -p $$(@D)
	perl -pe 's,prefix=/?$$$$,prefix=$($1_TARGETFS_PREFIX),' $$< > $$@
  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = software version
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_Stage

    $1_$2_STAGE         := $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/stage

    # How to install files if we ARE staging:     install to a build-specific staging directory ONCE (even if called by multiple targetfs), and create a single ".staged" sentinel
    $(call TargetFS_Make_Install,$1,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3,$(if $(filter BUILDINSRC,$4),,-build),.staged,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/stage,$(call TargetFS_Package_Installables,$5,$2,$4) $($2_PKGCONFIG),$4)

    # Next, copy from the staging directory into the target prefix
    $(call TargetFS_Install_From_Stage,$1,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/stage,$($1_TARGETFS_PREFIX),$5,$(call TargetFS_Package_Installables,$5,$2,$4),$(call $2_BUILD_ENVIRONMENT,$1,$4))

    # Add to the lists of targets the path of EACH installable file
    $1_TARGETFS_TARGETS += $(patsubst %,$($1_TARGETFS_PREFIX)/%,$(call TargetFS_Package_Installables,$5,$2,$4))
    $1_$2_TARGETS       += $(patsubst %,$($1_TARGETFS_PREFIX)/%,$(call TargetFS_Package_Installables,$5,$2,$4))

    $1_$2:                 $(patsubst %,$($1_TARGETFS_PREFIX)/%,$(call TargetFS_Package_Installables,$5,$2,$4))

    # run the appropriate readelf on each file in the installables, and if any report dynamic libs that aren't in the _RUNTIME_DEPENDENCIES list, print them out.
    $(patsubst %,$($1_TARGETFS_PREFIX)/%-check-runtime-dependencies,$(call TargetFS_Package_Installables,$5,$2,$4)): %-check-runtime-dependencies:
	@$($1_TARGETFS_BUILD_ENV) $($1_TARGETFS_TUPLE)-readelf --dynamic $$* 2>/dev/null | perl -ne 'if (/NEEDED.+\[([^\.]+)/) { if (! grep ($$$$1, qw($($2_RUNTIME_DEPENDENCIES)))) { print "$2:  $$$$1\n"}} '

    check-runtime-dependencies: $(patsubst %,$($1_TARGETFS_PREFIX)/%-check-runtime-dependencies,$(call TargetFS_Package_Installables,$5,$2,$4))

    # Add to the lists of targets the pkgconfig file
    $1_TARGETFS_TARGETS += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))
    $1_$2_TARGETS       += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    $1_$2:                 $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    # For doing software development based on this package, we don't need to install into the targetfs prefix.  We only need the .staged file and the .pc file.
    $1_$2_DEV_TARGETS   += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3$(if $(filter BUILDINSRC,$4),,-build)/.staged
    $1_$2_DEV_TARGETS   += $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG))

    # The packageconfig file comes from the staging directory.  Make sure references to prefix in that file point back to the staging directory for dependent builds.
    $(patsubst lib/pkgconfig/%,$($1_TARGETFS_PKGCONFIG)/%,$($2_PKGCONFIG)): $($1_TARGETFS_PKGCONFIG)/%: $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/stage/lib/pkgconfig/%
	mkdir -p $$(@D)
	perl -pe 's,prefix=/?$$$$,prefix=$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/stage,' $$< > $$@

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = staging root
  # $4 = target root
  # $5 = install tags
  # $6 = list of target paths (RELATIVE to $1)
  # $7 = optional environment
  define TargetFS_Install_From_Stage

    $(patsubst %,$4/%,$6): $4/%: $3/%
	@echo CrossPlex installing $$(<F) from $$(<D) to $$(@D)
	$$(call Cpio_DupOne,$$(<D),$$(<F),$$(@D))
	$(if $(filter STRIP,$5 $($1_TARGETFS_DEFAULT_INSTALL_TAGS)),if [ -f $$@ -a ! -h $$@ ] ; then $(if $7,$7,$($1_TARGETFS_BUILD_ENV)) $($1_TARGETFS_TUPLE)-strip $$@ -o $$@.stripped || echo WARNING CANT STRIP $$@; if [ -f $$@.stripped ] ; then mv -f $$@.stripped $$@ ; fi ; fi)
	-file $$@
	$(if $(filter LDD,$5 $($1_TARGETFS_DEFAULT_INSTALL_TAGS)),if [ -f $$@ -a ! -h $$@ ] ; then $(if $7,$7,$($1_TARGETFS_BUILD_ENV)) ldd $$@ || echo WARNING CANT LDD $$@; fi)

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = software version
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_Install_Autoconf_One

    $1_$2_TargetFS_Install_Autoconf_One := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6

    $(if $($2_LICENSE),,$(error must specify license for $2))
    $(if $3,,$(error must specify software version for $2))

    $(call TargetFS_Prep_Source,$1,$2,$3,$($1_TARGETFS_WORK),$(call TargetFS_Build_Dir,$1,$3 $4 $6),$6,$(call TagVal,SRC_PLUGIN,$4))

    $(call TargetFS_Build_Autoconf,$1,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 $6)/$3,$(if $(filter BUILDINSRC,$4),,-build),$(call $2_PRE_CONFIGURE_STEPS,$1,$2,$3,$4,$5,$6),$(filter AUTORECONF,$4),$(call $2_CONFIGURE_ARGS,$1,$2,$3,$4,$5,$6),$4,$3)

    $(if $(filter NOSTAGE,$4),$(call TargetFS_NoStage,$1,$2,$3,$4,$5,$6),$(call TargetFS_Stage,$1,$2,$3,$4,$5,$6))

    $$($1_$2_TARGETS): $(patsubst %,$$($1_%_TARGETS),$($2_RUNTIME_DEPENDENCIES))

    $1_$2: $(patsubst %,$$($1_%_TARGETS),$($2_RUNTIME_DEPENDENCIES))

    $1_AUTOCONF_MODULES += $2

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = list of software versions to install
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_Install_Autoconf

    $1_$2_TargetFS_Install_Autoconf := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5

    $(foreach module,$(CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES),$(if $(filter $(module)%,$2),$(if $(filter $(module)_LICENSE,$(.VARIABLES)),$(call TargetFS_Install_Autoconf_One,$1,$(module),$(filter $(module)-%,$2),$3 $($(module)_FORCE_BUILD_TAGS),$4,$5))))

  endef

  TargetFS_Autoconf_Module = $(strip $(foreach module,$(strip $(CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES)),$(if $(filter $(module)%,$1),$(if $(filter $(module)_LICENSE,$(.VARIABLES)),$(module)))))

  TargetFS_Make_Module = $(strip $(foreach module,$(strip $(CONFIGURE_TOOLS_KNOWN_MAKE_MODULES)),$(if $(filter $(module)%,$1),$(if $(filter $(module)_LICENSE,$(.VARIABLES)),$(module)))))

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = list of software versions to install
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_Install

    $1_$2_TargetFS_Install := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5

    $(foreach module_ver,$2,\
       $(if $(call TargetFS_Autoconf_Module,$(module_ver)),\
            $(call TargetFS_Install_Autoconf_One,$1,$(call TargetFS_Autoconf_Module,$(module_ver)),$(module_ver),$3 $($(call TargetFS_Autoconf_Module,$(module_ver))_FORCE_BUILD_TAGS),$4 $($(call TargetFS_Autoconf_Module,$(module_ver))_FORCE_INSTALL_TAGS),$5),\
            $(if $(call TargetFS_Make_Module,$(module_ver)),\
              $(call TargetFS_Install_Make_One,$1,$(call TargetFS_Make_Module,$(module_ver)),$(module_ver),$3 $($(call TargetFS_Make_Module,$(module_ver))_FORCE_BUILD_TAGS),$4 $($(call TargetFS_Make_Module,$(module_ver))_FORCE_INSTALL_TAGS),$5))))

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = software module name (eg "syslinux")
  # $3 = software version
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_Install_Make_One

    # TargetFS_Install_Make_One (1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6)

    $1_$2_TargetFS_Install_Make_One += (1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6)

    $(if $($2_LICENSE),,$(error must specify license for $2))
    $(if $3,,$(error must specify software version for $2))

    $(call TargetFS_Prep_Source,$1,$2,$3,$($1_TARGETFS_WORK),$(call TargetFS_Build_Dir,$1,$3 $4 NOCONFIGURE BUILDINSRC $6),$6,$(call TagVal,SRC_PLUGIN,$4))

    $(call TargetFS_Build_Autoconf,$1,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$3 $4 NOCONFIGURE BUILDINSRC $6)/$3,,$(call $2_PRE_CONFIGURE_STEPS,$1,$2,$3,$4 NOCONFIGURE BUILDINSRC,$5,$6),,$(call $2_CONFIGURE_ARGS,$1,$2,$3,$4 NOCONFIGURE BUILDINSRC,$5,$6),$4 NOCONFIGURE BUILDINSRC NOCONFIGURE BUILDINSRC,$3)

    $(if $(filter NOSTAGE,$4),$(call TargetFS_NoStage,$1,$2,$3,$4 NOCONFIGURE BUILDINSRC,$5,$6),$(call TargetFS_Stage,$1,$2,$3,$4 NOCONFIGURE BUILDINSRC,$5,$6))

    $$($1_$2_TARGETS): $(patsubst %,$$($1_%_TARGETS),$($2_RUNTIME_DEPENDENCIES))

    $1_$2: $(patsubst %,$$($1_%_TARGETS),$($2_RUNTIME_DEPENDENCIES))

    $1_MAKE_MODULES += $2

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  # $2 = list of software versions to install
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_Install_Make

    # TargetFS_Install_Make (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)

    $(foreach module,$(CONFIGURE_TOOLS_KNOWN_MAKE_MODULES),$(if $(filter $(module)%,$2),$(if $(filter $(module)_LICENSE,$(.VARIABLES)),$(call TargetFS_Install_Make_One,$1,$(module),$(filter $(module)-%,$2),$3 $($(module)_FORCE_BUILD_TAGS),$4 $($(module)_FORCE_INSTALL_TAGS),$5))))

  endef

  TargetFS_LINUX_ARCHMAP_x86    := i686-%
  TargetFS_LINUX_ARCHMAP_mips   := mips%

  TargetFS_Linux_Arch = $(sort $(foreach arch,$(patsubst TargetFS_LINUX_ARCHMAP_%,%,$(filter TargetFS_LINUX_ARCHMAP%,$(.VARIABLES))),$(if $(filter $(TargetFS_LINUX_ARCHMAP_$(arch)),$1),$(arch))))

  # $1 = targetfs name
  # $2 = linux kernel version
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_Install_Kernel_Headers

    # TargetFS_Install_Kernel_Headers (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)
    $(if $2,,$(error must specify software version for linux_headers))

    $(call Linux_Rules,$1-linux-headers,$2,$($1_TARGETFS_WORK),$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3),,,,$($1_TARGETFS_BUILD_PATH),$5)

    # targets defined in Linux_Rules
    $($1_TARGETFS_WORK)/$1-linux-headers/.headers-installed-$($1_TARGETFS_SAFENAME): $($1_TARGETFS_WORK)/$2-sanitized-headers/.installed

    $($1_TARGETFS_WORK)/$1-linux-headers/.headers-installed-$($1_TARGETFS_SAFENAME):
	mkdir -p $$(@D)
	touch $$(@D)/.headers-installed-$($1_TARGETFS_SAFENAME)-in-progress
	$(call Cpio_Findup,$($1_TARGETFS_WORK)/$2-sanitized-headers,$($1_TARGETFS_PREFIX))
	mv $$(@D)/.headers-installed-$($1_TARGETFS_SAFENAME)-in-progress $$@

    $1_linux_headers: $($1_TARGETFS_WORK)/$1-linux-headers/.headers-installed-$($1_TARGETFS_SAFENAME)

    $1_TARGETFS_TARGETS += $($1_TARGETFS_WORK)/$1-linux-headers/.headers-installed-$($1_TARGETFS_SAFENAME)

  endef

  # $1 = targetfs name
  # $2 = linux kernel version
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_initramfs_Kernel

    # TargetFS_Install_Kernel_Headers (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)
    $(if $2,,$(error must specify software version for linux_headers))

    $(sort $(dir $(call Complete_Targetfs_Target_List,$1))): $(call Complete_Targetfs_Target_List,$1)

    $(call Linux_Rules,$1-linux,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1),$($1_TARGETFS_TUPLE),$(call Targetfs_Prefix_Of,$1),,$(call Complete_Targetfs_Target_List,$1) | $(sort $(dir $(call Complete_Targetfs_Target_List,$1))),$($1_TARGETFS_BUILD_PATH),$5,$($1_TARGETFS_TOOLCHAIN_TARGETS))

    $1_initramfs-linux-prepare_DEV_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1)/$2-build/scripts/kallsyms

  endef


  # $1 = targetfs name
  # $2 = linux kernel version
  define TargetFS_initramfs_Kernel_DEVTARGETS

    $1_initramfs-linux-prepare_DEV_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1)/$2-build/scripts/kallsyms

  endef


  # $1 = targetfs name
  # $2 = linux kernel version
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_nfsroot_Kernel

    # TargetFS_Install_Kernel_Headers (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)
    $(if $2,,$(error must specify software version for linux_headers))

    $(call Linux_Rules,$1-linux,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1),$($1_TARGETFS_TUPLE),,,,$($1_TARGETFS_BUILD_PATH),$5,$($1_TARGETFS_TOOLCHAIN_TARGETS))

    $1_nfsroot-linux-prepare_DEV_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1)/$2-build/scripts/kallsyms

  endef

  # $1 = targetfs name
  # $2 = linux kernel version
  define TargetFS_nfsroot_Kernel_DEVTARGETS

    $1_nfsroot-linux-prepare_DEV_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $1)/$2-build/scripts/kallsyms

  endef


  # $1 = targetfs name
  # $2 = linux kernel version
  # $3 = list of build tags
  # $4 = list of install tags
  # $5 = list of patch tags
  define TargetFS_Install_Kernel_Headers_Orig

    # TargetFS_Install_Kernel_Headers_Orig (1=$1, 2=$2, 3=$3, 4=$4, 5=$5)

    $1_linux_headers_TargetFS_Install_Autoconf_One := 1=$1 , 2=$2 , 3=$3 , 4=$4 , 5=$5 , 6=$6

    $(if $(linux_headers_LICENSE),,$(error must specify license for linux_headers))
    $(if $2,,$(error must specify software version for linux_headers))

    $(call TargetFS_Prep_Source,$1,linux_headers,$2,$($1_TARGETFS_WORK),$(call TargetFS_Build_Dir,$1,$2 $3 $5),$5,$(call TagVal,SRC_PLUGIN,$3))

    $(if $($($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)_STAGE_SENTINEL_TARGET),,

      $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-staged: $$($($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2_SOURCE_PREPARED)
	mkdir -p $$(@D)
	touch $$(@D)/.staging-headers
	cp $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2/.config-build $$(@D)/.config
	+ yes "" | PATH=$(PATH) $(MAKE) V=1 O=$$(@D) -C $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2 ARCH=$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) CROSS_COMPILE=$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)- CC=$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)-gcc oldconfig
	+$(if $(linux_headers_BUILD_ENVIRONMENT),$(call linux_headers_BUILD_ENVIRONMENT,$1,$3),$($1_TARGETFS_BUILD_ENV)) $(MAKE) V=1 O=$$(@D) -C $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2 ARCH=$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) include/asm include/linux/version.h
	mkdir -p $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include
ifeq ($2,linux-2.6.12)
	+$(if $(linux_headers_BUILD_ENVIRONMENT),$(call linux_headers_BUILD_ENVIRONMENT,$1,$3),$($1_TARGETFS_BUILD_ENV)) $(MAKE) V=1 O=$$(@D) -C $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2 ARCH=$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) include/linux/autoconf.h
	cp -rf $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2/include/asm-generic $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include
	cp -rf $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2/include/linux $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include
	cp -f $$(@D)/include/linux/* $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include/linux
	cp -rf $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2/include/asm-$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include
	cd $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr/include && ln -s asm-$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) asm
else
	+ $(if $(linux_headers_BUILD_ENVIRONMENT),$(call linux_headers_BUILD_ENVIRONMENT,$1,$3),$($1_TARGETFS_BUILD_ENV)) $(MAKE) V=1 -C $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2 ARCH=$(call TargetFS_Linux_Arch,$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)) CROSS_COMPILE=$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)- CC=$(call TagCond,TARGET=%,%,$($1_TARGETFS_TUPLE),$3)-gcc INSTALL_HDR_PATH=$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging/usr headers_install
endif
	mv $$(@D)/.staging-headers $$@

      $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)_STAGE_SENTINEL_TARGET := $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-staged

    )

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-installed-$($1_TARGETFS_SAFENAME): $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-staged
	touch $$(@D)/.headers-installed-$($1_TARGETFS_SAFENAME)-in-progress
	$(call Cpio_Findup,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/staging,$($1_TARGETFS_PREFIX))
	mv $$(@D)/.headers-installed-$($1_TARGETFS_SAFENAME)-in-progress $$@

    $1_linux_headers: $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-installed-$($1_TARGETFS_SAFENAME)

    $1_TARGETFS_TARGETS += $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$2 $3 $5)/$2$(if $(filter BUILDINSRC,$3),,-build)/.headers-installed-$($1_TARGETFS_SAFENAME)

  endef

  # $1 = source-file
  # $2 = object-file
  # $3 = depend-file
  # $4 = gcc executable
  # $5 = all compile flags
  define TargetFS_Make_Depend
    $4 -MM -MF $3 -MP -MT $2 $5 $1
  endef

  # $1 = targetfs name
  # $2 = path to local code
  # $3 = list of modules to install
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_Install_Local_Library

    $(if $(INCLUDED_LOCAL_$2_MAKEFILE),,
        $(eval include $2/Makefile)
        INCLUDED_LOCAL_$2_MAKEFILE := yes
     )

    $(foreach libname,$3,
      $(if $(filter $(libname),$(CONFIGURE_TOOLS_KNOWN_LOCAL_LIBS)),

        $(foreach libobject,$($(libname)_OBJECTS),

    -include $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/$(patsubst %.o,%.d,$(libobject))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/$(libobject): $($1_TARGETFS_TOOLCHAIN_TARGETS)

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/$(libobject): $(patsubst %,$$($1_%_TARGETS),$($(libname)_BUILD_DEPENDENCIES))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/$(libobject): $($(libname)_$(libobject)_SOURCE)
	mkdir -p $$(@D)
	PATH=$($1_TARGETFS_BUILD_PATH) $(call TargetFS_Make_Depend,$$<,$$@,$$(subst .o,.d,$$@),$($1_TARGETFS_TUPLE)-$($(libname)_$(libobject)_COMPILE),$(call $(libname)_$(libobject)_FLAGS,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4),$4))
	PATH=$($1_TARGETFS_BUILD_PATH) $($1_TARGETFS_TUPLE)-$($(libname)_$(libobject)_COMPILE) $(call $(libname)_$(libobject)_FLAGS,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4),$4) -c $$< -o $$@

         )

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/lib$(libname)-$($(libname)_VERSION).so: $(patsubst %,$$($1_%_TARGETS),$($(libname)_RUNTIME_DEPENDENCIES))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/lib$(libname)-$($(libname)_VERSION).so: $(patsubst %,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/%,$($(libname)_OBJECTS))
	PATH=$($1_TARGETFS_BUILD_PATH) $($1_TARGETFS_TUPLE)-$($(libname)_LINK) -L$($1_TARGETFS_PREFIX)/lib $($(libname)_LDFLAGS) $(patsubst %,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/%,$($(libname)_OBJECTS)) -o $$@

    $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so: $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)/lib$(libname)-$($(libname)_VERSION).so
	mkdir -p $$(@D)
	cp $$< $$@

    $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname).so: $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so
	mkdir -p $$(@D)
	cd $$(@D); ln -sf $$(<F) $$@

    $1_TARGETFS_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so
    $1_TARGETFS_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname).so

    $1_$2_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so
    $1_$2_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname).so

    $1_$(libname)_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so
    $1_$(libname)_TARGETS += $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname).so

    $1_$(libname)-work-clean:
	rm -rf $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(libname) $4)

    $1_$(libname)-libs-clean:
	rm -rf $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname)-$($(libname)_VERSION).so
	rm -rf $($1_TARGETFS_PREFIX)/$($(libname)_INSTALL_PATH)/lib$(libname).so

    $(libname)-clean: $1_$(libname)-work-clean $1_$(libname)-libs-clean

        $(foreach installtag,$5,
           $(call TargetFS_Template,$1,$($(libname)_CONFIG_PATH)/$(installtag))

           $1_$2_TARGETS += $$($1_$($(libname)_CONFIG_PATH)/$(installtag)_TARGETS)
           $1_$(libname)_TARGETS += $$($1_$($(libname)_CONFIG_PATH)/$(installtag)_TARGETS)

    $1_$(libname)-$(installtag)-config-clean:
	rm -rf $$($1_$($(libname)_CONFIG_PATH)/$(installtag)_TARGETS)

    $(libname)-clean: $1_$(libname)-$(installtag)-config-clean

         )

       )
     )

  endef

  # $1 = targetfs name
  # $2 = path to local code
  # $3 = list of modules to install
  # $4 = list of build tags
  # $5 = list of install tags
  # $6 = list of patch tags
  define TargetFS_Install_Local_Program

    $(if $(INCLUDED_LOCAL_$2_MAKEFILE),,
        $(eval include $2/Makefile)
        INCLUDED_LOCAL_$2_MAKEFILE := yes
     )

    $(foreach progname,$3,
      $(if $(filter $(progname),$(CONFIGURE_TOOLS_KNOWN_LOCAL_PROGS)),

        $(foreach progobject,$($(progname)_OBJECTS),

    -include $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(patsubst %.o,%.d,$(progobject))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progobject): $($1_TARGETFS_TOOLCHAIN_TARGETS)

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progobject): $(patsubst %,$$($1_%_TARGETS),$($(progname)_BUILD_DEPENDENCIES))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progobject): $($(progname)_$(progobject)_SOURCE)
	mkdir -p $$(@D)
	PATH=$($1_TARGETFS_BUILD_PATH) $(call TargetFS_Make_Depend,$$<,$$@,$$(subst .o,.d,$$@),$($1_TARGETFS_TUPLE)-$($(progname)_$(progobject)_COMPILE),$(call $(progname)_$(progobject)_FLAGS,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4),$4))
	PATH=$($1_TARGETFS_BUILD_PATH) $($1_TARGETFS_TUPLE)-$($(progname)_$(progobject)_COMPILE) $(call $(progname)_$(progobject)_FLAGS,$2,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4),$4) -c $$< -o $$@

         )

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progname): $(foreach runtime_dep,$($(progname)_RUNTIME_DEPENDENCIES),$$(or $(patsubst %,$$($1_%_TARGETS),$(runtime_dep)),$(patsubst %,$($1_TARGETFS_PREFIX)/%,$(runtime_dep))))

    $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progname): $(patsubst %,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/%,$($(progname)_OBJECTS))
	PATH=$($1_TARGETFS_BUILD_PATH) $($1_TARGETFS_TUPLE)-$($(progname)_LINK) -L$($1_TARGETFS_PREFIX)/lib $($(progname)_LDFLAGS) $(patsubst %,$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/%,$($(progname)_OBJECTS)) -o $$@

    $($1_TARGETFS_PREFIX)/$($(progname)_INSTALL_PATH)/$(progname): $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)/$(progname)
	mkdir -p $$(@D)
	cp $$< $$@

    $1_TARGETFS_TARGETS += $($1_TARGETFS_PREFIX)/$($(progname)_INSTALL_PATH)/$(progname)

    $1_$2_TARGETS += $($1_TARGETFS_PREFIX)/$($(progname)_INSTALL_PATH)/$(progname)

    $1_$(progname)_TARGETS += $($1_TARGETFS_PREFIX)/$($(progname)_INSTALL_PATH)/$(progname)

    $1_$(progname)-work-clean:
	rm -rf $($1_TARGETFS_PREFIX)/$($(progname)_INSTALL_PATH)/$(progname)

    $1_$(progname)-prog-clean:
	rm -rf $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$1,$(progname) $4)

    $(progname)-clean: $1_$(progname)-work-clean $1_$(progname)-prog-clean

        $(foreach installtag,$5,
           $(call TargetFS_Template,$1,$($(progname)_CONFIG_PATH)/$(installtag))

           $1_$2_TARGETS += $$($1_$($(progname)_CONFIG_PATH)/$(installtag)_TARGETS)
           $1_$(progname)_TARGETS += $$($1_$($(progname)_CONFIG_PATH)/$(installtag)_TARGETS)

    $1_$(progname)-$(installtag)-config-clean:
	rm -rf $$($1_$($(progname)_CONFIG_PATH)/$(installtag)_TARGETS)

    $(progname)-clean: $1_$(progname)-$(installtag)-config-clean

         )

       )
     )

  endef

  # $1 = source targetfs name
  # $2 = new targetfs directory
  # $3 = path to fix-embedded-paths
  define Install_TargetFS_Fixpaths

    $2/.cpinstall-$($1_TARGETFS_SAFENAME)-fixedpaths: $($1_TARGETFS_TARGETS)
	mkdir -p $2
	# Install the Additional Tools
	# copy $($1_TARGETFS_PREFIX) to $2
	(cd $($1_TARGETFS_PREFIX); tar cf - .) | (cd $2; tar xvf -)
	# replace any strings that point to $($1_TARGETFS_PREFIX) to a temporary string
	-$3 $($1_TARGETFS_PREFIX) /temp-prefix $2
	# replace any strings that point to $(dir $($1_TARGETFS_PREFIX)) (now no longer including $(notdir $($1_TARGETFS_PREFIX))) to a bogus string
	-$3 $(dir $($1_TARGETFS_PREFIX)) /useless-prefix/ $2
	# replace any strings that point to /temp-prefix (what was originally pointing to $(file $($1_TARGETFS_PREFIX))) to the actual path $2
	-$3 /temp-prefix $2 $2 $(call strlen,$($1_TARGETFS_PREFIX))

    $2_TARGETS += $2/.cpinstall-$($1_TARGETFS_SAFENAME)-fixedpaths

  endef

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  Complete_Targetfs_Target_List = $($1_TARGETFS_TARGETS)

  # $1 = targetfs name (eg "daves_favorite_targetfs")
  Targetfs_Prefix_Of = $($1_TARGETFS_PREFIX)

endif
