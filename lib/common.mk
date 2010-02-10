# -*- makefile -*-		common.mk - common variables used by many makefiles in this project
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


ifndef COMMON_MAKE_INCLUDED

  COMMON_MAKE_INCLUDED := yes

  # ALWAYS use the bourne shell for commands
  override SHELL := /bin/sh

  # Where the source directory is (i.e. where the main Makefile is).  There *should* never be a need to edit this.
  SOURCE		:= $(shell pwd)

  # Create an identifier unique to this process for use in naming temporary files
  TEMPFILE_ID		:= $(shell echo $$$$)

  # What am I running on?
  HOST_TUPLE		:= $(shell echo $$MACHTYPE)
ifeq ($(HOST_TUPLE),)
  $(error /bin/sh does not define MACHTYPE.  Either install a /bin/sh which does (like bash) or set MACHTYPE in your top-level makefile before including crossplex)
endif

  # take a list of paths from standard input, and COPY the files at those paths to equivalent paths rooted at the path in the following argument
  Cpio_Copy		:= /bin/cpio -apmdu

  # take a list of paths from standard input, and LINK the files at those paths to equivalent paths rooted at the path in the following argument
  Cpio_Link		:= /bin/cpio -aplmdu

  # Copy or Link a single file named $2 from directory $1 to directory $3.  If the device hosting directory $1 matches that for directory $3, use link, otherwise use copy.
  # $1 = source directory
  # $2 = source file
  # $3 = target directory
  Cpio_DupOne	= mkdir -p $3; if [ x`stat --format=%D $1` = x`stat --format=%D $3` ]; then pushd $1 && echo $2 | $(Cpio_Link) $3 && popd ; else pushd $1 && echo $2 | $(Cpio_Copy) $3 && popd ; fi

  # If a source file is a softlink, dup any of its targets which have not already been duped, then dup the source
  # $1 = source directory
  # $2 = source file
  # $3 = target directory
  Cpio_DupOne_WithLinks = function duptargets { if [ -L $$1/$$2 ]; then t=`readlink $$1/$$2`; td=`dirname $$t`; duptargets $$1/$$td $$t $$3/$$td; fi; mkdir -p $$3; if [ x`stat --format=%D $$1` = x`stat --format=%D $$3` ]; then echo hardlinking $$1/$$2 to $$3 && pushd $$1 && echo $$2 | cpio -aplmdu $$3 && popd; else echo copying $$1/$$2 to $$3 && pushd $$1 && echo $$2 | cpio -apmdu $$3 && popd ; fi }; mkdir -p $1; pushd $1; asd=`pwd`; popd; mkdir -p $3; pushd $3; atd=`pwd`; popd; duptargets $$asd $2 $$atd

  # cd to directory $1 and LINK every file found under that directory to an equivalent path rooted at direcory $2
  Cpio_Findlink = if [ -d $1 ]; then cd $1 && find . | $(Cpio_Link) $2; fi

  # cd to directory $1 and COPY every file found under that directory to an equivalent path rooted at direcory $2
  Cpio_Findcopy = if [ -d $1 ]; then cd $1 && find . | $(Cpio_Copy) $2; fi

  # cd to directory $1 and COPY or LINK every file found under that directory to an equivalent path rooted at direcory $2
  # if the devices of the two directories match, use LINK, otherwise use COPY.
  Cpio_Findup = mkdir -p $2; if [ x`stat --format=%D $1` = x`stat --format=%D $2` ]; then $(call Cpio_Findlink,$1,$2) ; else $(call Cpio_Findcopy,$1,$2) ; fi

  # This results in __crosstool_space containing just a space
  __crossplex_space := 
  __crossplex_space +=

  __crossplex_characters := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  __crossplex_characters += a b c d e f g h i j k l m n o p q r s t u v w y z
  __crossplex_characters += 0 1 2 3 4 5 6 7 8 9
  __crossplex_characters += ` ~ ! @ \# $$ % ^ & * ( ) - _ = +
  __crossplex_characters += { } [ ] \ : ; ' " < > , . / ? |

  strlen = $(strip $(eval __temp := $(subst $(__crossplex_space),x,$1))$(foreach a,$(__crossplex_characters),$(eval __temp := $$(subst $$a,x,$(__temp))))$(eval __temp := $(subst x,x ,$(__temp)))$(words $(__temp)))

  dsubstr = $(strip $(eval __temp := $$(subst $$(__crossplex_space),ｧ ,$$1))$(foreach a,$(__crossplex_characters),$(eval __temp := $$(subst $$a,$$a$$(__crossplex_space),$(__temp))))$(eval __temp := $(wordlist $2,$3,$(__temp))))$(subst ｧ,$(__crossplex_space),$(subst $(__crossplex_space),,$(__temp)))

  cmerge = $(strip $(if $2,$(if $(wordlist 2,$(words $2),$2),$(firstword $2)$1$(call cmerge,$1,$(wordlist 2,$(words $2),$2)),$2)))

  TagVal = $(subst $1=,,$(filter $1=%,$2))

  TagReVal = $(patsubst $1=%,$2,$(filter $1=%,$3))

  TagSubst = $(subst $1,$2,$(filter $1,$3))

  TagCond = $(if $(filter $1,$4),$(patsubst $1,$2,$(filter $1,$4)),$3)

  crossplex_token := �
  crossplex_ten_token := $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) $(crossplex_token) 
  crossplex_lots_of_token := $(foreach a,$(crossplex_ten_token),         \
			  $(foreach b,$(crossplex_ten_token),    \
			      $(foreach c,$(crossplex_ten_token), \
				  $(crossplex_ten_token)))))

  tokenize = $(and $1,$(wordlist 1,$1,$(crossplex_lots_of_token)))

  crossplex_max = $(subst $(crossplex_token)$(crossplex_token),$(crossplex_token),$(join $1,$2))

  crossplex_lt0 =  $(filter-out $(words $(call tokenize,$1)),$(words $(call crossplex_max,$(call tokenize,$1),$(call tokenize,$2))))
  crossplex_lt  =  $(call crossplex_lt0,0$1,0$2)

  # should
  $(if $(call crossplex_lt,1,2),,$(error crossplex_lt(1,2) returns $(call crossplex_lt,1,2)))
  $(if $(call crossplex_lt,,2),,$(error crossplex_lt(,2) returns $(call crossplex_lt,,2)))
  $(if $(call crossplex_lt,0,01),,$(error crossplex_lt(0,01) returns $(call crossplex_lt,0,01)))
  # should not
  $(if $(call crossplex_lt,0,0),$(error crossplex_lt(0,0) returns $(call crossplex_lt,0,0)))
  $(if $(call crossplex_lt,01,01),$(error crossplex_lt(01,01) returns $(call crossplex_lt,01,01)))
  $(if $(call crossplex_lt,01,0),$(error crossplex_lt(01,0) returns $(call crossplex_lt,01,0)))
  $(if $(call crossplex_lt,2,1),$(error crossplex_lt(2,1) returns $(call crossplex_lt,2,1)))
  $(if $(call crossplex_lt,2,2),$(error crossplex_lt(2,2) returns $(call crossplex_lt,2,2)))
  $(if $(call crossplex_lt,2,),$(error crossplex_lt(2,) returns $(call crossplex_lt,2,)))
  $(if $(call crossplex_lt,,),$(error crossplex_lt(,) returns $(call crossplex_lt,,)))

  crossplex_gt0 =  $(filter-out $(words $(call tokenize,$2)),$(words $(call crossplex_max,$(call tokenize,$1),$(call tokenize,$2))))
  crossplex_gt  =  $(call crossplex_gt0,0$1,0$2)

  # should
  $(if $(call crossplex_gt,2,1),,$(error crossplex_gt(2,1) returns $(call crossplex_gt,2,1)))
  $(if $(call crossplex_gt,2,),,$(error crossplex_gt(2,) returns $(call crossplex_gt,2,)))
  $(if $(call crossplex_gt,01,0),,$(error crossplex_gt(0,01) returns $(call crossplex_gt,0,01)))
  $(if $(call crossplex_gt,01,0),,$(error crossplex_gt(01,01) returns $(call crossplex_gt,01,01)))
  # should not
  $(if $(call crossplex_gt,0,01),$(error crossplex_gt(0,01) returns $(call crossplex_gt,0,01)))
  $(if $(call crossplex_gt,0,0),$(error crossplex_gt(0,0) returns $(call crossplex_gt,0,0)))
  $(if $(call crossplex_gt,01,01),$(error crossplex_gt(01,01) returns $(call crossplex_gt,01,01)))
  $(if $(call crossplex_gt,0,01),$(error crossplex_gt(0,01) returns $(call crossplex_gt,0,01)))
  $(if $(call crossplex_gt,1,2),$(error crossplex_gt(1,2) returns $(call crossplex_gt,1,2)))
  $(if $(call crossplex_gt,2,2),$(error crossplex_gt(2,2) returns $(call crossplex_gt,2,2)))
  $(if $(call crossplex_gt,,2),$(error crossplex_gt(,2) returns $(call crossplex_gt,,2)))
  $(if $(call crossplex_gt,,),$(error crossplex_gt(,) returns $(call crossplex_gt,,)))

  crossplex_eq0 =  $(filter $(words $(call tokenize,$1)),$(words $(call tokenize,$2)))
  crossplex_eq  =  $(call crossplex_eq0,0$1,0$2)

  # should
  $(if $(call crossplex_eq,2,2),,$(error crossplex_eq(2,2) returns $(call crossplex_eq,2,2)))
  $(if $(call crossplex_eq,,),,$(error crossplex_eq(,) returns $(call crossplex_eq,,)))
  $(if $(call crossplex_eq,0,0),,$(error crossplex_eq(0,0) returns $(call crossplex_eq,0,0)))
  $(if $(call crossplex_eq,01,01),,$(error crossplex_eq(01,01) returns $(call crossplex_eq,01,01)))
  # should not
  $(if $(call crossplex_eq,01,0),$(error crossplex_eq(01,01) returns $(call crossplex_eq,01,01)))
  $(if $(call crossplex_eq,0,01),$(error crossplex_eq(0,01) returns $(call crossplex_eq,0,01)))
  $(if $(call crossplex_eq,,2),$(error crossplex_eq(,2) returns $(call crossplex_eq,,2)))
  $(if $(call crossplex_eq,1,2),$(error crossplex_eq(1,2) returns $(call crossplex_eq,1,2)))
  $(if $(call crossplex_eq,2,),$(error crossplex_eq(2,) returns $(call crossplex_eq,2,)))
  $(if $(call crossplex_eq,2,1),$(error crossplex_eq(2,1) returns $(call crossplex_eq,2,1)))

  crossplex_ne0 =  $(filter-out $(words $(call tokenize,$1)),$(words $(call tokenize,$2)))
  crossplex_ne  =  $(call crossplex_ne0,0$1,0$2)

  # should
  $(if $(call crossplex_ne,,2),,$(error crossplex_ne(,2) returns $(call crossplex_ne,,2)))
  $(if $(call crossplex_ne,1,2),,$(error crossplex_ne(1,2) returns $(call crossplex_ne,1,2)))
  $(if $(call crossplex_ne,2,),,$(error crossplex_ne(2,) returns $(call crossplex_ne,2,)))
  $(if $(call crossplex_ne,2,1),,$(error crossplex_ne(2,1) returns $(call crossplex_ne,2,1)))
  $(if $(call crossplex_ne,01,0),,$(error crossplex_ne(01,01) returns $(call crossplex_ne,01,01)))
  $(if $(call crossplex_ne,0,01),,$(error crossplex_ne(0,01) returns $(call crossplex_ne,0,01)))
  # should not
  $(if $(call crossplex_ne,0,0),$(error crossplex_ne(0,0) returns $(call crossplex_ne,0,0)))
  $(if $(call crossplex_ne,01,01),$(error crossplex_ne(01,01) returns $(call crossplex_ne,01,01)))
  $(if $(call crossplex_ne,2,2),$(error crossplex_ne(2,2) returns $(call crossplex_ne,2,2)))
  $(if $(call crossplex_ne,,),$(error crossplex_ne(,) returns $(call crossplex_ne,,)))

  crossplex_version_field_eq = $(call crossplex_eq,$(word $1,$(subst ., ,$2)),$(word $1,$(subst ., ,$3)))

  crossplex_version_field_ne = $(call crossplex_ne,$(word $1,$(subst ., ,$2)),$(word $1,$(subst ., ,$3)))

  crossplex_version_field_lt = $(call crossplex_lt,$(word $1,$(subst ., ,$2)),$(word $1,$(subst ., ,$3)))

  crossplex_version_field_gt = $(call crossplex_gt,$(word $1,$(subst ., ,$2)),$(word $1,$(subst ., ,$3)))

  crossplex_version_lt = $(or $(and $(call crossplex_version_field_eq,1,$1,$2),$(call crossplex_version_field_lt,2,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,2,$1,$2),$(call crossplex_version_field_lt,3,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,3,$1,$2),$(call crossplex_version_field_lt,4,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,4,$1,$2),$(call crossplex_version_field_lt,5,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,5,$1,$2),$(call crossplex_version_field_lt,6,$1,$2)), \
			  )

  crossplex_version_gt = $(or $(and $(call crossplex_version_field_eq,1,$1,$2),$(call crossplex_version_field_gt,2,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,2,$1,$2),$(call crossplex_version_field_gt,3,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,3,$1,$2),$(call crossplex_version_field_gt,4,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,4,$1,$2),$(call crossplex_version_field_gt,5,$1,$2)), \
			      $(and $(call crossplex_version_field_eq,5,$1,$2),$(call crossplex_version_field_gt,6,$1,$2)), \
			  )

  crossplex_version_ge = $(if $(call crossplex_version_lt,$1,$2),,yes)

  crossplex_version_le = $(if $(call crossplex_version_gt,$1,$2),,yes)

  VERSION0 := 04.0
  VERSION1 := 4.0.2
  VERSION2 := 4.01
  VERSION3 := 4.01.2
  VERSION4 := 4.2.2
  VERSION5 := 4.2.3

  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION0)),,$(error crossplex_version_gt($(VERSION1),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION0))))

  # should
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION1)),,$(error crossplex_version_le($(VERSION0),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION2)),,$(error crossplex_version_le($(VERSION0),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION3)),,$(error crossplex_version_le($(VERSION0),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION4)),,$(error crossplex_version_le($(VERSION0),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION4))))
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION5)),,$(error crossplex_version_le($(VERSION0),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION5))))
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION2)),,$(error crossplex_version_le($(VERSION1),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION3)),,$(error crossplex_version_le($(VERSION1),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION4)),,$(error crossplex_version_le($(VERSION1),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION4))))
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION5)),,$(error crossplex_version_le($(VERSION1),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION5))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION3)),,$(error crossplex_version_le($(VERSION2),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION4)),,$(error crossplex_version_le($(VERSION2),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION4))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION5)),,$(error crossplex_version_le($(VERSION2),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION5))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION4)),,$(error crossplex_version_le($(VERSION3),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION4))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION5)),,$(error crossplex_version_le($(VERSION3),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION5))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION5)),,$(error crossplex_version_le($(VERSION4),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION5))))
  $(if $(call crossplex_version_le,$(VERSION0),$(VERSION0)),,$(error crossplex_version_le($(VERSION0),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION0),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION1)),,$(error crossplex_version_le($(VERSION1),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION2)),,$(error crossplex_version_le($(VERSION2),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION3)),,$(error crossplex_version_le($(VERSION3),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION4)),,$(error crossplex_version_le($(VERSION4),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION4))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION5)),,$(error crossplex_version_le($(VERSION5),$(VERSION5)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION5))))
  # should not
  $(if $(call crossplex_version_le,$(VERSION1),$(VERSION0)),$(error crossplex_version_le($(VERSION1),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION1),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION0)),$(error crossplex_version_le($(VERSION2),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION0)),$(error crossplex_version_le($(VERSION3),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION0)),$(error crossplex_version_le($(VERSION4),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION0)),$(error crossplex_version_le($(VERSION5),$(VERSION0)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION0))))
  $(if $(call crossplex_version_le,$(VERSION2),$(VERSION1)),$(error crossplex_version_le($(VERSION2),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION2),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION1)),$(error crossplex_version_le($(VERSION3),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION1)),$(error crossplex_version_le($(VERSION4),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION1)),$(error crossplex_version_le($(VERSION5),$(VERSION1)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION1))))
  $(if $(call crossplex_version_le,$(VERSION3),$(VERSION2)),$(error crossplex_version_le($(VERSION3),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION3),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION2)),$(error crossplex_version_le($(VERSION4),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION2)),$(error crossplex_version_le($(VERSION5),$(VERSION2)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION2))))
  $(if $(call crossplex_version_le,$(VERSION4),$(VERSION3)),$(error crossplex_version_le($(VERSION4),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION4),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION3)),$(error crossplex_version_le($(VERSION5),$(VERSION3)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION3))))
  $(if $(call crossplex_version_le,$(VERSION5),$(VERSION4)),$(error crossplex_version_le($(VERSION5),$(VERSION4)) returns $(call crossplex_version_le,$(VERSION5),$(VERSION4))))

  # should
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION0)),,$(error crossplex_version_ge($(VERSION1),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION0)),,$(error crossplex_version_ge($(VERSION2),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION0)),,$(error crossplex_version_ge($(VERSION3),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION0)),,$(error crossplex_version_ge($(VERSION4),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION0)),,$(error crossplex_version_ge($(VERSION5),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION1)),,$(error crossplex_version_ge($(VERSION2),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION1)),,$(error crossplex_version_ge($(VERSION3),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION1)),,$(error crossplex_version_ge($(VERSION4),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION1)),,$(error crossplex_version_ge($(VERSION5),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION2)),,$(error crossplex_version_ge($(VERSION3),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION2)),,$(error crossplex_version_ge($(VERSION4),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION2)),,$(error crossplex_version_ge($(VERSION5),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION3)),,$(error crossplex_version_ge($(VERSION4),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION3)),,$(error crossplex_version_ge($(VERSION5),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION4)),,$(error crossplex_version_ge($(VERSION5),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION0)),,$(error crossplex_version_ge($(VERSION0),$(VERSION0)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION0))))
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION1)),,$(error crossplex_version_ge($(VERSION1),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION2)),,$(error crossplex_version_ge($(VERSION2),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION3)),,$(error crossplex_version_ge($(VERSION3),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION4)),,$(error crossplex_version_ge($(VERSION4),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION5),$(VERSION5)),,$(error crossplex_version_ge($(VERSION5),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION5),$(VERSION5))))
  # should not
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION1)),$(error crossplex_version_ge($(VERSION0),$(VERSION1)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION1))))
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION2)),$(error crossplex_version_ge($(VERSION0),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION3)),$(error crossplex_version_ge($(VERSION0),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION4)),$(error crossplex_version_ge($(VERSION0),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION0),$(VERSION5)),$(error crossplex_version_ge($(VERSION0),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION0),$(VERSION5))))
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION2)),$(error crossplex_version_ge($(VERSION1),$(VERSION2)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION2))))
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION3)),$(error crossplex_version_ge($(VERSION1),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION4)),$(error crossplex_version_ge($(VERSION1),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION1),$(VERSION5)),$(error crossplex_version_ge($(VERSION1),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION1),$(VERSION5))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION3)),$(error crossplex_version_ge($(VERSION2),$(VERSION3)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION3))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION4)),$(error crossplex_version_ge($(VERSION2),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION2),$(VERSION5)),$(error crossplex_version_ge($(VERSION2),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION2),$(VERSION5))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION4)),$(error crossplex_version_ge($(VERSION3),$(VERSION4)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION4))))
  $(if $(call crossplex_version_ge,$(VERSION3),$(VERSION5)),$(error crossplex_version_ge($(VERSION3),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION3),$(VERSION5))))
  $(if $(call crossplex_version_ge,$(VERSION4),$(VERSION5)),$(error crossplex_version_ge($(VERSION4),$(VERSION5)) returns $(call crossplex_version_ge,$(VERSION4),$(VERSION5))))

  # should
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION1)),,$(error crossplex_version_lt($(VERSION0),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION2)),,$(error crossplex_version_lt($(VERSION0),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION3)),,$(error crossplex_version_lt($(VERSION0),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION4)),,$(error crossplex_version_lt($(VERSION0),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION4))))
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION5)),,$(error crossplex_version_lt($(VERSION0),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION5))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION2)),,$(error crossplex_version_lt($(VERSION1),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION3)),,$(error crossplex_version_lt($(VERSION1),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION4)),,$(error crossplex_version_lt($(VERSION1),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION4))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION5)),,$(error crossplex_version_lt($(VERSION1),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION5))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION3)),,$(error crossplex_version_lt($(VERSION2),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION4)),,$(error crossplex_version_lt($(VERSION2),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION4))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION5)),,$(error crossplex_version_lt($(VERSION2),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION5))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION4)),,$(error crossplex_version_lt($(VERSION3),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION4))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION5)),,$(error crossplex_version_lt($(VERSION3),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION5))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION5)),,$(error crossplex_version_lt($(VERSION4),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION5))))
  # should not
  $(if $(call crossplex_version_lt,$(VERSION0),$(VERSION0)),$(error crossplex_version_lt($(VERSION0),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION0),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION1)),$(error crossplex_version_lt($(VERSION1),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION2)),$(error crossplex_version_lt($(VERSION2),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION3)),$(error crossplex_version_lt($(VERSION3),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION4)),$(error crossplex_version_lt($(VERSION4),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION4))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION5)),$(error crossplex_version_lt($(VERSION5),$(VERSION5)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION5))))
  $(if $(call crossplex_version_lt,$(VERSION1),$(VERSION0)),$(error crossplex_version_lt($(VERSION1),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION1),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION0)),$(error crossplex_version_lt($(VERSION2),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION0)),$(error crossplex_version_lt($(VERSION3),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION0)),$(error crossplex_version_lt($(VERSION4),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION0)),$(error crossplex_version_lt($(VERSION5),$(VERSION0)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION0))))
  $(if $(call crossplex_version_lt,$(VERSION2),$(VERSION1)),$(error crossplex_version_lt($(VERSION2),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION2),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION1)),$(error crossplex_version_lt($(VERSION3),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION1)),$(error crossplex_version_lt($(VERSION4),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION1)),$(error crossplex_version_lt($(VERSION5),$(VERSION1)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION1))))
  $(if $(call crossplex_version_lt,$(VERSION3),$(VERSION2)),$(error crossplex_version_lt($(VERSION3),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION3),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION2)),$(error crossplex_version_lt($(VERSION4),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION2)),$(error crossplex_version_lt($(VERSION5),$(VERSION2)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION2))))
  $(if $(call crossplex_version_lt,$(VERSION4),$(VERSION3)),$(error crossplex_version_lt($(VERSION4),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION4),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION3)),$(error crossplex_version_lt($(VERSION5),$(VERSION3)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION3))))
  $(if $(call crossplex_version_lt,$(VERSION5),$(VERSION4)),$(error crossplex_version_lt($(VERSION5),$(VERSION4)) returns $(call crossplex_version_lt,$(VERSION5),$(VERSION4))))

  # should
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION0)),,$(error crossplex_version_gt($(VERSION1),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION0)),,$(error crossplex_version_gt($(VERSION2),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION0)),,$(error crossplex_version_gt($(VERSION3),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION0)),,$(error crossplex_version_gt($(VERSION4),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION0)),,$(error crossplex_version_gt($(VERSION5),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION1)),,$(error crossplex_version_gt($(VERSION2),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION1)),,$(error crossplex_version_gt($(VERSION3),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION1)),,$(error crossplex_version_gt($(VERSION4),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION1)),,$(error crossplex_version_gt($(VERSION5),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION2)),,$(error crossplex_version_gt($(VERSION3),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION2)),,$(error crossplex_version_gt($(VERSION4),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION2)),,$(error crossplex_version_gt($(VERSION5),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION3)),,$(error crossplex_version_gt($(VERSION4),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION3)),,$(error crossplex_version_gt($(VERSION5),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION4)),,$(error crossplex_version_gt($(VERSION5),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION4))))
  # should not
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION0)),$(error crossplex_version_gt($(VERSION0),$(VERSION0)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION0))))
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION1)),$(error crossplex_version_gt($(VERSION1),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION2)),$(error crossplex_version_gt($(VERSION2),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION3)),$(error crossplex_version_gt($(VERSION3),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION4)),$(error crossplex_version_gt($(VERSION4),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION4))))
  $(if $(call crossplex_version_gt,$(VERSION5),$(VERSION5)),$(error crossplex_version_gt($(VERSION5),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION5),$(VERSION5))))
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION1)),$(error crossplex_version_gt($(VERSION0),$(VERSION1)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION1))))
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION2)),$(error crossplex_version_gt($(VERSION0),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION3)),$(error crossplex_version_gt($(VERSION0),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION4)),$(error crossplex_version_gt($(VERSION0),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION4))))
  $(if $(call crossplex_version_gt,$(VERSION0),$(VERSION5)),$(error crossplex_version_gt($(VERSION0),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION0),$(VERSION5))))
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION2)),$(error crossplex_version_gt($(VERSION1),$(VERSION2)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION2))))
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION3)),$(error crossplex_version_gt($(VERSION1),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION4)),$(error crossplex_version_gt($(VERSION1),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION4))))
  $(if $(call crossplex_version_gt,$(VERSION1),$(VERSION5)),$(error crossplex_version_gt($(VERSION1),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION1),$(VERSION5))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION3)),$(error crossplex_version_gt($(VERSION2),$(VERSION3)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION3))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION4)),$(error crossplex_version_gt($(VERSION2),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION4))))
  $(if $(call crossplex_version_gt,$(VERSION2),$(VERSION5)),$(error crossplex_version_gt($(VERSION2),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION2),$(VERSION5))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION4)),$(error crossplex_version_gt($(VERSION3),$(VERSION4)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION4))))
  $(if $(call crossplex_version_gt,$(VERSION3),$(VERSION5)),$(error crossplex_version_gt($(VERSION3),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION3),$(VERSION5))))
  $(if $(call crossplex_version_gt,$(VERSION4),$(VERSION5)),$(error crossplex_version_gt($(VERSION4),$(VERSION5)) returns $(call crossplex_version_gt,$(VERSION4),$(VERSION5))))

  tolower = $(shell echo $1 | tr [:upper:] [:lower:])
  toupper = $(shell echo $1 | tr [:upper:] [:lower:])

#  # User can set their path to find gcc.  We supply the rest
#  GCC_PATH := $(shell gcc --print-search-dirs | grep programs)

  # Figure out where we are.
  define my-dir
    $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST),$(MAKEFILE_LIST))))
  endef

  # force target
  FORCE:

  # useful for debuggging
  .PHONY: printvars
  printvars:
	@$(foreach V,$(sort $(.VARIABLES)),$(if $(filter-out environment% default automatic,$(origin $V)),$(warning $V=$($V) ($(value $V)))))

endif
