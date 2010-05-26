# -*- makefile -*-		uclibc-toolchain.mk - how to build cross uclibc toolchains
#
# Copyright (C) 2001,2002,2003,2004,2005,2006,2007,2008,2009,2010  David Wuertele <dave@crossplex.org>
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

ifndef UCLIBC_TOOLCHAIN_MAKE_LOADED

  UCLIBC_TOOLCHAIN_MAKE_LOADED := 1

  include $(CROSSPLEX_BUILD_SYSTEM)/targetfs.mk

### Building Toolchains with TargetFS

  UCLIBC_PROGRAMS += sbin/ldconfig                # Configures the dynamic linker runtime bindings
  UCLIBC_PROGRAMS += usr/bin/ldd                  # Reports which shared libraries are required by each given program or shared library
  UCLIBC_PROGRAMS += usr/bin/iconv                # Performs character set conversion

  UCLIBC_LIBRARIES := 

# lib/$(LIB)-$(UCLIBC_VERSION).so, lib/libc.so.0
  UCLIBC_LIBRARIES_LIBC += libuClibc

# lib/$(LIB)-$(UCLIBC_VERSION).so, lib/$(LIB).so.0
  UCLIBC_LIBRARIES_VS0 += ld-uClibc

# lib/$(LIB)-$(UCLIBC_VERSION).so, lib/$(LIB).so.0, usr/lib/$(LIB).a, usr/lib/$(LIB).so, usr/lib/$(LIB)_pic.a
  UCLIBC_LIBRARIES_VS0ulaSp += libcrypt
  UCLIBC_LIBRARIES_VS0ulaSp += libdl
  UCLIBC_LIBRARIES_VS0ulaSp += libm
  UCLIBC_LIBRARIES_VS0ulaSp += libnsl
  UCLIBC_LIBRARIES_VS0ulaSp += libpthread
  UCLIBC_LIBRARIES_VS0ulaSp += libresolv
  UCLIBC_LIBRARIES_VS0ulaSp += librt
  UCLIBC_LIBRARIES_VS0ulaSp += libutil

# lib/$(LIB)-$(UCLIBC_VERSION).so, lib/$(LIB).so.1, usr/lib/$(LIB).a, usr/lib/$(LIB).so, usr/lib/$(LIB)_pic.a
  UCLIBC_LIBRARIES_VS1ulaSp += libthread_db

# lib/$(LIB).so, lib/$(LIB).so.0, lib/$(LIB).so.0.0.0, lib/$(LIB).a, lib/$(LIB).la
  UCLIBC_LIBRARIES_S000ala += libmudflap #
  UCLIBC_LIBRARIES_S000ala += libmudflapth

# lib/$(LIB).so, lib/$(LIB).so.0, lib/$(LIB).so.0.0.0, lib/$(LIB).a, lib/$(LIB).la, lib/$(LIB)_nonshared.a lib/$(LIB)_nonshared.la
  UCLIBC_LIBRARIES_S000alasns += libssp

# lib/$(LIB).so, lib/$(LIB).so.1, lib/$(LIB).so.1.0.0, lib/$(LIB).a, lib/$(LIB).la, lib/$(LIB).spec
  UCLIBC_LIBRARIES_S100 += libgomp

# lib/$(LIB).so, lib/$(LIB).so.3, lib/$(LIB).so.3.0.0, lib/$(LIB).a, lib/$(LIB).la
  UCLIBC_LIBRARIES_S300 += libgfortran

# lib/$(LIB).so, lib/$(LIB).so.6, lib/$(LIB).so.6.0.0, lib/$(LIB).a, lib/$(LIB).la, lib/$(LIB)_pic.a
  UCLIBC_LIBRARIES_S600p += libstdc++

# lib/$(LIB).so, lib/$(LIB).so.1
  UCLIBC_LIBRARIES_S1 += libgcc_s

# usr/lib/$(LIB)-2.19.1.so, usr/lib/$(LIB).a, usr/lib/$(LIB).la, usr/lib/$(LIB).so
  UCLIBC_LIBRARIES_bfd += libbfd

# usr/lib/$(LIB).a, usr/lib/$(LIB).la
  UCLIBC_LIBRARIES_ulala += libgmp, libmp, libmpfr

# usr/lib/$(LIB).a, usr/lib/$(LIB).so
  UCLIBC_LIBRARIES_ulaso += libdmalloc, libdmallocth, libdmallocthcxx, libdmallocxx

# usr/lib/$(LIB).a, usr/lib/$(LIB).so, usr/lib/$(LIB).so.0.0.0
  UCLIBC_LIBRARIES_ulaso000 += libduma

# usr/lib/$(LIB).o (NPTL STARTFILES ONLY)
  UCLIBC_STARTFILES_UO += crt1
  UCLIBC_STARTFILES_UO += crti
  UCLIBC_STARTFILES_UO += crtn

# usr/lib/$(LIB).o
  UCLIBC_LIBRARIES_UO += Scrt1

  UCLIBC_HOST_PROGRAMS   += bin/ldd.host

  UCLIBC_CLIENT_PROGRAMS += bin/ldd

  # $1 = targetfs name
  # $2 = name of component library of uclibc
  # $3 = relative path of component library's files
  # $4 = additional sublib order-only dependencies
  define Uclibc_Sub_Lib_Depends

    $1_TARGETFS_INSTALLABLE_COMPONENT += $2

    $1_TARGETFS_INSTALLABLE_FILE += $3

    $1_TARGETFS_TARGETS += $($1_TARGETFS_PREFIX)/$3

    $1_$2_INSTALLABLE_FILE += $3

    $1_$2_TARGETS += $($1_TARGETFS_PREFIX)/$3

    $($1_TARGETFS_PREFIX)/$3: $($1_uClibc_TARGETS) | $4

  endef

  # $1 = targetfs name
  # $2 = name of component library of uclibc
  # $3 = relative path of component library's files
  # $4 = additional sublib order-only dependencies
  define Uclibc_Sub_Lib_Depends_Devel

    $1_TARGETFS_INSTALLABLE_COMPONENT += $2

    $1_TARGETFS_INSTALLABLE_FILE += $3

    $1_TARGETFS_TARGETS += $($1_TARGETFS_PREFIX)/$3

    $1_$2_INSTALLABLE_DEV_FILE += $3

    $1_$2_DEV_TARGETS += $($1_TARGETFS_PREFIX)/$3

    $($1_TARGETFS_PREFIX)/$3: $($1_uClibc_TARGETS) | $4

  endef

  INSTALL_KERNEL_HEADERS    = $(call TargetFS_Install_Kernel_Headers,$1/$2,$(filter linux-%,$3),NOSTAGE TARGET=$4 $5,,$6)
  INSTALL_BINUTILS          = $(call TargetFS_Install_Autoconf,$1/$2,$(filter binutils-%,$3),NOSTAGE TARGET=$4 SYSROOT=$1/toolchain $5,,$6)
  INSTALL_UCLIBC_HEADERS    = $(call TargetFS_Install_Make,$1/$2,$(filter uClibc-%,$3),NOSTAGE TARGET=$4 SYSROOT=$1/uclibc-headers-sysroot MAKEARGS=headers ENV=-i $5 ,,$6)
  INSTALL_GCC_CORE_STATIC   = $(call TargetFS_Install_Autoconf,$1/$2,$(filter gcc-%,$3),NOSTAGE TARGET=$4 NOSHARED ALLTARGETLIBGCC SYSROOT=$1/gcc-core-static-sysroot MAKEARGS=stage1 PLACEHOLDER_FOR_GMP=PLACEHOLDER_FOR_MPFR $5,,$6)
  INSTALL_UCLIBC_FINAL      = $(call TargetFS_Install_Make,$1/$2,$(filter uClibc-%,$3),NOSTAGE TARGET=$4 SYSROOT=$1/uclibc-final-sysroot ENV=-i MAKEARGS=final $5 ,,$6)
  INSTALL_GCC_FINAL         = $(call TargetFS_Install_Autoconf,$1/$2,$(filter gcc-%,$3),NOSTAGE TARGET=$4 SYSROOT=$1/toolchain MAKEARGS=stage3 $5,,$6)
  INSTALL_GDB               = $(call TargetFS_Install_Autoconf,$1/$2,$(filter gdb-%,$3),NOSTAGE TARGET=$4 SYSROOT=$1/toolchain $5,,$6)

  # $1 = build top
  # $2 = toolchain (targetfs) name
  # $3 = target tuple
  # $4 = toolchain source package versions
  # $5 = path code (UNIMPLEMENTED)
  # $6 = toolchain flags
  # $7 = patch tags
  define Uclibc_Toolchain

    $(eval $(call Configure_TargetFS,$2/uclibc-headers-sysroot,$1,$5,,$3))
    $(eval $(call Configure_TargetFS,$2/gcc-core-static-sysroot,$1,$5,,$3))
    $(eval $(call Configure_TargetFS,$2/uclibc-final-sysroot,$1,$5,,$3))
    $(eval $(call Configure_TargetFS,$2/toolchain,$1,$5,,$3))

    # Uclibc Headers build depends on binutils and kernel headers
    $(eval $(call INSTALL_BINUTILS,$2,uclibc-headers-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_KERNEL_HEADERS,$2,uclibc-headers-sysroot,$4,$3,$6,$7))

    # GCC Core (no shared libs) build depends on kernel headers, binutils, and uclibc headers
    $(eval $(call INSTALL_BINUTILS,$2,gcc-core-static-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_KERNEL_HEADERS,$2,gcc-core-static-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_UCLIBC_HEADERS,$2,gcc-core-static-sysroot,$4,$3,$6,$7))

    # Uclibc final build depends on binutils, kernel headers, uclibc headers, and GCC Core (no shared libs)
    $(eval $(call INSTALL_BINUTILS,$2,uclibc-final-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_KERNEL_HEADERS,$2,uclibc-final-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_UCLIBC_HEADERS,$2,uclibc-final-sysroot,$4,$3,$6,$7))
    $(eval $(call INSTALL_GCC_CORE_STATIC,$2,uclibc-final-sysroot,$4,$3,$6,$7))

    # Toolchain:  depends on binutils, uclibc final, gcc final, and gdb
    $(eval $(call INSTALL_BINUTILS,$2,toolchain,$4,$3,$6,$7))
    $(eval $(call INSTALL_KERNEL_HEADERS,$2,toolchain,$4,$3,$6,$7))
    $(eval $(call INSTALL_UCLIBC_FINAL,$2,toolchain,$4,$3,$6,$7))
    $(eval $(call INSTALL_GCC_FINAL,$2,toolchain,$4,$3,$6,$7))
    $(eval $(call INSTALL_GDB,$2,toolchain,$4,$3,$6,$7))

    $2/toolchain_RUNTIMES  += uclibc
    $2/toolchain_TOOLCHAIN += uclibc
    $2/toolchain_TOOLCHAIN_TARGET_TUPLE = $3

    $2_TOOLCHAIN_TARGETS = $($2/toolchain_TARGETFS_TARGETS)

    # Tell the toolchain TargetFS where to find the files that make up each of the component libraries of uclibc
    # If a module calls out one of these component libraries as a runtime dependency, the module's TargetFS should know how to copy it from here
    $(foreach library_name,$(UCLIBC_LIBRARIES_LIBC) $(UCLIBC_LIBRARIES_VS0) $(UCLIBC_LIBRARIES_VS0ulaSp) $(UCLIBC_LIBRARIES_VS1ulaSp) $(UCLIBC_LIBRARIES_0UAS),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name)-$(patsubst uClibc-%,%,$(filter uClibc-%,$4)).so))
    $(foreach library_name,$(UCLIBC_LIBRARIES_LIBC),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/libc.so.0))
       $(foreach library_name,$(UCLIBC_LIBRARIES_VS0) $(UCLIBC_LIBRARIES_VS0ulaSp) $(UCLIBC_LIBRARIES_S000ala) $(UCLIBC_LIBRARIES_S000alasns) $(UCLIBC_LIBRARIES_0UAS),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.0))
    $(foreach library_name,$(UCLIBC_LIBRARIES_VS1ulaSp),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.1))
    $(foreach library_name,$(UCLIBC_LIBRARIES_VS0ulaSp) $(UCLIBC_LIBRARIES_VS1ulaSp) $(UCLIBC_LIBRARIES_bfd) $(UCLIBC_LIBRARIES_ulaso) $(UCLIBC_LIBRARIES_ulaso000) $(UCLIBC_LIBRARIES_0UAS) ,$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),usr/lib/$(library_name).so))
      $(foreach library_name,$(UCLIBC_LIBRARIES_S000ala) $(UCLIBC_LIBRARIES_S000alasns),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.0.0.0))
    $(foreach library_name,$(UCLIBC_LIBRARIES_ulaso000),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),usr/lib/$(library_name).so.0.0.0))
      $(foreach library_name,$(UCLIBC_LIBRARIES_S100),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.1.0.0))
      $(foreach library_name,$(UCLIBC_LIBRARIES_S300),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.3.0.0))
     $(foreach library_name,$(UCLIBC_LIBRARIES_S600p),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name).so.6.0.0))
    $(foreach library_name,$(UCLIBC_LIBRARIES_bfd),$(call Uclibc_Sub_Lib_Depends,$2/toolchain,$(library_name),lib/$(library_name)-2.19.1.so))

        $(foreach library_name,$(UCLIBC_LIBRARIES_VS0ulaSp) $(UCLIBC_LIBRARIES_VS1ulaSp) $(UCLIBC_LIBRARIES_S000ala) $(UCLIBC_LIBRARIES_S000alasns) $(UCLIBC_LIBRARIES_S100) $(UCLIBC_LIBRARIES_S300) $(UCLIBC_LIBRARIES_S600p) $(UCLIBC_LIBRARIES_bfd) $(UCLIBC_LIBRARIES_ulala) $(UCLIBC_LIBRARIES_ulaso) $(UCLIBC_LIBRARIES_ulaso000) $(UCLIBC_LIBRARIES_0UAS) ,$(call Uclibc_Sub_Lib_Depends_Devel,$2/toolchain,$(library_name),usr/lib/$(library_name).a))

    # TODO:  add inter-library dependencies for the above component libraries

    # there are some libraries that aren't defined completely yet

  endef

endif
