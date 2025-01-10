# Package Name
PKG_NAME:=coverage_hole_detection
PKG_VERSION:=1.0
PKG_RELEASE:=1

# Include OpenWRT build system
include $(TOPDIR)/rules.mk

# Define the build directory
BUILD_DIR:=$(PKG_BUILD_DIR)

# Source files
SRC_C := $(PKG_BUILD_DIR)/src/coverage_hole_detection.c $(PKG_BUILD_DIR)/src/utils.c
SRC_HEADER := $(PKG_BUILD_DIR)/src/coverage_hole_detection.h

# Define the target binaries
PKG_BINARIES := coverage_hole_detection

# Makefile rules
define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Network
  TITLE:=Coverage Hole Detection and Mitigation for APs
  DEPENDS:=+libc
endef

define Build/Compile
  $(MAKE) -C $(PKG_BUILD_DIR) all
endef

define Package/$(PKG_NAME)/install
  # Install the binary to /usr/bin
  $(INSTALL_DIR) $(1)/usr/bin
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/coverage_hole_detection $(1)/usr/bin/
  
  # Install config file
  $(INSTALL_DIR) $(1)/etc/config
  $(INSTALL_CONF) $(PKG_BUILD_DIR)/files/config $(1)/etc/config/
endef

# Build the package
$(eval $(call BuildPackage,$(PKG_NAME)))
