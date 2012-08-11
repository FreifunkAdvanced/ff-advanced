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
export COMMUNITY

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
[ -d files/$(REPO)/$(PLAT)-$(MODEL) ] \
	&& rsync -a files/$(REPO)/$(PLAT)-$(MODEL)/ openwrt/$(REPO)/files/
endef

define create_firmware_file
echo $(DATE)_$$(echo $(VERSION) \
	| sed -e "s/git-//g")_$(REPO)-`[[ "$(REPO)" == "trunk" ]] \
	&& echo $(SVNREVISION) || echo $(BACKFIREVERSION)` \
	> openwrt/$(REPO)/files/etc/firmware
endef

define brand_firmware
[[ -e config/misc/banner.$(MODEL) ]] && \
sed config/misc/banner.$(MODEL) \
-e "s/SVNRV/$(SVNREVISION)/g" \
-e "s/LINUXVERSION/`grep '^LINUX_VERSION:=' openwrt/$(REPO)/target/linux/$(PLAT)/Makefile | sed 's/^LINUX_VERSION:='//g`/g" \
-e "s/BATMANVERSION/`grep '^PKG_VERSION:=' openwrt/$(REPO)/package/feeds/packages/batman-adv/Makefile | sed 's/^PKG_VERSION:='//g`/g" \
-e "s/FFRLversion/$(DATE)_$(VERSION)/g" \
-e "s/buildSystem/`uname -n` by $(NAME) <$(MAIL)>/g" > openwrt/$(REPO)/files/etc/banner

[[ "$(REPO)" == "backfire" ]] && \
sed openwrt/$(REPO)/files/etc/banner -i -e "s/.*bleeding edge.*/ Backfire (10.03.1, r29592) ----------------------------------------------------/g" || true
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
update: update-trunk

update-backfire: openwrt/backfire/.update

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

# ------------------------------------
# Clean targets
# ------------------------------------

clean: 
	-rm -r config/*.config image/*

mrpropper: mrpropper-trunk

mrpropper-trunk:
	cd openwrt/trunk && $(MAKE) clean

# ------------------------------------
# Package targets
# ------------------------------------

pack:
	./makepackages

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
image-%: MODEL=$(shell echo $(@F) | cut -f4- -d-)
image-%:
image-%: 
	if [ "$(PLAT)" == "" ]; then \
		for pla in $(PLATFORM); do \
			$(MAKE) image-$(REPO)-$${pla}; \
		done; \
	elif [[ "$(MODEL)" == "" ]]; then \
		for com in $(COMMUNITY); do \
			$(MAKE) image-$(REPO)-$(PLAT)-$${com}; \
		done; \
	else \
	[[ "$(REPO)" == "trunk" ]] && $(MAKE) images/$(DATE)_$(VERSION)/$(MODEL)-$(PLAT)-$(REPO)-r$(SVNREVISION) || true; \
	[[ "$(REPO)" != "trunk" ]] && $(MAKE) images/$(DATE)_$(VERSION)/$(MODEL)-$(PLAT)-$(REPO)-$(BACKFIREVERSION) || true; \
	fi

image/%:
	@echo '"make image/$$(repo)/openwrt-$$(platform)-$$(model)" is deprecated'
	@echo 'please use the new make syntax:'
	head -n24 doc/build-HOWTO

# create a pure OpenWrt image to test the .config and for package integration
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): REPO="trunk"
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): PLAT="ar71xx"
images/$(DATE)_$(VERSION)/devel-ar71xx-trunk-r$(SVNREVISION): MODEL="devel"
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

# DIR-300 build target
images/$(DATE)_$(VERSION)/miniconfig-atheros_dir300-trunk-r$(SVNREVISION): REPO="trunk"
images/$(DATE)_$(VERSION)/miniconfig-atheros_dir300-trunk-r$(SVNREVISION): PLAT="atheros"
images/$(DATE)_$(VERSION)/miniconfig-atheros_dir300-trunk-r$(SVNREVISION): MODEL="miniconfig"
images/$(DATE)_$(VERSION)/miniconfig-atheros_dir300-trunk-r$(SVNREVISION): openwrt/trunk/.repo_access 
	@echo '  BUILD   OpenWrt trunk for D-Link DIR-300'
	./genconfig dir300 > openwrt/$(REPO)/.config
	$(oldconfig)
	-rm -r openwrt/$(REPO)/files 2> /dev/null || true
	mkdir -p openwrt/$(REPO)/files/etc/
	$(create_firmware_file)
	$(brand_firmware)
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $@
	rsync --exclude="*-squashfs.bin" \
	      --exclude="*.elf" \
	      --exclude="*-vmlinux.gz" -a \
	      openwrt/$(REPO)/bin/$(PLAT)/ $@/
	cd $@/ && rm md5sums
	cd $@/ && md5sum * > md5sums 2> /dev/null || true

# WRT54G build target
images/$(DATE)_$(VERSION)/miniconfig-brcm47xx_wrt54g-trunk-r$(SVNREVISION): REPO="trunk"
images/$(DATE)_$(VERSION)/miniconfig-brcm47xx_wrt54g-trunk-r$(SVNREVISION): PLAT="brcm47xx"
images/$(DATE)_$(VERSION)/miniconfig-brcm47xx_wrt54g-trunk-r$(SVNREVISION): MODEL="miniconfig"
images/$(DATE)_$(VERSION)/miniconfig-brcm47xx_wrt54g-trunk-r$(SVNREVISION): openwrt/trunk/.repo_access 
	@echo '  BUILD   OpenWrt trunk for Linksys WRT54G'
	./genconfig wrt54g > openwrt/$(REPO)/.config
	$(oldconfig)
	-rm -r openwrt/$(REPO)/files 2> /dev/null || true
	mkdir -p openwrt/$(REPO)/files/etc/
	$(create_firmware_file)
	$(brand_firmware)
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $@
	rsync -a openwrt/$(REPO)/bin/$(PLAT)/packages $@/
	rsync --exclude="*3g*" \
	      --include="*wrt54g*" \
	      --include="*-rootfs.tar.gz" \
	      --include="openwrt-brcm47xx-squashfs.trx" \
	      --exclude="*" -a \
	      openwrt/$(REPO)/bin/$(PLAT)/ $@/
	cd $@/ && md5sum * > md5sums 2> /dev/null || true

# ar71xx build target
.SECONDEXPANSION:
images/%: REPO=$(shell echo $(@F) | cut -f3 -d-)
images/%: PLAT=$(shell echo $(@F) | cut -f2 -d-)
images/%: MODEL=$(shell echo $(@F) | cut -f1 -d-)
images/%: openwrt/$$(REPO)/.repo_access 
	@echo '  BUILD   OpenWrt $(REPO) for $(PLAT) in $(MODEL)'
	./genconfig $(PLAT) > openwrt/$(REPO)/.config
	-rm -r openwrt/$(REPO)/files
	$(move_files)
	$(create_firmware_file)
	$(brand_firmware)
	$(oldconfig)
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $@
	rsync -a openwrt/$(REPO)/bin/$(PLAT)/ $@/

