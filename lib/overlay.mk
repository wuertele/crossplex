# -*- makefile -*-		Target Filesystem Overlay Rules
# dave@crossplex.org		Mon Nov 15 15:52:43 2010
#
#
# DESIGN
#
#  The macros in this Makefile are a system for creating rules for 
#  overlays using four passes:
#     1) store all rewrite rules
#     2) enumerate all the overlay directories
#     3) create mappings from target (i.e. installed) file to source overlay file
#     4) create the rule for installing each target file from its overlay
#
#  The rationale for separating into these four passes is this:
#  First, all the real installation rules are overloaded by rewrite
#  rules, so load them into memory, then create mappings according
#  to the following steps.
#
#  A particular target file might be specified by multiple overlays.
#  Make complains if you create multiple rules for the same target.
#  We only want to create rules of the latest-specified overlay that 
#  applies to the current target.
#
#  So first eliminate all non-applicable overlays (in step 1), then
#  define the mapping for each target, overwriting old mappings as new
#  ones are specified, finally declare the rule for creating each file
#  based on its newest mapping.
# 


# PURPOSE:    Data-driven initializer for root filesystem staging areas
#
# DESIGN GOALS:
#
# 	1.  Support easy configuration of new filesystem staging areas
# 	    or new platforms
#
# 	2.  Make day-to-day maintenance of the configuration as simple
# 	    as possible:  easy to find and edit existing files, easy
# 	    to add or remove files
#
# 	3.  Make addition of new platforms as easy as possible
#
# 	4.  Make addition of new filesystems as easy as possible
#
# 	5.  Make addition of new filesystem slices as easy as possible
#
# 	6.  Eliminate redundant logic or data
#
# 	7.  Maximize robustness of logic so that changes to the data
# 	    do not break the build
#
# 	8.  Support robust rebuilding: the same make command twice
# 	    should only build the output the first time.  If make does
# 	    not complete the first time, the next time it is run it
# 	    will not try to build any files that were successfully
# 	    built on previous passes.
#
# 	9.  Support correct cleaning: "make clean" removes all files
# 	    installed by "make", and it removes ONLY those files.
#
# 	10. Support parallel make: "make -jN" results in the same
# 	    output as "make -j1" for any target and for any value of N
#
#
# STATUS:
#
# 	All design goals are fully supported by the current
# 	implementation except for the following caveat(s):
#
# 	1.  If one of the Overlays contains a symlink to a file that
# 	    exists on the host outside of the vobs, that file's
# 	    modification time could cause the build to create the
# 	    target filesystem's symlink from scratch even if it
# 	    already existed and was correct.  This does not result in
# 	    corruption, but it does break the "robust rebuilding" goal.
# 	    If this is a problem, the workaround is to remove the
# 	    symlink from the Overlay and instead make a call in the
# 	    appropriate dynamic-rewrite.mk file to the
# 	    Target_Local_Symlink macro.
#
#
# IMPLEMENTATION CONCEPTS:
#
# The implementation relies on the following concepts.
#
# Install Root:   INSTALL_ROOTS is a list of paths, defined in
# 		build-config.mk, at which staging directories are to
# 		be created.  The list of Install Roots can be
# 		hardcoded, or it can be derived based on the platform
# 		name or any other variables.  For example, if a
# 		platform needs two copies of the output root, one
# 		stripped and one not, and a staging directory for
# 		initramfs, you might define INSTALL_ROOTS to include
# 		the following paths:
#
# 		/mybuild/PLATFORMNAME/unstripped-rootfs
# 		/mybuild/PLATFORMNAME/stripped-rootfs
# 		/mybuild/PLATFORMNAME/initramfs-stage
#
# 		Note that the overlay logic does not interpret the
# 		names in any way.  They are simply paths that are used
# 		as the root for essentially identical copies of the
# 		target configuration.
#
# Root Slice:	Root Slices are associated with an Install Root.  For
# 		the convenience of the developer, all paths in the
# 		Overlays are interpreted relative to the root ("/") of 
# 		the target userspace filesystem.  However, in some
# 		cases not all the files in an Overlay should be
# 		installed relative to the same path.  For exmaple, in
# 		One embedded system the /opt directory is deployed separately
# 		from the rest of the target filesystem, and no files should
# 		be installed under opt in the initramfs staging
# 		directory.  In the build-config.mk file, the developer
# 		can specify a Root Slice associated with
# 		initramfs-stage that separates out the opt directory
# 		to a sister path not under initramfs-stage:
#
# 		/mybuild/PLATFORMNAME/initramfs-stage_ROOTSLICE_PATH_opt := /mybuild/PLATFORMNAME/optfs-stage
#
# 		So given our three example INSTALL roots and our
# 		example ROOTSLICE_PATH, file in an Overlay with these
# 		paths:
#
# 		/path/to/my/overlay/file1
# 		/path/to/my/overlay/opt/file2
# 		/path/to/my/overlay/opt/file3
# 		/path/to/my/overlay/etc/file4
#
# 		would be installed on the Install Roots in these paths:
#
# 		/mybuild/PLATFORMNAME/unstripped-rootfs/file1
# 		/mybuild/PLATFORMNAME/unstripped-rootfs/opt/file2
# 		/mybuild/PLATFORMNAME/unstripped-rootfs/opt/file3
# 		/mybuild/PLATFORMNAME/unstripped-rootfs/etc/file4
# 		/mybuild/PLATFORMNAME/stripped-rootfs/file1
# 		/mybuild/PLATFORMNAME/stripped-rootfs/opt/file2
# 		/mybuild/PLATFORMNAME/stripped-rootfs/opt/file3
# 		/mybuild/PLATFORMNAME/stripped-rootfs/etc/file4
# 		/mybuild/PLATFORMNAME/initramfs-stage/file1
# 		/mybuild/PLATFORMNAME/initramfs-stage/etc/file3
# 		/mybuild/PLATFORMNAME/optfs-stage/file2
# 		/mybuild/PLATFORMNAME/optfs-stage/file3
#
# 		As you can see, it is only the initramfs-stage that
# 		gets split because it is the only one matching a
# 		%_ROOTSLICE_PATH_% variable.
#
# 		Note that rootslices are only interpreted by the
# 		macros that define rules, which is the second stage of
# 		overlay installation.  The first stage
# 		only sets up mappings, and
# 		these mappings will refer to UNSLICED paths.  Those
# 		mappings are converted to SLICED paths by the macros
# 		Overlay_Install, Target_Local_Symlink, and
# 		Install_Toolchain_Lib.
#
# Overlay:	Each Install Root is generated from a set of Overlays.
# 		An Overlay consists of a single checked-in directory,
# 		under which there are checked-in files,
# 		subdirectories, and links.  If an Overlay is applied
# 		to an Install Root, those files, subdirectories, and
# 		links are copied into the Install Root path.  Some of
# 		those objects may be rewritten by rewrite rules (see
# 		Rewrite Rules) below.  Overlays are checked in as
# 		subdirectories of an Overlay Group (see below).
# 		Overlays applied later in the build can override
# 		Overlays applied earlier in the build.  In that case,
# 		the object to be installed from the earlier Overlay is
# 		not installed, only the object from the later Overlay
# 		is installed.
#
# Overlay Group:  An Overlay Group is a directory of Overlays.  If an
# 		Overlay Group is selected for a build, every Overlay
# 		in that Overlay Group will be applied to the targetfs.
# 		If an Overlay Group contains a dynamic-rewrite.mk
# 		file, it will be interpreted by the overlay logic in
# 		the context of the current Install Root.
#
# Overlay Map:	The Overlay Map is a large set of variables,
# 		defined by the macro Overlay_Group, for the
# 		purpose of mapping target files to source files.  The
# 		mapping is a necessary first step before creating
# 		rules because all overlays specified later in the
# 		configuration need to be able to overload previous
# 		overlays before the target rules are actually
# 		defined.  The macro Overlay_Install interprets
# 		the Overlay Map in the context of any Root Slices in
# 		order to generate the actual rules.


# Call for sub-makes to create rewrite rules.  Look in subdirs for "dynamic-rewrite.mk" for these calls.
# $1 = name of overlay (relative to dynamic-rewrite.mk file)
# $2 = path of source file (or link to source file) to be rewritten, relative to root of overlay
# $3 = rewrite script taking two arguments ($1 is the source path of the rewrite, $2 is the target path)
define Overlay_Rewrite_Rule
$(if $(shell readlink -e $(dir $(lastword $(MAKEFILE_LIST)))/$1/$2),\
       $(eval OVERLAY_REWRITE_RULE_$(shell readlink -e $(dir $(lastword $(MAKEFILE_LIST)))/$1/$2) = $3))
endef

# $1 = relative path of node in targetfs
# $2 = node type
# $3 = node major number
# $4 = node minor number
# $(install_root) is a local variable that must be defined before this macro is called
define Make_Device_Node
   $(eval OVERLAY_MKNOD_RULE_$(install_root)/$1 = sudo /bin/mknod $$$$@ $2 $3 $4)\
   $(eval $(install_root)_OVERLAY_TARGETS += $(install_root)/$1)
endef

# Sometimes you must create a symlink in the targetfs that points to a path that should not exist on the host.
# If that symlink is used as a dependency anywhere, make will try to figure out how to create the thing it points to.
# Since on the build host, you can't create the path the symlink points to, you can't give make a rule for how to create it.
# Make will then complain that it doesn't know how to make the thing the symlink points to.
# Therefore, to create an arbitrary symlink without confusing make we have to generate a rule that does not include
# the symlink as a dependency.  But if we don't include the symlink as a dependency, it will always get created or never get created.
# Never getting created is a problem because you need the symlink on the target.  Always getting created is a problem
# because you want make to only rebuild things that need rebuilding.
# The workaround here is to make all symlinks a side-effect of a rule for creating a sentinel file.
# $1 = relative path of symlink directory
# $2 = name of symlink
# $3 = path (relative to $1 or an absolute path relative to the target root) to which symlink links
# $(install_root) is a local variable that must be defined before this macro is called
define Target_Local_Symlink
   $(eval OVERLAY_SIDE_EFFECT_RULE_$(dir $(install_root))/.$(notdir $(install_root))-symlink_sentinel += && mkdir -p $(call Rootsliced_Target,$(install_root),$(install_root)/$1) && cd $(call Rootsliced_Target,$(install_root),$(install_root)/$1) && rm -f $2 && ln -sf $3 $2)\
   $(eval OVERLAY_SIDE_EFFECT_CLEAN_$(dir $(install_root))/.$(notdir $(install_root))-symlink_sentinel += && rm -f $(call Rootsliced_Target,$(install_root),$(install_root)/$1/$2))\
   $(eval $(install_root)_OVERLAY_TARGETS += $(dir $(install_root))/.$(notdir $(install_root))-symlink_sentinel)\
   $(eval .PHONY: $(dir $(install_root)))
endef

# Find all directories that are immediate children of path $1
# "readlink -f" is for the purpose of canonicalizing paths (for symmetry with part 2 of this macro)
Find_Dirs_In = $(shell find $1 -mindepth 1 -maxdepth 1 -type d | xargs --no-run-if-empty -n 1 readlink -f)
# Find all links that are immediate children of path $1 which canonicalize to directories
# "file -L", "grep directory", and "cut" prints only paths that canonicalize to directories
Find_Dirs_In += $(shell find $1 -mindepth 1 -maxdepth 1 -type l | xargs --no-run-if-empty -n 1 readlink -f | xargs --no-run-if-empty -n 1 file -L | grep directory | cut -f1 -d:)

# Find all files, links, or dirs under a given path
Find_All_Files_Under = $(shell if [ -d $1 ]; then find $1 -mindepth 1 -type f; fi)
Find_All_Links_Under = $(shell if [ -d $1 ]; then find $1 -mindepth 1 -type l; fi)
Find_All_Dirs_Under  = $(shell if [ -d $1 ]; then find $1 -mindepth 1 -type d; fi)

# This macro is called by Overlay_Map, once for each type of file (FILE, LINK, or DIR).
# $1 = path to root of target filesystem into which this overlay will be installed
# $2 = path to overlay directory
# $3 = file type ("FILE", "LINK", or "DIR")
# $4 = list of source paths with this type
define Overlay_Map_Core
    # This accumulates all targets from all calls to Overlay_Map to present
    $(eval $1_OVERLAY_TARGETS := $(sort $($1_OVERLAY_TARGETS) $(patsubst $2/%,$1/%,$4)))

    # Keep track of sources that were specified but not used because they were replaced
    $(foreach target,$(sort $(patsubst $2/%,$1/%,$4)),\
               $(if $(strip $(OVERLAY_SOURCE_$(target))),\
                    $(eval UNUSED_OVERLAY_SOURCE += $(patsubst $1/%,$2/%,$(target)))))

    # Flip it and reverse it.  This is the map from target file/dir/link to source file/dir/link.
    # Remember to undefine LINK and DIR mappings if we find a FILE mapping, and vice versa.
    $(foreach source,$(sort $4),\
               $(eval OVERLAY_SOURCE_FILE_$(patsubst $2/%,$1/%,$(source)) := )\
               $(eval OVERLAY_SOURCE_DIR_$(patsubst $2/%,$1/%,$(source)) := )\
               $(eval OVERLAY_SOURCE_LINK_$(patsubst $2/%,$1/%,$(source)) := )\
               $(if $(OVERLAY_REWRITE_RULE_$(source)),\
                    $(eval OVERLAY_SOURCE_REWRITE_RULE_$(patsubst $2/%,$1/%,$(source)) := OVERLAY_REWRITE_RULE_$(source)),\
                    $(eval OVERLAY_SOURCE_$3_$(patsubst $2/%,$1/%,$(source)) := $(source)))\
               $(eval OVERLAY_SOURCE_$(patsubst $2/%,$1/%,$(source)) := $(source)))

endef

# For a given overlay directory, create a map from the installed files on the targetfs to the source
# This is intended to be called over and over, so that later calls can actually overwrite the
# map from some targetfs files to newer overlay source files.
# $1 = path to root of target filesystem into which this overlay will be installed
# $2 = path to overlay directory
define Overlay_Map
    # append this source to the list of all sources
    # could be used to debug the logic for selecting an overlay
    OVERLAY_SOURCES := $(sort $(OVERLAY_SOURCES) $2)

    $(call Overlay_Map_Core,$1,$2,FILE,$(call Find_All_Files_Under,$2))
    $(call Overlay_Map_Core,$1,$2,LINK,$(call Find_All_Links_Under,$2))
    $(call Overlay_Map_Core,$1,$2,DIR,$(call Find_All_Dirs_Under,$2))

endef

# For a given overlay group, load all the dynamic rewrite rules,
# Then create the map.
# $1 = path to root of target filesystem into which this overlay will be installed
# $2 = path to overlay group
# $(install_root) is a local variable that MUST be defined before this macro is called
define Overlay_Group

  $(eval -include $2/dynamic-rewrite.mk)
  $(foreach overlay,$(call Find_Dirs_In,$2),\
            $(eval $(call Overlay_Map,$1,$(overlay))))

endef

# Discover Rootslice paths
# If we find a variable of the form $1_ROOTSLICE_PATH_% and the path to our target file matches %,
# translate the root of our target file's path to $($1_ROOTSLICE_PATH_%)
# $1 = install root
# $2 = absolute path to target file
Rootsliced_Target = $(or $(strip $(foreach rootslice_path,$(patsubst $1_ROOTSLICE_PATH_%,%,$(filter $1_ROOTSLICE_PATH_%,$(.VARIABLES))),$(if $(filter $1/$(rootslice_path)%,$2),$(patsubst $1/$(rootslice_path)%,$($1_ROOTSLICE_PATH_$(rootslice_path))%,$2)))),$2)

# Instantiate the rules for installing rewrites / files / directories / links from the overlay sources
# to the target filesystem.  This should be called once and only once for each target argument.
# $1 = path to target file
# $2 = install root
define Overlay_Install

  $(if $(strip $(filter-out $(firstword $(OVERLAY_SOURCE_FILE_$1) $(OVERLAY_SOURCE_DIR_$1) $(OVERLAY_SOURCE_LINK_$1)),$(OVERLAY_SOURCE_FILE_$1) $(OVERLAY_SOURCE_DIR_$1) $(OVERLAY_SOURCE_LINK_$1))),
       $(warning There is more than one rule for $1)
       $(foreach sourcefile,$(OVERLAY_SOURCE_FILE_$1) $(OVERLAY_SOURCE_DIR_$1) $(OVERLAY_SOURCE_LINK_$1),$(warning $(shell file $(sourcefile))))
       $(error This indicates a bug in Overlay_Map.))

  $(if $(filter %symlink_sentinel,$1),
    $(call Rootsliced_Target,$2,$1):
	echo side effects $(OVERLAY_SIDE_EFFECT_RULE_$1)
	touch $$@

    clean_$(call Rootsliced_Target,$2,$1):
	echo removing side effects $(OVERLAY_SIDE_EFFECT_CLEAN_$1)
	rm -f $(call Rootsliced_Target,$2,$1)
   )

  $(if $(OVERLAY_SOURCE_REWRITE_RULE_$1),
    $(call Rootsliced_Target,$2,$1): $(OVERLAY_SOURCE_$1)
	# Generating $$@ from file $$< using rewrite rule
	$(call $(OVERLAY_SOURCE_REWRITE_RULE_$1),$$<,$$@)

    clean_$(call Rootsliced_Target,$2,$1):
	rm -f $(call Rootsliced_Target,$2,$1)
   )

  $(if $(OVERLAY_MKNOD_RULE_$1),
    $(call Rootsliced_Target,$2,$1):
	# Generating $$@ from file $$< using rewrite rule
	$(OVERLAY_MKNOD_RULE_$1)

    clean_$(call Rootsliced_Target,$2,$1):
	rm -f $(call Rootsliced_Target,$2,$1)
   )

  $(if $(OVERLAY_SOURCE_FILE_$1),
    $(call Rootsliced_Target,$2,$1): $(OVERLAY_SOURCE_FILE_$1)
	# copying file and its metadata from $$< to $$@
	rm -f $$@
	cp -a $$< $$@
	# touch the file since the source filesystem might have a different timebase
	touch $$@

    clean_$(call Rootsliced_Target,$2,$1):
	rm -f $(call Rootsliced_Target,$2,$1)
   )

  $(if $(OVERLAY_SOURCE_DIR_$1),
    $(call Rootsliced_Target,$2,$1): | $(OVERLAY_SOURCE_DIR_$1)
	# using metadata from $(OVERLAY_SOURCE_DIR_$1) to create dir $$@
	mkdir -p $$@
	chmod --reference=$(OVERLAY_SOURCE_DIR_$1) $$@

    clean_$(call Rootsliced_Target,$2,$1):
	-rmdir --ignore-fail-on-non-empty $(call Rootsliced_Target,$2,$1)
   )

  $(if $(OVERLAY_SOURCE_LINK_$1),
   $(call Rootsliced_Target,$2,$1): $(OVERLAY_SOURCE_LINK_$1)
	# copying link $$< to $$@
	if [ ! -L $$@ ]; then rm -f $$@; cp -a $$< $$@; fi

    clean_$(call Rootsliced_Target,$2,$1):
	rm -f $(call Rootsliced_Target,$2,$1)
   )

   # Don't bother to remake a file if it's directory is newer than it.
   # But link the rule for the dir to this file with "order-only",
   # so that the directory doesn't get "made" twice.
   $(call Rootsliced_Target,$2,$1): | $(dir $(call Rootsliced_Target,$2,$1))

   clean_$(dir $(call Rootsliced_Target,$2,$1)): clean_$(call Rootsliced_Target,$2,$1)

   all-overlays: $(call Rootsliced_Target,$2,$1)

   clean-overlays: clean_$(call Rootsliced_Target,$2,$1)

   clean: clean-overlays

endef


# Define a diverted root slice path
# $1 = absolute path on build host of install_root (eg "/path/to/my/installroot")
# $2 = path on target, relative to "/", to be sliced (eg "opt")
# $3 = absolute path on build host of diverted root (eg "/path/to/my/optfs-stage")
Root_Slice = $(eval $1_ROOTSLICE_PATH_$2 := $3)
