

include $(TOPDIR)/rules.mk

PKG_NAME:=wifimon
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/wifimon
  SECTION:=net
  CATEGORY:=Network
  TITLE:=WiFi Client Capability Monitor
  DEPENDS:=+libpcap +libnl-tiny
endef

define Package/wifimon/description
  Captures and displays WiFi client capabilities from probe/association frames
endef

define Build/Prepare
    mkdir -p $(PKG_BUILD_DIR)
    $(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
    $(TARGET_CC) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/wifimon.o -c $(PKG_BUILD_DIR)/wifimon.c
    $(TARGET_CC) $(TARGET_LDFLAGS) -o $(PKG_BUILD_DIR)/$1 $(PKG_BUILD_DIR)/wifimon.o -lpcap -lnl-tiny
endef

define Package/wifimon/install
    $(INSTALL_DIR) $(1)/usr/bin
    $(INSTALL_BIN) $(PKG_BUILD_DIR)/wifimon $(1)/usr/bin/
endef

$(eval $(call BuildPackage,wifimon))
