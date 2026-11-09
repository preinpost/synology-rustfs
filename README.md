# synology-rustfs

[한국어](README.ko.md)

> **Unofficial community package, not affiliated with RustFS or Synology.**
> It is not provided or supported by Synology, SynoCommunity or the RustFS project.

An **unofficial** DSM package (SPK) to run [RustFS](https://github.com/rustfs/rustfs) (S3 compatible object storage) on Synology DSM 7.1 or later.

- RustFS is not built from source. The package uses the **static musl binaries** that upstream publishes on its GitHub Releases (`rustfs-linux-{x86_64,aarch64}-musl-v<ver>.zip`). The downloads are verified against `cross/rustfs/digests` (SHA1/SHA256/MD5).
- Packaging uses the [spksrc](https://github.com/SynoCommunity/spksrc) framework, and the layout follows spksrc's `spk/minio`.
- The upstream RustFS `LICENSE` of the packaged release is shipped in the SPK as `share/doc/rustfs/LICENSE` (`/var/packages/rustfs/target/share/doc/rustfs/LICENSE` on the NAS).

| Item | Value |
|---|---|
| RustFS | 1.0.4 |
| Minimum DSM | 7.1 (`os_min_ver="7.1-42661"`) |
| Architectures | `x64` (Intel/AMD 64-bit), `aarch64` (ARMv8: rtd1296, rtd1619b, armada37xx) |
| Service account | `sc-rustfs` (DSM 7 package user) |

## Installation (manual install)

> ⚠️ **Trust level warning**
> This SPK does not come from the Synology Package Center repository and is not signed. Installing it runs the RustFS binary and the installer scripts on your NAS. Only install it if you have reviewed the sources in this repository (`spk/rustfs/src/service-setup.sh`, the wizards) and the build process, or if you built the SPK yourself. The package service runs as the `sc-rustfs` account, not as root.

1. Check the NAS architecture: look at the CPU model in Control Panel → Info Center, or run `uname -m` over SSH (`x86_64` → x64, `aarch64` → aarch64).
2. Download the matching file from the Releases page (or from `dist/` if you built it yourself).
   - `rustfs_x64-7.1_<ver>-<rev>.spk`
   - `rustfs_aarch64-7.1_<ver>-<rev>.spk`
   - Verify it against the release `SHA256SUMS`: `sha256sum -c SHA256SUMS`
3. In DSM **Package Center → Manual Install**, select the SPK.
   - If an "unknown publisher" warning appears, read the warning above before continuing.
4. Values for the install wizard:
   - **Data shared folder**: default `rustfs`. If the shared folder does not exist, it is created on the volume where the package is installed and `sc-rustfs` gets read/write permission. To use another volume, create the shared folder in Control Panel first and enter its name. The folder chosen here is the only source of the RustFS data path (`SHARE_PATH` in `/var/packages/rustfs/etc/installer-variables`). If you reinstall with a different shared folder after "Uninstall only", the new folder is used.
   - **Access key**: 3 to 128 characters. `=`, `,` and spaces are not allowed.
   - **Secret key**: at least 8 characters. `=`, `,` and spaces are not allowed.
   - The keys are stored in `/var/packages/rustfs/var/access_key` and `secret_key` with mode 600 (owned by `sc-rustfs`). Only the paths are passed to RustFS (`RUSTFS_ACCESS_KEY_FILE` / `RUSTFS_SECRET_KEY_FILE`), so the keys are never left in plain text in the process environment or in installer-variables.
5. After installation, click the **RustFS** icon in the DSM main menu or open `http://<NAS>:9201/rustfs/console/`.

## Ports

| Port | Purpose | Setting |
|---|---|---|
| 9200/tcp | S3 API | `RUSTFS_ADDRESS=:9200` |
| 9201/tcp | Web console | `RUSTFS_CONSOLE_ADDRESS=:9201` |

The RustFS default ports are 9000/9001. This package uses 9200/9201 to avoid conflicts with Synology services or the MinIO package. Both ports are registered in the DSM firewall service list as "RustFS" and "RustFS Console" (`spk/rustfs/src/rustfs.sc`).

S3 client examples:

```sh
aws --endpoint-url http://<NAS>:9200 s3 ls
mc alias set nas http://<NAS>:9200 <access_key> <secret_key>
```

## Configuration

The user configuration file is `/var/packages/rustfs/var/environment-variables` (`${SYNOPKG_PKGVAR}/environment-variables`). Write one `KEY=VALUE` per line; lines starting with `#` are ignored. There is no shell expansion. Stop and start the package after editing it.

Defaults right after installation:

```sh
RUSTFS_ADDRESS=:9200
RUSTFS_CONSOLE_ENABLE=true
RUSTFS_CONSOLE_ADDRESS=:9201
RUSTFS_DRIVE_TIMEOUT_PROFILE=high_latency   # for HDD NAS (default | high_latency)
```

All variable names below were checked against the rustfs 1.0.4 sources (`deploy/config/rustfs.env`, `crates/config/src/constants/*.rs`, `rustfs/src/config/cli.rs`). Commonly useful ones:

| Variable | Description |
|---|---|
| `RUSTFS_SERVER_DOMAINS` | Domains for virtual-hosted-style requests (comma separated) |
| `RUSTFS_REGION` | Region |
| `RUSTFS_TLS_PATH` | TLS certificate directory |
| `RUSTFS_OBS_LOGGER_LEVEL` | Log level |
| `RUSTFS_OBS_LOG_DIRECTORY` | Log file directory. When empty, logs go to stdout and end up in the package log |

- The data path (`RUSTFS_VOLUMES`) is set by the start script on every start from the shared folder chosen in the wizard (`SHARE_PATH`). A `RUSTFS_VOLUMES` entry in `environment-variables` is **ignored** and a warning is written to the service log. (This is deliberate: it prevents a leftover config file from pointing at an old path. Multi-volume setups are not supported.) To change the path, change the shared folder in the upgrade wizard.
- Before starting, the script checks that the data folder exists and is writable by `sc-rustfs`. If not, the package does not start and the cause (path, current owner/permissions, how to fix it) is written to the service log as `ERROR:`. Reinstalling the package can change the UID of `sc-rustfs`, so existing files may no longer be writable. In that case, go to Control Panel → Shared Folder → Edit → Permissions, give the internal system user `sc-rustfs` read/write, and in the advanced permissions re-apply it with "Apply to this folder, sub-folders and files".
- Credentials are passed as key files. If you put `RUSTFS_ACCESS_KEY` / `RUSTFS_SECRET_KEY` in the config file, the start script removes them (rustfs refuses to start when both a key value and a key file are given).
- To change the keys, enter new values in the upgrade wizard, or edit the key files above over SSH. Do not add a trailing newline (`printf '%s' 'newkey' > ...`) and keep mode 600.
- Service log: `/var/packages/rustfs/var/rustfs.log`
- Installer log: `/var/log/packages/rustfs.log`

## Upgrade

- Installing a newer SPK the same way (manual install) shows the upgrade wizard.
  - The data shared folder field is pre-filled with the shared folder currently in use.
  - **Leaving the Access key / Secret key fields empty keeps the existing keys.**
- `/var/packages/rustfs/var/` is kept across upgrades. `environment-variables` is not overwritten; the new default config is installed next to it as `environment-variables.new`. Compare the two files and merge changes yourself if needed.
- If you change the shared folder during an upgrade, the new folder is used right after the upgrade. Existing data is not moved automatically.
- Upgrading from 1.0.4-1: the installer turns an existing `RUSTFS_VOLUMES=...` line in the old `environment-variables` into a `# ignored since 1.0.4-2 ...` comment. All other settings are left untouched.
- Data format compatibility follows the upstream RustFS release notes. Back up important data before upgrading.

## Uninstall

Uninstalling from Package Center shows the uninstall wizard (`spk/rustfs/src/wizard/uninstall_uifile`, Korean `uninstall_uifile_krn`).

- **Uninstall only** (default): keeps the settings, keys and logs (`/var/packages/rustfs/var`) and the installer settings (`/var/packages/rustfs/etc`). A reinstall continues where you left off. If you choose a different shared folder, the new folder is used.
- **Delete all package data**: deletes the contents of the two folders above. This also deletes the service log (`rustfs.log`), so back it up first if you need it.
- **Either way, the S3 data in the shared folder (buckets, `.rustfs.sys`) is not deleted.** Remove it yourself if you no longer need it.

### Clean reset

1. Back up the logs first if you need them (SSH, administrator account):
   ```sh
   sudo cp /var/packages/rustfs/var/rustfs.log /var/log/packages/rustfs.log ~/
   ```
2. Uninstall RustFS in Package Center and choose **Delete all package data**.
3. Delete the S3 data. If the shared folder was used only by RustFS, delete it in Control Panel → Shared Folder; otherwise delete `.rustfs.sys` and the bucket folders inside it (e.g. `sudo rm -rf /volume1/rustfs/.rustfs.sys /volume1/rustfs/<bucket>`).
4. Check that nothing is left:
   ```sh
   ls -la /volume*/@appdata/rustfs /volume*/@appconf/rustfs /volume*/@apphome/rustfs 2>&1
   ls -la /var/packages/rustfs 2>&1          # should not exist
   getent passwd sc-rustfs                    # no output means the service account is gone too
   ```
   If the `sc-rustfs` account remains or is created again, its UID may differ. If you reinstalled while keeping old data, follow the permission re-apply steps in "Configuration" above.

## Limitations

- **DSM 7.1 or later only.** The package does not install on DSM 6.x or 7.0.
- **64-bit (x86_64, aarch64) only.** Upstream does not publish other Linux binaries, so 32-bit ARM (armv7, armada38x, alpine, ...), i686 (evansport), PowerPC and ARMv5 models are not supported.
- **Models with Linux kernel 3.10 are not supported.** On some older x64 platforms based on kernel 3.10 (e.g. bromolow, cedarview, avoton), the system calls and kernel features required by current Rust/musl binaries may be missing, so RustFS may not run. These platforms are part of the spksrc x64 group, so the SPK itself installs, but it is not guaranteed to work. A NAS with `uname -r` 4.4 or later is recommended.
- Only a single-node, single-drive setup (one shared folder) is supported (`RUSTFS_VOLUMES` is fixed to the wizard shared folder). Distributed (multi-node) setups are not tested.
- TLS is not enabled by default for the console/API. To expose them externally, use the DSM reverse proxy (Control Panel → Login Portal → Advanced → Reverse Proxy) or `RUSTFS_TLS_PATH`.
- The package icon is an image made in this repository (`scripts/make-icon.py`), not the official RustFS logo.

## Building

### Requirements

- Docker. The spksrc image and the Synology toolchains are x86_64 only, so on arm64 hosts such as Apple Silicon the build runs under `--platform linux/amd64` emulation.
- git (submodule)

### Local build

```sh
git clone --recurse-submodules <this repo> synology-rustfs
cd synology-rustfs
# if already cloned: git submodule update --init --depth 1

./scripts/build.sh            # x64 + aarch64
./scripts/build.sh x64        # x64 only
ls -l dist/                   # rustfs_x64-7.1_1.0.4-3.spk ...
```

What `scripts/build.sh` does:

1. `scripts/sync-overlay.sh` copies `cross/rustfs`, `cross/rustfs-license` and `spk/rustfs` into the `spksrc/` submodule. They are registered in the submodule's `.git/info/exclude`, so the submodule stays clean.
2. Runs `make arch-<arch>-7.1` in the `ghcr.io/synocommunity/spksrc` container. The build runs inside the named volume `synology-rustfs-spksrc`, because bind mounting a case-insensitive file system such as macOS breaks the toolchain extraction. Toolchains and distfiles are cached in this volume.
3. Copies the resulting SPKs to `dist/`.

To run directly inside the spksrc container or in CI, use `NO_DOCKER=1 ./scripts/build.sh x64`.

### Updating to a new upstream version

```sh
./scripts/update-version.sh 1.0.5
```

Downloads the zips, verifies them against the upstream `SHA256SUMS`, regenerates `cross/rustfs/digests` (and `cross/rustfs-license/digests` from the `LICENSE` of the release tag), updates `PKG_VERS` / `SPK_VERS` / `CHANGELOG` and resets `SPK_REV` to 1. If only the packaging changed, just bump `SPK_REV` in `spk/rustfs/Makefile`.

### GitHub Actions

`.github/workflows/build.yml`

- **Manual run** (`workflow_dispatch`): builds x64/aarch64 SPKs for the version in the repository or for an upstream version given as input. Uploads them as artifacts and optionally creates a Release (`v<ver>`).
- **Schedule** (daily): checks the latest release tag of `rustfs/rustfs`. If this repository has no Release for that version yet, it builds and uploads the SPKs and `SHA256SUMS` to a Release. The version change is not committed to the repository (`update-version.sh` is only applied during the build).

## Repository layout and design

```
cross/rustfs/         download/install of the upstream binary (PKG_DIST_ARCH, digests)
cross/rustfs-license/ upstream LICENSE of the release tag (digests) -> share/doc/rustfs/LICENSE
spk/rustfs/           SPK definition (Makefile, service-setup.sh, wizards, .sc, icon, default config)
spksrc/               SynoCommunity/spksrc (git submodule, pinned commit)
scripts/              build.sh, sync-overlay.sh, update-version.sh, make-icon.py
.github/workflows/    CI
```

spksrc is not forked; this repository uses a **submodule + overlay copy** approach.

- This repository only contains our own files (`cross/rustfs*`, `spk/rustfs`), so diffs and reviews stay simple. There is no need to maintain the full spksrc history in a fork.
- The spksrc version is pinned by the submodule commit, so builds are reproducible; update it with `git submodule update --remote`.
- The directories use the same paths and format as in the spksrc tree (`../../mk/...` includes), so moving to SynoCommunity later only requires copying them into a spksrc fork and opening a PR. `MAINTAINER`, the icon, the `REQUIRED_MIN_DSM` policy etc. would then need to follow SynoCommunity's rules.
- Why copy instead of symlink: spksrc Makefiles include `../../mk` by relative path, and make resolves it from the physical path, so the paths break in a symlinked directory.

## License

- This repository is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE).
- Parts of `cross/` and `spk/` are derived from [SynoCommunity/spksrc](https://github.com/SynoCommunity/spksrc) (BSD-3-Clause, included as a submodule); the spksrc copyright notice is reproduced in [NOTICE](NOTICE).
- RustFS is licensed under Apache-2.0 by its authors. The SPK redistributes the unmodified official binaries together with the upstream `LICENSE` (`share/doc/rustfs/LICENSE`). The RustFS 1.0.4 release does not ship a NOTICE file or a third-party license list.
- RustFS and Synology/DSM are trademarks of their respective owners. This is an unofficial project.
