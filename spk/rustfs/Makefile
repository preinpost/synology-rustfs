SPK_NAME = rustfs
SPK_VERS = 1.0.4
SPK_REV = 1
SPK_ICON = src/rustfs.png
DSM_UI_DIR = app

DEPENDS = cross/rustfs

REQUIRED_MIN_DSM = 7.1
# upstream provides static musl binaries for x86_64 and aarch64 only
UNSUPPORTED_ARCHS = $(PPC_ARCHS) $(ARMv5_ARCHS) $(ARMv7_ARCHS) $(ARMv7L_ARCHS) $(i686_ARCHS)

MAINTAINER = synology-rustfs
DESCRIPTION = RustFS is a high-performance, S3 compatible object storage server written in Rust. This package uses the official static musl binaries published by the RustFS project.
DISPLAY_NAME = RustFS
CHANGELOG = "Initial package of RustFS 1.0.4.<br/>Changelog: <a target=\"_blank\" href=\"https://github.com/rustfs/rustfs/releases/tag/1.0.4\">https://github.com/rustfs/rustfs/releases/tag/1.0.4</a>"
HOMEPAGE = https://rustfs.com/
LICENSE = Apache-2.0

WIZARDS_DIR = src/wizard

STARTABLE = yes
SERVICE_USER = auto
SERVICE_SETUP = src/service-setup.sh
SERVICE_WIZARD_SHARENAME = wizard_data_directory
FWPORTS = src/rustfs.sc
# Web console (S3 API port 9200 is defined in src/rustfs.sc)
# SERVICE_PORT creates the DSM main menu shortcut (app/config)
SERVICE_PORT = 9201
SERVICE_URL = /rustfs/console/
SERVICE_DESC = RustFS Web Console
ADMIN_PORT = $(SERVICE_PORT)
ADMIN_URL = $(SERVICE_URL)

POST_STRIP_TARGET = rustfs_extra_install

SPK_COMMANDS = bin/rustfs

include ../../mk/spksrc.spk.mk

.PHONY: rustfs_extra_install
rustfs_extra_install:
	@install -d -m 755 $(STAGING_DIR)/var
	@install -m 644 src/environment-variables $(STAGING_DIR)/var/
