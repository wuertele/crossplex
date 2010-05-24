# -*- makefile -*-		main.mk - include all crossplex macros
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


# Completely insulate our build from the environment
# unexport $(.VARIABLES) # breaks parallel recursive make
unexport $(foreach V,$(.VARIABLES),$(if $(filter environment,$(origin $V)),$V))

default: all-targets

ultraclean:
	rm -rf $(BUILD_TOP)

nothing:	# good for just building makefile dependencies and stopping at that

ALL_TARGETS += nothing

ifndef CROSSPLEX_BUILD_SYSTEM
  $(error CROSSPLEX_BUILD_SYSTEM undefined.)
endif

ifndef BUILD_TOP
  $(error BUILD_TOP undefined.)
endif

#$(error verify that build_top is absolute)
#$(error verify that thirdparty is absolute)
#$(error verify that patches is absolute)

# How to build target filesystems
include $(CROSSPLEX_BUILD_SYSTEM)/targetfs.mk

# How to build toolchains
include $(CROSSPLEX_BUILD_SYSTEM)/glibc-toolchain.mk
include $(CROSSPLEX_BUILD_SYSTEM)/uclibc-toolchain.mk

# How to build toolchains and kernels from source
include $(CROSSPLEX_BUILD_SYSTEM)/linux-kernel.mk

# How to build local source
include $(CROSSPLEX_BUILD_SYSTEM)/local.mk

# How to build various deployment kits
include $(CROSSPLEX_BUILD_SYSTEM)/kit.mk

all-targets: $(ALL_TARGETS)
