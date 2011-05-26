# -*- makefile -*-		patch.mk - how to unpack tarballs and patch them
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


ifndef Unpack_Rules

  UNPACKED_SOURCES_DIRNAME := unpacked-sources

unpack-clean:
	rm -rf $(sort $(UNPACK_CLEAN))

sourceclean: unpack-clean

clean: unpack-clean


# $1 = package version (e.g. "dropbear-0.48.1")
# $2 = package unpack PARENT dir (e.g. "dirname (/some/path/to/dropbear-0.48.1)")
# $3 = package sources dir
# $4 = archive file postfix
# $5 = unarchive shell command
# $6 = archive file list command
define General_Unpack_Rule

  $2/%/.unpacked: $3/%$4
	rm -rf $$(@D) $$(@D)-unpacking
	mkdir -p $$(@D)-unpacking
	cd $$(@D)-unpacking && $5 $$<
	$(if $6,cd $$(@D)-unpacking && $6 $$< | cut -f1 -d/ | sort -u | perl -e '@a=<>; if ($$$$#a==0){chomp $$$$a[0]; system("echo $$$$a[0] > .archivedirname");}' )
	cd `dirname $$(@D)-unpacking`; if [ -d $$(@D)-unpacking/$$(*F) ] && [ `ls $$(@D)-unpacking | wc -l` = 1 ]; then mv $$(@D)-unpacking/$$(*F) $$(@D) ; rm -rf $$(@D)-unpacking; else cd $$(@D)-unpacking; if [ -f .archivedirname ]; then mv `cat .archivedirname` $$(@D); rm -rf $$(@D)-unpacking; else mv $$(@D)-unpacking $$(@D); fi; fi
	-$(foreach rulevar,$(filter CROSSPLEX_POST_UNPACK_RULE,$(.VARIABLES)),find $$(@D) -exec $($(rulevar)) {} \;)
	-$(foreach rulevar,$(filter CROSSPLEX_POST_UNPACK_RULE_TYPE%,$(.VARIABLES)),find $$(@D) -type $(patsubst CROSSPLEX_POST_UNPACK_RULE_TYPE_%,%,$(rulevar)) -exec $($(rulevar)) {} \;)
	echo crossplexwashere > $$@

endef

# $1 = package version (e.g. "dropbear-0.48.1")
# $2 = package unpack PARENT dir (e.g. "dirname (/some/path/to/dropbear-0.48.1)")
# $3 = package sources dir
define Unpack_Rules

  # Unpack_Rules (1=$1, 2=$2, 3=$3)

  $(call General_Unpack_Rule,$1,$2,$3,.tar.gz,tar xvzf,tar tzf)
  $(call General_Unpack_Rule,$1,$2,$3,.tgz,tar xvzf,tar tzf)
  $(call General_Unpack_Rule,$1,$2,$3,.tar.bz2,tar xvjf,tar tjf)
  $(call General_Unpack_Rule,$1,$2,$3,.tbz,tar xvjf,tar tjf)
  $(call General_Unpack_Rule,$1,$2,$3,.zip,unzip)

  UNPACK_CLEAN += $2/$1

endef


# $1 = final resolved patch directory (e.g. "/find/a/bunch/of/patches/here")
# $2 = package unpack dir (e.g. "/some/path/to/unpacked-sources/dropbear-0.48.1")
# $3 = package patch dir (e.g. "/some/other/path/to/patched-sources/dropbear-0.48.1")
define Patch_Rules_Core

    # Patch_Rules_Core (1=$1, 2=$2, 3=$3)

    $(subst $(__crossplex_space),_,$1_$2_$3_UNIQUE_PATCH_RULES_CORE_ARGS) := $1 , $2 , $3
    $(subst $(__crossplex_space),_,$3_PATCH_DIRS_SEARCHED) := $$(sort $$($3_PATCH_DIRS_SEARCHED) $1)

    # Rule that actually enumerates and applies all patches found in the given directory, and copies the patch to an ".applied-*" state file
    # Note that this is just the rule for applying patches individually.  See the commands for patchorder.mk for the whole series.
    # Note^2: this checks whether the patch has already been applied, and calls make to unwind this patch and its dependents before re-applying
    $(patsubst $1/%.patch,$3/.applied-%,$(wildcard $1/*.patch)): $3/.applied-%: $1/%.patch $3/.repliduplicated
	# Check for a preexisting .applied- file, and unroll it and its dependents if necessary
	+if [ -f $$@ ] ; then $(MAKE) -f $(firstword $(MAKEFILE_LIST)) $$(@D)/.unapplied-$$(*F) ; fi
	cd $$(@D) && patch -g 0 -f -p1 < $$<
	cp -f $$< $$@
	$(if $(GIT),cd $$(@D) && $(GIT) add -f . && $(GIT) commit -q -m $$(*F))
	rm -f $$(@D)/.unapplied-$$(*F)

    # This is a system of unrolling patches.  It depends on $(dir $3)/$3-patchorder.mk properly ordering the unroll.
    # This rule is ONLY invoked when called on a single .unapplied-XYZ file, which is ONLY done in the rule defined six lines up (for $3/.applied).
    $(patsubst $1/%.patch,$3/.unapplied-%,$(wildcard $1/*.patch)): $3/.unapplied-%: $1/%.patch
	cd $$(@D) && patch --reverse -g 0 -f -p1 < $$(@D)/.applied-$$(*F)
	cp -f $$< $$@
	rm -f $$(@D)/.applied-$$(*F)

    # As long as the user is not just doing "make clean", go ahead and add the newly defined patch targets to the list of appliable patches
    ifneq "$(MAKECMDGOALS)" "clean"
      ifneq "$(MAKECMDGOALS)" "ultraclean"
        $3_PATCHES += $(if $(strip $(wildcard $1/*.patch)),$(patsubst $1/%.patch,$3/.applied-%,$(wildcard $1/*.patch)))
      endif
    endif

    # The patchorder file is out of date if any of the files found here are newer than it.
    # Note that there might be other patches found by other invocations of this macro, so this dependency is cumulative.
    $(dir $3)/$(notdir $3)-patchorder.mk: $(wildcard $1/*.patch)

    .PRECIOUS: $(dir $3)/$(notdir $3)-patchorder.mk

    # For every overlay_target, set a variable LATEST_OVERLAY_SOURCE_FOR_$(overlay_target).
    # The final value of this variable will be used in the dependency for $(overlay_target).
    # See below in Patch_Rules for where $3_OVERLAY_TARGETS and LATEST_OVERLAY_SOURCE_FOR_$(overlay_target) are used.
    $$(foreach overlay_source, \
               $(shell find $1/overlay -type f -o -type l 2>/dev/null), \
               $$(if $$(LATEST_OVERLAY_SOURCE_FOR_$$(patsubst $1/overlay/%,$3/%,$$(overlay_source))), \
                     $$(warning crossplex/patch.mk: $$(overlay_source) will override $$(LATEST_OVERLAY_SOURCE_FOR_$$(patsubst $1/overlay/%,$3/%,$$(overlay_source))) as existing rule for $$(patsubst $1/overlay/%,$3/%,$$(overlay_source))) \
                 ) \
               $$(eval $3_OVERLAY_TARGETS += $$(patsubst $1/overlay/%,$3/%,$$(overlay_source))) \
               $$(eval LATEST_OVERLAY_SOURCE_FOR_$$(patsubst $1/overlay/%,$3/%,$$(overlay_source)) := $$(overlay_source)) \
      )

endef


# $1 = package version (e.g. "dropbear-0.48.1")
# $2 = package unpack dir (e.g. "/some/path/to/unpacked-sources/dropbear-0.48.1")
# $3 = package patch dir (e.g. "/some/other/path/to/patched-sources/dropbear-0.48.1")
# $4 = patch directory (e.g. "/find/a/bunch/of/patches/here")
# $5 = list of patch subdirs to check
define Patch_Rules

  # Patch_Rules(1=$1, 2=$2, 3=$3, 4=$4, 5=$5)

  ifndef $(subst $(__crossplex_space),_,DEFINED_$3_REPLIDUPLICATED)
    $(subst $(__crossplex_space),_,DEFINED_$3_REPLIDUPLICATED) := $3
    $3/.repliduplicated: $2/.unpacked
    ifeq ($2,$3)
	cp -f $$< $$@
    else
	rm -rf $$(@D)
	$(call Cpio_Findup,$2,$3)
	$(if $(GIT),cd $$(@D) && $(GIT) init && $(GIT) add -f . && $(GIT) commit -q -m "initial commit" && $(GIT) tag $1 && $(GIT) tag base)
	touch $$@
    endif

    $3-compare/.repliduplicated: $2/.unpacked
    ifeq ($2,$3-compare)
	cp -f $$< $$@
    else
	rm -rf $$(@D)
	$(call Cpio_Findup,$2,$3-compare)
	touch $$@
    endif
  endif

  ifndef $(subst $(__crossplex_space),_,$1_$2_$3_$4_UNIQUE_PATCH_ARGS)
    $(subst $(__crossplex_space),_,$1_$2_$3_$4_UNIQUE_PATCH_ARGS) := $1 , $2 , $3 , $4 , $5

    $(subst $(__crossplex_space),_,$1_$2_$3_$4_$5_replidupliclean):
	rm -rf $3

    sourceclean: $(subst $(__crossplex_space),_,$1_$2_$3_$4_$5_replidupliclean)

    $(call Patch_Rules_Core,$4/$1,$2,$3)
    $(foreach subdir,$5,$(call Patch_Rules_Core,$4/$1/$(subdir),$2,$3))

    # For each overlay_target defined in the above calls to Patch_Rules_Core, create a rule.
    # There is a chance that another package with the exact same same patch tags coming from different
    # patch hierarchies could collide here.  In that case you will see an error
    # like "multiple rules for ..."
    $$(foreach overlay_target,$$(sort $$($3_OVERLAY_TARGETS)),\
               $$(eval $$(overlay_target): $$(LATEST_OVERLAY_SOURCE_FOR_$$(overlay_target)) $3/.repliduplicated; mkdir -p $$$$(@D); cp -f $$$$< $$$$@; ls -f $$$$@)\
      )

    # Don't remove the ".applied-*" state files even though they may be intermediates
    .PRECIOUS: $3/.applied-%

    # As long as the user is not just doing "make clean", go ahead and add the newly defined build-config targets to the list of appliable build-configs
    ifneq "$(MAKECMDGOALS)" "clean"
      ifneq "$(MAKECMDGOALS)" "ultraclean"
        $3_BUILD_CONFIGS += $(patsubst $4/$1/overlay/%,$3/%,$(shell find $4/$1/overlay -type f -o -type l 2>/dev/null))
        $(foreach subdir,$5,
          $3_BUILD_CONFIGS += $(patsubst $4/$1/$(subdir)/overlay/%,$3/%,$(shell find $4/$1/$(subdir)/overlay -type f -o -type l 2>/dev/null))
         )
      endif
    endif

    $(call Patch_Rules_Core,$4/$1,$2,$3-compare)
    $(foreach subdir,$5,$(call Patch_Rules_Core,$4/$1/$(subdir),$2,$3-compare))

    # For each overlay_target defined in the above calls to Patch_Rules_Core, create a rule.
    # There is a chance that another package with the exact same same patch tags coming from different
    # patch hierarchies could collide here.  In that case you will see an error
    # like "multiple rules for ..."
    $$(foreach overlay_target,$$(sort $$($3-compare_OVERLAY_TARGETS)),\
               $$(eval $$(overlay_target): $$(LATEST_OVERLAY_SOURCE_FOR_$$(overlay_target)) $3-compare/.repliduplicated; mkdir -p $$$$(@D); cp -f $$$$< $$$$@)\
      )

    # Don't remove the ".applied-*" state files even though they may be intermediates
    .PRECIOUS: $3-compare/.applied-%

    # As long as the user is not just doing "make clean", go ahead and add the newly defined build-config targets to the list of appliable build-configs
    ifneq "$(MAKECMDGOALS)" "clean"
      ifneq "$(MAKECMDGOALS)" "ultraclean"
        $3-compare_BUILD_CONFIGS += $(patsubst $4/$1/overlay/%,$3-compare/%,$(shell find $4/$1/overlay -type f -o -type l 2>/dev/null))
        $(foreach subdir,$5,
          $3-compare_BUILD_CONFIGS += $(patsubst $4/$1/$(subdir)/overlay/%,$3-compare/%,$(shell find $4/$1/$(subdir)/overlay -type f -o -type l 2>/dev/null))
         )
      endif
    endif

  endif

endef


# $1 = package version (e.g. "dropbear-0.48.1")
# $2 = patched package dir (e.g. "/some/path/to/dropbear-0.48.1")
# Only call this macro after Patch_Rules has been invoked on all appropriate directories, otherwise the list of patches will be incomplete.
define Patch_Order_Rules

  # Patch_Order_Rules(1=$1, 2=$2)

  ifndef $1_$2_$3_$4_UNIQUE_PATCH_ORDER_ARGS
    $1_$2_$3_$4_UNIQUE_PATCH_ORDER_ARGS := $1 , $2

    # Specify a series of patches in which each individual patch application rule depends on the alphabetically previous one having been successfully applied
    $(dir $2)/$(notdir $2)-patchorder.mk:
	mkdir -p $$(@D)
	perl -e 'foreach my $$$$index (1 .. $$$$#ARGV) { print $$$$ARGV[$$$$index], ": ", $$$$ARGV[$$$$index-1], "\n"; }' $$($2_PATCHES) > $$@
	perl -e 'foreach (@ARGV) { $$$$_ =~ s/applied-/unapplied-/; } foreach my $$$$index (1 .. $$$$#ARGV) { print $$$$ARGV[$$$$index-1], ": ", $$$$ARGV[$$$$index], "\n"; }' $$($2_PATCHES) >> $$@

    .PRECIOUS: $(dir $2)/$(notdir $2)-patchorder.mk

    $(dir $2)/$(notdir $2)-compare-patchorder.mk:
	mkdir -p $$(@D)
	perl -e 'foreach my $$$$index (1 .. $$$$#ARGV) { print $$$$ARGV[$$$$index], ": ", $$$$ARGV[$$$$index-1], "\n"; }' $$($2-compare_PATCHES) > $$@
	perl -e 'foreach (@ARGV) { $$$$_ =~ s/applied-/unapplied-/; } foreach my $$$$index (1 .. $$$$#ARGV) { print $$$$ARGV[$$$$index-1], ": ", $$$$ARGV[$$$$index], "\n"; }' $$($2-compare_PATCHES) >> $$@

    .PRECIOUS: $(dir $2)/$(notdir $2)-compare-patchorder.mk

    # As long as the user is not just doing "make clean", include the patch order rules we just defined
    ifneq "$(MAKECMDGOALS)" "clean"
      ifneq "$(MAKECMDGOALS)" "ultraclean"
        include $(dir $2)/$(notdir $2)-patchorder.mk
      endif
    endif

    # A complete preparation of a source directory includes a) unpacking it, b) applying patches, and c) copying build-configs.
    $2_SOURCE_PREPARED := $2/.repliduplicated $$($2_PATCHES) $$(sort $$($2_BUILD_CONFIGS))
    $2-source-prepared: $2/.repliduplicated $$($2_PATCHES) $$(sort $$($2_BUILD_CONFIGS))

    ifeq "$(MAKECMDGOALS)" "$2/new.patch"
        include $(dir $2)/$(notdir $2)-compare-patchorder.mk
        $2/new.patch: FORCE
    endif

    $2_NEW_PATCH_BASENAME := new-$(shell echo $$$$)

    $2/new.patch: $2/.repliduplicated $$($2_PATCHES) $$(sort $$($2_BUILD_CONFIGS)) $2-compare/.repliduplicated $$($2-compare_PATCHES) $$(sort $$($2-compare_BUILD_CONFIGS))
	@if [ `ls $2/.applied-* | wc -l` != `ls $2-compare/.applied-* | wc -l` ]; then echo ERROR!  Directories dont have same patch base!; echo; echo ls $2/.applied-\* ; ls $2/.applied-*; echo; echo ls $2-compare/.applied-\*; ls $2-compare/.applied-*; exit -1 ; fi
	-diff --exclude=patchorder.mk --exclude=new.patch --exclude=*~ -Nur $2-compare $2 | perl -pe 's,$2,$1,g; s,$2-compare,$1,g;' > $$@
	@echo If diff complains of recursive directory loops, you can ignore it.
	cp $$@ $2/.applied-$$($2_NEW_PATCH_BASENAME)
	@if [ `stat -c '%s' $$@` != 0 ]; then echo Created patch --- to install patch, choose one of the following: ; for dir in $$($2_PATCH_DIRS_SEARCHED); do if [ ! -d $$$$dir ]; then echo -n mkdir -p $$$$dir\; ; fi; echo /bin/mv $$@ $$$$dir/$$($2_NEW_PATCH_BASENAME).patch; done ; else echo Created empty patch... removing.; rm -f $$@; rm -f $2/.applied-$$($2_NEW_PATCH_BASENAME); fi

  endif

endef


# $1 = software package version (eg. gcc-4.2.0)
# $2 = untar staging dir (eg /export/builds/unpacked-sources)
# $3 = list of places where tarball might be found (eg /path/to/GPLv2 /other/path/for/GPLv2)
# $4 = build top (eg /export/builds/kernel)
# $5 = OPTIONAL build nickname
# $6 = where are patches found (eg /vobs/stb_common/bcm_kernel_impl/patches/GPL)
# $7 = extra patch subdirs
define Patchify_Rules

    # Patchify_Rules(1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6, 7=$7)

    $(foreach tarball_path,$3,$(call Unpack_Rules,$1,$2,$(tarball_path)))
    $(foreach patch_path,$6,$(call Patch_Rules,$1,$2/$1,$(if $5,$4/$5/$1,$4/$1),$(patch_path),$7))
    $(call Patch_Order_Rules,$1,$(if $5,$4/$5/$1,$4/$1))

endef

endif
