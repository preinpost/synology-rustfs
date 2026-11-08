# synology-rustfs

[RustFS](https://github.com/rustfs/rustfs)(S3 호환 오브젝트 스토리지)를 Synology DSM 7.1 이상에서 돌리기 위한 **비공식** DSM 패키지(SPK)입니다.

- RustFS 소스를 빌드하지 않습니다. upstream이 GitHub Release에 올린 **musl 정적 바이너리**(`rustfs-linux-{x86_64,aarch64}-musl-v<ver>.zip`)를 받아서 패키징합니다. 받은 파일은 `cross/rustfs/digests`(SHA1/SHA256/MD5)로 검증합니다.
- 패키징은 [spksrc](https://github.com/SynoCommunity/spksrc) 프레임워크로 하고, 구조는 spksrc의 `spk/minio`를 따랐습니다.
- Synology, SynoCommunity, RustFS 프로젝트 중 어느 쪽에서도 제공하거나 지원하는 패키지가 아닙니다.

| 항목 | 값 |
|---|---|
| RustFS | 1.0.4 |
| 최소 DSM | 7.1 (`os_min_ver="7.1-42661"`) |
| 아키텍처 | `x64`(Intel/AMD 64비트), `aarch64`(ARMv8: rtd1296, rtd1619b, armada37xx) |
| 서비스 계정 | `sc-rustfs` (DSM 7 패키지 전용 사용자) |

## 설치 (수동 설치)

> ⚠️ **신뢰 수준 경고**
> 이 SPK는 Synology 패키지 센터 저장소에서 받는 패키지가 아니고 서명도 없습니다. 설치하면 RustFS 바이너리와 설치 스크립트가 NAS에서 실행됩니다. 이 저장소의 소스(`spk/rustfs/src/service-setup.sh`, 위저드)와 빌드 과정을 직접 확인했거나, 직접 빌드한 SPK만 설치하세요. 패키지 서비스는 root가 아니라 `sc-rustfs` 계정으로 돕니다.

1. NAS 아키텍처를 확인합니다. 제어판 → 정보 센터에서 CPU 모델을 보거나, SSH에서 `uname -m`을 실행합니다(`x86_64` → x64, `aarch64` → aarch64).
2. Release 페이지(또는 직접 빌드한 `dist/`)에서 맞는 파일을 받습니다.
   - `rustfs_x64-7.1_<ver>-<rev>.spk`
   - `rustfs_aarch64-7.1_<ver>-<rev>.spk`
   - Release의 `SHA256SUMS`와 대조해 보세요: `sha256sum -c SHA256SUMS`
3. DSM **패키지 센터 → 수동 설치**에서 SPK를 고릅니다.
   - "알 수 없는 게시자" 경고가 뜨면 위 경고를 읽어 보고 진행합니다.
4. 설치 위저드에 입력할 값:
   - **데이터 공유 폴더**: 기본값 `rustfs`. 공유 폴더가 없으면 패키지가 설치된 볼륨에 새로 만들고, `sc-rustfs`에 읽기/쓰기 권한을 줍니다. 다른 볼륨을 쓰려면 제어판에서 공유 폴더를 먼저 만들어 두고 그 이름을 입력하세요.
   - **Access key**: 3~128자. `=`, `,`, 공백은 쓸 수 없습니다.
   - **Secret key**: 8자 이상. `=`, `,`, 공백은 쓸 수 없습니다.
   - 입력한 키는 `/var/packages/rustfs/var/access_key`, `secret_key` 파일에 권한 600(`sc-rustfs` 소유)으로 저장됩니다. RustFS에는 `RUSTFS_ACCESS_KEY_FILE` / `RUSTFS_SECRET_KEY_FILE` 경로만 넘기므로, 키가 프로세스 환경변수나 installer-variables에 평문으로 남지 않습니다.
5. 설치가 끝나면 DSM 메인 메뉴의 **RustFS** 아이콘을 누르거나 `http://<NAS>:9201/rustfs/console/`로 접속합니다.

## 포트

| 포트 | 용도 | 설정 변수 |
|---|---|---|
| 9200/tcp | S3 API | `RUSTFS_ADDRESS=:9200` |
| 9201/tcp | 웹 콘솔 | `RUSTFS_CONSOLE_ADDRESS=:9201` |

RustFS 기본 포트는 9000/9001입니다. Synology 쪽 서비스나 MinIO 패키지와 겹치지 않도록 이 패키지에서는 9200/9201을 씁니다. 두 포트 모두 DSM 방화벽 서비스 목록에 "RustFS", "RustFS Console"로 등록됩니다(`spk/rustfs/src/rustfs.sc`).

S3 클라이언트 예시:

```sh
aws --endpoint-url http://<NAS>:9200 s3 ls
mc alias set nas http://<NAS>:9200 <access_key> <secret_key>
```

## 설정

사용자 설정 파일은 `/var/packages/rustfs/var/environment-variables`입니다(`${SYNOPKG_PKGVAR}/environment-variables`). 한 줄에 `KEY=VALUE` 하나씩 쓰고, `#`으로 시작하는 줄은 무시합니다. 셸 확장은 되지 않습니다. 고친 뒤에는 패키지를 중지했다가 다시 실행하세요.

설치 직후의 기본값:

```sh
RUSTFS_VOLUMES=/volume1/rustfs        # 위저드에서 고른 공유 폴더의 실제 경로
RUSTFS_ADDRESS=:9200
RUSTFS_CONSOLE_ENABLE=true
RUSTFS_CONSOLE_ADDRESS=:9201
RUSTFS_DRIVE_TIMEOUT_PROFILE=high_latency   # HDD NAS용 (default | high_latency)
```

아래 변수 이름은 모두 rustfs 1.0.4 소스(`deploy/config/rustfs.env`, `crates/config/src/constants/*.rs`, `rustfs/src/config/cli.rs`)에서 확인했습니다. 자주 쓸 만한 것:

| 변수 | 설명 |
|---|---|
| `RUSTFS_VOLUMES` | 데이터 경로. 여러 개면 공백으로 구분 |
| `RUSTFS_SERVER_DOMAINS` | virtual-hosted-style 요청용 도메인(쉼표로 구분) |
| `RUSTFS_REGION` | 리전 |
| `RUSTFS_TLS_PATH` | TLS 인증서 디렉터리 |
| `RUSTFS_OBS_LOGGER_LEVEL` | 로그 레벨 |
| `RUSTFS_OBS_LOG_DIRECTORY` | 로그 파일 디렉터리. 비워 두면 stdout으로 나가고, 패키지 로그에 기록됨 |

- 자격 증명은 키 파일로 넘깁니다. `RUSTFS_ACCESS_KEY` / `RUSTFS_SECRET_KEY`를 설정 파일에 적어도 시작 스크립트가 지웁니다(rustfs는 키 값과 키 파일을 동시에 주면 실행을 거부합니다).
- 키를 바꾸려면 업그레이드 위저드에서 새 값을 넣거나, SSH에서 위 키 파일을 직접 고칩니다. 끝에 줄바꿈이 들어가지 않게 하고(`printf '%s' 'newkey' > ...`), 권한은 600으로 유지하세요.
- 서비스 로그: `/var/packages/rustfs/var/rustfs.log`
- 설치 로그: `/var/log/packages/rustfs.log`

## 업그레이드

- 새 버전 SPK를 같은 방식(수동 설치)으로 올리면 업그레이드 위저드가 뜹니다.
  - 데이터 공유 폴더 칸에는 지금 쓰는 공유 폴더 이름이 미리 들어가 있습니다.
  - Access key / Secret key 칸을 **비워 두면 기존 키를 그대로 씁니다**.
- `/var/packages/rustfs/var/`는 업그레이드해도 유지됩니다. `environment-variables`는 덮어쓰지 않으며, 새 기본 설정 파일은 옆에 `environment-variables.new`로 설치됩니다. 필요하면 두 파일을 직접 비교해 반영하세요.
- 업그레이드할 때 공유 폴더를 바꿨다면 `environment-variables`의 `RUSTFS_VOLUMES`도 직접 고쳐야 합니다. 기존 데이터는 자동으로 옮겨지지 않습니다.
- 데이터 포맷 호환성은 upstream RustFS 릴리즈 노트를 따릅니다. 업그레이드 전에 중요한 데이터를 백업하세요.

## 제한사항

- **DSM 7.1 이상만** 지원합니다. DSM 6.x와 7.0에는 설치되지 않습니다.
- **64비트(x86_64, aarch64)만** 지원합니다. upstream이 그 밖의 Linux 바이너리를 내지 않기 때문에 32비트 ARM(armv7, armada38x, alpine 등), i686(evansport), PowerPC, ARMv5 모델은 지원 대상이 아닙니다.
- **리눅스 커널 3.10 모델은 지원하지 않습니다.** 커널 3.10 기반 일부 x64 플랫폼(예: bromolow, cedarview, avoton 등 오래된 모델)에서는 최신 Rust/musl 바이너리가 요구하는 시스템 콜·커널 기능이 부족해 실행이 안 될 수 있습니다. spksrc x64 그룹에 포함돼 있어서 SPK 자체는 설치되지만, 동작은 보장하지 않습니다. `uname -r`이 4.4 이상인 NAS를 권장합니다.
- 단일 노드·단일 드라이브(공유 폴더 1개) 구성이 기본입니다. 분산(멀티 노드) 구성은 테스트하지 않았습니다.
- 콘솔/API에 TLS가 기본으로 켜져 있지 않습니다. 외부에 노출하려면 DSM 리버스 프록시(제어판 → 로그인 포털 → 고급 → 리버스 프록시)나 `RUSTFS_TLS_PATH`를 쓰세요.
- 패키지 아이콘은 이 저장소에서 따로 만든 이미지이고(`scripts/make-icon.py`), RustFS 공식 로고가 아닙니다.

## 빌드 방법

### 요구 사항

- Docker. spksrc 이미지와 Synology 툴체인이 x86_64 전용이라, Apple Silicon 같은 arm64 호스트에서는 `--platform linux/amd64` 에뮬레이션으로 돌아갑니다.
- git (submodule)

### 로컬 빌드

```sh
git clone --recurse-submodules <this repo> synology-rustfs
cd synology-rustfs
# 이미 clone했다면: git submodule update --init --depth 1

./scripts/build.sh            # x64 + aarch64
./scripts/build.sh x64        # x64만
ls -l dist/                   # rustfs_x64-7.1_1.0.4-1.spk ...
```

`scripts/build.sh`가 하는 일:

1. `scripts/sync-overlay.sh`로 `cross/rustfs`, `spk/rustfs`를 `spksrc/` 서브모듈 안에 복사합니다. 서브모듈의 `.git/info/exclude`에 등록해 두므로 서브모듈 상태는 깨끗하게 유지됩니다.
2. `ghcr.io/synocommunity/spksrc` 컨테이너에서 `make arch-<arch>-7.1`을 실행합니다. 빌드는 named volume `synology-rustfs-spksrc` 안에서 합니다. macOS 같은 대소문자 비구분 파일시스템을 bind mount하면 툴체인 압축 해제가 실패하기 때문입니다. 툴체인과 배포 파일은 이 볼륨에 캐시됩니다.
3. 결과 SPK를 `dist/`로 복사합니다.

spksrc 컨테이너 안이나 CI에서 바로 돌리려면 `NO_DOCKER=1 ./scripts/build.sh x64`를 씁니다.

### upstream 새 버전 반영

```sh
./scripts/update-version.sh 1.0.5
```

zip을 받아 upstream `SHA256SUMS`와 대조한 뒤 `cross/rustfs/digests`를 다시 만들고, `PKG_VERS` / `SPK_VERS` / `CHANGELOG`를 갱신하며 `SPK_REV`는 1로 되돌립니다. 패키징만 바꾼 경우에는 `spk/rustfs/Makefile`의 `SPK_REV`만 올리세요.

### GitHub Actions

`.github/workflows/build.yml`

- **수동 실행**(`workflow_dispatch`): 저장소에 있는 버전 또는 입력한 upstream 버전으로 x64/aarch64 SPK를 빌드합니다. 아티팩트로 올리고, 선택하면 Release(`v<ver>`)도 만듭니다.
- **스케줄**(매일): `rustfs/rustfs`의 최신 릴리즈 태그를 확인합니다. 이 저장소에 같은 버전의 Release가 아직 없으면 빌드해서 Release에 SPK와 `SHA256SUMS`를 올립니다. 버전 변경을 저장소에 커밋하지는 않습니다(빌드할 때만 `update-version.sh` 적용).

## 저장소 구조와 설계

```
cross/rustfs/      upstream 바이너리 다운로드/설치 (PKG_DIST_ARCH 방식, digests)
spk/rustfs/        SPK 정의 (Makefile, service-setup.sh, 위저드, .sc, 아이콘, 기본 설정)
spksrc/            SynoCommunity/spksrc (git submodule, 커밋 고정)
scripts/           build.sh, sync-overlay.sh, update-version.sh, make-icon.py
.github/workflows/ CI
```

spksrc는 fork하지 않고 **submodule + 오버레이 복사** 방식을 썼습니다.

- 이 저장소에는 우리 파일(`cross/rustfs`, `spk/rustfs`)만 들어 있어 diff와 리뷰가 단순합니다. spksrc 전체 이력을 fork로 관리할 필요가 없습니다.
- spksrc 버전은 submodule 커밋으로 고정해 빌드를 재현할 수 있고, `git submodule update --remote`로 올립니다.
- 두 디렉터리는 spksrc 트리에서 쓰는 경로·형식(`../../mk/...` include) 그대로라서, 나중에 SynoCommunity로 옮길 때는 `cross/rustfs`, `spk/rustfs`를 spksrc fork에 복사해 PR하면 됩니다. 이때 `MAINTAINER`, 아이콘, `REQUIRED_MIN_DSM` 정책 등은 SynoCommunity 기준에 맞춰 조정해야 합니다.
- 심볼릭 링크 대신 복사하는 이유: spksrc Makefile은 `../../mk`를 상대 경로로 include하는데, make는 물리 경로를 기준으로 하기 때문에 심볼릭 링크로 연결한 디렉터리에서는 경로가 깨집니다.

## 라이선스

- RustFS: Apache-2.0 (upstream)
- spksrc: BSD-3-Clause (submodule)
