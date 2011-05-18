# -*- makefile -*-		self-replicate-config.mk
# dave@crossplex.org		Fri Nov  6 12:25:32 2009

# Specify Host build tools used for selfrep
$(eval $(call Configure_TargetFS,localhost/sr-build-tools,$(BUILD_TOP),localhost/sr-build-tools PATH,STRIP LDD))

$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,termcap-1.3.1 pkg-config-0.23 Python-2.6.1 autoconf-2.64 libtool-2.2.4 automake-1.11,NOSTAGE UNIQBUILD NODESTDIR))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,nasm-2.07,BUILDINSRC NOSTAGE UNIQBUILD NODESTDIR))
$(eval $(call TargetFS_Install_Make,localhost/sr-build-tools,syslinux-3.83 cdrtools-3.00,,default))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,qemu-0.12.4,,minimal))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,util-linux-2.19.1,BUILDINSRC,full))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,grub-1.98,NOSTAGE NODESTDIR))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,e2fsprogs-1.41.12,,basic))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,genext2fs-1.4.1,,minimal))
$(eval $(call TargetFS_Install_Autoconf,localhost/sr-build-tools,LVM2-2.02.68,,minimal))
$(eval $(call TargetFS_Install_Make,localhost/sr-build-tools,multipath-tools-0.4.9,,minimal))

SELFREP_BUILD_PATH          := $(call Toolchain_Path,host-tools):$(PATH)
SELFREP_TOOLCHAIN_VERSIONS  := binutils-2.20 gcc-4.2.0 glibc-2.5 linux-2.6.28.7 gdb-6.8
SELFREP_TOOLCHAIN_FLAGS     := THREAD=nptl ENDIAN=l MMU=y FLOAT=hard
SELFREP_TOOLCHAIN_PATCHTAGS := davixtc

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

# Specify the Selfrep rootfs filesystem
$(eval $(call Configure_TargetFS,selfrep/rootfs,$(BUILD_TOP),localhost/sr-build-tools selfrep-glibc/toolchain PATH,STRIP LDD))

#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,bash-4.1,,minimal)) # todo: get rid of kernel initramfs and use this rootfs
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,binutils-2.20,,basic)) # todo: install binutils files from stage/i686-selfrep-linux-gnu/bin
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Bzip2-1.0.2,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Coreutils-5.0,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Diffutils-2.8,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Findutils-4.1.20,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Gawk-3.0,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,gcc-4.2.0,NOSTAGE))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,glibc-2.5,NOSTAGE))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Grep-2.5,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Gzip-1.2.4,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Make-3.79.1,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Patch-2.5.4,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Sed-3.0.2,,basic))
#$(eval $(call TargetFS_Install_Autoconf,selfrep/rootfs,Tar-1.14,,basic))
# install crossplex
# install perl

# Configure the release version of selfrep/rootfs
$(eval $(call TargetFS_Template,selfrep/rootfs,$(shell pwd)/fs-template/HOME))
$(eval $(call TargetFS_Template,selfrep/rootfs,$(shell pwd)/fs-template/GRUB))

$(eval $(call VMDK_Kit,selfrep,localhost/sr-build-tools,selfrep/linux,selfrep/rootfs,$(BUILD_TOP)))

sbvmdk: $(selfrep/VMDK_FILENAME)
