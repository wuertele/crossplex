# -*- makefile -*-		fetch-sources.mk

# dave@rokulabs.com		Thu Feb  4 07:12:45 2010
# Steal This Program!!!

# Normally, embedded systems will be created on the basis of a closed
# source control system, without the benefit of dynamic download of
# third-party sources.  However, for this example, we will define some
# sources that are available and use wget to fetch them into the
# appropriate third party sources directory.

# Uncomment the following three lines if you are behind a web proxy.
# Of course, make sure the URLs for the HTTP and FTP proxies are correct.
#HTTP_PROXY := "http://myproxy.com:1080/"
#FTP_PROXY  := "http://myproxy.com:1080/"

# $1 = path to package
# $2 = URL of original file
define Download_Package

  $1:
	mkdir -p $$(@D)
	cd $$(@D) && http_proxy=$(HTTP_PROXY) ftp_proxy=$(FTP_PROXY) wget $2

endef

$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/autoconf-2.64.tar.gz,http://ftp.gnu.org/gnu/autoconf/autoconf-2.64.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/automake-1.11.tar.gz,http://ftp.gnu.org/gnu/automake/automake-1.11.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/binutils-2.19.1.tar.gz,http://ftp.gnu.org/gnu/binutils/binutils-2.19.1.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/binutils-2.20.tar.gz,http://ftp.gnu.org/gnu/binutils/binutils-2.20.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/busybox-1.16.1.tar.bz2,http://busybox.net/downloads/busybox-1.16.1.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/busybox-1.4.0.tar.bz2,http://busybox.net/downloads/busybox-1.4.0.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gcc-4.2.0.tar.bz2,http://ftp.gnu.org/gnu/gcc/gcc-4.2.0/gcc-4.2.0.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gcc-4.3.2.tar.bz2,http://ftp.gnu.org/gnu/gcc/gcc-4.3.2/gcc-4.3.2.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gdb-6.8.tar.gz,http://ftp.gnu.org/gnu/gdb/gdb-6.8.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-2.5.tar.gz,http://ftp.gnu.org/gnu/glibc/glibc-2.5.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-linuxthreads-2.5.tar.bz2,http://ftp.gnu.org/gnu/glibc/glibc-linuxthreads-2.5.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-ports-2.5.tar.bz2,http://ftp.gnu.org/gnu/glibc/glibc-ports-2.5.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/libtool-2.2.4.tar.gz,http://ftp.gnu.org/gnu/libtool/libtool-2.2.4.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/linux-2.6.28.7.tar.bz2,http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.28.7.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/linux-2.6.31.tar.bz2,http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.31.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/linux-2.6.31.12.tar.bz2,http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.31.12.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/pkg-config-0.23.tar.gz,http://pkg-config.freedesktop.org/releases/pkg-config-0.23.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/syslinux-3.83.tar.gz,ftp://ftp.kernel.org/pub/linux/utils/boot/syslinux/3.xx/syslinux-3.83.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/termcap-1.3.1.tar.gz,ftp://ftp.gnu.org/gnu/termcap/termcap-1.3.1.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/Python-2.6.1.tar.bz2,http://www.python.org/ftp/python/2.6.1/Python-2.6.1.tgz))
$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/cdrtools-3.00.tar.bz2,ftp://ftp.berlios.de/pub/cdrecord/cdrtools-3.00.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/nasm-2.07.tar.gz,http://www.nasm.us/pub/nasm/releasebuilds/2.07/nasm-2.07.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/LGPL/uClibc-0.9.30.1.tar.bz2,http://www.uclibc.org/downloads/uClibc-0.9.30.1.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/LGPL/uClibc-0.9.31.tar.bz2,http://www.uclibc.org/downloads/uClibc-0.9.31.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gmp-4.3.1.tar.bz2,ftp://ftp.sunet.se/pub/gnu/gmp/gmp-4.3.1.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/mpfr-2.4.2.tar.bz2,http://www.mpfr.org/mpfr-2.4.2/mpfr-2.4.2.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/qemu-0.12.4.tar.gz,http://download.savannah.gnu.org/releases/qemu/qemu-0.12.4.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/util-linux-2.12r.tar.gz,ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.12/util-linux-2.12r.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/util-linux-2.19.1.tar.bz2,ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.19/util-linux-2.19.1.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/genext2fs-1.4.1.tar.gz,http://downloads.sourceforge.net/project/genext2fs/genext2fs/1.4.1/genext2fs-1.4.1.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/grub-1.96.tar.gz,ftp://alpha.gnu.org/gnu/grub/grub-1.96.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/grub-1.98.tar.gz,ftp://alpha.gnu.org/gnu/grub/grub-1.98.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/e2fsprogs-1.41.12.tar.gz,http://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/1.41.12/e2fsprogs-1.41.12.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/multipath-tools-0.4.9.tar.bz2,http://christophe.varoqui.free.fr/multipath-tools/multipath-tools-0.4.9.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/LGPL/LVM2.2.02.68.tgz,ftp://sources.redhat.com/pub/lvm2/LVM2.2.02.68.tgz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/bash-4.1.tar.gz,ftp://ftp.cwru.edu/pub/bash/bash-4.1.tar.gz))

$(THIRD_PARTY)/LGPL/LVM2-2.02.68.tgz: $(THIRD_PARTY)/LGPL/LVM2.2.02.68.tgz
	cd /tmp && rm -rf LVM2-2.02.68 LVM2.2.02.68 && tar xvzf $< && mv LVM2.2.02.68 LVM2-2.02.68 && tar cvzf $@ LVM2-2.02.68
