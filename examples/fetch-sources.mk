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
HTTP_PROXY := "http://wwwgate0.mot.com:1080/"
FTP_PROXY  := "http://wwwgate0.mot.com:1080/"
DOWNLOADER_ENV := HTTP_PROXY=$(HTTP_PROXY) FTP_PROXY=$(FTP_PROXY)

# $1 = path to package
# $2 = URL of original file
define Download_Package

  $1:
	mkdir -p $$(@D)
	cd $$(@D) && http_proxy=$(HTTP_PROXY) ftp_proxy=$(FTP_PROXY) wget $2

endef

$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/Python-2.6.1.tar.bz2,http://www.python.org/ftp/python/2.6.1/Python-2.6.1.tgz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/busybox-1.4.0.tar.bz2,http://busybox.net/downloads/busybox-1.4.0.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gcc-4.2.0.tar.bz2,http://ftp.gnu.org/gnu/gcc/gcc-4.2.0/gcc-4.2.0.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/linux-2.6.28.7.tar.bz2,http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.28.7.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-ports-2.5.tar.bz2,http://ftp.gnu.org/gnu/glibc/glibc-ports-2.5.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-linuxthreads-2.5.tar.bz2,http://ftp.gnu.org/gnu/glibc/GPL/glibc-linuxthreads-2.5.tar.bz2))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/glibc-2.5.tar.gz,http://ftp.gnu.org/gnu/glibc/GPL/glibc-2.5.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/autoconf-2.64.tar.gz,http://ftp.gnu.org/gnu/autoconf/autoconf-2.64.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/automake-1.11.tar.gz,http://ftp.gnu.org/gnu/automake/automake-1.11.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/binutils-2.20.tar.gz,http://ftp.gnu.org/gnu/binutils/binutils-2.20.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/gdb-6.8.tar.gz,http://ftp.gnu.org/gnu/gdb/gdb-6.8.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/libtool-2.2.4.tar.gz,http://ftp.gnu.org/gnu/libtool/libtool-2.2.4.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/pkg-config-0.23.tar.gz,http://pkg-config.freedesktop.org/releases/pkg-config-0.23.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/syslinux-3.83.tar.gz,ftp://ftp.kernel.org/pub/linux/utils/boot/syslinux/syslinux-3.83.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/GPL/termcap-1.3.1.tar.gz,ftp://ftp.gnu.org/gnu/termcap/termcap-1.3.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/nasm-2.07.tar.gz,http://www.nasm.us/pub/nasm/releasebuilds/2.07/nasm-2.07.tar.gz))
$(eval $(call Download_Package,$(THIRD_PARTY)/REDIST_OK/cdrtools-2.01.01a75.tar.gz,ftp://ftp.berlios.de/pub/cdrecord/alpha/cdrtools-2.01.01a75.tar.gz))

