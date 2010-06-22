# -*- makefile -*-		self-replicate-config.mk
# dave@crossplex.org		Fri Nov  6 12:25:32 2009

# Specify Host build tools used for Davix
$(eval $(call Configure_TargetFS,localhost/sr-build-tools,$(BUILD_TOP),localhost/sr-build-tools PATH,STRIP LDD))

$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,termcap-1.3.1 pkg-config-0.23 Python-2.6.1 autoconf-2.64 libtool-2.2.4 automake-1.11,NOSTAGE NODESTDIR))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,nasm-2.07,BUILDINSRC NOSTAGE NODESTDIR))
$(eval $(call TargetFS_Install_Make,localhost/sr-build-tools,syslinux-3.83 cdrtools-2.01.01a75,,default))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,qemu-0.12.4,,minimal))

SELFREP_BUILD_PATH          := $(call Toolchain_Path,host-tools):$(PATH)
SELFREP_TOOLCHAIN_VERSIONS  := binutils-2.20 gcc-4.2.0 glibc-2.5 linux-2.6.28.7 gdb-6.8
SELFREP_TOOLCHAIN_FLAGS     := THREAD=nptl ENDIAN=l MMU=y FLOAT=hard
SELFREP_TOOLCHAIN_PATCHTAGS := selfreptc

# Specify Toolchain for Selfrep
$(eval $(call Glibc_Toolchain,$(BUILD_TOP),selfrep-glibc,i686-selfrep-linux-gnu,$(SELFREP_TOOLCHAIN_VERSIONS),localhost/sr-build-tools PATH,$(SELFREP_TOOLCHAIN_FLAGS),$(SELFREP_TOOLCHAIN_PATCHTAGS)))

# Specify the Selfrep initramfs filesystem
$(eval $(call Configure_TargetFS,selfrep/initramfs,$(BUILD_TOP),localhost/sr-build-tools selfrep-glibc/toolchain PATH,STRIP LDD))

SELFREP_BUSYBOX    += busybox-1.4.0

# Configure the release version of selfrep/initramfs
$(eval $(call TargetFS_Template,selfrep/initramfs,$(shell pwd)/fs-template/INITRAMFS))
$(eval $(call TargetFS_Install_Make,selfrep/initramfs,$(SELFREP_BUSYBOX),RELEASE,BASIC SH))

SELFREP_INITRAMFS_TARGETFS_NAME := selfrep/initramfs

$(sort $(dir $(call Complete_Targetfs_Target_List,$(SELFREP_INITRAMFS_TARGETFS_NAME)))): $(call Complete_Targetfs_Target_List,$(SELFREP_INITRAMFS_TARGETFS_NAME))

SELFREP_KERNEL_INITRAMFS_ROOT := $(call Targetfs_Prefix_Of,$(SELFREP_INITRAMFS_TARGETFS_NAME))

SELFREP_KERNEL_DEPENDENCIES   := $(call Complete_Targetfs_Target_List,$(SELFREP_INITRAMFS_TARGETFS_NAME)) | $(sort $(dir $(call Complete_Targetfs_Target_List,$(SELFREP_INITRAMFS_TARGETFS_NAME))))

SELFREP_LINUX_VERSION := linux-2.6.28.7

$(eval $(call Build_Linux_Kernel,selfrep/linux,$(SELFREP_LINUX_VERSION),$(BUILD_TOP),$(SELFREP_KERNEL_INITRAMFS_ROOT),,$(SELFREP_KERNEL_DEPENDENCIES),localhost/sr-build-tools selfrep-glibc/toolchain PATH,,,selfrep))

$(eval $(call VMDX_Kit,selfrep,localhost/sr-build-tools,selfrep/linux,/path/to/bogus/rootfs,$(BUILD_TOP)))

sbvmdx: $(selfrep/VMDX_FILENAME)
