PKG_NAME = rustfs-license
PKG_VERS = 1.0.5
PKG_EXT = txt
# the upstream release zips contain the binary only, take the LICENSE of the release tag
PKG_DIST_NAME = LICENSE
PKG_DIST_SITE = https://raw.githubusercontent.com/rustfs/rustfs/$(PKG_VERS)
PKG_DIST_FILE = rustfs-LICENSE-$(PKG_VERS).$(PKG_EXT)
PKG_DIR = $(PKG_NAME)-$(PKG_VERS)
EXTRACT_PATH = $(WORK_DIR)/$(PKG_DIR)
EXTRACT_CMD = cp $(DIST_FILE) $(EXTRACT_PATH)/LICENSE

HOMEPAGE = https://rustfs.com/
COMMENT  = License of the RustFS release redistributed in the package.
LICENSE  = Apache-2.0

INSTALL_TARGET = rustfs_license_install

include ../../mk/spksrc.cross-install.mk

.PHONY: rustfs_license_install
rustfs_license_install:
	@install -d -m 755 $(STAGING_INSTALL_PREFIX)/share/doc/rustfs
	@install -m 644 $(WORK_DIR)/$(PKG_DIR)/LICENSE $(STAGING_INSTALL_PREFIX)/share/doc/rustfs/LICENSE
