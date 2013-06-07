SHELL := /bin/bash
VERSION := $(shell echo git-`git log --format=format:%h -n1`)
DATE := $(shell git log --format=format:%cd --date=short -n1)

include settings.mk

# *DOCUMENTATION*
# To see a list of typical targets execute "make help"
# More info can be located in ./README

NUMPROC := 1
OS := $(shell uname)
export NUMPROC

export REPOSITORY
export PLATFORM
export COMMUNITIES

ifeq ($(OS),Linux)
        NUMPROC := $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
        NUMPROC := $(shell sysctl hw.ncpu | awk '{print $$2}')
else ifeq ($(OS),FreeBSD)
		NUMPROC := $(shell sysctl hw.ncpu | awk '{print $$2}')
endif

# Always use # of processory plus 1
NUMPROC:=$$((${NUMPROC}+1))
NUMPROC:=$(shell echo ${NUMPROC})

ifeq ($(NUMPROC),0)
        NUMPROC = 1
endif

# ------
# define
# ------

define move_files
	cp -a files/common openwrt/$(REPO)/files
	[ -d files/$(REPO)/$(PLAT) ] \
		&& rsync -a files/$(REPO)/$(PLAT)/ openwrt/$(REPO)/files/

	if test -d "files/communities/$(COMMUNITY)/$(PLAT)"; \
		then rsync -a files/communities/$(COMMUNITY)/$(PLAT)/ openwrt/$(REPO)/files/; \
	fi
	./gensettings $(REPO) $(PLAT) $(COMMUNITY)
endef

define create_firmware_file
echo $(DATE)_$$(echo $(VERSION) \
	| sed -e "s/git-//g")/$(REPO)/`[[ "$(REPO)" == "attitude_adjustment" ]] \
	&& echo $(SVNREVISION) || echo "stable"` \
	> openwrt/$(REPO)/files/etc/firmware
endef

define brand_firmware
[[ -e config/communities/$(COMMUNITY)/banner ]] \
	&& cp config/communities/$(COMMUNITY)/banner openwrt/$(REPO)/files/etc/banner || cp config/default/banner openwrt/$(REPO)/files/etc/banner

sed openwrt/$(REPO)/files/etc/banner -i \
	-e "s/SVNRV/$(SVNREVISION)/g" \
	-e "s/LINUXVERSION/`grep '^LINUX_VERSION:=' openwrt/$(REPO)/target/linux/$(PLAT)/Makefile | sed 's/^LINUX_VERSION:='//g`/g" \
	-e "s/FFRLversion/$(DATE)_$(VERSION)/g" \
	-e "s/buildSystem/`uname -n` by $(NAME) <$(MAIL)>/g"

[[ "$(REPO)" == "attitude_adjustment" ]] \
	&& sed openwrt/$(REPO)/files/etc/banner -i -e "s/.*bleeding edge.*/ ATTITUDE ADJUSTMENT (12.09, r36088) -------------------------------------------/g" \
	&& sed openwrt/$(REPO)/files/etc/banner -i -e "s/BATMANVERSION/`grep '^PKG_VERSION:=' openwrt/$(REPO)/package/feeds/openwrtrouting/batman-adv/Makefile | sed 's/^PKG_VERSION:='//g`/g" \
	|| sed openwrt/$(REPO)/files/etc/banner -i -e "s/BATMANVERSION/`grep '^PKG_VERSION:=' openwrt/$(REPO)/package/feeds/packages/batman-adv/Makefile | sed 's/^PKG_VERSION:='//g`/g" || true
endef

define oldconfig
cd openwrt/$(REPO) && while true; do echo; done | $(MAKE) oldconfig >/dev/null
endef

# ------------------------------------
# Miscellaneous targets and flag lists
# ------------------------------------

# The first rule in the file had better be this one.  Don't put any above it.
# This lives here to allow makefile fragments to contain dependencies.
# You can modify the default targets in settings.mk
all: ${DEFAULTIMAGES}

settings.mk:
	@echo "Please edit settings.mk first."
	@echo "Copy & edit settings.mk.example for your purposes."
	[ -e settings.mk ] || exit 1

devimage: images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION)

mcimage: images/$(DATE)_$(VERSION)/miniconfig-ar71xx-trunk-r$(SVNREVISION)

dir300image: images/$(DATE)_$(VERSION)/miniconfig-atheros_dir300-trunk-r$(SVNREVISION)

wrt54gimage: images/$(DATE)_$(VERSION)/miniconfig-brcm47xx_wrt54g-trunk-r$(SVNREVISION)

help:
	cat doc/build-HOWTO

info:
	@echo "Freifunk Rheinland Buildroot"
	@echo "	 Version: $(VERSION)"
	@echo "	    Date: $(DATE)"
	@echo ''
	@echo ' To see a list of typical targets execute "make help"'
	@echo ' More info can be located in ./README'

# ------------------------------------
# Config targets | see config/Makefile
# ------------------------------------

config-all:
	cd config && $(MAKE) $(REPOSITORY)

.SECONDEXPANSION:
config-%:
	cd config && $(MAKE) $(shell echo $(@F) | sed s/config-//g  )

# for historical reasons
config/%.config:
	cd config && $(MAKE) $(shell echo $(@F) | sed -e "s:config/::g" )

# ------------------------------------
# Fetch targets
# ------------------------------------

fetch: fetch-trunk

fetch-trunk: openwrt/trunk/.repo_access

fetch-attitude_adjustment: openwrt/attitude_adjustment/.repo_access

# TODO: bis Pakete aus dem Buildroot herausgelöst wurden existieren zwei Paket-
#       Quellen:
#       - ffrlgit: git://github.com/ffrl/ffrl-feed.git
#       - ffrl: Verzeichnisse im Buildroot - laut Upstream (Jan/Jena) nicht
#               Standardkonform
.NOTPARALLEL:
openwrt/trunk/.repo_access:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Trunk r$(SVNREVISION)'
	svn co -q -r $(SVNREVISION) svn://svn.openwrt.org/openwrt/trunk/ $(@D)
	[[ -h $(@D)/dl ]] || ln -s ../../dl $(@D)/
	@echo '  UPDATE  OpenWrt Trunk r$(SVNREVISION) feeds'
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  INSERT  Freifunk Rheinland Buildroot packages in OpenWrt Trunk'
	echo "src-link ffrl $$(pwd)/feeds/ffrl" >> $(@D)/feeds.conf
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland Git repo in OpenWrt Trunk'
	cd $(@D) && ./scripts/feeds install -a -p ffrlgit > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland packages in OpenWrt Trunk'
	cd $(@D) && ./scripts/feeds install -a -p ffrl > /dev/null 2&>1
	@echo '  LINK    OpenWrt Trunk r$(SVNREVISION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $@

.NOTPARALLEL:
openwrt/attitude_adjustment/.repo_access:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Attitude Adjustment'
	svn co -q svn://svn.openwrt.org/openwrt/branches/attitude_adjustment $(@D)
	[[ -h $(@D)/dl ]] || ln -s ../../dl $(@D)/
	@echo '  UPDATE  OpenWrt Attitude Adjustment feeds'
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  INSERT  Freifunk Rheinland Buildroot packages in OpenWrt Attitude Adjustment'
	echo "src-link ffrl $$(pwd)/feeds/ffrl" >> $(@D)/feeds.conf
	cd $(@D) && ./scripts/feeds update -a > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland Git repo in OpenWrt Attitude Adjustment'
	cd $(@D) && ./scripts/feeds install -a -p ffrlgit > /dev/null 2&>1
	@echo '  INSTALL Alfred Git repo in OpenWrt Attitude Adjustment'
	cd $(@D) && ./scripts/feeds install -a -p alfred > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland packages in OpenWrt Attitude Adjustment'
	cd $(@D) && ./scripts/feeds install -a -p ffrl > /dev/null 2&>1
	@echo '  LINK    OpenWrt Attitude Adjustment packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	@echo '  REMOVE  OpenWrt Attitude Adjustment kmod-batman-adv package'
	cd $(@D) && ./scripts/feeds uninstall kmod-batman-adv > /dev/null 2&>1
	@echo '  INSTALL OpenWrt Routing kmod-batman-adv package'
	cd $(@D) && ./scripts/feeds install -p openwrtrouting kmod-batman-adv > /dev/null 2&>1
	touch $@
	
	
# ------------------------------------
# Update targets
# ------------------------------------

settings_update: newSVN = $(shell svn info svn://svn.openwrt.org/openwrt/trunk/ 2> /dev/null | grep "Rev:" | sed -e "s/.*: //g" || exit 1)
settings_update: oldSVN = $(shell LANG=C svn info openwrt/trunk/ 2> /dev/null | grep "Rev:" | sed -e "s/.*: //g" || exit 1)
settings_update: SVNREVISION = $(newSVN)
settings_update:
	if [ "$(newSVN)" == "" ] || [ "$(oldSVN)" == "" ];then echo "  SVN 	  nicht erreichbar"; exit 1; fi
	@echo '  MOD 	  settings.mk ($(oldSVN) -> $(newSVN))'
	sed -i -e 's/SVNREVISION	=.*/SVNREVISION	= $(newSVN)/g' settings.mk

.NOTPARALLEL:
update: update-attitude_adjustment update-trunk

update-attitude_adjustment: openwrt/attitude_adjustment/.update

.NOTPARALLEL:
# update-trunk: settings_update
update-trunk: openwrt/trunk/.update

.NOTPARALLEL:
openwrt/trunk/.update:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Trunk r$(SVNREVISION) (update)'
	cd $(@D) && svn update -q -r $(SVNREVISION)
	@echo '  UPDATE  OpenWrt Trunk r$(SVNREVISION) feeds'
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	echo "src-link ffrl $$(pwd)/feeds/ffrl" >> $(@D)/feeds.conf
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena hbbpd $(FFJVERSION) (update)'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland packages in OpenWrt Trunk'
	cd $(@D) && ./scripts/feeds install -a -p ffrl > /dev/null 2&>1
	@echo '  LINK    OpenWrt Trunk r$(SVNREVISION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $(@D).repo_access

.NOTPARALLEL:
openwrt/attitude_adjustment/.update:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Attitude Adjustment (update)'
	cd $(@D) && svn update -q
	@echo '  UPDATE  OpenWrt Attitude Adjustment feeds'
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	echo "src-link ffrl $$(pwd)/feeds/ffrl" >> $(@D)/feeds.conf
	cd $(@D) && ./scripts/feeds update -a > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena hbbpd $(FFJVERSION) (update)'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  INSTALL Freifunk Rheinland packages in OpenWrt Attitude Adjustment'
	cd $(@D) && ./scripts/feeds install -a -p ffrl > /dev/null 2&>1
	@echo '  LINK    OpenWrt Attitude Adjustment packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	@echo '  REMOVE  OpenWrt Attitude Adjustment kmod-batman-adv package'
	cd $(@D) && ./scripts/feeds uninstall kmod-batman-adv > /dev/null 2&>1
	@echo '  INSTALL OpenWrt Routing kmod-batman-adv package'
	cd $(@D) && ./scripts/feeds install -p openwrtrouting kmod-batman-adv > /dev/null 2&>1
	touch $(@D).repo_access	
	
# ------------------------------------
# Clean targets
# ------------------------------------

clean: 
	-rm -r config/*.config image/*

mrpropper: mrpropper-attitude_adjustment mrpropper-trunk

mrpropper-trunk:
	cd openwrt/trunk && $(MAKE) clean

mrpropper-attitude_adjustment:
	cd openwrt/attitude_adjustment && $(MAKE) clean

	
	
# ------------------------------------
# Package targets
# ------------------------------------

pack:
	./makepackages build

# ------------------------------------
# Build targets
# ------------------------------------

image:
	for rep in $(REPOSITORY); do \
		$(MAKE) $(MAKEFLAGS) image-$${rep}; \
	done 

.SECONDEXPANSION:
image-%: REPO=$(shell echo $(@F) | cut -f2 -d-)
image-%: PLAT=$(shell echo $(@F) | cut -f3 -d-)
image-%: COMMUNITY=$(shell echo $(@F) | cut -f4- -d-)
image-%:
image-%: 
	if [ "$(PLAT)" == "" ]; then \
		for pla in $(PLATFORM); do \
			$(MAKE) image-$(REPO)-$${pla}; \
		done; \
	elif [[ "$(COMMUNITY)" == "" ]]; then \
		for com in $(COMMUNITIES); do \
			$(MAKE) image-$(REPO)-$(PLAT)-$${com}; \
		done; \
	else \
	[[ "$(REPO)" == "trunk" ]] && $(MAKE) images/$(DATE)_$(VERSION)/$(COMMUNITY)-$(PLAT)-$(REPO)-r$(SVNREVISION) || true; \
	[[ "$(REPO)" != "trunk" ]] && $(MAKE) images/$(DATE)_$(VERSION)/$(COMMUNITY)-$(PLAT)-$(REPO) || true; \
	fi

image/%:
	@echo '"make image/$$(repo)/openwrt-$$(platform)-$$(COMMUNITY)" is deprecated'
	@echo 'please use the new make syntax:'
	head -n24 doc/build-HOWTO

# create a pure OpenWrt image to test the .config and for package integration
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): REPO="trunk"
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): PLAT="ar71xx"
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): COMMUNITY="devel"
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): openwrt/trunk/.repo_access 
	@echo '  BUILD   Development OpenWrt trunk for ar71xx'
	cp -p config/devel.config openwrt/trunk/.config
	-rm -r openwrt/trunk/files 2> /dev/null || true
#	mkdir -p openwrt/trunk/files/etc/
#	$(create_firmware_file)
#	$(brand_firmware)
#	echo '! development image' >> openwrt/$(REPO)/files/etc/banner
#	echo '  ------------------------------------------------------------------------------' >> openwrt/$(REPO)/files/etc/banner
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $@
#	rsync -a openwrt/$(REPO)/bin/$(PLAT)/ $@/
	mv openwrt/$(REPO)/bin/$(PLAT)/* $@/
#	cd $@/ && rm md5sums
#	cd $@/ && md5sum * > md5sums 2> /dev/null || true

# ar71xx build target
.SECONDEXPANSION:
images/%: REPO=$(shell echo $(@F) | cut -f3 -d-)
images/%: PLAT=$(shell echo $(@F) | cut -f2 -d-)
images/%: COMMUNITY=$(shell echo $(@F) | cut -f1 -d-)
images/%: openwrt/$$(REPO)/.repo_access 
	@echo '  BUILD   OpenWrt $(REPO) for $(PLAT) in $(COMMUNITY)'
	./genconfig $(PLAT) > openwrt/$(REPO)/.config
	-rm -r openwrt/$(REPO)/files
	$(move_files)
	$(create_firmware_file)
	$(brand_firmware)
	$(oldconfig)
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $@
	rsync -a openwrt/$(REPO)/bin/$(PLAT)/ $@/
	mkdir -p packages/$(PLAT)
	rm -f packages/$(PLAT)/*
	rsync --include="ffadv*" \
	      --exclude="*" -a \
		  openwrt/$(REPO)/bin/$(PLAT)/packages/ packages/$(PLAT)/
	cd packages/$(PLAT) && md5sum * > md5sums
	cd packages/$(PLAT) && ../../openwrt/$(REPO)/scripts/ipkg-make-index.sh . > Packages 
	cat packages/$(PLAT)/Packages | gzip > packages/$(PLAT)/Packages.gz

