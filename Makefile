# -*- makefile -*-			Crossplex Library Install Makefile
#
# This program Copyright (C) 2000-2009 David Wuertele
# This program is distributed under the GNU General Public License v2 - see the 
# accompanying COPYING file for more details. 

ifneq ($(MAKE_VERSION),3.81)
  $(warning CROSSPLEX REQUIRES MAKE VERSION 3.81 TO RUN!)
  NEEDFORCE := 1
else
  NEEDFORCE := 0
endif

FORCE ?= 0

VERSION := crossplex-0.11.2

DESTDIR ?= /usr/local

LIBDIR ?= $(DESTDIR)/lib
BINDIR ?= $(DESTDIR)/bin
ETCDIR ?= $(DESTDIR)/etc

LIBFILES_TOFIX := $(patsubst %.in,%,$(filter %.in,$(shell find lib -type f)))
LIBFILES_NOFIX := $(filter-out %.in,$(shell find lib -type f))

ETCFILES := MOTOROLA_README COPYING Makefile
LIBFILES := $(patsubst lib/%,%,$(LIBFILES_NOFIX) $(LIBFILES_TOFIX))
BINFILES := crossplex-project freshmeat-downloader

INSTALLED_LIBFILES := $(patsubst %,$(LIBDIR)/$(VERSION)/%,$(LIBFILES))
INSTALLED_BINFILES := $(patsubst %,$(BINDIR)/%,$(BINFILES))

help:
	@echo
	@echo This makefile simply copies the contents of the bin and lib directories to the destination of your choice.
	@echo
	@echo "Default usage (installs in $(LIBDIR)/$(VERSION) and $(BINDIR)):"
	@echo
	@echo "         " make install
	@echo
	@echo "Specify target prefix:"
	@echo
	@echo "         " make install DESTDIR=/some/path
	@echo
	@echo "Specify individual lib and bin directories:"
	@echo
	@echo "         " make install LIBDIR=/some/path/to/lib BINDIR=/some/path/to/bin
	@echo

ifeq ($(NEEDFORCE),1)
  ifeq ($(FORCE),1)
     INSTALL_OK := 1
    $(warning Forcing crossplex installation with make version $(MAKE_VERSION))
  else
    $(warning To install crossplex with a different make version, type "$(MAKE) FORCE=1 $(MAKECMDGOALS)")
  endif
else
     INSTALL_OK := 1
endif

ifeq ($(INSTALL_OK),1)

  install: $(INSTALLED_LIBFILES) $(INSTALLED_BINFILES)

  $(INSTALLED_LIBFILES): $(LIBDIR)/$(VERSION)/%: lib/%
	mkdir -p $(@D)
	cp -a $< $@

  $(INSTALLED_BINFILES): $(BINDIR)/%: bin/%
	mkdir -p $(@D)
	cp -a $< $@

  bin/%: bin/%.in
	perl -pe 's,\@\@\@LIBDIR\@\@\@,"$(LIBDIR)/$(VERSION)",' < $< > $@.new
	chmod +x $@.new
	mv $@.new $@

  $(LIBFILES_TOFIX): lib/templates/%: lib/templates/%.in
	perl -pe 's,\@\@\@LIBDIR\@\@\@,"$(LIBDIR)/$(VERSION)",' < $< > $@.new
	chmod +x $@.new
	mv $@.new $@

endif

dist: ../$(VERSION).tbz

../$(VERSION).tbz: FORCE
	git archive -v --format=tar --prefix=$(VERSION)/ HEAD | bzip2 - > $@

FORCE:

checkgit:
	rm -rf ../$(VERSION)
	mkdir -p ../$(VERSION)
	cd ../$(VERSION); git init; git remote add github git@github.com:wuertele/crossplex.git; git pull github master
#	cd ../$(VERSION); git init; git remote add github https://github.com/wuertele/crossplex.git; git pull github master


TEST_PATH := $(shell pwd)/test

test-build-examples:
	rm -rf test
	$(MAKE) install DESTDIR=$(TEST_PATH)
	$(MAKE) -C examples vmware udlinux CROSSPLEX_BUILD_INSTALL=$(TEST_PATH) BUILD_TOP=$(TEST_PATH)/build THIRD_PARTY=$(TEST_PATH)/thirdparty HTTP_PROXY=http://wwwgate0.mot.com:1080/ FTP_PROXY=http://wwwgate0.mot.com:1080/ 

test-self-build:
	rm -rf test
	$(MAKE) install DESTDIR=$(TEST_PATH)
	$(MAKE) -C examples sbvmdx CROSSPLEX_BUILD_INSTALL=$(TEST_PATH) BUILD_TOP=$(TEST_PATH)/build THIRD_PARTY=$(TEST_PATH)/thirdparty HTTP_PROXY=http://wwwgate0.mot.com:1080/ FTP_PROXY=http://wwwgate0.mot.com:1080/  

BUILD_GUEST_IP=10.77.181.25
VMGUEST_NAME=Ubuntu-JeOS-Dev-a4db519
VMGUEST_TARBALL=/nightly/dave/vmware/$(VMGUEST_NAME).tbz

$(VMGUEST_NAME)-$(VERSION)/Ubuntu-JeOS-Dev.vmx $(VMGUEST_NAME)-$(VERSION).tbz: ../$(VERSION).tbz $(VMGUEST_TARBALL)
	rm -rf $(VMGUEST_NAME)-$(VERSION) $(VMGUEST_NAME)
	tar xvjf "$(VMGUEST_TARBALL)"
	mv $(VMGUEST_NAME) $(VMGUEST_NAME)-$(VERSION)
	env -i HOME=$(HOME) /usr/bin/vmrun start $(VMGUEST_NAME)-$(VERSION)/Ubuntu-JeOS-Dev.vmx nogui
	sleep 60
	/usr/bin/scp -i id_cpbuild ../$(VERSION).tbz crossplex@$(BUILD_GUEST_IP):
	/usr/bin/ssh $(BUILD_GUEST_IP) -l crossplex -i id_cpbuild "tar xvjf $(VERSION).tbz && find $(VERSION) -exec touch {} \;"
	/usr/bin/ssh $(BUILD_GUEST_IP) -l root -i id_cpbuild "cd /home/crossplex/$(VERSION) && make install && shutdown -h now"
	sleep 20
	tar cvjf $(VMGUEST_NAME)-$(VERSION).tbz $(VMGUEST_NAME)-$(VERSION)

test-build-vmrelease: $(VMGUEST_NAME)-$(VERSION)/Ubuntu-JeOS-Dev.vmx
	env -i HOME=$(HOME) /usr/bin/vmrun start $(VMGUEST_NAME)-$(VERSION)/Ubuntu-JeOS-Dev.vmx nogui
	sleep 60
	/usr/bin/ssh $(BUILD_GUEST_IP) -l crossplex -i id_cpbuild "cd /home/crossplex/$(VERSION)/examples && perl -pe 's/#HTTP_PROXY/HTTP_PROXY/; s/#FTP_PROXY/FTP_PROXY/; s/myproxy.com/wwwgate0.mot.com/' fetch-sources.mk > fetch-sources.mk.new && mv fetch-sources.mk.new fetch-sources.mk && time make vmware udlinux > make.out 2>&1"
	/usr/bin/ssh $(BUILD_GUEST_IP) -l root -i id_cpbuild 'shutdown -h now'

