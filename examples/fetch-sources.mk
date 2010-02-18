# -*- makefile -*-		fetch-sources.mk
# dave@rokulabs.com		Thu Feb  4 07:12:45 2010
# Steal This Program!!!

# Normally, embedded systems will be created on the basis of a closed source control system, 
# without the benefit of dynamic download of third-party sources.  However, for this example,
# we will define some sources that are available and use a perl script to query freshmeat
# for their location and download them into the appropriate third party sources directory.

# The perl script uses the WWW::Freshmeat module, so you should make sure that it works before
# trying this example.  If you want, you can just download these sources manually, and 
# comment out the "include fetch-sources.mk" line in this directory's Makeifle.

BZ_PACKAGES += REDIST_OK/Python-2.6.1.tar.bz2
BZ_PACKAGES += GPL/busybox-1.4.0.tar.bz2
BZ_PACKAGES += GPL/gcc-4.2.0.tar.bz2
BZ_PACKAGES += GPL/linux-2.6.28.7.tar.bz2
BZ_PACKAGES += GPL/glibc-ports-2.5.tar.bz2
BZ_PACKAGES += GPL/glibc-linuxthreads-2.5.tar.bz2

GZ_PACKAGES += GPL/autoconf-2.64.tar.gz
GZ_PACKAGES += GPL/automake-1.11.tar.gz
GZ_PACKAGES += GPL/binutils-2.20.tar.gz
GZ_PACKAGES += GPL/gdb-6.8.tar.gz
GZ_PACKAGES += GPL/glibc-2.5.tar.gz
GZ_PACKAGES += GPL/libtool-2.2.4.tar.gz
GZ_PACKAGES += GPL/pkg-config-0.23.tar.gz
GZ_PACKAGES += GPL/syslinux-3.83.tar.gz
GZ_PACKAGES += GPL/termcap-1.3.1.tar.gz
GZ_PACKAGES += REDIST_OK/nasm-2.07.tar.gz
GZ_PACKAGES += REDIST_OK/cdrtools-2.01.01a75.tar.gz

# Uncomment the following three lines if you are behind a web proxy.
# Of course, make sure the URLs for the HTTP and FTP proxies are correct.
#HTTP_PROXY := "http://myproxy.web.addr:1080/"
#FTP_PROXY  := "http://myproxy.web.addr:1080/"
#DOWNLOADER_ENV := HTTP_PROXY=$(HTTP_PROXY) FTP_PROXY=$(FTP_PROXY)

$(BZ_PACKAGES:%=$(THIRD_PARTY)/%): %.tar.bz2: /usr/local/bin/freshmeat-downloader
	mkdir -p $(THIRD_PARTY)
	cd $(THIRD_PARTY) && env $(DOWNLOADER_ENV) /usr/local/bin/freshmeat-downloader $(*F)

$(GZ_PACKAGES:%=$(THIRD_PARTY)/%): %.tar.gz: /usr/local/bin/freshmeat-downloader
	mkdir -p $(THIRD_PARTY)
	cd $(THIRD_PARTY) && env $(DOWNLOADER_ENV) /usr/local/bin/freshmeat-downloader $(*F)
