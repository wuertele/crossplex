# -*- makefile -*-		linux-kernel.mk - how to build locally-written (i.e. not third-party) software
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


ifndef Crossplex_Configure_Local_Library

  LocalFlags_Wl_soname = -Wl,-soname,$1

  # $1 = unique library name
  # $2 = library version
  # $3 = tool dependencies
  # $4 = compile dependencies
  # $5 = runtime (link) dependencies
  # $6 = link program
  # $7 = default compiler flags
  # $8 = include directories
  # $9 = configuration template directories
  # $(10) = replacement default linker flags
  # $(11) = additional default linker flags
  # $(12) = replacement install path
  define Crossplex_Configure_Local_Library

    CONFIGURE_TOOLS_KNOWN_LOCAL_LIBS += $1

    $1_VERSION = $2

    $1_TOOL_DEPENDENCIES    = $3
    $1_BUILD_DEPENDENCIES   = $4
    $1_RUNTIME_DEPENDENCIES = $5

    $1_INCLUDE_DIRECTORIES += $8

    $1_CONFIG_PATH         += $9

    $1_LINK = $6

    $1_LDFLAGS = $(or $(10),-shared $(call LocalFlags_Wl_soname,$1)) $(11)

    $1_DEFAULT_COMPILER_FLAGS  = $(foreach include-dir,$8,-I$(include-dir))
    $1_DEFAULT_COMPILER_FLAGS += $7

    $1_INSTALL_PATH = $(or $(12),lib)

  endef

  # $1 = unique library name
  # $2 = source directory
  # $3 = list of source files
  # $4 = replacement compiler flags
  # $5 = additional compiler flags
  define Crossplex_Configure_Local_Library_Source

    $1_SOURCES += $3

    $(foreach c-file,$(filter %.c,$3),

      $1_OBJECTS += $(patsubst %.c,%.o,$(c-file))

      $1_$(patsubst %.c,%.o,$(c-file))_SOURCE = $2/$(c-file)

      $1_$(patsubst %.c,%.o,$(c-file))_COMPILE = gcc

      $1_$(patsubst %.c,%.o,$(c-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5

     )

    $(foreach cpp-file,$(filter %.cpp,$3),

      $1_OBJECTS += $(patsubst %.cpp,%.o,$(cpp-file))

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_SOURCE = $2/$(cpp-file)

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_COMPILE = g++

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5
     )

    $(foreach cc-file,$(filter %.cc,$3),

      $1_OBJECTS += $(patsubst %.cc,%.o,$(cc-file))

      $1_$(patsubst %.cc,%.o,$(cc-file))_SOURCE = $2/$(cc-file)

      $1_$(patsubst %.cc,%.o,$(cc-file))_COMPILE = g++

      $1_$(patsubst %.cc,%.o,$(cc-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5
     )

  endef


  # $1 = unique program name
  # $2 = unused
  # $3 = tool dependencies
  # $4 = compile dependencies
  # $5 = runtime (link) dependencies
  # $6 = link program
  # $7 = default compiler flags
  # $8 = include directories
  # $9 = libraries
  # $(10) = configuration template directories
  # $(11) = replacement default linker flags
  # $(12) = additional default linker flags
  # $(13) = replacement install path
  define Crossplex_Configure_Local_Program

    CONFIGURE_TOOLS_KNOWN_LOCAL_PROGS += $1

    $1_TOOL_DEPENDENCIES    = $3
    $1_BUILD_DEPENDENCIES   = $4
    $1_RUNTIME_DEPENDENCIES = $5

    $1_INCLUDE_DIRECTORIES += $8

    $1_LIBRARIES           := $9

    $1_CONFIG_PATH         += $(10)

    $1_LINK = $6

    $1_LDFLAGS = $(or $(11),$(foreach library,$9,-l$(library))) $(12)

    $1_DEFAULT_COMPILER_FLAGS  = $(foreach include-dir,$8,-I$(include-dir))
    $1_DEFAULT_COMPILER_FLAGS += $7

    $1_INSTALL_PATH = $(or $(13),bin)

  endef

  # $1 = unique program name
  # $2 = source directory
  # $3 = list of source files
  # $4 = replacement compiler flags
  # $5 = additional compiler flags
  define Crossplex_Configure_Local_Program_Source

    $1_SOURCES += $3

    $(foreach c-file,$(filter %.c,$3),

      $1_OBJECTS += $(patsubst %.c,%.o,$(c-file))

      $1_$(patsubst %.c,%.o,$(c-file))_SOURCE = $2/$(c-file)

      $1_$(patsubst %.c,%.o,$(c-file))_COMPILE = gcc

      $1_$(patsubst %.c,%.o,$(c-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5

     )

    $(foreach cpp-file,$(filter %.cpp,$3),

      $1_OBJECTS += $(patsubst %.cpp,%.o,$(cpp-file))

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_SOURCE = $2/$(cpp-file)

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_COMPILE = g++

      $1_$(patsubst %.cpp,%.o,$(cpp-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5
     )

    $(foreach cc-file,$(filter %.cc,$3),

      $1_OBJECTS += $(patsubst %.cc,%.o,$(cc-file))

      $1_$(patsubst %.cc,%.o,$(cc-file))_SOURCE = $2/$(cc-file)

      $1_$(patsubst %.cc,%.o,$(cc-file))_COMPILE = g++

      $1_$(patsubst %.cc,%.o,$(cc-file))_FLAGS = $(or $4,$(and $(filter $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_$($1_VERSION)_DEFAULT_COMPILER_FLAGS,$2)),$(and $(filter $1_DEFAULT_COMPILER_FLAGS,$(.VARIABLES)),$(call $1_DEFAULT_COMPILER_FLAGS,$2))) $5
     )

  endef




endif
