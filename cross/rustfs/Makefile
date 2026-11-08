PKG_NAME = rustfs
PKG_VERS = 1.0.4
PKG_EXT = zip
PKG_DIST_NAME = $(PKG_NAME)-linux-$(PKG_DIST_ARCH)-musl-v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://github.com/rustfs/rustfs/releases/download/$(PKG_VERS)
# the upstream zip contains the bare "rustfs" binary without a top level folder
PKG_DIR = $(PKG_NAME)-$(PKG_VERS)-$(PKG_DIST_ARCH)
EXTRACT_PATH = $(WORK_DIR)/$(PKG_DIR)

# upstream provides static musl binaries for x86_64 and aarch64 only
UNSUPPORTED_ARCHS = $(PPC_ARCHS) $(ARMv5_ARCHS) $(ARMv7_ARCHS) $(ARMv7L_ARCHS) $(i686_ARCHS)

HOMEPAGE = https://rustfs.com/
COMMENT  = RustFS is a high-performance, S3 compatible distributed object storage system written in Rust.
LICENSE  = Apache-2.0

INSTALL_TARGET = rustfs_install

# use digests with multiple files
PKG_DIST_ARCH_LIST = x86_64 aarch64

include ../../mk/spksrc.common.mk
ifeq ($(findstring $(ARCH),$(x64_ARCHS)),$(ARCH))
PKG_DIST_ARCH = x86_64
else ifeq ($(findstring $(ARCH),$(ARMv8_ARCHS)),$(ARCH))
PKG_DIST_ARCH = aarch64
endif

include ../../mk/spksrc.cross-install.mk

.PHONY: rustfs_install
rustfs_install:
	@install -d -m 755 $(STAGING_INSTALL_PREFIX)/bin
	@install -m 755 $(WORK_DIR)/$(PKG_DIR)/rustfs $(STAGING_INSTALL_PREFIX)/bin/rustfs
