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

VERSION := crossplex-0.10.2

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
