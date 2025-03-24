include $(TOPDIR)/rules.mk

# Name, version and release number
# The name and version of your package are used to define the variable to point to the build directory of your package: $(PKG_BUILD_DIR)
PKG_NAME:=client_captool
PKG_VERSION:=1.0
PKG_RELEASE:=1

# Source settings (i.e. where to find the source codes)
# This is a custom variable, used below

include $(INCLUDE_DIR)/package.mk

LDFLAGS += -Wl,--gc-sections,-luci,-ljson-c
# Package definition; instructs on how and where our package will appear in the overall configuration menu ('make menuconfig')
define Package/client_captool
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A tool to monitor client capabilities activity
  DEPENDS:=+libuci +libjson-c
endef

# Package description; a more verbose description on what our package does
define Package/client_captool/description
  A tool to monitor client capabilities activity.
endef

# Package preparation instructions; create the build directory and copy the source code. 
# The last command is necessary to ensure our preparation instructions remain compatible with the patching system.
define Build/Prepare
		$(call Build/Prepare/Default)
		mkdir -p $(PKG_BUILD_DIR)
		cp -rfv src/* $(PKG_BUILD_DIR)
endef

# Package build instructions; invoke the target-specific compiler to first compile the source file, and then to link the file into the final executable
define Build/Compile
		$(TARGET_CC) $(PKG_BUILD_DIR)/client_captool.c $(PKG_BUILD_DIR)/interface_setup.c $(PKG_BUILD_DIR)/radiotap/parse.c $(PKG_BUILD_DIR)/radiotap/radiotap.c -o $(PKG_BUILD_DIR)/$1 $(LDFLAGS)
endef

# Package install instructions; create a directory inside the package to hold our executable, and then copy the executable we built previously into the folder
define Package/client_captool/install
		$(INSTALL_DIR) $(1)/usr/bin
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/client_captool $(1)/usr/bin
endef

# This command is always the last, it uses the definitions and variables we give above in order to get the job done
$(eval $(call BuildPackage,client_captool))
