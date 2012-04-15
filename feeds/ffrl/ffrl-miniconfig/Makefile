#
# Copyright (C) 2012 Freifunk Rheinland
#
# This is free software, licensed under the GNU General Public License v3.
# See http://www.gnu.org/licenses/ for more information.
#

include $(TOPDIR)/rules.mk


PKG_NAME:=ffrl-miniconfig
PKG_VERSION:=0.0.20120415
PKG_RELEASE:=1
#PKG_REV:=

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DEPENDS := uci base-files

include $(INCLUDE_DIR)/package.mk

define Package/ffrl-miniconfig
  SECTION:=ffrl
  CATEGORY:=Network
  TITLE:=Freifunk Rheinland - miniconfig
  DEPENDS:=+base-files
  URL:=http://www.freifunk-rheinland.net
  DEFAULT:=n
  PKGARCH:=all
endef

define Package/ffrl-miniconfig/description
 Ein Skript, welches den Router für eine Freifunkzelle umkonfiguriert.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/ffrl-miniconfig/install
	$(CP) -ap files/root/* $(1)/
endef

$(eval $(call BuildPackage,ffrl-miniconfig))
