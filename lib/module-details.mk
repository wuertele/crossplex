# -*- makefile -*-		module-details.mk - details on how to build specific third-party packages
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


ifndef MODULE_DETAILS_LOADED

  MODULE_DETAILS_LOADED := 1

  ## Linux Headers

  linux_headers_LICENSE := GPL

  ## Linux Kernel

  linux_LICENSE := GPL

  ## Binutils

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += binutils

  binutils_LICENSE := GPL

  binutils_CONFIGURE_ARGS =  --prefix=/ --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE)
  binutils_CONFIGURE_ARGS += $(if $(filter TARGET=%,$4),--target=$(subst TARGET=,,$(filter TARGET=%,$4)))
  binutils_CONFIGURE_ARGS += --disable-nls
  binutils_CONFIGURE_ARGS += $(if $(filter SYSROOT=%,$4),--with-sysroot=$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX),$(filter SYSROOT=%,$4)))

  binutils_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) AR=ar

  # List of programs that are both part of the cross-compiler, and used to create the stage1 gcc.
  binutils_INSTALLABLE_basic += bin/$1$2ar  # Creates, modifies, and extracts from archives
  binutils_INSTALLABLE_basic += bin/$1$2as  # An assembler that assembles the output of gcc into object files
  binutils_INSTALLABLE_basic += bin/$1$2ld  # A linker that combines a number of object and archive files into a single file, relocating their data and tying up symbol references
  binutils_INSTALLABLE_basic += bin/$1$2nm  # Lists the symbols occurring in a given object file
  binutils_INSTALLABLE_basic += bin/$1$2objdump # Displays information about the given object file, with options controlling the particular information to display; the information shown is useful to programmers who are working on the compilation tools
  binutils_INSTALLABLE_basic += bin/$1$2ranlib  # Generates an index of the contents of an archive and stores it in the archive; the index lists all of the symbols defined by archive members that are relocatable object files
  binutils_INSTALLABLE_basic += bin/$1$2strip   # Discards symbols from object files

  # List of programs that are part of the cross-compiler
  binutils_INSTALLABLE_more += bin/$1$2addr2line     # Translates program addresses to file names and line numbers; given an address and the name of an executable, it uses the debugging information in the executable to determine which source file and line number are associated with the address
  binutils_INSTALLABLE_more += bin/$1$2c++filt       # Used by the linker to de-mangle C++ and Java symbols and to keep overloaded functions from clashing
  binutils_INSTALLABLE_more += bin/$1$2objcopy       # Translates one type of object file into another
  binutils_INSTALLABLE_more += bin/$1$2readelf       # Displays information about ELF type binaries
  binutils_INSTALLABLE_more += bin/$1$2size          # Lists the section sizes and the total size for the given object files
  binutils_INSTALLABLE_more += bin/$1$2strings       # Outputs, for each given file, the sequences of printable characters that are of at least the specified length (defaulting to four); for object files, it prints, by default, only the strings from the initializing and loading sections while for other types of files, it scans the entire file

  # List of programs that don't get built in an android toolchain
  binutils_INSTALLABLE_glibc += bin/$1$2gprof         # Displays call graph profile data

  # List of ldscripts
  binutils_LDSCRIPT_BASES := elf32btsmip elf32btsmipn32 elf32ltsmip elf32ltsmipn32 elf64btsmip elf64ltsmip 
  binutils_LDSCRIPT_EXTS  := x xbn xc xd xdc xdw xn xr xs xsc xsw xu xw

  binutils_INSTALLABLE_ldscripts = $(foreach base,$(CROSS_BINUTILS_LDSCRIPT_BASES),$(foreach ext,$(CROSS_BINUTILS_LDSCRIPT_EXTS),$1/lib/ldscripts/$(base).$(ext)))


  ## gcc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += gcc

  gcc_LICENSE := GPL

  gcc_SYSROOT_DEPENDENCIES = binutils linux_headers

  gcc_enable_c_and_cplusplus := --enable-languages=c,c++

  gcc_CONFIGURE_ARGS  = --prefix=/
  gcc_CONFIGURE_ARGS += --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE)
  gcc_CONFIGURE_ARGS += $(if $(filter TARGET=%,$4),--target=$(subst TARGET=,,$(filter TARGET=%,$4))) 
  gcc_CONFIGURE_ARGS += $(if $(filter SYSROOT=%,$4),--with-sysroot=$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX),$(filter SYSROOT=%,$4)))
  gcc_CONFIGURE_ARGS += $(if $(filter SYSROOT=%,$4),--with-local-prefix=$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX),$(filter SYSROOT=%,$4)))   # remove /usr/local/include from gcc's include search path (http://gcc.gnu.org/PR10532)
  gcc_CONFIGURE_ARGS += $(call TagCond,MAKEARGS=stage3,$(gcc_enable_c_and_cplusplus),--enable-languages=c,$4)
  gcc_CONFIGURE_ARGS += $(call TagCond,MAKEARGS=stage3,,--without-headers,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage1,--disable-threads,$4)	# BROADCOM crosstools_hf-linux-2.6.18.0-uclibc-0.9.29-nptl-20070423-4.2-4ts.spec says: --enable-threads
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage1,--enable-threads=no,$4)	# crosstool.sh's way of syaing "--disable-threads"
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage1,--with-newlib,$4)	# hack used by crosstool.sh to convince gcc-core that it doesn't need real glibc headers
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--without-newlib,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--enable-threads=posix,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--disable-libgomp,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--disable-libssp,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--enable-c99,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--enable-long-long,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--with-gnu-as,$4)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--with-gnu-ld,$4)
  gcc_CONFIGURE_ARGS += --disable-multilib
  gcc_CONFIGURE_ARGS += --disable-nls			# no human will be reading this tools error codes
  gcc_CONFIGURE_ARGS += --enable-symvers=gnu		# from crosstool.sh
  gcc_CONFIGURE_ARGS += --enable-__cxa_atexit           # from crosstool.sh.  (cross-lfs.org says that this allows use of __cxa_atexit, rather than atexit, to register C++ destructors for local statics and global objects and is essential for fully standards-compliant handling of destructors. It also affects the C++ ABI and therefore results in C++ shared libraries and C++ programs that are interoperable with other Linux distributions.)
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage1,--enable-target-optspace,$4)	# from BROADCOM crosstools_hf-linux-2.6.18.0-uclibc-0.9.29-nptl-20070423-4.2-4ts.spec
  gcc_CONFIGURE_ARGS += $(call TagSubst,MAKEARGS=stage3,--enable-target-optspace,$4)	# from BROADCOM crosstools_hf-linux-2.6.18.0-uclibc-0.9.29-nptl-20070423-4.2-4ts.spec
  gcc_CONFIGURE_ARGS += $(if $(filter NOSHARED,$4),--disable-shared,--enable-shared)

  gcc_BUILD_ENVIRONMENT = PATH=$(if $(filter SYSROOT=%,$2),$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX)/bin:,$(filter SYSROOT=%,$2)))$(PATH)

  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 := configure-gcc 
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += configure-libcpp
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += configure-build-libiberty
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += configure-libdecnumber
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += all-libcpp
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += all-build-libiberty
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC4 += all-libdecnumber

  CROSS_GCC_STAGE2_MAKE_OPTS_GCC3 := configure-gcc
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC3 += configure-build-libiberty
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC3 += all-build-libiberty 
  CROSS_GCC_STAGE2_MAKE_OPTS_GCC3 += all-libiberty 

  gcc_MAKE_ARGS  = $(call TagSubst,MAKEARGS=stage1,all-gcc,$2)
  gcc_MAKE_ARGS += $(call TagSubst,MAKEARGS=stage2,$(if $(filter gcc-4.%,$3),$(CROSS_GCC_STAGE2_MAKE_OPTS_GCC4),$(CROSS_GCC_STAGE2_MAKE_OPTS_GCC3)),$2)
  gcc_MAKE_ARGS += $(call TagCond,SYSROOT=%,build_tooldir=$$(%_TARGETFS_PREFIX)/$(subst TARGET=,,$(filter TARGET=%,$2)),,$2)

  gcc_POST_BUILD_STEPS  = $(call TagSubst,MAKEARGS=stage2,+ $(and $(call crossplex_version_lt,$9,4.4),$(call gcc_BUILD_ENVIRONMENT,$1,$2) $(MAKE) -C $3$4/gcc libgcc.mk && sed 's@-lc@@g' < $3$4/gcc/libgcc.mk > $3$4/gcc/libgcc.mk.new && mv $3$4/gcc/libgcc.mk.new $3$4/gcc/libgcc.mk &&,$2))
  gcc_POST_BUILD_STEPS += $(call TagSubst,MAKEARGS=stage2, $(call gcc_BUILD_ENVIRONMENT,$1,$2) $(MAKE) -C $3$4 all-gcc $(call TagCond,SYSROOT=%,build_tooldir=$$(%_TARGETFS_PREFIX)/$(subst TARGET=,,$(filter TARGET=%,$2)),,$2),$2)

  gcc_MAKE_INSTALL_ARGS  = $(call TagSubst,MAKEARGS=stage1,install-gcc,$2)
  gcc_MAKE_INSTALL_ARGS += $(call TagSubst,MAKEARGS=stage2,install-gcc,$2)
  gcc_MAKE_INSTALL_ARGS += $(call TagSubst,MAKEARGS=stage3,install,$2)

  ## glibc-ports

  CONFIGURE_TOOLS_KNOWN_SRC_PLUGINS += glibc-ports

  glibc-ports_LICENSE := GPL

  glibc-ports_COPY_TARGET := ports

  ## glibc-ports

  CONFIGURE_TOOLS_KNOWN_SRC_PLUGINS += glibc-linuxthreads

  glibc-linuxthreads_LICENSE := GPL

  glibc-linuxthreads_COPY_PATHS := linuxthreads linuxthreads_db

  ## glibc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += glibc

  glibc_LICENSE := GPL

  glibc_SYSROOT_DEPENDENCIES = binutils linux_headers gcc

  glibc_PRE_CONFIGURE_STEPS = cd $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3; cp -f config.cache $$(@D)/config.cache; 

  glibc_CONFIGURE_ARGS  = --prefix=/usr
  glibc_CONFIGURE_ARGS += --build=$(HOST_TUPLE)
  glibc_CONFIGURE_ARGS += $(if $(filter TARGET=%,$4),--host=$(subst TARGET=,,$(filter TARGET=%,$4))) 
  glibc_CONFIGURE_ARGS += --without-cvs            # ? from crosstool.sh
  glibc_CONFIGURE_ARGS += --disable-sanity-checks # ? from crosstool.sh
  glibc_CONFIGURE_ARGS += $(patsubst SYSROOT=%,--with-headers=$$(%_TARGETFS_PREFIX)/usr/include,$(filter SYSROOT=%,$4))
  glibc_CONFIGURE_ARGS += --enable-hacker-mode    # As of glibc-2.3.2, to get this step to work for hppa-linux
  glibc_CONFIGURE_ARGS += --enable-add-ons=ports,$(call TagCond,THREAD=%,%,,$4)
  glibc_CONFIGURE_ARGS += --with-tls
  glibc_CONFIGURE_ARGS += --enable-kernel=2.6.9
  glibc_CONFIGURE_ARGS += $(call TagCond,THREAD=linuxthreads,--without-__thread,--with-__thread,$4)
  glibc_CONFIGURE_ARGS += $(call TagCond,DEBUG_GLIBC,,--enable-omitfp,$4)
  glibc_CONFIGURE_ARGS += $(call TagCond,DEBUG_GLIBC,--enable-profile,--disable-profile,$4)
  glibc_CONFIGURE_ARGS += $(call TagCond,DEBUG_GLIBC,--enable-debug,--disable-debug,$4)
  glibc_CONFIGURE_ARGS += --without-gd # from crosstool.sh: to avoid error "memusagestat.c:36:16: gd.h: No such file or directory" (see also http://sources.redhat.com/ml/libc-alpha/2000-07/msg00024.html)
  glibc_CONFIGURE_ARGS += --cache-file=config.cache    

  glibc_CONFIGURE_ARGS_TOTEST += --enable-bind-now

  glibc_BUILD_ENVIRONMENT  = PATH=$(if $(filter SYSROOT=%,$2),$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX)/bin:,$(filter SYSROOT=%,$2)))$(PATH)
  glibc_BUILD_ENVIRONMENT += libc_cv_ppc_machine=yes
  glibc_BUILD_ENVIRONMENT += libc_cv_forced_unwind=yes
  glibc_BUILD_ENVIRONMENT += libc_cv_c_cleanup=yes
  glibc_BUILD_ENVIRONMENT += BUILD_CC=gcc
  glibc_BUILD_ENVIRONMENT += $(patsubst TARGET=%,CC=%-gcc,$(filter TARGET=%,$2))
  glibc_BUILD_ENVIRONMENT += $(patsubst TARGET=%,AR=%-ar,$(filter TARGET=%,$2))
  glibc_BUILD_ENVIRONMENT += $(patsubst TARGET=%,RANLIB=%-ranlib,$(filter TARGET=%,$2))
  glibc_BUILD_ENVIRONMENT += CFLAGS="-O2 -finline-limit=10000 -g -ggdb"

  glibc_MAKE_ARGS  = $(call TagSubst,MAKEARGS=headers,remove-old-headers,$2)
  glibc_MAKE_ARGS += $(call TagSubst,MAKEARGS=startfiles,FAQ,$2)
  glibc_MAKE_ARGS += $(call TagSubst,MAKEARGS=final,all $(if $(filter glibc-2.3.6,$3),,subdir_stubs) manual/libc.info po/linguas,$2)
  glibc_MAKE_ARGS += LINGUAS=""
  glibc_MAKE_ARGS += libc_cv_ppc_machine=yes # Override libc_cv_ppc_machine so glibc-cvs doesn't complain (from crosstool.sh)
  glibc_MAKE_ARGS += cross-compiling=yes     # from crosstool.sh
  glibc_MAKE_ARGS += install_root=$($1_TARGETFS_PREFIX)
  glibc_MAKE_ARGS += $$(if $$(filter -j%,$$(MAKEFLAGS)),PARALLELMFLAGS=-j4)

  glibc_MAKE_INSTALL_ARGS  = $(call TagSubst,MAKEARGS=headers,install-headers,$2)
  glibc_MAKE_INSTALL_ARGS += $(call TagSubst,MAKEARGS=startfiles,csu/subdir_lib,$2)
  glibc_MAKE_INSTALL_ARGS += $(call TagSubst,MAKEARGS=final,install,$2)
  glibc_MAKE_INSTALL_ARGS += libc_cv_ppc_machine=yes # Override libc_cv_ppc_machine so glibc-cvs doesn't complain (from crosstool.sh)
  glibc_MAKE_INSTALL_ARGS += LINGUAS=""
  glibc_MAKE_INSTALL_ARGS += cross-compiling=yes     # from crosstool.sh
  glibc_MAKE_INSTALL_ARGS += install_root=$($1_TARGETFS_PREFIX)
  glibc_MAKE_INSTALL_ARGS += -j1

  # From crosstool.sh: Two headers -- stubs.h and features.h -- aren't installed by install-headers, so do them by hand.  We can tolerate an empty stubs.h for the moment.
  glibc_POST_INSTALL_STEPS_headerscript  = mkdir -p $5/usr/include/gnu; 
  glibc_POST_INSTALL_STEPS_headerscript += touch $5/usr/include/gnu/stubs.h; 
  glibc_POST_INSTALL_STEPS_headerscript += cp $3/include/features.h $5/usr/include/gnu;
  # Hmm... seems like this features.h file is put in a different place by crosstool.  Should remove one of these.
  glibc_POST_INSTALL_STEPS_headerscript += mkdir -p $5/include;
  glibc_POST_INSTALL_STEPS_headerscript += cp $3/include/features.h $5/include;
  # From crosstool.sh:  Building the bootstrap gcc requires either setting inhibit_libc, or having a copy of stdio_lim.h...
  glibc_POST_INSTALL_STEPS_headerscript += mkdir -p $5/usr/include/bits;
  glibc_POST_INSTALL_STEPS_headerscript += cp $3$4/bits/stdio_lim.h $5/usr/include/bits;
  # Hmm... seems like this stdio_lim.h file is put in a different place by crosstool.  Should remove one of these.
  glibc_POST_INSTALL_STEPS_headerscript += mkdir -p $5/include/bits;
  glibc_POST_INSTALL_STEPS_headerscript += cp $3$4/bits/stdio_lim.h $5/include/bits;

  glibc_POST_INSTALL_STEPS  = $(call TagSubst,MAKEARGS=headers,$(glibc_POST_INSTALL_STEPS_headerscript),$2) 
  glibc_POST_INSTALL_STEPS += $(call TagSubst,MAKEARGS=startfiles,mkdir -p $5/lib && cp -fp $3$4/csu/crt[1in].o $5/lib; ,$2)

  glibc_POST_INSTALL_STEPS += $(call TagSubst,MAKEARGS=final,cd $5/usr/lib && mv libc.so libc.so_orig && sed 's/\/usr\/lib\///g;s/\/usr\/lib64\///g;s/\/lib\///g;s/\/lib64\///g;/BUG in libc.scripts.output-format.sed/d' < libc.so_orig > libc.so; ,$2)
  glibc_POST_INSTALL_STEPS += $(call TagSubst,MAKEARGS=final,mv libpthread.so libpthread.so_orig && sed 's/\/usr\/lib\///g;s/\/usr\/lib64\///g;s/\/lib\///g;s/\/lib64\///g;/BUG in libpthread.scripts.output-format.sed/d' < libpthread.so_orig > libpthread.so; ,$2)

  glibc_POST_INSTALL_STEPS += $(call TagSubst,NEEDSEMH,mkdir -p $5/usr/include && cp $3/linuxthreads/semaphore.h $5/usr/include; ,$2)


  ## GDB

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += gdb

  gdb_LICENSE := GPL

  gdb_SYSROOT_DEPENDENCIES = binutils linux_headers glibc gcc

  gdb_BUILD_ENVIRONMENT  = PATH=$(if $(filter SYSROOT=%,$2),$(patsubst SYSROOT=%,$$(%_TARGETFS_PREFIX)/bin:,$(filter SYSROOT=%,$2)))$(PATH)
  gdb_BUILD_ENVIRONMENT += CC=gcc AR=ar

  gdb_CONFIGURE_ARGS  = --prefix=/
  gdb_CONFIGURE_ARGS += --host=$(HOST_TUPLE)
  gdb_CONFIGURE_ARGS += $(call TagCond,TARGET=%,--target=%,,$4)
  gdb_CONFIGURE_ARGS += $(call TagCond,SYSROOT=%,--with-sysroot=%,,$4)

  gdb_POST_BUILD_STEPS = +mkdir -p $3/gdbserver-build; cd $3/gdbserver-build; $(call gcc_BUILD_ENVIRONMENT,$1,$2) $3/gdb/gdbserver/configure --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --target=$($1_TARGETFS_TUPLE) --includedir=$(call TagReVal,SYSROOT,$$(%_TARGETFS_PREFIX)/sysroot/usr/include,$2); $(call gcc_BUILD_ENVIRONMENT,$1,$2) $(MAKE) -C $3/gdbserver-build

  gdb_POST_INSTALL_STEPS = +$(call gcc_BUILD_ENVIRONMENT,$1,$2) $(MAKE) -C $3/gdbserver-build DESTDIR=$5 install

  ## Syslinux

  CONFIGURE_TOOLS_KNOWN_MAKE_MODULES += syslinux

  syslinux_LICENSE := GPL
  syslinux_BUILD_DEPENDENCIES := 
  syslinux_PREBUILD_STEPS     := 
  syslinux_MAKE_BUILD_OPTS    := SKIP
  syslinux_POSTBUILD_STEPS    := 
  syslinux_MAKE_INSTALL_ARGS   = install INSTALLROOT=$3
  syslinux_FORCE_BUILD_TAGS   := NODESTDIR

  syslinux_INSTALLABLE_default += usr/bin/syslinux
  syslinux_INSTALLABLE_default += usr/bin/mkdiskimage
  syslinux_INSTALLABLE_default += usr/bin/isohybrid
  syslinux_INSTALLABLE_default += usr/bin/gethostip
  syslinux_INSTALLABLE_default += usr/bin/keytab-lilo
  syslinux_INSTALLABLE_default += usr/bin/lss16toppm
  syslinux_INSTALLABLE_default += usr/bin/md5pass
  syslinux_INSTALLABLE_default += usr/bin/ppmtolss16
  syslinux_INSTALLABLE_default += usr/bin/sha1pass
  syslinux_INSTALLABLE_default += usr/bin/syslinux2ansi
  syslinux_INSTALLABLE_default += usr/share/syslinux/pxelinux.0
  syslinux_INSTALLABLE_default += usr/share/syslinux/gpxelinux.0
  syslinux_INSTALLABLE_default += usr/share/syslinux/isolinux.bin
  syslinux_INSTALLABLE_default += usr/share/syslinux/isolinux-debug.bin
  syslinux_INSTALLABLE_default += usr/share/syslinux/syslinux.com
  syslinux_INSTALLABLE_default += usr/share/syslinux/copybs.com
  syslinux_INSTALLABLE_default += usr/share/syslinux/syslinux.exe
  syslinux_INSTALLABLE_default += usr/share/syslinux/mbr.bin
  syslinux_INSTALLABLE_default += usr/share/syslinux/gptmbr.bin
  syslinux_INSTALLABLE_default += usr/share/syslinux/memdisk
  syslinux_INSTALLABLE_default += usr/share/syslinux/memdump.com
  syslinux_INSTALLABLE_default += usr/share/syslinux/pxechain.com
  syslinux_INSTALLABLE_default += usr/share/syslinux/menu.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/vesamenu.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/chain.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/config.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/cpuidtest.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/dmitest.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/elf.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/ethersel.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/ifcpu64.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/linux.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/mboot.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/meminfo.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/pcitest.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/pmload.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/reboot.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/sanboot.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/sdi.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/vesainfo.c32
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/libcom32.a
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/com32.ld
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi_bios.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi_system.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi_base_board.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi_processor.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dmi/dmi_chassis.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/dev.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stddef.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/inttypes.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/zconf.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/setjmp.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/minmax.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/png.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stdint.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/alloca.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stdbool.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stdlib.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stdarg.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/unistd.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/stdio.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/math.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/ctype.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/com32.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/diverr.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/compiler.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/extern.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/sysconfig.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/archsetjmp.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/klibc/endian.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/cpufeature.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/errno.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/tinyjpeg.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/limits.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/elf.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/pngconf.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/fcntl.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/time.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/netinet/in.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/string.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/cpu.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/elfcommon.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/stat.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/pci.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/elf64.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/elf32.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/time.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/fpu.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/times.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/types.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/sys/io.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/pxe.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/config.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/bootpm.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/zio.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/resolve.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/linux.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/features.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/advconst.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/reboot.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/vesacon.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/boot.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/loadfile.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/idle.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/video.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/io.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/bootrm.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/movebits.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/syslinux/adv.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/colortbl.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/cpuid.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/zlib.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/console.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/assert.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/endian.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/bitsize/stdintlimits.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/bitsize/stddef.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/bitsize/stdint.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/bitsize/stdintconst.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/include/bitsize/limits.h
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/libutil_com.a
  syslinux_INSTALLABLE_default += usr/share/syslinux/com32/libutil_lnx.a
  syslinux_INSTALLABLE_default += sbin/extlinux
  syslinux_INSTALLABLE_default += usr/man/man1/gethostip.1
  syslinux_INSTALLABLE_default += usr/man/man1/lss16toppm.1
  syslinux_INSTALLABLE_default += usr/man/man1/ppmtolss16.1
  syslinux_INSTALLABLE_default += usr/man/man1/syslinux.1
  syslinux_INSTALLABLE_default += usr/man/man1/syslinux2ansi.1

  ## Pkg-config

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += pkg-config

  pkg-config_LICENSE := GPL
  pkg-config_BUILD_DEPENDENCIES := autoconf automake

  pkg-config_INSTALLABLE_default += bin/pkg-config
  pkg-config_INSTALLABLE_default += share/aclocal/pkg.m4

  ## Python

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += Python

  Python_LICENSE += REDIST_OK
  Python_INSTALLABLE_default += bin/python

  ## autoconf

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += autoconf

  autoconf_LICENSE += GPL

  ## libtool

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libtool

  libtool_LICENSE += GPL

  ## automake

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += automake

  automake_LICENSE += GPL

  automake_BUILD_DEPENDENCIES := libtool

  ## util-macros

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += util-macros

  util-macros_LICENSE += GPL

  util-macros_BUILD_DEPENDENCIES := autoconf automake

  ## udev

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += udev

  udev_LICENSE += GPL

  udev_RUNTIME_DEPENDENCIES := libc

  udev_INSTALLABLE_minimal += sbin/udevd
  udev_INSTALLABLE_minimal += sbin/udevadm

  udev_PKGCONFIG += lib/pkgconfig/libvolume_id.pc
  udev_PKGCONFIG += lib/pkgconfig/libudev.pc

  ## libpng

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libpng

  libpng_LICENSE += REDIST_OK

  libpng_RUNTIME_DEPENDENCIES := zlib

  libpng_BUILD_DEPENDENCIES := zlib

  libpng_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CFLAGS=-I$($1_zlib_STAGE)/include LDFLAGS=-L$($1_TARGETFS_PREFIX)/lib

  libpng_INSTALLABLE_minimal += lib/libpng12.so.0
  libpng_INSTALLABLE_minimal += lib/libpng12.so
  libpng_INSTALLABLE_minimal += lib/libpng.so.3
  libpng_INSTALLABLE_minimal += lib/libpng.so
  libpng_INSTALLABLE_minimal += lib/libpng12.so.0.35.0
  libpng_INSTALLABLE_minimal += lib/libpng.so.3.35.0

  libpng_INSTALLABLE_devel += bin/libpng12-config
  libpng_INSTALLABLE_devel += lib/libpng12.la
  libpng_INSTALLABLE_devel += lib/libpng.la
  libpng_INSTALLABLE_devel += lib/libpng12.a
  libpng_INSTALLABLE_devel += lib/libpng.a
  libpng_INSTALLABLE_devel += include/libpng12/png.h
  libpng_INSTALLABLE_devel += include/png.h
  libpng_INSTALLABLE_devel += include/libpng12/pngconf.h
  libpng_INSTALLABLE_devel += include/pngconf.h

  libpng_PKGCONFIG += lib/pkgconfig/libpng12.pc
  libpng_PKGCONFIG += lib/pkgconfig/libpng.pc

  ## termcap

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += termcap

  termcap_LICENSE := GPL

  termcap_RUNTIME_DEPENDENCIES := ld libc libm

  termcap_BUILD_ENVIRONMENT  = $($1_TARGETFS_BUILD_ENV)
  termcap_BUILD_ENVIRONMENT += AR="$($1_TARGETFS_TUPLE)-ar rc"
  termcap_BUILD_ENVIRONMENT += AS=$($1_TARGETFS_TUPLE)-as
  termcap_BUILD_ENVIRONMENT += LD=$($1_TARGETFS_TUPLE)-gcc
  termcap_BUILD_ENVIRONMENT += NM=$($1_TARGETFS_TUPLE)-nm
  termcap_BUILD_ENVIRONMENT += CC=$($1_TARGETFS_TUPLE)-gcc
  termcap_BUILD_ENVIRONMENT += GCC=$($1_TARGETFS_TUPLE)-gcc
  termcap_BUILD_ENVIRONMENT += CXX=$($1_TARGETFS_TUPLE)-g++
  termcap_BUILD_ENVIRONMENT += STRIP=$($1_TARGETFS_TUPLE)-strip
  termcap_BUILD_ENVIRONMENT += RANLIB=$($1_TARGETFS_TUPLE)-ranlib

  termcap_CONFIGURE_ARGS = --prefix=$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/stage --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE)

  termcap_INSTALLABLE_devel += lib/libtermcap.a
  termcap_INSTALLABLE_devel += include/termcap.h

  ## zlib

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += zlib

  zlib_LICENSE += REDIST_OK

  zlib_RUNTIME_DEPENDENCIES := ld libc libm

  zlib_BUILD_DEPENDENCIES := 

  zlib_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) AR="$($1_TARGETFS_TUPLE)-ar rc" AS=$($1_TARGETFS_TUPLE)-as LD=$($1_TARGETFS_TUPLE)-gcc NM=$($1_TARGETFS_TUPLE)-nm CC=$($1_TARGETFS_TUPLE)-gcc GCC=$($1_TARGETFS_TUPLE)-gcc CXX=$($1_TARGETFS_TUPLE)-g++ STRIP=$($1_TARGETFS_TUPLE)-strip RANLIB=$($1_TARGETFS_TUPLE)-ranlib

  zlib_CONFIGURE_ARGS = --shared --prefix=$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/stage

  zlib_INSTALLABLE_minimal += lib/libz.so
  zlib_INSTALLABLE_minimal += lib/libz.so.1
  zlib_INSTALLABLE_minimal += lib/libz.so.1.2.3

  zlib_INSTALLABLE_devel += include/zlib.h
  zlib_INSTALLABLE_devel += include/zconf.h

  zlib_PKGCONFIG += 

  ## expat

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += expat

  expat_LICENSE += REDIST_OK

  expat_RUNTIME_DEPENDENCIES := 

  expat_BUILD_DEPENDENCIES := 

  expat_INSTALLABLE_minimal += lib/libexpat.so.1.5.2
  expat_INSTALLABLE_minimal += lib/libexpat.so.1
  expat_INSTALLABLE_minimal += lib/libexpat.so
  expat_INSTALLABLE_minimal += bin/xmlwf

  expat_INSTALLABLE_devel += lib/libexpat.la
  expat_INSTALLABLE_devel += lib/libexpat.a
  expat_INSTALLABLE_devel += include/expat.h
  expat_INSTALLABLE_devel += include/expat_external.h

  ## freetype

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += freetype

  freetype_LICENSE += GPL

  freetype_RUNTIME_DEPENDENCIES := 

  freetype_TOOL_DEPENDENCIES := autoconf automake

  freetype_BUILD_DEPENDENCIES := 

  freetype_INSTALLABLE_minimal += lib/libfreetype.so.6.3.19
  freetype_INSTALLABLE_minimal += lib/libfreetype.so.6
  freetype_INSTALLABLE_minimal += lib/libfreetype.so

  freetype_INSTALLABLE_devel += lib/libfreetype.a
  freetype_INSTALLABLE_devel += include/freetype2/freetype/config/ftconfig.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/config/ftheader.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/config/ftmodule.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/config/ftoption.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/config/ftstdlib.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/freetype.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftadvanc.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftbbox.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftbdf.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftbitmap.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftcache.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftchapters.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftcid.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/fterrdef.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/fterrors.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftgasp.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftglyph.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftgxval.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftgzip.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftimage.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftincrem.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftlcdfil.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftlist.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftlzw.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftmac.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftmm.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftmodapi.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftmoderr.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftotval.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftoutln.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftpfr.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftrender.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftsizes.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftsnames.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftstroke.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftsynth.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftsystem.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/fttrigon.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/fttypes.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftwinfnt.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ftxf86.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/t1tables.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ttnameid.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/tttables.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/tttags.h
  freetype_INSTALLABLE_devel += include/freetype2/freetype/ttunpat.h
  freetype_INSTALLABLE_devel += include/ft2build.h
  freetype_INSTALLABLE_devel += bin/freetype-config
  freetype_INSTALLABLE_devel += share/aclocal/freetype2.m4

  freetype_PKGCONFIG += lib/pkgconfig/freetype2.pc


  ## fontconfig

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += fontconfig

  fontconfig_LICENSE += REDIST_OK

  fontconfig_BUILD_DEPENDENCIES := freetype zlib expat

  fontconfig_RUNTIME_DEPENDENCIES := freetype expat

  FONTCONFIG_ARCHMAP_x86    := i686-%-linux-gnu
  FONTCONFIG_ARCHMAP_mipsel := mipsel-%-linux-gnu

  Fontconfig_Arch = $(sort $(foreach arch,$(patsubst FONTCONFIG_ARCHMAP_%,%,$(filter FONTCONFIG_ARCHMAP%,$(.VARIABLES))),$(if $(filter $(FONTCONFIG_ARCHMAP_$(arch)),$1),$(arch))))

  fontconfig_CONFIGURE_ARGS = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --with-arch=$(call Fontconfig_Arch,$($1_TARGETFS_TUPLE)) --with-freetype-config=$$($1_freetype_STAGE)/bin/freetype-config

  fontconfig_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CFLAGS="-I$$($1_zlib_STAGE)/include -I$$($1_expat_STAGE)/include -I$$($1_freetype_STAGE)/include -I$$($1_freetype_STAGE)/include/freetype2" LDFLAGS=-L$($1_TARGETFS_PREFIX)/lib

  fontconfig_MAKE_ARGS = -j1

  fontconfig_INSTALLABLE_minimal += lib/libfontconfig.so.1.2.0
  fontconfig_INSTALLABLE_minimal += lib/libfontconfig.so.1
  fontconfig_INSTALLABLE_minimal += lib/libfontconfig.so
  fontconfig_INSTALLABLE_minimal += bin/fc-cache
  fontconfig_INSTALLABLE_minimal += bin/fc-cat
  fontconfig_INSTALLABLE_minimal += bin/fc-list
  fontconfig_INSTALLABLE_minimal += bin/fc-match
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/README
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-autohint.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-no-sub-pixel.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-sub-pixel-bgr.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-sub-pixel-rgb.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-sub-pixel-vbgr.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-sub-pixel-vrgb.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/10-unhinted.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/20-fix-globaladvance.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/20-lohit-gujarati.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/20-unhint-small-vera.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/30-amt-aliases.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/30-urw-aliases.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/40-generic.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/49-sansserif.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/50-user.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/51-local.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/60-latin.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/65-fonts-persian.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/65-nonlatin.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/69-unifont.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/70-no-bitmaps.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/70-yes-bitmaps.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/80-delicious.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.avail/90-synthetic.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/20-fix-globaladvance.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/20-lohit-gujarati.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/20-unhint-small-vera.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/30-amt-aliases.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/30-urw-aliases.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/40-generic.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/49-sansserif.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/50-user.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/51-local.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/60-latin.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/65-fonts-persian.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/65-nonlatin.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/69-unifont.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/80-delicious.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/conf.d/90-synthetic.conf
  fontconfig_INSTALLABLE_minimal += etc/fonts/fonts.dtd
  fontconfig_INSTALLABLE_minimal += etc/fonts/fonts.conf

  fontconfig_INSTALLABLE_devel += include/fontconfig/fontconfig.h
  fontconfig_INSTALLABLE_devel += include/fontconfig/fcfreetype.h
  fontconfig_INSTALLABLE_devel += include/fontconfig/fcprivate.h
  fontconfig_INSTALLABLE_devel += lib/libfontconfig.la
  fontconfig_INSTALLABLE_devel += lib/libfontconfig.a

  fontconfig_PKGCONFIG += lib/pkgconfig/fontconfig.pc

  ## openssl

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += openssl

  openssl_LICENSE += REDIST_OK

  openssl_FORCE_BUILD_TAGS += BUILDINSRC

  openssl_RUNTIME_DEPENDENCIES := 

  openssl_BUILD_DEPENDENCIES := zlib

  openssl_CONFIGURE_ARGS = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --install-prefix=$($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/stage linux-elf shared zlib-dynamic

  openssl_MAKE_ARGS = -j1 CC=$($1_TARGETFS_TUPLE)-gcc AR="$($1_TARGETFS_TUPLE)-ar r " RANLIB=$($1_TARGETFS_TUPLE)-ranlib INCLUDES="-I. -I.. -I../.. -I../include -I../crypto -I../../include -I$$($1_zlib_STAGE)/include"

  openssl_INSTALLABLE_minimal += bin/c_rehash
  openssl_INSTALLABLE_minimal += ssl/misc/CA.sh
  openssl_INSTALLABLE_minimal += ssl/misc/CA.pl
  openssl_INSTALLABLE_minimal += ssl/misc/c_hash
  openssl_INSTALLABLE_minimal += ssl/misc/c_info
  openssl_INSTALLABLE_minimal += ssl/misc/c_issuer
  openssl_INSTALLABLE_minimal += ssl/misc/c_name
  openssl_INSTALLABLE_minimal += ssl/openssl.cnf
  openssl_INSTALLABLE_minimal += lib/engines/lib4758cca.so
  openssl_INSTALLABLE_minimal += lib/engines/libaep.so
  openssl_INSTALLABLE_minimal += lib/engines/libatalla.so
  openssl_INSTALLABLE_minimal += lib/engines/libcswift.so
  openssl_INSTALLABLE_minimal += lib/engines/libgmp.so
  openssl_INSTALLABLE_minimal += lib/engines/libchil.so
  openssl_INSTALLABLE_minimal += lib/engines/libnuron.so
  openssl_INSTALLABLE_minimal += lib/engines/libsureware.so
  openssl_INSTALLABLE_minimal += lib/engines/libubsec.so
  openssl_INSTALLABLE_minimal += lib/engines/libcapi.so
  openssl_INSTALLABLE_minimal += lib/libssl.so.0.9.8
  openssl_INSTALLABLE_minimal += lib/libcrypto.so
  openssl_INSTALLABLE_minimal += lib/libcrypto.so.0.9.8
  openssl_INSTALLABLE_minimal += lib/libssl.so

  openssl_INSTALLABLE_devel += include/openssl/e_os2.h
  openssl_INSTALLABLE_devel += include/openssl/crypto.h
  openssl_INSTALLABLE_devel += include/openssl/tmdiff.h
  openssl_INSTALLABLE_devel += include/openssl/opensslv.h
  openssl_INSTALLABLE_devel += include/openssl/opensslconf.h
  openssl_INSTALLABLE_devel += include/openssl/ebcdic.h
  openssl_INSTALLABLE_devel += include/openssl/symhacks.h
  openssl_INSTALLABLE_devel += include/openssl/ossl_typ.h
  openssl_INSTALLABLE_devel += include/openssl/objects.h
  openssl_INSTALLABLE_devel += include/openssl/obj_mac.h
  openssl_INSTALLABLE_devel += include/openssl/md2.h
  openssl_INSTALLABLE_devel += include/openssl/md4.h
  openssl_INSTALLABLE_devel += include/openssl/md5.h
  openssl_INSTALLABLE_devel += include/openssl/sha.h
  openssl_INSTALLABLE_devel += include/openssl/hmac.h
  openssl_INSTALLABLE_devel += include/openssl/ripemd.h
  openssl_INSTALLABLE_devel += include/openssl/des.h
  openssl_INSTALLABLE_devel += include/openssl/des_old.h
  openssl_INSTALLABLE_devel += include/openssl/aes.h
  openssl_INSTALLABLE_devel += include/openssl/rc2.h
  openssl_INSTALLABLE_devel += include/openssl/rc4.h
  openssl_INSTALLABLE_devel += include/openssl/idea.h
  openssl_INSTALLABLE_devel += include/openssl/blowfish.h
  openssl_INSTALLABLE_devel += include/openssl/cast.h
  openssl_INSTALLABLE_devel += include/openssl/bn.h
  openssl_INSTALLABLE_devel += include/openssl/ec.h
  openssl_INSTALLABLE_devel += include/openssl/rsa.h
  openssl_INSTALLABLE_devel += include/openssl/dsa.h
  openssl_INSTALLABLE_devel += include/openssl/ecdsa.h
  openssl_INSTALLABLE_devel += include/openssl/dh.h
  openssl_INSTALLABLE_devel += include/openssl/ecdh.h
  openssl_INSTALLABLE_devel += include/openssl/dso.h
  openssl_INSTALLABLE_devel += include/openssl/engine.h
  openssl_INSTALLABLE_devel += include/openssl/buffer.h
  openssl_INSTALLABLE_devel += include/openssl/bio.h
  openssl_INSTALLABLE_devel += include/openssl/stack.h
  openssl_INSTALLABLE_devel += include/openssl/safestack.h
  openssl_INSTALLABLE_devel += include/openssl/lhash.h
  openssl_INSTALLABLE_devel += include/openssl/rand.h
  openssl_INSTALLABLE_devel += include/openssl/err.h
  openssl_INSTALLABLE_devel += include/openssl/evp.h
  openssl_INSTALLABLE_devel += include/openssl/asn1.h
  openssl_INSTALLABLE_devel += include/openssl/asn1_mac.h
  openssl_INSTALLABLE_devel += include/openssl/asn1t.h
  openssl_INSTALLABLE_devel += include/openssl/pem.h
  openssl_INSTALLABLE_devel += include/openssl/pem2.h
  openssl_INSTALLABLE_devel += include/openssl/x509.h
  openssl_INSTALLABLE_devel += include/openssl/x509_vfy.h
  openssl_INSTALLABLE_devel += include/openssl/x509v3.h
  openssl_INSTALLABLE_devel += include/openssl/conf.h
  openssl_INSTALLABLE_devel += include/openssl/conf_api.h
  openssl_INSTALLABLE_devel += include/openssl/txt_db.h
  openssl_INSTALLABLE_devel += include/openssl/pkcs7.h
  openssl_INSTALLABLE_devel += include/openssl/pkcs12.h
  openssl_INSTALLABLE_devel += include/openssl/comp.h
  openssl_INSTALLABLE_devel += include/openssl/ocsp.h
  openssl_INSTALLABLE_devel += include/openssl/ui.h
  openssl_INSTALLABLE_devel += include/openssl/ui_compat.h
  openssl_INSTALLABLE_devel += include/openssl/krb5_asn.h
  openssl_INSTALLABLE_devel += include/openssl/store.h
  openssl_INSTALLABLE_devel += include/openssl/pqueue.h
  openssl_INSTALLABLE_devel += include/openssl/pq_compat.h
  openssl_INSTALLABLE_devel += include/openssl/fips.h
  openssl_INSTALLABLE_devel += include/openssl/fips_rand.h
  openssl_INSTALLABLE_devel += include/openssl/ssl.h
  openssl_INSTALLABLE_devel += include/openssl/ssl2.h
  openssl_INSTALLABLE_devel += include/openssl/ssl3.h
  openssl_INSTALLABLE_devel += include/openssl/ssl23.h
  openssl_INSTALLABLE_devel += include/openssl/tls1.h
  openssl_INSTALLABLE_devel += include/openssl/dtls1.h
  openssl_INSTALLABLE_devel += include/openssl/kssl.h
  openssl_INSTALLABLE_devel += lib/libcrypto.a
  openssl_INSTALLABLE_devel += lib/libssl.a
  openssl_INSTALLABLE_devel += lib/fips_premain.c
  openssl_INSTALLABLE_devel += lib/fips_premain.c.sha1

  openssl_PKGCONFIG += lib/pkgconfig/libcrypto.pc
  openssl_PKGCONFIG += lib/pkgconfig/libssl.pc
  openssl_PKGCONFIG += lib/pkgconfig/openssl.pc


  # X11 Prototypes

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xproto
  xproto_LICENSE += REDIST_OK
  xproto_PKGCONFIG += lib/pkgconfig/xproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xextproto
  xextproto_LICENSE += REDIST_OK
  xextproto_PKGCONFIG += lib/pkgconfig/xextproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += bigreqsproto
  bigreqsproto_LICENSE += REDIST_OK
  bigreqsproto_PKGCONFIG += lib/pkgconfig/bigreqsproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xcmiscproto
  xcmiscproto_LICENSE += REDIST_OK
  xcmiscproto_PKGCONFIG += lib/pkgconfig/xcmiscproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += fontsproto
  fontsproto_LICENSE += REDIST_OK
  fontsproto_PKGCONFIG += lib/pkgconfig/fontsproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += inputproto
  inputproto_LICENSE += REDIST_OK
  inputproto_PKGCONFIG += lib/pkgconfig/inputproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += kbproto
  kbproto_LICENSE += REDIST_OK
  kbproto_PKGCONFIG += lib/pkgconfig/kbproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += resourceproto
  resourceproto_LICENSE += REDIST_OK
  resourceproto_PKGCONFIG += lib/pkgconfig/resourceproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += scrnsaverproto
  scrnsaverproto_LICENSE += REDIST_OK
  scrnsaverproto_PKGCONFIG += lib/pkgconfig/scrnsaverproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += videoproto
  videoproto_LICENSE += REDIST_OK
  videoproto_PKGCONFIG += lib/pkgconfig/videoproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += recordproto
  recordproto_LICENSE += REDIST_OK
  recordproto_PKGCONFIG += lib/pkgconfig/recordproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += trapproto
  trapproto_LICENSE += REDIST_OK
  trapproto_PKGCONFIG += lib/pkgconfig/trapproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86bigfontproto
  xf86bigfontproto_LICENSE += REDIST_OK
  xf86bigfontproto_PKGCONFIG += lib/pkgconfig/xf86bigfontproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86dgaproto
  xf86dgaproto_LICENSE += REDIST_OK
  xf86dgaproto_PKGCONFIG += lib/pkgconfig/xf86dgaproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86miscproto
  xf86miscproto_LICENSE += REDIST_OK
  xf86miscproto_PKGCONFIG += lib/pkgconfig/xf86miscproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86vidmodeproto
  xf86vidmodeproto_LICENSE += REDIST_OK
  xf86vidmodeproto_PKGCONFIG += lib/pkgconfig/xf86vidmodeproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += compositeproto
  compositeproto_LICENSE += REDIST_OK
  compositeproto_PKGCONFIG += lib/pkgconfig/compositeproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += damageproto
  damageproto_LICENSE += REDIST_OK
  damageproto_PKGCONFIG += lib/pkgconfig/damageproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += fixesproto
  fixesproto_LICENSE += REDIST_OK
  fixesproto_PKGCONFIG += lib/pkgconfig/fixesproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += randrproto
  randrproto_LICENSE += REDIST_OK
  randrproto_PKGCONFIG += lib/pkgconfig/randrproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += renderproto
  renderproto_LICENSE += REDIST_OK
  renderproto_PKGCONFIG += lib/pkgconfig/renderproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += evieext
  evieext_LICENSE += REDIST_OK
  evieext_PKGCONFIG += lib/pkgconfig/evieext.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xineramaproto
  xineramaproto_LICENSE += REDIST_OK
  xineramaproto_PKGCONFIG += lib/pkgconfig/xineramaproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += glproto
  glproto_LICENSE += REDIST_OK
  glproto_PKGCONFIG += lib/pkgconfig/glproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86driproto
  xf86driproto_LICENSE += REDIST_OK
  xf86driproto_PKGCONFIG += lib/pkgconfig/xf86driproto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += pthread-stubs
  pthread-stubs_LICENSE += REDIST_OK
  pthread-stubs_TOOL_DEPENDENCIES := autoconf automake
  pthread-stubs_FORCE_BUILD_TAGS += AUTORECONF
  pthread-stubs_PKGCONFIG += lib/pkgconfig/pthread-stubs.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xcb-proto
  xcb-proto_TOOL_DEPENDENCIES += Python
  xcb-proto_LICENSE += REDIST_OK
  xcb-proto_PKGCONFIG += lib/pkgconfig/xcb-proto.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += dri2proto
  dri2proto_LICENSE += REDIST_OK
  dri2proto_PKGCONFIG += lib/pkgconfig/dri2proto.pc

  # Libdrm (for xorg)

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libdrm
  libdrm_LICENSE += REDIST_OK

  libdrm_TOOL_DEPENDENCIES += pkg-config

  libdrm_BUILD_DEPENDENCIES := pthread-stubs

  libdrm_PRE_CONFIGURE_STEPS = sed < $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3/configure > $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3/configure-2 's/hardcode_libdir_flag_spec=$$$$lt_hardcode_libdir_flag_spec/hardcode_libdir_flag_spec=/'; mv $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3/configure-2 $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3/configure; chmod 755 $($1_TARGETFS_WORK)/$(call TargetFS_Build_Dir,$3 $4 $6)/$3/configure

  libdrm_INSTALLABLE_minimal += lib/libdrm.so.2.4.0
  libdrm_INSTALLABLE_minimal += lib/libdrm.so.2
  libdrm_INSTALLABLE_minimal += lib/libdrm.so
  libdrm_INSTALLABLE_minimal += lib/libdrm_intel.so.1.0.0
  libdrm_INSTALLABLE_minimal += lib/libdrm_intel.so.1
  libdrm_INSTALLABLE_minimal += lib/libdrm_intel.so

  libdrm_PKGCONFIG += lib/pkgconfig/libdrm.pc

  # Xorg Libraries

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xtrans
  xtrans_LICENSE += REDIST_OK
  xtrans_PKGCONFIG += lib/pkgconfig/xtrans.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXau
  libXau_LICENSE += REDIST_OK

  libXau_BUILD_DEPENDENCIES := xproto

  libXau_INSTALLABLE_minimal += lib/libXau.so.6.0.0
  libXau_INSTALLABLE_minimal += lib/libXau.so.6
  libXau_INSTALLABLE_minimal += lib/libXau.so
  libXau_PKGCONFIG += lib/pkgconfig/xau.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXdmcp
  libXdmcp_LICENSE += REDIST_OK
  libXdmcp_BUILD_DEPENDENCIES := xproto
  libXdmcp_INSTALLABLE_minimal += lib/libXdmcp.so.6.0.0
  libXdmcp_INSTALLABLE_minimal += lib/libXdmcp.so.6
  libXdmcp_INSTALLABLE_minimal += lib/libXdmcp.so
  libXdmcp_PKGCONFIG += lib/pkgconfig/xdmcp.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libxcb
  libxcb_LICENSE += REDIST_OK
  libxcb_TOOL_DEPENDENCIES := Python libtool
  libxcb_BUILD_DEPENDENCIES := xproto pthread-stubs xcb-proto libXau libXdmcp
  libxcb_INSTALLABLE_minimal += lib/libxcb.so.1.1.0
  libxcb_INSTALLABLE_minimal += lib/libxcb.so.1
  libxcb_INSTALLABLE_minimal += lib/libxcb.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-composite.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-composite.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-composite.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-damage.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-damage.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-damage.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-dpms.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-dpms.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-dpms.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-glx.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-glx.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-glx.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-randr.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-randr.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-randr.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-record.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-record.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-record.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-render.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-render.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-render.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-res.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-res.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-res.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-screensaver.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-screensaver.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-screensaver.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-shape.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-shape.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-shape.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-shm.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-shm.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-shm.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-sync.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-sync.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-sync.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xevie.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xevie.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xevie.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xf86dri.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xf86dri.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xf86dri.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xfixes.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xfixes.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xfixes.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xinerama.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xinerama.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xinerama.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xprint.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xprint.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xprint.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xtest.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xtest.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xtest.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xv.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xv.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xv.so
  libxcb_INSTALLABLE_minimal += lib/libxcb-xvmc.so.0.0.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xvmc.so.0
  libxcb_INSTALLABLE_minimal += lib/libxcb-xvmc.so

  libxcb_PKGCONFIG += lib/pkgconfig/xcb.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-composite.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-damage.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-dpms.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-glx.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-randr.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-record.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-render.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-res.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-screensaver.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-shape.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-shm.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-sync.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xevie.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xf86dri.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xfixes.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xinerama.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xprint.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xtest.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xv.pc
  libxcb_PKGCONFIG += lib/pkgconfig/xcb-xvmc.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libX11
  libX11_LICENSE += REDIST_OK
  libX11_TOOL_DEPENDENCIES := util-macros autoconf automake pkg-config
  libX11_BUILD_DEPENDENCIES := xproto xextproto inputproto kbproto xf86bigfontproto pthread-stubs xtrans libXau libXdmcp libxcb

  libX11_RUNTIME_DEPENDENCIES := libxcb libdl libc libXau ld

  libX11_FORCE_BUILD_TAGS += MALLOC0RETURNSNULL AUTORECONF

  libX11_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  libX11_AUTORECONF_ENV += ACLOCAL="aclocal -I $$($1_xtrans_STAGE)/share/aclocal"

  libX11_INSTALLABLE_minimal += lib/libX11.so.6.2.0
  libX11_INSTALLABLE_minimal += lib/libX11.so.6
  libX11_INSTALLABLE_minimal += lib/libX11.so
  libX11_INSTALLABLE_minimal += lib/libX11-xcb.so.1.0.0
  libX11_INSTALLABLE_minimal += lib/libX11-xcb.so.1
  libX11_INSTALLABLE_minimal += lib/libX11-xcb.so
  libX11_INSTALLABLE_minimal += share/X11/XKeysymDB
  libX11_INSTALLABLE_minimal += share/X11/XErrorDB
  libX11_INSTALLABLE_minimal += share/X11/locale/am_ET.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/am_ET.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/am_ET.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/armscii-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/armscii-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/armscii-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/C/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/C/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/C/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/el_GR.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/el_GR.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/el_GR.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/en_US.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/en_US.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/en_US.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-academy/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-academy/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-academy/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-ps/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-ps/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/georgian-ps/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ibm-cp1133/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ibm-cp1133/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ibm-cp1133/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iscii-dev/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iscii-dev/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iscii-dev/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/isiri-3342/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/isiri-3342/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/isiri-3342/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-1/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-1/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-1/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-10/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-10/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-10/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-11/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-11/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-11/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-13/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-13/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-13/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-14/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-14/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-14/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-15/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-15/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-15/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-2/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-2/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-2/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-3/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-3/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-3/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-4/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-4/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-4/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-5/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-5/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-5/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-6/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-6/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-6/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-7/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-7/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-7/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9e/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9e/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/iso8859-9e/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.JIS/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.JIS/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.JIS/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja_JP.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja_JP.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja_JP.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.S90/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.S90/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.S90/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.SJIS/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.SJIS/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.SJIS/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.U90/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.U90/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ja.U90/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ko/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ko/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ko/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-c/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-c/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-c/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-r/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-r/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-r/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-u/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-u/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/koi8-u/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/ko_KR.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/ko_KR.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/ko_KR.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1251/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1251/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1251/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1255/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1255/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1255/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1256/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1256/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/microsoft-cp1256/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/mulelao-1/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/mulelao-1/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/mulelao-1/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/nokhchi-1/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/nokhchi-1/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/nokhchi-1/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/pt_BR.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/pt_BR.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/pt_BR.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/tatar-cyr/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/tatar-cyr/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/tatar-cyr/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/th_TH.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/tscii-0/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/tscii-0/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/tscii-0/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.tcvn/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.tcvn/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.tcvn/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.viscii/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.viscii/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/vi_VN.viscii/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gb18030/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gb18030/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gb18030/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gbk/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gbk/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.gbk/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_CN.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5hkscs/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5hkscs/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.big5hkscs/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_HK.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.big5/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.big5/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.big5/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.UTF-8/XI18N_OBJS
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.UTF-8/XLC_LOCALE
  libX11_INSTALLABLE_minimal += share/X11/locale/zh_TW.UTF-8/Compose
  libX11_INSTALLABLE_minimal += share/X11/locale/locale.alias
  libX11_INSTALLABLE_minimal += share/X11/locale/locale.dir
  libX11_INSTALLABLE_minimal += share/X11/locale/compose.dir

  libX11_PKGCONFIG += lib/pkgconfig/x11.pc
  libX11_PKGCONFIG += lib/pkgconfig/x11-xcb.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libfontenc
  libfontenc_LICENSE += REDIST_OK
  libfontenc_BUILD_DEPENDENCIES := xproto zlib

  libfontenc_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CFLAGS="-I$$($1_zlib_STAGE)/include"

  libfontenc_INSTALLABLE_minimal += lib/libfontenc.so.1.0.0
  libfontenc_INSTALLABLE_minimal += lib/libfontenc.so.1
  libfontenc_INSTALLABLE_minimal += lib/libfontenc.so

  libfontenc_PKGCONFIG += lib/pkgconfig/fontenc.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXfont
  libXfont_LICENSE += REDIST_OK
  libXfont_BUILD_DEPENDENCIES := zlib freetype fontsproto xtrans libfontenc xproto
  libXfont_RUNTIME_DEPENDENCIES := zlib

  libXfont_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CFLAGS="-I$$($1_zlib_STAGE)/include" LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib"

  libXfont_INSTALLABLE_minimal += lib/libXfont.so.1.4.1
  libXfont_INSTALLABLE_minimal += lib/libXfont.so.1
  libXfont_INSTALLABLE_minimal += lib/libXfont.so

  libXfont_PKGCONFIG += lib/pkgconfig/xfont.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libxkbfile
  libxkbfile_LICENSE += REDIST_OK
  libxkbfile_BUILD_DEPENDENCIES := xproto kbproto pthread-stubs libX11 libXau libXdmcp libxcb

  libxkbfile_INSTALLABLE_minimal += lib/libxkbfile.so.1.0.2
  libxkbfile_INSTALLABLE_minimal += lib/libxkbfile.so.1
  libxkbfile_INSTALLABLE_minimal += lib/libxkbfile.so

  libxkbfile_PKGCONFIG += lib/pkgconfig/xkbfile.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXrender
  libXrender_LICENSE += REDIST_OK
  libXrender_BUILD_DEPENDENCIES := xproto renderproto libX11 kbproto pthread-stubs libXau libXdmcp libxcb

  libXrender_FORCE_BUILD_TAGS += MALLOC0RETURNSNULL 

  libXrender_INSTALLABLE_minimal += lib/libXrender.so.1.3.0
  libXrender_INSTALLABLE_minimal += lib/libXrender.so.1
  libXrender_INSTALLABLE_minimal += lib/libXrender.so

  libXrender_PKGCONFIG += lib/pkgconfig/xrender.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libICE
  libICE_LICENSE += REDIST_OK
  libICE_BUILD_DEPENDENCIES := xproto xtrans

  libICE_INSTALLABLE_minimal += lib/libICE.so.6.3.0
  libICE_INSTALLABLE_minimal += lib/libICE.so.6
  libICE_INSTALLABLE_minimal += lib/libICE.so

  libICE_PKGCONFIG += lib/pkgconfig/ice.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libSM
  libSM_LICENSE += REDIST_OK
  libSM_BUILD_DEPENDENCIES := xproto xtrans libICE

  libSM_CONFIGURE_ARGS = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --without-libuuid

  libSM_INSTALLABLE_minimal += lib/libSM.so.6.0.0
  libSM_INSTALLABLE_minimal += lib/libSM.so.6
  libSM_INSTALLABLE_minimal += lib/libSM.so

  libSM_PKGCONFIG += lib/pkgconfig/sm.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXt
  libXt_LICENSE += REDIST_OK
  libXt_BUILD_DEPENDENCIES := xproto kbproto pthread-stubs libXau libXdmcp libxcb libX11 libICE libSM

  libXt_RUNTIME_DEPENDENCIES := libSM

  libXt_FORCE_BUILD_TAGS += MALLOC0RETURNSNULL 

  libXt_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  libXt_INSTALLABLE_minimal += lib/libXt.so.6.0.0
  libXt_INSTALLABLE_minimal += lib/libXt.so.6
  libXt_INSTALLABLE_minimal += lib/libXt.so

  libXt_PKGCONFIG += lib/pkgconfig/xt.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libpciaccess
  libpciaccess_LICENSE += REDIST_OK

  libpciaccess_FORCE_BUILD_TAGS += AUTORECONF

  libpciaccess_TOOL_DEPENDENCIES := autoconf automake pkg-config

  libpciaccess_INSTALLABLE_minimal += lib/libpciaccess.so.0.10.2
  libpciaccess_INSTALLABLE_minimal += lib/libpciaccess.so.0
  libpciaccess_INSTALLABLE_minimal += lib/libpciaccess.so

  libpciaccess_PKGCONFIG += lib/pkgconfig/pciaccess.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXext
  libXext_LICENSE += REDIST_OK

  libXext_BUILD_DEPENDENCIES := xproto xextproto kbproto pthread-stubs libXau libXdmcp libxcb libX11

  libXext_FORCE_BUILD_TAGS += MALLOC0RETURNSNULL 

  libXext_INSTALLABLE_minimal += lib/libXext.so.6.4.0
  libXext_INSTALLABLE_minimal += lib/libXext.so.6
  libXext_INSTALLABLE_minimal += lib/libXext.so

  libXext_PKGCONFIG += lib/pkgconfig/xext.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXxf86vm
  libXxf86vm_LICENSE += REDIST_OK

  libXxf86vm_BUILD_DEPENDENCIES := xproto xextproto kbproto xf86vidmodeproto pthread-stubs libXau libXdmcp libxcb libX11 libXext

  libXxf86vm_RUNTIME_DEPENDENCIES := libX11 libXext

  libXxf86vm_FORCE_BUILD_TAGS += MALLOC0RETURNSNULL 

  libXxf86vm_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  libXxf86vm_INSTALLABLE_minimal += lib/libXxf86vm.so.1.0.0
  libXxf86vm_INSTALLABLE_minimal += lib/libXxf86vm.so.1
  libXxf86vm_INSTALLABLE_minimal += lib/libXxf86vm.so

  libXxf86vm_PKGCONFIG += lib/pkgconfig/xxf86vm.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXfixes
  libXfixes_LICENSE += REDIST_OK

  libXfixes_BUILD_DEPENDENCIES := xproto xextproto kbproto fixesproto pthread-stubs libXau libXdmcp libxcb libX11

  libXfixes_INSTALLABLE_minimal += lib/libXfixes.so.3.1.0
  libXfixes_INSTALLABLE_minimal += lib/libXfixes.so.3
  libXfixes_INSTALLABLE_minimal += lib/libXfixes.so

  libXfixes_PKGCONFIG += lib/pkgconfig/xfixes.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += libXdamage
  libXdamage_LICENSE += REDIST_OK

  libXdamage_BUILD_DEPENDENCIES := xproto xextproto kbproto damageproto xextproto fixesproto pthread-stubs libXfixes libXau libXdmcp libxcb libX11

  libXdamage_RUNTIME_DEPENDENCIES := libXfixes

  libXdamage_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  libXdamage_INSTALLABLE_minimal += lib/libXdamage.so.1.1.0
  libXdamage_INSTALLABLE_minimal += lib/libXdamage.so.1
  libXdamage_INSTALLABLE_minimal += lib/libXdamage.so

  libXdamage_PKGCONFIG += lib/pkgconfig/xdamage.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += Mesa
  Mesa_LICENSE += GPL

  Mesa_FORCE_BUILD_TAGS += BUILDINSRC AUTORECONF

  Mesa_BUILD_DEPENDENCIES := expat xproto xextproto kbproto xf86vidmodeproto damageproto fixesproto glproto dri2proto pthread-stubs libXau libXdmcp libdrm libxcb libX11 libXext libXxf86vm libXfixes libXdamage

  Mesa_RUNTIME_DEPENDENCIES := expat

  Mesa_CONFIGURE_ARGS = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --enable-xcb --with-driver=dri --disable-glw --disable-glut --disable-gl-osmesa

  Mesa_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CFLAGS="-I$$($1_expat_STAGE)/include" LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  Mesa_INSTALLABLE_minimal += lib/libGL.so
  Mesa_INSTALLABLE_minimal += lib/libGL.so.1
  Mesa_INSTALLABLE_minimal += lib/libGL.so.1.2
  Mesa_INSTALLABLE_minimal += lib/dri/i810_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/i915_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/i965_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/mach64_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/mga_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/r128_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/r200_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/r300_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/radeon_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/sis_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/tdfx_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/trident_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/unichrome_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/ffb_dri.so
  Mesa_INSTALLABLE_minimal += lib/dri/swrast_dri.so
  Mesa_INSTALLABLE_minimal += lib/libGLU.so
  Mesa_INSTALLABLE_minimal += lib/libGLU.so.1
  Mesa_INSTALLABLE_minimal += lib/libGLU.so.1.3.070300

  Mesa_PKGCONFIG += lib/pkgconfig/gl.pc
  Mesa_PKGCONFIG += lib/pkgconfig/dri.pc
  Mesa_PKGCONFIG += lib/pkgconfig/glu.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += pixman
  pixman_LICENSE += GPL

  pixman_TOOL_DEPENDENCIES := pkg-config

  pixman_BUILD_DEPENDENCIES := 

  pixman_INSTALLABLE_minimal += lib/libpixman-1.so.0.14.0
  pixman_INSTALLABLE_minimal += lib/libpixman-1.so.0
  pixman_INSTALLABLE_minimal += lib/libpixman-1.so

  pixman_PKGCONFIG += lib/pkgconfig/pixman-1.pc

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xorg-server
  xorg-server_LICENSE += REDIST_OK

  xorg-server_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) LDFLAGS="-L$($1_TARGETFS_PREFIX)/lib -Wl,-rpath-link=$($1_TARGETFS_PREFIX)/lib -static-libgcc"

  xorg-server_AUTORECONF_ENV += ACLOCAL="aclocal -I $$($1_xtrans_STAGE)/share/aclocal"

  xorg-server_FORCE_BUILD_TAGS += AUTORECONF

  xorg-server_TOOL_DEPENDENCIES += autoconf automake

  xorg-server_BUILD_DEPENDENCIES += openssl freetype zlib expat
  xorg-server_BUILD_DEPENDENCIES += randrproto renderproto fixesproto damageproto xcmiscproto xextproto xproto xtrans bigreqsproto resourceproto fontsproto inputproto kbproto videoproto compositeproto scrnsaverproto 
  xorg-server_BUILD_DEPENDENCIES += libxkbfile libXfont libXau libfontenc libXdmcp Mesa pixman xf86vidmodeproto xf86dgaproto glproto xf86driproto dri2proto libpciaccess libdrm libxcb 
  xorg-server_BUILD_DEPENDENCIES += libX11 libXext pthread-stubs libXfixes libXrender libXdamage libXxf86vm libICE libSM libXt 

  xorg-server_CONFIGURE_ARGS = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --disable-xinerama --enable-xorg

  xorg-server_INSTALLABLE_minimal += lib/xorg/protocol.txt
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/bt829_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/fi1236_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/msp3430_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/tda8425_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/tda9850_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/tda9885_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/multimedia/uda1380_drv.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libint10.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/linux/libfbdevhw.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libshadowfb.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libvbe.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libvgahw.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libxaa.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libxf8_16bpp.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/extensions/libextmod.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/extensions/libdbe.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/extensions/libglx.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/extensions/libdri.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/extensions/libdri2.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libfb.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libwfb.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libshadow.so
  xorg-server_INSTALLABLE_minimal += lib/xorg/modules/libexa.so
  xorg-server_INSTALLABLE_minimal += lib/X11/Options
  xorg-server_INSTALLABLE_minimal += bin/gtf
  xorg-server_INSTALLABLE_minimal += bin/cvt
  xorg-server_INSTALLABLE_minimal += bin/Xorg
  xorg-server_INSTALLABLE_minimal += bin/X
  xorg-server_INSTALLABLE_minimal += bin/Xvfb

  xorg-server_INSTALLABLE_full += bin/Xnest

  xorg-server_PKGCONFIG += lib/pkgconfig/xorg-server.pc

  xorg-server_RUNTIME_DEPENDENCIES += libm libc ld libdl libpthread librt
  xorg-server_RUNTIME_DEPENDENCIES += dev/tty0
  xorg-server_RUNTIME_DEPENDENCIES += var/log
  xorg-server_RUNTIME_DEPENDENCIES += libdrm libfontenc libpciaccess pixman openssl libXau libXdmcp libXfont zlib
  xorg-server_RUNTIME_DEPENDENCIES += freetype

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += xf86-video-vmware
  xf86-video-vmware_LICENSE += REDIST_OK

  xf86-video-vmware_AUTORECONF_ENV += ACLOCAL="aclocal -I $$($1_xorg-server_STAGE)/share/aclocal"
  xf86-video-vmware_FORCE_BUILD_TAGS += AUTORECONF

  xf86-video-vmware_TOOL_DEPENDENCIES += autoconf automake

  xf86-video-vmware_BUILD_DEPENDENCIES += xproto xextproto fontsproto inputproto videoproto randrproto renderproto xineramaproto libpciaccess pixman xorg-server

  xf86-video-vmware_RUNTIME_DEPENDENCIES += xorg-server

  xf86-video-vmware_INSTALLABLE_minimal += lib/xorg/modules/drivers/vmware_drv.so

  # Linux Trace Toolkit
  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += TraceToolkit

  TraceToolkit_LICENSE += GPL
  TraceToolkit_RUNTIME_DEPENDENCIES += ld libc libpthread

  TraceToolkit_BUILD_ENVIRONMENT = $($1_TARGETFS_BUILD_ENV) CC=$($1_TARGETFS_TUPLE)-gcc GCC=$($1_TARGETFS_TUPLE)-gcc SUBDIRS="LibLTT LibUserTrace Daemon"
  TraceToolkit_CONFIGURE_ARGS    = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE) --without-gtk --without-rtai --with-gnu-ld --disable-target-native

  TraceToolkit_INSTALLABLE_minimal := 
  TraceToolkit_INSTALLABLE_minimal += lib/libltt-0.9.so.6.0.0
  TraceToolkit_INSTALLABLE_minimal += lib/libltt-0.9.so.6
  TraceToolkit_INSTALLABLE_minimal += lib/libltt.so
  TraceToolkit_INSTALLABLE_minimal += lib/libltt.la
  TraceToolkit_INSTALLABLE_minimal += lib/libltt.a
  TraceToolkit_INSTALLABLE_minimal += lib/libusertrace-0.9.so.6.0.0
  TraceToolkit_INSTALLABLE_minimal += lib/libusertrace-0.9.so.6
  TraceToolkit_INSTALLABLE_minimal += lib/libusertrace.so
  TraceToolkit_INSTALLABLE_minimal += lib/libusertrace.la
  TraceToolkit_INSTALLABLE_minimal += lib/libusertrace.a
  TraceToolkit_INSTALLABLE_minimal += bin/trace
  TraceToolkit_INSTALLABLE_minimal += bin/tracecore
  TraceToolkit_INSTALLABLE_minimal += bin/tracecpuid
  TraceToolkit_INSTALLABLE_minimal += bin/traceu
  TraceToolkit_INSTALLABLE_minimal += bin/tracedaemon
  TraceToolkit_INSTALLABLE_minimal += bin/traceanalyze
  TraceToolkit_INSTALLABLE_minimal += bin/tracedcore
  TraceToolkit_INSTALLABLE_minimal += bin/tracedump
  TraceToolkit_INSTALLABLE_minimal += bin/traceview
  TraceToolkit_INSTALLABLE_minimal += bin/tracevisualizer

  # Bash
  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += bash

  bash_LICENSE += GPL

  bash_RUNTIME_DEPENDENCIES += dev/console
  bash_RUNTIME_DEPENDENCIES += dev/ptmx
  bash_RUNTIME_DEPENDENCIES += ld
  bash_RUNTIME_DEPENDENCIES += libc
  bash_RUNTIME_DEPENDENCIES += libm
  bash_RUNTIME_DEPENDENCIES += libdl
  bash_RUNTIME_DEPENDENCIES += libcrypt

  bash_INSTALLABLE_minimal := 
  bash_INSTALLABLE_minimal += bin/bash
  bash_INSTALLABLE_minimal += share/locale/en@quot
  bash_INSTALLABLE_minimal += share/locale/en@quot/LC_MESSAGES
  bash_INSTALLABLE_minimal += share/locale/en@quot/LC_MESSAGES/bash.mo
  bash_INSTALLABLE_minimal += share/locale/en@boldquot
  bash_INSTALLABLE_minimal += share/locale/en@boldquot/LC_MESSAGES
  bash_INSTALLABLE_minimal += share/locale/en@boldquot/LC_MESSAGES/bash.mo

  # Strace
  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += strace

  strace_LICENSE += REDIST_OK

  strace_RUNTIME_DEPENDENCIES += dev/console
  strace_RUNTIME_DEPENDENCIES += dev/ptmx
  strace_RUNTIME_DEPENDENCIES += ld
  strace_RUNTIME_DEPENDENCIES += libc
  strace_RUNTIME_DEPENDENCIES += libm
  strace_RUNTIME_DEPENDENCIES += libdl
  strace_RUNTIME_DEPENDENCIES += libcrypt

  strace_INSTALLABLE_minimal := 
  strace_INSTALLABLE_minimal += bin/strace
  strace_INSTALLABLE_minimal += bin/strace-graph

  # prngd

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += prngd

  prngd_LICENSE += REDIST_OK

  # SSH

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += openssh

  openssh_LICENSE += REDIST_OK

  openssh_BUILD_DEPENDENCIES := zlib

  openssh_CONFIGURE_ARGS  = --prefix=$(if $(filter NOSTAGE,$4),$($1_TARGETFS_PREFIX),/) --build=$(HOST_TUPLE) --host=$($1_TARGETFS_TUPLE)
  openssh_CONFIGURE_ARGS += --with-zlib=$$($1_zlib_STAGE)
  openssh_CONFIGURE_ARGS += --with-ssl-dir=$$($1_openssl_STAGE)

  openssh_RUNTIME_DEPENDENCIES += dev/null
  openssh_RUNTIME_DEPENDENCIES += dev/urandom
  openssh_RUNTIME_DEPENDENCIES += dev/random
  openssh_RUNTIME_DEPENDENCIES += libnsl
  openssh_RUNTIME_DEPENDENCIES += libnss_files
  openssh_RUNTIME_DEPENDENCIES += libresolv
  openssh_RUNTIME_DEPENDENCIES += libutil
  openssh_RUNTIME_DEPENDENCIES += libc
  openssh_RUNTIME_DEPENDENCIES += libcrypt
  oepnssh_RUNTIME_DEPENDENCIES += zlib

  openssh_INSTALLABLE_minimal := 
  openssh_INSTALLABLE_minimal += share/Ssh.bin
  openssh_INSTALLABLE_minimal += bin/ssh
  openssh_INSTALLABLE_minimal += bin/scp
  openssh_INSTALLABLE_minimal += bin/ssh-add
  openssh_INSTALLABLE_minimal += bin/ssh-agent
  openssh_INSTALLABLE_minimal += bin/ssh-keygen
  openssh_INSTALLABLE_minimal += bin/ssh-keyscan
  openssh_INSTALLABLE_minimal += bin/sftp
  openssh_INSTALLABLE_minimal += sbin/sshd
  openssh_INSTALLABLE_minimal += libexec/ssh-keysign
  openssh_INSTALLABLE_minimal += libexec/sftp-server
  openssh_INSTALLABLE_minimal += etc/ssh_config
  openssh_INSTALLABLE_minimal += etc/sshd_config
  openssh_INSTALLABLE_minimal += etc/moduli

  # util-linux

  CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES += util-linux

  util-linux_LICENSE += GPL

  util-linux_RUNTIME_DEPENDENCIES += libc

  util-linux_INSTALLABLE_minimal := 
  util-linux_INSTALLABLE_minimal += bin/mount

  # fix-embedded-paths

  CONFIGURE_TOOLS_KNOWN_MAKE_MODULES += fix-embedded-paths

  fix-embedded-paths_LICENSE += GPL

  fix-embedded-paths_INSTALLABLE_minimal += bin/fix-embedded-paths

  # Busybox

  CONFIGURE_TOOLS_KNOWN_MAKE_MODULES += busybox

  busybox_LICENSE += GPL

  BUSYBOX_ARCHMAP_x86    := i686-%-linux-gnu
  BUSYBOX_ARCHMAP_mipsel := mipsel-%-linux-gnu

  Busybox_Arch = $(sort $(foreach arch,$(patsubst BUSYBOX_ARCHMAP_%,%,$(filter BUSYBOX_ARCHMAP%,$(.VARIABLES))),$(if $(filter $(BUSYBOX_ARCHMAP_$(arch)),$1),$(arch))))

  busybox_MAKE_ARGS  = CROSS_COMPILE=$($1_TARGETFS_TUPLE)-
  busybox_MAKE_ARGS += ARCH=$(call Fontconfig_Arch,$($1_TARGETFS_TUPLE))
  busybox_MAKE_ARGS += V=1

  busybox_MAKE_INSTALL_ARGS  = CROSS_COMPILE=$($1_TARGETFS_TUPLE)-
  busybox_MAKE_INSTALL_ARGS += ARCH=$(call Fontconfig_Arch,$($1_TARGETFS_TUPLE))
  busybox_MAKE_INSTALL_ARGS += V=1
  busybox_MAKE_INSTALL_ARGS += install

  busybox_POST_INSTALL_STEPS += cd $3$4/_install && find . | cpio -aplmdu $5

  busybox_RUNTIME_DEPENDENCIES += dev/console
  busybox_RUNTIME_DEPENDENCIES += dev/ptmx
  busybox_RUNTIME_DEPENDENCIES += dev/null
  busybox_RUNTIME_DEPENDENCIES += dev/tty
  busybox_RUNTIME_DEPENDENCIES += dev/urandom
  busybox_RUNTIME_DEPENDENCIES += proc
  busybox_RUNTIME_DEPENDENCIES += etc/localtime
  busybox_RUNTIME_DEPENDENCIES += ld
  busybox_RUNTIME_DEPENDENCIES += libc
  busybox_RUNTIME_DEPENDENCIES += libm
  busybox_RUNTIME_DEPENDENCIES += libdl
  busybox_RUNTIME_DEPENDENCIES += libcrypt

  busybox_INSTALLABLE_BASIC := 
  busybox_INSTALLABLE_BASIC += sbin/setlogcons
  busybox_INSTALLABLE_BASIC += sbin/sulogin
  busybox_INSTALLABLE_BASIC += sbin/readprofile
  busybox_INSTALLABLE_BASIC += sbin/telnetd
  busybox_INSTALLABLE_BASIC += sbin/watchdog
  busybox_INSTALLABLE_BASIC += sbin/halt
  busybox_INSTALLABLE_BASIC += sbin/zcip
  busybox_INSTALLABLE_BASIC += sbin/runlevel
  busybox_INSTALLABLE_BASIC += sbin/fakeidentd
  busybox_INSTALLABLE_BASIC += sbin/ifconfig
  busybox_INSTALLABLE_BASIC += sbin/hwclock
  busybox_INSTALLABLE_BASIC += sbin/rmmod
  busybox_INSTALLABLE_BASIC += sbin/start-stop-daemon
  busybox_INSTALLABLE_BASIC += sbin/freeramdisk
  busybox_INSTALLABLE_BASIC += sbin/init
  busybox_INSTALLABLE_BASIC += sbin/fdisk
  busybox_INSTALLABLE_BASIC += sbin/swapon
  busybox_INSTALLABLE_BASIC += sbin/udhcpc
  busybox_INSTALLABLE_BASIC += sbin/lsmod
  busybox_INSTALLABLE_BASIC += sbin/reboot
  busybox_INSTALLABLE_BASIC += sbin/ifup
  busybox_INSTALLABLE_BASIC += sbin/udhcpd
  busybox_INSTALLABLE_BASIC += sbin/sysctl
  busybox_INSTALLABLE_BASIC += sbin/poweroff
  busybox_INSTALLABLE_BASIC += sbin/mkfs.minix
  busybox_INSTALLABLE_BASIC += sbin/nameif
  busybox_INSTALLABLE_BASIC += sbin/makedevs
  busybox_INSTALLABLE_BASIC += sbin/rdate
  busybox_INSTALLABLE_BASIC += sbin/mkswap
  busybox_INSTALLABLE_BASIC += sbin/klogd
  busybox_INSTALLABLE_BASIC += sbin/fsck.minix
  busybox_INSTALLABLE_BASIC += sbin/inetd
  busybox_INSTALLABLE_BASIC += sbin/ifdown
  busybox_INSTALLABLE_BASIC += sbin/chroot
  busybox_INSTALLABLE_BASIC += sbin/losetup
  busybox_INSTALLABLE_BASIC += sbin/fsck
  busybox_INSTALLABLE_BASIC += sbin/vconfig
  busybox_INSTALLABLE_BASIC += sbin/loadkmap
  busybox_INSTALLABLE_BASIC += sbin/dnsd
  busybox_INSTALLABLE_BASIC += sbin/httpd
  busybox_INSTALLABLE_BASIC += sbin/logread
  busybox_INSTALLABLE_BASIC += sbin/fbset
  busybox_INSTALLABLE_BASIC += sbin/insmod
  busybox_INSTALLABLE_BASIC += sbin/raidautorun
  busybox_INSTALLABLE_BASIC += sbin/getty
  busybox_INSTALLABLE_BASIC += sbin/setconsole
  busybox_INSTALLABLE_BASIC += sbin/mdev
  busybox_INSTALLABLE_BASIC += sbin/crond
  busybox_INSTALLABLE_BASIC += sbin/pivot_root
  busybox_INSTALLABLE_BASIC += sbin/arp
  busybox_INSTALLABLE_BASIC += sbin/switch_root
  busybox_INSTALLABLE_BASIC += sbin/modprobe
  busybox_INSTALLABLE_BASIC += sbin/route
  busybox_INSTALLABLE_BASIC += sbin/hdparm
  busybox_INSTALLABLE_BASIC += sbin/adjtimex
  busybox_INSTALLABLE_BASIC += sbin/swapoff
  busybox_INSTALLABLE_BASIC += sbin/dhcprelay
  busybox_INSTALLABLE_BASIC += sbin/syslogd
  busybox_INSTALLABLE_BASIC += bin/cpio
  busybox_INSTALLABLE_BASIC += bin/mount
  busybox_INSTALLABLE_BASIC += bin/cmp
  busybox_INSTALLABLE_BASIC += bin/yes
  busybox_INSTALLABLE_BASIC += bin/free
  busybox_INSTALLABLE_BASIC += bin/awk
  busybox_INSTALLABLE_BASIC += bin/pwd
  busybox_INSTALLABLE_BASIC += bin/addgroup
  busybox_INSTALLABLE_BASIC += bin/dd
  busybox_INSTALLABLE_BASIC += bin/sync
  busybox_INSTALLABLE_BASIC += bin/df
  busybox_INSTALLABLE_BASIC += bin/mt
  busybox_INSTALLABLE_BASIC += bin/hostname
  busybox_INSTALLABLE_BASIC += bin/mktemp
  busybox_INSTALLABLE_BASIC += bin/dmesg
  busybox_INSTALLABLE_BASIC += bin/sha1sum
  busybox_INSTALLABLE_BASIC += bin/uncompress
  busybox_INSTALLABLE_BASIC += bin/fdflush
  busybox_INSTALLABLE_BASIC += bin/dc
  busybox_INSTALLABLE_BASIC += bin/sleep
  busybox_INSTALLABLE_BASIC += bin/id
  busybox_INSTALLABLE_BASIC += bin/mv
  busybox_INSTALLABLE_BASIC += bin/cp
  busybox_INSTALLABLE_BASIC += bin/od
  busybox_INSTALLABLE_BASIC += bin/test
  busybox_INSTALLABLE_BASIC += bin/bunzip2
  busybox_INSTALLABLE_BASIC += bin/ar
  busybox_INSTALLABLE_BASIC += bin/unzip
  busybox_INSTALLABLE_BASIC += bin/stty
  busybox_INSTALLABLE_BASIC += bin/resize
  busybox_INSTALLABLE_BASIC += bin/setarch
  busybox_INSTALLABLE_BASIC += bin/ftpput
  busybox_INSTALLABLE_BASIC += bin/uname
  busybox_INSTALLABLE_BASIC += bin/setkeycodes
  busybox_INSTALLABLE_BASIC += bin/pidof
  busybox_INSTALLABLE_BASIC += bin/length
  busybox_INSTALLABLE_BASIC += bin/mesg
  busybox_INSTALLABLE_BASIC += bin/nohup
  busybox_INSTALLABLE_BASIC += bin/rm
  busybox_INSTALLABLE_BASIC += bin/nc
  busybox_INSTALLABLE_BASIC += bin/uptime
  busybox_INSTALLABLE_BASIC += bin/gzip
  busybox_INSTALLABLE_BASIC += bin/grep
  busybox_INSTALLABLE_BASIC += bin/mkfifo
  busybox_INSTALLABLE_BASIC += bin/vlock
  busybox_INSTALLABLE_BASIC += bin/netstat
  busybox_INSTALLABLE_BASIC += bin/hexdump
  busybox_INSTALLABLE_BASIC += bin/tr
  busybox_INSTALLABLE_BASIC += bin/login
  busybox_INSTALLABLE_BASIC += bin/rmdir
  busybox_INSTALLABLE_BASIC += bin/expr
  busybox_INSTALLABLE_BASIC += bin/[[
  busybox_INSTALLABLE_BASIC += bin/whoami
  busybox_INSTALLABLE_BASIC += bin/md5sum
  busybox_INSTALLABLE_BASIC += bin/ed
  busybox_INSTALLABLE_BASIC += bin/loadfont
  busybox_INSTALLABLE_BASIC += bin/lsattr
  busybox_INSTALLABLE_BASIC += bin/diff
  busybox_INSTALLABLE_BASIC += bin/uuencode
  busybox_INSTALLABLE_BASIC += bin/logger
  busybox_INSTALLABLE_BASIC += bin/rpm
  busybox_INSTALLABLE_BASIC += bin/envdir
  busybox_INSTALLABLE_BASIC += bin/bzcat
  busybox_INSTALLABLE_BASIC += bin/rx
  busybox_INSTALLABLE_BASIC += bin/traceroute
  busybox_INSTALLABLE_BASIC += bin/logname
  busybox_INSTALLABLE_BASIC += bin/kill
  busybox_INSTALLABLE_BASIC += bin/less
  busybox_INSTALLABLE_BASIC += bin/run-parts
  busybox_INSTALLABLE_BASIC += bin/clear
  busybox_INSTALLABLE_BASIC += bin/linux64
  busybox_INSTALLABLE_BASIC += bin/dirname
  busybox_INSTALLABLE_BASIC += bin/stat
  busybox_INSTALLABLE_BASIC += bin/crontab
  busybox_INSTALLABLE_BASIC += bin/ls
  busybox_INSTALLABLE_BASIC += bin/echo
  busybox_INSTALLABLE_BASIC += bin/reset
  busybox_INSTALLABLE_BASIC += bin/killall5
  busybox_INSTALLABLE_BASIC += bin/arping
  busybox_INSTALLABLE_BASIC += bin/touch
  busybox_INSTALLABLE_BASIC += bin/ftpget
  busybox_INSTALLABLE_BASIC += bin/mknod
  busybox_INSTALLABLE_BASIC += bin/readlink
  busybox_INSTALLABLE_BASIC += bin/tar
  busybox_INSTALLABLE_BASIC += bin/chattr
  busybox_INSTALLABLE_BASIC += bin/top
  busybox_INSTALLABLE_BASIC += bin/softlimit
  busybox_INSTALLABLE_BASIC += bin/killall
  busybox_INSTALLABLE_BASIC += bin/umount
  busybox_INSTALLABLE_BASIC += bin/printenv
  busybox_INSTALLABLE_BASIC += bin/sum
  busybox_INSTALLABLE_BASIC += bin/getopt
  busybox_INSTALLABLE_BASIC += bin/su
  busybox_INSTALLABLE_BASIC += bin/cal
  busybox_INSTALLABLE_BASIC += bin/false
  busybox_INSTALLABLE_BASIC += bin/setsid
  busybox_INSTALLABLE_BASIC += bin/uniq
  busybox_INSTALLABLE_BASIC += bin/find
  busybox_INSTALLABLE_BASIC += bin/last
  busybox_INSTALLABLE_BASIC += bin/cut
  busybox_INSTALLABLE_BASIC += bin/env
  busybox_INSTALLABLE_BASIC += bin/fgrep
  busybox_INSTALLABLE_BASIC += bin/passwd
  busybox_INSTALLABLE_BASIC += bin/xargs
  busybox_INSTALLABLE_BASIC += bin/linux32
  busybox_INSTALLABLE_BASIC += bin/pipe_progress
  busybox_INSTALLABLE_BASIC += bin/time
  busybox_INSTALLABLE_BASIC += bin/hostid
  busybox_INSTALLABLE_BASIC += bin/dos2unix
  busybox_INSTALLABLE_BASIC += bin/gunzip
  busybox_INSTALLABLE_BASIC += bin/fuser
  busybox_INSTALLABLE_BASIC += bin/ipcrm
  busybox_INSTALLABLE_BASIC += bin/deallocvt
  busybox_INSTALLABLE_BASIC += bin/eject
  busybox_INSTALLABLE_BASIC += bin/chvt
  busybox_INSTALLABLE_BASIC += bin/basename
  busybox_INSTALLABLE_BASIC += bin/bbconfig
  busybox_INSTALLABLE_BASIC += bin/wget
  busybox_INSTALLABLE_BASIC += bin/unix2dos
  busybox_INSTALLABLE_BASIC += bin/ipcs
  busybox_INSTALLABLE_BASIC += bin/install
  busybox_INSTALLABLE_BASIC += bin/which
  busybox_INSTALLABLE_BASIC += bin/nice
  busybox_INSTALLABLE_BASIC += bin/chown
  busybox_INSTALLABLE_BASIC += bin/strings
  busybox_INSTALLABLE_BASIC += bin/fold
  busybox_INSTALLABLE_BASIC += bin/seq
  busybox_INSTALLABLE_BASIC += bin/cksum
  busybox_INSTALLABLE_BASIC += bin/unlzma
  busybox_INSTALLABLE_BASIC += bin/mountpoint
  busybox_INSTALLABLE_BASIC += bin/renice
  busybox_INSTALLABLE_BASIC += bin/ping
  busybox_INSTALLABLE_BASIC += bin/uudecode
  busybox_INSTALLABLE_BASIC += bin/ipcalc
  busybox_INSTALLABLE_BASIC += bin/rpm2cpio
  busybox_INSTALLABLE_BASIC += bin/comm
  busybox_INSTALLABLE_BASIC += bin/head
  busybox_INSTALLABLE_BASIC += bin/tee
  busybox_INSTALLABLE_BASIC += bin/watch
  busybox_INSTALLABLE_BASIC += bin/nmeter
  busybox_INSTALLABLE_BASIC += bin/chmod
  busybox_INSTALLABLE_BASIC += bin/usleep
  busybox_INSTALLABLE_BASIC += bin/tftp
  busybox_INSTALLABLE_BASIC += bin/setuidgid
  busybox_INSTALLABLE_BASIC += bin/dumpkmap
  busybox_INSTALLABLE_BASIC += bin/vi
  busybox_INSTALLABLE_BASIC += bin/dumpleases
  busybox_INSTALLABLE_BASIC += bin/envuidgid
  busybox_INSTALLABLE_BASIC += bin/tail
  busybox_INSTALLABLE_BASIC += bin/chgrp
  busybox_INSTALLABLE_BASIC += bin/lzmacat
  busybox_INSTALLABLE_BASIC += bin/who
  busybox_INSTALLABLE_BASIC += bin/[
  busybox_INSTALLABLE_BASIC += bin/wc
  busybox_INSTALLABLE_BASIC += bin/printf
  busybox_INSTALLABLE_BASIC += bin/delgroup
  busybox_INSTALLABLE_BASIC += bin/ln
  busybox_INSTALLABLE_BASIC += bin/fdformat
  busybox_INSTALLABLE_BASIC += bin/egrep
  busybox_INSTALLABLE_BASIC += bin/mkdir
  busybox_INSTALLABLE_BASIC += bin/telnet
  busybox_INSTALLABLE_BASIC += bin/tty
  busybox_INSTALLABLE_BASIC += bin/cat
  busybox_INSTALLABLE_BASIC += bin/more
  busybox_INSTALLABLE_BASIC += bin/true
  busybox_INSTALLABLE_BASIC += bin/catv
  busybox_INSTALLABLE_BASIC += bin/sort
  busybox_INSTALLABLE_BASIC += bin/openvt
  busybox_INSTALLABLE_BASIC += bin/realpath
  busybox_INSTALLABLE_BASIC += bin/sed
  busybox_INSTALLABLE_BASIC += bin/adduser
  busybox_INSTALLABLE_BASIC += bin/deluser
  busybox_INSTALLABLE_BASIC += bin/busybox
  busybox_INSTALLABLE_BASIC += bin/zcat
  busybox_INSTALLABLE_BASIC += bin/du
  busybox_INSTALLABLE_BASIC += bin/chpst
  busybox_INSTALLABLE_BASIC += bin/nslookup
  busybox_INSTALLABLE_BASIC += bin/date
  busybox_INSTALLABLE_BASIC += bin/patch
  busybox_INSTALLABLE_BASIC += bin/ps

  busybox_INSTALLABLE_NOUTIL := 
  busybox_INSTALLABLE_NOUTIL += sbin/setlogcons
  busybox_INSTALLABLE_NOUTIL += sbin/sulogin
  busybox_INSTALLABLE_NOUTIL += sbin/readprofile
  busybox_INSTALLABLE_NOUTIL += sbin/telnetd
  busybox_INSTALLABLE_NOUTIL += sbin/watchdog
  busybox_INSTALLABLE_NOUTIL += sbin/halt
  busybox_INSTALLABLE_NOUTIL += sbin/zcip
  busybox_INSTALLABLE_NOUTIL += sbin/runlevel
  busybox_INSTALLABLE_NOUTIL += sbin/fakeidentd
  busybox_INSTALLABLE_NOUTIL += sbin/ifconfig
  busybox_INSTALLABLE_NOUTIL += sbin/hwclock
  busybox_INSTALLABLE_NOUTIL += sbin/rmmod
  busybox_INSTALLABLE_NOUTIL += sbin/start-stop-daemon
  busybox_INSTALLABLE_NOUTIL += sbin/freeramdisk
  busybox_INSTALLABLE_NOUTIL += sbin/init
  busybox_INSTALLABLE_NOUTIL += sbin/fdisk
  busybox_INSTALLABLE_NOUTIL += sbin/swapon
  busybox_INSTALLABLE_NOUTIL += sbin/udhcpc
  busybox_INSTALLABLE_NOUTIL += sbin/lsmod
  busybox_INSTALLABLE_NOUTIL += sbin/reboot
  busybox_INSTALLABLE_NOUTIL += sbin/ifup
  busybox_INSTALLABLE_NOUTIL += sbin/udhcpd
  busybox_INSTALLABLE_NOUTIL += sbin/sysctl
  busybox_INSTALLABLE_NOUTIL += sbin/poweroff
  busybox_INSTALLABLE_NOUTIL += sbin/mkfs.minix
  busybox_INSTALLABLE_NOUTIL += sbin/nameif
  busybox_INSTALLABLE_NOUTIL += sbin/makedevs
  busybox_INSTALLABLE_NOUTIL += sbin/rdate
  busybox_INSTALLABLE_NOUTIL += sbin/mkswap
  busybox_INSTALLABLE_NOUTIL += sbin/klogd
  busybox_INSTALLABLE_NOUTIL += sbin/fsck.minix
  busybox_INSTALLABLE_NOUTIL += sbin/inetd
  busybox_INSTALLABLE_NOUTIL += sbin/ifdown
  busybox_INSTALLABLE_NOUTIL += sbin/chroot
  busybox_INSTALLABLE_NOUTIL += sbin/losetup
  busybox_INSTALLABLE_NOUTIL += sbin/fsck
  busybox_INSTALLABLE_NOUTIL += sbin/vconfig
  busybox_INSTALLABLE_NOUTIL += sbin/loadkmap
  busybox_INSTALLABLE_NOUTIL += sbin/dnsd
  busybox_INSTALLABLE_NOUTIL += sbin/httpd
  busybox_INSTALLABLE_NOUTIL += sbin/logread
  busybox_INSTALLABLE_NOUTIL += sbin/fbset
  busybox_INSTALLABLE_NOUTIL += sbin/insmod
  busybox_INSTALLABLE_NOUTIL += sbin/raidautorun
  busybox_INSTALLABLE_NOUTIL += sbin/getty
  busybox_INSTALLABLE_NOUTIL += sbin/setconsole
  busybox_INSTALLABLE_NOUTIL += sbin/mdev
  busybox_INSTALLABLE_NOUTIL += sbin/crond
  busybox_INSTALLABLE_NOUTIL += sbin/pivot_root
  busybox_INSTALLABLE_NOUTIL += sbin/arp
  busybox_INSTALLABLE_NOUTIL += sbin/switch_root
  busybox_INSTALLABLE_NOUTIL += sbin/modprobe
  busybox_INSTALLABLE_NOUTIL += sbin/route
  busybox_INSTALLABLE_NOUTIL += sbin/hdparm
  busybox_INSTALLABLE_NOUTIL += sbin/adjtimex
  busybox_INSTALLABLE_NOUTIL += sbin/swapoff
  busybox_INSTALLABLE_NOUTIL += sbin/dhcprelay
  busybox_INSTALLABLE_NOUTIL += sbin/syslogd
  busybox_INSTALLABLE_NOUTIL += bin/cpio
  busybox_INSTALLABLE_NOUTIL += bin/cmp
  busybox_INSTALLABLE_NOUTIL += bin/yes
  busybox_INSTALLABLE_NOUTIL += bin/free
  busybox_INSTALLABLE_NOUTIL += bin/awk
  busybox_INSTALLABLE_NOUTIL += bin/pwd
  busybox_INSTALLABLE_NOUTIL += bin/addgroup
  busybox_INSTALLABLE_NOUTIL += bin/dd
  busybox_INSTALLABLE_NOUTIL += bin/sync
  busybox_INSTALLABLE_NOUTIL += bin/df
  busybox_INSTALLABLE_NOUTIL += bin/mt
  busybox_INSTALLABLE_NOUTIL += bin/hostname
  busybox_INSTALLABLE_NOUTIL += bin/mktemp
  busybox_INSTALLABLE_NOUTIL += bin/dmesg
  busybox_INSTALLABLE_NOUTIL += bin/sha1sum
  busybox_INSTALLABLE_NOUTIL += bin/uncompress
  busybox_INSTALLABLE_NOUTIL += bin/fdflush
  busybox_INSTALLABLE_NOUTIL += bin/dc
  busybox_INSTALLABLE_NOUTIL += bin/sleep
  busybox_INSTALLABLE_NOUTIL += bin/id
  busybox_INSTALLABLE_NOUTIL += bin/mv
  busybox_INSTALLABLE_NOUTIL += bin/cp
  busybox_INSTALLABLE_NOUTIL += bin/od
  busybox_INSTALLABLE_NOUTIL += bin/test
  busybox_INSTALLABLE_NOUTIL += bin/bunzip2
  busybox_INSTALLABLE_NOUTIL += bin/ar
  busybox_INSTALLABLE_NOUTIL += bin/unzip
  busybox_INSTALLABLE_NOUTIL += bin/stty
  busybox_INSTALLABLE_NOUTIL += bin/resize
  busybox_INSTALLABLE_NOUTIL += bin/setarch
  busybox_INSTALLABLE_NOUTIL += bin/ftpput
  busybox_INSTALLABLE_NOUTIL += bin/uname
  busybox_INSTALLABLE_NOUTIL += bin/setkeycodes
  busybox_INSTALLABLE_NOUTIL += bin/pidof
  busybox_INSTALLABLE_NOUTIL += bin/length
  busybox_INSTALLABLE_NOUTIL += bin/mesg
  busybox_INSTALLABLE_NOUTIL += bin/nohup
  busybox_INSTALLABLE_NOUTIL += bin/rm
  busybox_INSTALLABLE_NOUTIL += bin/nc
  busybox_INSTALLABLE_NOUTIL += bin/uptime
  busybox_INSTALLABLE_NOUTIL += bin/gzip
  busybox_INSTALLABLE_NOUTIL += bin/grep
  busybox_INSTALLABLE_NOUTIL += bin/mkfifo
  busybox_INSTALLABLE_NOUTIL += bin/vlock
  busybox_INSTALLABLE_NOUTIL += bin/netstat
  busybox_INSTALLABLE_NOUTIL += bin/hexdump
  busybox_INSTALLABLE_NOUTIL += bin/tr
  busybox_INSTALLABLE_NOUTIL += bin/login
  busybox_INSTALLABLE_NOUTIL += bin/rmdir
  busybox_INSTALLABLE_NOUTIL += bin/expr
  busybox_INSTALLABLE_NOUTIL += bin/[[
  busybox_INSTALLABLE_NOUTIL += bin/whoami
  busybox_INSTALLABLE_NOUTIL += bin/md5sum
  busybox_INSTALLABLE_NOUTIL += bin/ed
  busybox_INSTALLABLE_NOUTIL += bin/loadfont
  busybox_INSTALLABLE_NOUTIL += bin/lsattr
  busybox_INSTALLABLE_NOUTIL += bin/diff
  busybox_INSTALLABLE_NOUTIL += bin/uuencode
  busybox_INSTALLABLE_NOUTIL += bin/logger
  busybox_INSTALLABLE_NOUTIL += bin/rpm
  busybox_INSTALLABLE_NOUTIL += bin/envdir
  busybox_INSTALLABLE_NOUTIL += bin/bzcat
  busybox_INSTALLABLE_NOUTIL += bin/rx
  busybox_INSTALLABLE_NOUTIL += bin/traceroute
  busybox_INSTALLABLE_NOUTIL += bin/logname
  busybox_INSTALLABLE_NOUTIL += bin/kill
  busybox_INSTALLABLE_NOUTIL += bin/less
  busybox_INSTALLABLE_NOUTIL += bin/run-parts
  busybox_INSTALLABLE_NOUTIL += bin/clear
  busybox_INSTALLABLE_NOUTIL += bin/linux64
  busybox_INSTALLABLE_NOUTIL += bin/dirname
  busybox_INSTALLABLE_NOUTIL += bin/stat
  busybox_INSTALLABLE_NOUTIL += bin/crontab
  busybox_INSTALLABLE_NOUTIL += bin/ls
  busybox_INSTALLABLE_NOUTIL += bin/echo
  busybox_INSTALLABLE_NOUTIL += bin/reset
  busybox_INSTALLABLE_NOUTIL += bin/killall5
  busybox_INSTALLABLE_NOUTIL += bin/arping
  busybox_INSTALLABLE_NOUTIL += bin/touch
  busybox_INSTALLABLE_NOUTIL += bin/ftpget
  busybox_INSTALLABLE_NOUTIL += bin/mknod
  busybox_INSTALLABLE_NOUTIL += bin/readlink
  busybox_INSTALLABLE_NOUTIL += bin/tar
  busybox_INSTALLABLE_NOUTIL += bin/chattr
  busybox_INSTALLABLE_NOUTIL += bin/top
  busybox_INSTALLABLE_NOUTIL += bin/softlimit
  busybox_INSTALLABLE_NOUTIL += bin/killall
  busybox_INSTALLABLE_NOUTIL += bin/umount
  busybox_INSTALLABLE_NOUTIL += bin/printenv
  busybox_INSTALLABLE_NOUTIL += bin/sum
  busybox_INSTALLABLE_NOUTIL += bin/getopt
  busybox_INSTALLABLE_NOUTIL += bin/su
  busybox_INSTALLABLE_NOUTIL += bin/cal
  busybox_INSTALLABLE_NOUTIL += bin/false
  busybox_INSTALLABLE_NOUTIL += bin/setsid
  busybox_INSTALLABLE_NOUTIL += bin/uniq
  busybox_INSTALLABLE_NOUTIL += bin/find
  busybox_INSTALLABLE_NOUTIL += bin/last
  busybox_INSTALLABLE_NOUTIL += bin/cut
  busybox_INSTALLABLE_NOUTIL += bin/env
  busybox_INSTALLABLE_NOUTIL += bin/fgrep
  busybox_INSTALLABLE_NOUTIL += bin/passwd
  busybox_INSTALLABLE_NOUTIL += bin/xargs
  busybox_INSTALLABLE_NOUTIL += bin/linux32
  busybox_INSTALLABLE_NOUTIL += bin/pipe_progress
  busybox_INSTALLABLE_NOUTIL += bin/time
  busybox_INSTALLABLE_NOUTIL += bin/hostid
  busybox_INSTALLABLE_NOUTIL += bin/dos2unix
  busybox_INSTALLABLE_NOUTIL += bin/gunzip
  busybox_INSTALLABLE_NOUTIL += bin/fuser
  busybox_INSTALLABLE_NOUTIL += bin/ipcrm
  busybox_INSTALLABLE_NOUTIL += bin/deallocvt
  busybox_INSTALLABLE_NOUTIL += bin/eject
  busybox_INSTALLABLE_NOUTIL += bin/chvt
  busybox_INSTALLABLE_NOUTIL += bin/basename
  busybox_INSTALLABLE_NOUTIL += bin/bbconfig
  busybox_INSTALLABLE_NOUTIL += bin/wget
  busybox_INSTALLABLE_NOUTIL += bin/unix2dos
  busybox_INSTALLABLE_NOUTIL += bin/ipcs
  busybox_INSTALLABLE_NOUTIL += bin/install
  busybox_INSTALLABLE_NOUTIL += bin/which
  busybox_INSTALLABLE_NOUTIL += bin/nice
  busybox_INSTALLABLE_NOUTIL += bin/chown
  busybox_INSTALLABLE_NOUTIL += bin/strings
  busybox_INSTALLABLE_NOUTIL += bin/fold
  busybox_INSTALLABLE_NOUTIL += bin/seq
  busybox_INSTALLABLE_NOUTIL += bin/cksum
  busybox_INSTALLABLE_NOUTIL += bin/unlzma
  busybox_INSTALLABLE_NOUTIL += bin/mountpoint
  busybox_INSTALLABLE_NOUTIL += bin/renice
  busybox_INSTALLABLE_NOUTIL += bin/ping
  busybox_INSTALLABLE_NOUTIL += bin/uudecode
  busybox_INSTALLABLE_NOUTIL += bin/ipcalc
  busybox_INSTALLABLE_NOUTIL += bin/rpm2cpio
  busybox_INSTALLABLE_NOUTIL += bin/comm
  busybox_INSTALLABLE_NOUTIL += bin/head
  busybox_INSTALLABLE_NOUTIL += bin/tee
  busybox_INSTALLABLE_NOUTIL += bin/watch
  busybox_INSTALLABLE_NOUTIL += bin/nmeter
  busybox_INSTALLABLE_NOUTIL += bin/chmod
  busybox_INSTALLABLE_NOUTIL += bin/usleep
  busybox_INSTALLABLE_NOUTIL += bin/tftp
  busybox_INSTALLABLE_NOUTIL += bin/setuidgid
  busybox_INSTALLABLE_NOUTIL += bin/dumpkmap
  busybox_INSTALLABLE_NOUTIL += bin/vi
  busybox_INSTALLABLE_NOUTIL += bin/dumpleases
  busybox_INSTALLABLE_NOUTIL += bin/envuidgid
  busybox_INSTALLABLE_NOUTIL += bin/tail
  busybox_INSTALLABLE_NOUTIL += bin/chgrp
  busybox_INSTALLABLE_NOUTIL += bin/lzmacat
  busybox_INSTALLABLE_NOUTIL += bin/who
  busybox_INSTALLABLE_NOUTIL += bin/[
  busybox_INSTALLABLE_NOUTIL += bin/wc
  busybox_INSTALLABLE_NOUTIL += bin/printf
  busybox_INSTALLABLE_NOUTIL += bin/delgroup
  busybox_INSTALLABLE_NOUTIL += bin/ln
  busybox_INSTALLABLE_NOUTIL += bin/fdformat
  busybox_INSTALLABLE_NOUTIL += bin/egrep
  busybox_INSTALLABLE_NOUTIL += bin/mkdir
  busybox_INSTALLABLE_NOUTIL += bin/telnet
  busybox_INSTALLABLE_NOUTIL += bin/tty
  busybox_INSTALLABLE_NOUTIL += bin/cat
  busybox_INSTALLABLE_NOUTIL += bin/more
  busybox_INSTALLABLE_NOUTIL += bin/true
  busybox_INSTALLABLE_NOUTIL += bin/catv
  busybox_INSTALLABLE_NOUTIL += bin/sort
  busybox_INSTALLABLE_NOUTIL += bin/openvt
  busybox_INSTALLABLE_NOUTIL += bin/realpath
  busybox_INSTALLABLE_NOUTIL += bin/sed
  busybox_INSTALLABLE_NOUTIL += bin/adduser
  busybox_INSTALLABLE_NOUTIL += bin/deluser
  busybox_INSTALLABLE_NOUTIL += bin/busybox
  busybox_INSTALLABLE_NOUTIL += bin/zcat
  busybox_INSTALLABLE_NOUTIL += bin/du
  busybox_INSTALLABLE_NOUTIL += bin/chpst
  busybox_INSTALLABLE_NOUTIL += bin/nslookup
  busybox_INSTALLABLE_NOUTIL += bin/date
  busybox_INSTALLABLE_NOUTIL += bin/patch
  busybox_INSTALLABLE_NOUTIL += bin/ps

  busybox_INSTALLABLE_SH += bin/sh

  CONFIGURE_TOOLS_KNOWN_MODULES := $(strip $(CONFIGURE_TOOLS_KNOWN_AUTOCONF_MODULES) $(CONFIGURE_TOOLS_KNOWN_MAKE_MODULES) $(CONFIGURE_TOOLS_KNOWN_SRC_PLUGINS))



endif
