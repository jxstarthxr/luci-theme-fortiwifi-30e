<div align="center">
<img src="./package/luci-theme-fluent/htdocs/luci-static/fluent/img/fluent.svg" alt="FortiWiFi 30E community theme emblem" width="112" />

# FortiWiFi 30E Community Theme

An unofficial FortiGate-inspired LuCI theme for a FortiWiFi 30E running OpenWrt.

[![license](https://img.shields.io/badge/license-Apache_2.0-blue.svg?style=flat-square)](./LICENSE)
[![CI](https://github.com/jxstarthxr/luci-theme-fortiwifi-30e/actions/workflows/ci.yml/badge.svg)](https://github.com/jxstarthxr/luci-theme-fortiwifi-30e/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/jxstarthxr/luci-theme-fortiwifi-30e?style=flat-square)](https://github.com/jxstarthxr/luci-theme-fortiwifi-30e/releases)

</div>

This fork keeps the stable internal package/config identifiers from [`LazuliKao/luci-theme-fluent`](https://github.com/LazuliKao/luci-theme-fluent). Keeping `luci-theme-fluent`, `/luci-static/fluent`, and the `fluent` UCI namespace avoids unnecessary upgrade conflicts while all user-facing branding is presented as the FortiGate community theme.

## What is customized

- FortiGate orange (`#f4511e`) is the default light accent; a brighter orange is used in dark mode.
- Original shield, network, and Wi-Fi artwork is used for the header, login page, app icon, and favicons.
- The login canvas uses a warm orange/red palette.
- LuCI menu, settings, about page, dashboard, package descriptions, and web-app metadata use FortiGate community branding.
- The built-in updater reads releases from this fork and verifies GitHub SHA-256 asset digests when available.
- A scheduled GitHub Action proposes upstream changes in a pull request, keeping updates reviewable.

Accent colors and the other appearance settings remain editable under **System → FortiGate Theme**.

## Install

The automated builds target OpenWrt 24.10 (`.ipk`) and OpenWrt 25.12 (`.apk`). The full theme includes the settings page and GUI updater; the lite build omits the updater and optional enhancements.

Install the latest stable release:

```sh
wget -qO- https://raw.githubusercontent.com/jxstarthxr/luci-theme-fortiwifi-30e/main/install.sh | sh
```

Install the rolling nightly release:

```sh
wget -qO- https://raw.githubusercontent.com/jxstarthxr/luci-theme-fortiwifi-30e/main/install.sh | sh -s nightly
```

Or download the correct package from the [release page](https://github.com/jxstarthxr/luci-theme-fortiwifi-30e/releases) and install it manually:

```sh
# OpenWrt 24.10.x
opkg install /tmp/luci-theme-fluent_*.ipk

# OpenWrt 25.12.x
apk add --allow-untrusted /tmp/luci-theme-fluent-*.apk
```

Only install one variant (`luci-theme-fluent` or `luci-theme-fluent-lite`) at a time.

## Update from LuCI

Open **System → FortiGate Theme → About**, choose a release channel, and select **Check for updates**. Stable uses the newest `v*` release. Nightly uses the package rebuilt after changes land on `main`.

The official GitHub backend is recommended. The optional GHProxy route is allowed only when GitHub supplied SHA-256 digests for every package, so proxy downloads are never installed without integrity verification.

## Publishing the first builds

GitHub Actions must be enabled for the fork.

- Pushing to `main` runs tests/builds and refreshes the `nightly` prerelease.
- Pushing a version tag such as `v1.0.10` creates a stable release.
- The release must contain the package format matching the router before the LuCI updater can offer it.

Example stable release:

```sh
git tag v1.0.10
git push origin v1.0.10
```

## Keep the fork current

The `Sync upstream` workflow runs every Monday and can also be started manually from the Actions tab. It merges `LazuliKao/luci-theme-fluent:main` into `automation/sync-upstream` and opens or refreshes a pull request. CI then tests the combined result before you merge it.

For a local sync:

```sh
git fetch upstream
git switch main
git merge --no-ff upstream/main
pnpm install --frozen-lockfile
pnpm run build
pnpm run test
pnpm run typecheck
pnpm run lint
git push origin main
```

If upstream touches the same branding or updater lines, resolve the pull request manually and retain the fork repository URL, orange defaults, community artwork, and trademark disclaimer.

## Development

```sh
pnpm install
pnpm run build
pnpm run build:lite
pnpm run test
pnpm run typecheck
pnpm run lint
pnpm run icons:generate
```

Generated output is written under `package/luci-theme-fluent/htdocs/luci-static/`, `package/luci-theme-fluent-lite/htdocs/luci-static/`, and `package/luci-mod-fluentdashboard/htdocs/`.

## Naming and trademark note

This is an independent community theme and is not affiliated with or endorsed by Fortinet. It intentionally uses original emblem artwork rather than Fortinet's official logos. See [TRADEMARKS.md](./TRADEMARKS.md) before publishing branding changes.

Fortinet, FortiGate, and FortiWiFi are trademarks of Fortinet, Inc. Microsoft Fluent remains the design-system/source attribution for the upstream codebase.

## Credits and license

- Original theme: [LazuliKao/luci-theme-fluent](https://github.com/LazuliKao/luci-theme-fluent)
- [OpenWrt](https://openwrt.org/) and [LuCI](https://github.com/openwrt/luci)
- Licensed under [Apache-2.0](./LICENSE)
