VERSION := $(shell echo git-`git log --format=format:%h -n1`)
DATE := $(shell git log --format=format:%cd --date=short -n1)
SHELL := /bin/bash

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
endif

# Always use # of processory plus 1
NUMPROC:=$$((${NUMPROC}+1))
NUMPROC:=$(shell echo ${NUMPROC})

ifeq ($(NUMPROC),0)
        NUMPROC = 1
endif

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

mcimage:
	@echo "Miniconfig image not implemented yet."

dir300image:
	@echo "DIR-300 image not implemented yet. You have to move the files by yourself"

help:
	cat doc/build-HOWTO

info:
	@echo "Freifunk Rheinland Buildroot"
	@echo "	 Version: $(VERSION)"
	@echo "	    Date: $(DATE)"
	@echo ''
	@echo "Freifunk Jena udp-broadcast"
	@echo "	 Version: $(FFJVERSION)"
	@echo "	    Date: $(FFJDATE)"
	@echo ''
	@echo "OpenWrt"
	@echo "	Backfire: $(BACKFIREVERSION)"
	@echo "	   Trunk: r$(SVNREVISION)"
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

fetch: fetch-backfire fetch-trunk

fetch-backfire: openwrt/backfire/.repo_access

fetch-trunk: openwrt/trunk/.repo_access

.NOTPARALLEL:
openwrt/backfire/.repo_access:
	mkdir -p openwrt dl
	@echo '  SVN 	  OpenWrt Backfire $(BACKFIREVERSION)'
	svn co -q svn://svn.openwrt.org/openwrt/tags/backfire_$(BACKFIREVERSION)/ $(@D)
	[[ -h $(@D)/dl ]] || ln -s ../../dl $(@D)/
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  UPDATE  OpenWrt Backfire $(BACKFIREVERSION) feeds'
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena udp-broadcast $(FFJVERSION) in OpenWrt Backfire'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  LINK    OpenWrt Backfire $(BACKFIREVERSION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $@

.NOTPARALLEL:
openwrt/trunk/.repo_access:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Trunk r$(SVNREVISION)'
	svn co -q -r $(SVNREVISION) svn://svn.openwrt.org/openwrt/trunk/ $(@D)
	[[ -h $(@D)/dl ]] || ln -s ../../dl $(@D)/
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  UPDATE  OpenWrt Trunk r$(SVNREVISION) feeds'
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena udp-broadcast $(FFJVERSION) in OpenWrt Trunk'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  LINK    OpenWrt Trunk r$(SVNREVISION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $@

# ------------------------------------
# Update targets
# ------------------------------------

update: update-backfire update-trunk

update-backfire: openwrt/backfire/.update

update-trunk: openwrt/trunk/.update

.NOTPARALLEL:
openwrt/backfire/.update:
	mkdir -p openwrt dl
	@echo '  SVN 	  OpenWrt Backfire $(BACKFIREVERSION) (update)'
	cd $(@D) && svn update -q
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  UPDATE  OpenWrt Backfire $(BACKFIREVERSION) feeds'
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena udp-broadcast $(FFJVERSION) (update)'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  LINK    OpenWrt Backfire $(BACKFIREVERSION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $(@D).repo_access

.NOTPARALLEL:
openwrt/trunk/.update:
	mkdir -p openwrt dl
	@echo '  SVN     OpenWrt Trunk r$(SVNREVISION) (update)'
	cd $(@D) && svn update -q -r $(SVNREVISION)
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	@echo '  UPDATE  OpenWrt Trunk r$(SVNREVISION) feeds'
	cd $(@D) && ./scripts/feeds update > /dev/null 2&>1
	@echo '  INSTALL Freifunk Jena udp-broadcast $(FFJVERSION) (update)'
	cd $(@D) && ./scripts/feeds install -a -p ffj > /dev/null 2&>1
	@echo '  LINK    OpenWrt Trunk r$(SVNREVISION) packages'
	cd $(@D) && $(MAKE) $(MAKEFLAGS) package/symlinks
	touch $(@D).repo_access

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

# format image/($repo)/openwrt-$(platform)-$(model)
.SECONDEXPANSION:
images/%: REPO=$(shell echo $(@F) | cut -f3 -d-)
images/%: PLAT=$(shell echo $(@F) | cut -f2 -d-)
images/%: MODEL=$(shell echo $(@F) | cut -f1 -d-)
images/%: config/$$(REPO)-$$(PLAT)-$$(MODEL).config \
			 openwrt/$$(REPO)/.repo_access 

	@echo '  BUILD   OpenWrt $(REPO) for $(PLAT) in $(MODEL)'

	cp $< openwrt/$(REPO)/.config

	-rm -r openwrt/$(REPO)/files
	# not needed, make gets rid of old files by itself
	#-rm -r openwrt/$(REPO)/bin/$(PLAT)

	cp -a files/common openwrt/$(REPO)/files
	[ -d files/$(REPO)/$(PLAT) ] && rsync -a files/$(REPO)/$(PLAT)/ openwrt/$(REPO)/files/
	[ -d files/$(REPO)/$(PLAT)-$(MODEL) ] && rsync -a files/$(REPO)/$(PLAT)-$(MODEL)/ openwrt/$(REPO)/files/

	#./name_firmware openwrt/$(REPO)
	echo $(DATE)_$(VERSION)`[ -n "$$(git status --porcelain)" ] && \
	echo -n "-modified"`_$(REPO)-`[[ "$(REPO)" == "trunk" ]] && \
	echo $(SVNREVISION) || echo $(BACKFIREVERSION)` > openwrt/$(REPO)/files/etc/firmware

	[[ -e config/misc/banner.$(MODEL) ]] && \
	sed config/misc/banner.$(MODEL) \
	-e "s/SVNRV/$(SVNREVISION)/g" \
	-e "s/LINUXVERSION/`grep '^LINUX_VERSION:=' openwrt/$(REPO)/target/linux/$(PLAT)/Makefile | sed 's/^LINUX_VERSION:='//g`/g" \
	-e "s/BATMANVERSION/`grep '^PKG_VERSION:=' openwrt/$(REPO)/package/feeds/packages/batman-adv/Makefile | sed 's/^PKG_VERSION:='//g`/g" \
	-e "s/FFRLversion/$(DATE)_$(VERSION)`[ -n "$$(git status --porcelain)" ] && echo -n "-modified"`_$(REPO)/g" \
	-e "s/buildSystem/`uname -n` by $(NAME) <$(MAIL)>/g" > openwrt/$(REPO)/files/etc/banner

	[[ "$(REPO)" == "backfire" ]] && \
	sed openwrt/$(REPO)/files/etc/banner -i -e "s/.*bleeding edge.*/ Backfire (10.03.1, r29592) ----------------------------------------------------/g" || true

	# It’s all about this command :-) disable for dry run
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)

	mkdir -p $@
	#mv openwrt/$(REPO)/bin/$(PLAT)/ $@/
	rsync -a openwrt/$(REPO)/bin/$(PLAT)/ $@/

