# -*- makefile -*-		simple-davix-config.mk
# dave@crossplex.org		Fri Nov  6 12:25:32 2009

# Specify Host build tools used for Davix
$(eval $(call Configure_TargetFS,localhost/build-tools,$(BUILD_TOP),localhost/build-tools PATH,STRIP LDD))

$(eval $(call TargetFS_Install_Autoconf,localhost/build-tools,termcap-1.3.1 pkg-config-0.23 Python-2.6.1 autoconf-2.64 libtool-2.2.4 automake-1.11,NOSTAGE NODESTDIR))
$(eval $(call TargetFS_Install_Autoconf,localhost/build-tools,nasm-2.07,BUILDINSRC NOSTAGE NODESTDIR))
$(eval $(call TargetFS_Install_Make,localhost/build-tools,syslinux-3.83 cdrtools-2.01.01a75,,default))

DAVIX_BUILD_PATH          := $(call Toolchain_Path,host-tools):$(PATH)
DAVIX_TOOLCHAIN_VERSIONS  := binutils-2.20 gcc-4.2.0 glibc-2.5 linux-2.6.28.7 gdb-6.8
#DAVIX_TOOLCHAIN_VERSIONS  := binutils-2.20 gcc-4.4.1 glibc-2.10.1 linux-2.6.28.7 gdb-7.0
DAVIX_TOOLCHAIN_FLAGS     := THREAD=nptl ENDIAN=l MMU=y FLOAT=hard
DAVIX_TOOLCHAIN_PATCHTAGS := davixtc

# Specify Toolchain for Davix
$(eval $(call Glibc_Toolchain,$(BUILD_TOP),davix-glibc,i686-davix-linux-gnu,$(DAVIX_TOOLCHAIN_VERSIONS),localhost/build-tools PATH,$(DAVIX_TOOLCHAIN_FLAGS),$(DAVIX_TOOLCHAIN_PATCHTAGS)))

# Specify the Davix initramfs filesystem
$(eval $(call Configure_TargetFS,davix/initramfs,$(BUILD_TOP),localhost/build-tools davix-glibc/toolchain PATH,STRIP LDD))

DAVIX_BUSYBOX    += busybox-1.4.0

# Configure the release version of davix/initramfs
$(eval $(call TargetFS_Template,davix/initramfs,$(shell pwd)/fs-template/INITRAMFS))
$(eval $(call TargetFS_Install_Make,davix/initramfs,$(DAVIX_BUSYBOX),RELEASE,BASIC SH))

DAVIX_INITRAMFS_TARGETFS_NAME := davix/initramfs

$(sort $(dir $(call Complete_Targetfs_Target_List,$(DAVIX_INITRAMFS_TARGETFS_NAME)))): $(call Complete_Targetfs_Target_List,$(DAVIX_INITRAMFS_TARGETFS_NAME))

DAVIX_KERNEL_INITRAMFS_ROOT := $(call Targetfs_Prefix_Of,$(DAVIX_INITRAMFS_TARGETFS_NAME))

DAVIX_KERNEL_DEPENDENCIES   := $(call Complete_Targetfs_Target_List,$(DAVIX_INITRAMFS_TARGETFS_NAME)) | $(sort $(dir $(call Complete_Targetfs_Target_List,$(DAVIX_INITRAMFS_TARGETFS_NAME))))

DAVIX_LINUX_VERSION := linux-2.6.28.7

$(eval $(call Build_Linux_Kernel,davix/linux,$(DAVIX_LINUX_VERSION),$(BUILD_TOP),$(DAVIX_KERNEL_INITRAMFS_ROOT),,$(DAVIX_KERNEL_DEPENDENCIES),localhost/build-tools davix-glibc/toolchain PATH,,,davix))

$(eval $(call LiveCD_Kit,davix/vmware-iso,localhost/build-tools,davix/linux,$(BUILD_TOP)))

vmware: $(davix/vmware-iso_ISO_FILENAME)
