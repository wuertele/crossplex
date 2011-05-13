# -*- makefile -*-		simple-udavix-config.mk
# dave@crossplex.org		Fri Nov  6 12:25:32 2009

# Specify Host build tools used for Udavix
$(eval $(call Configure_TargetFS,localhost/ubuild-tools,$(BUILD_TOP),localhost/ubuild-tools PATH,STRIP LDD))

$(eval $(call TargetFS_Install_Autoconf,localhost/ubuild-tools,termcap-1.3.1))
#$(eval $(call TargetFS_Install_Autoconf,localhost/ubuild-tools,gmp-4.3.1,NOSTAGE UNIQBUILD NODESTDIR))
#$(eval $(call TargetFS_Install_Autoconf,localhost/ubuild-tools,mpfr-2.4.2,NOSTAGE UNIQBUILD NODESTDIR))
$(eval $(call TargetFS_Install_Make,localhost/ubuild-tools,syslinux-3.83 cdrtools-3.00,,default))

UDAVIX_TOOLCHAIN_VERSIONS  := binutils-2.19.1 gcc-4.3.2 gmp-4.3.1 mpfr-2.4.2 uClibc-0.9.30.1 linux-2.6.31.12 gdb-6.8
# dmalloc-5.5.2
# duma_2_5_15
# ncurses-5.7
# strace-4.5.19
UDAVIX_TOOLCHAIN_FLAGS     := THREAD=nptl ENDIAN=l MMU=y FLOAT=hard
UDAVIX_TOOLCHAIN_PATCHTAGS := udavixtc-mips

# Specify Toolchain for Udavix
$(eval $(call Uclibc_Toolchain,$(BUILD_TOP),davix-uclibc,mipsel-davix-linux-uclibc,$(UDAVIX_TOOLCHAIN_VERSIONS),localhost/ubuild-tools PATH,$(UDAVIX_TOOLCHAIN_FLAGS),$(UDAVIX_TOOLCHAIN_PATCHTAGS)))

utest: $(davix-uclibc/toolchain_TARGETFS_TARGETS)

# Specify the Udavix initramfs filesystem
$(eval $(call Configure_TargetFS,udavix/initramfs,$(BUILD_TOP),localhost/ubuild-tools davix-uclibc/toolchain PATH,STRIP LDD))

UDAVIX_BUSYBOX += busybox-1.16.1

# Configure the release version of udavix/initramfs
$(eval $(call TargetFS_Template,udavix/initramfs,$(shell pwd)/fs-template/INITRAMFS))
$(eval $(call TargetFS_Install_Make,udavix/initramfs,$(UDAVIX_BUSYBOX),RELEASE,BASIC SH,mips))

UDAVIX_INITRAMFS_TARGETFS_NAME := udavix/initramfs

$(sort $(dir $(call Complete_Targetfs_Target_List,$(UDAVIX_INITRAMFS_TARGETFS_NAME)))): $(call Complete_Targetfs_Target_List,$(UDAVIX_INITRAMFS_TARGETFS_NAME))

UDAVIX_KERNEL_INITRAMFS_ROOT := $(call Targetfs_Prefix_Of,$(UDAVIX_INITRAMFS_TARGETFS_NAME))

UDAVIX_KERNEL_DEPENDENCIES   := $(call Complete_Targetfs_Target_List,$(UDAVIX_INITRAMFS_TARGETFS_NAME)) | $(sort $(dir $(call Complete_Targetfs_Target_List,$(UDAVIX_INITRAMFS_TARGETFS_NAME))))

UDAVIX_LINUX_VERSION := linux-2.6.31.12

$(eval $(call Build_Linux_Kernel,udavix/linux,$(UDAVIX_LINUX_VERSION),$(BUILD_TOP),$(UDAVIX_KERNEL_INITRAMFS_ROOT),,$(UDAVIX_KERNEL_DEPENDENCIES),localhost/ubuild-tools davix-uclibc/toolchain PATH,,,udavixtc-mips))

udlinux: udavix/linux-kernel-compressed-image
