#!/bin/sh
# build.sh - Downloads OpenWrt SDK and builds packages
# Usage: build.sh <version> <full|lite>
# Example: build.sh 24.10.7 full  (produces full theme, dashboard, and .ipk translations)
#          build.sh 25.12.4 lite  (produces lite theme .apk)
#
# OpenWrt 24.x uses opkg/ipk, OpenWrt 25.x+ uses apk.

set -e

VERSION="${1:?Usage: build.sh <version> <full|lite>}"
VARIANT="${2:?Usage: build.sh <version> <full|lite>}"
case "${VARIANT}" in
  full) PACKAGE="luci-theme-fluent" ;;
  lite) PACKAGE="luci-theme-fluent-lite" ;;
  *) echo "ERROR: variant must be full or lite" >&2; exit 1 ;;
esac
SDK_BASE_URL="https://downloads.openwrt.org/releases/${VERSION}/targets/x86/64"

# Use local directory (works on GitHub Actions runners and Docker)
BUILDER_DIR="${HOME}/builder"
SDK_DIR="${BUILDER_DIR}/sdk"
PACKAGES_DIR="${BUILDER_DIR}/packages"
OUTPUT_DIR="${BUILDER_DIR}/output"

# Determine package format from major version
MAJOR_VERSION=$(echo "$VERSION" | cut -d. -f1)
if [ "$MAJOR_VERSION" -ge 25 ]; then
  PKG_FORMAT="apk"
  PKG_EXT="apk"
else
  PKG_FORMAT="opkg"
  PKG_EXT="ipk"
fi

echo "=== OpenWrt ${VERSION} SDK Build ==="
echo "Theme variant: ${VARIANT} (${PACKAGE})"
echo "Package format: ${PKG_FORMAT} (.${PKG_EXT})"
echo "Builder directory: ${BUILDER_DIR}"

# Discover exact SDK filename (handles gcc version changes)
echo ">>> Discovering SDK..."
SDK_TARBALL=$(wget -qO- "${SDK_BASE_URL}/" | grep -oP 'openwrt-sdk-[^"<>]+\.tar\.zst' | head -1)
if [ -z "$SDK_TARBALL" ]; then
  echo "ERROR: Could not find SDK tarball at ${SDK_BASE_URL}/"
  echo "Available files:"
  wget -qO- "${SDK_BASE_URL}/" | grep -oP 'href="[^"]*"' | head -20
  exit 1
fi

SDK_URL="${SDK_BASE_URL}/${SDK_TARBALL}"
echo "SDK: ${SDK_URL}"

# Verify URL exists
echo ">>> Verifying SDK URL..."
HTTP_CODE=$(wget --spider -S "${SDK_URL}" 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: SDK URL returned HTTP ${HTTP_CODE}"
  echo "URL: ${SDK_URL}"
  exit 1
fi
echo "    HTTP ${HTTP_CODE} OK"

# Download SDK
echo ">>> Downloading SDK (${SDK_TARBALL})..."
mkdir -p "${BUILDER_DIR}"
cd "${BUILDER_DIR}"
wget -q -O sdk.tar.zst "${SDK_URL}"

# Extract SDK
echo ">>> Extracting SDK..."
mkdir -p "${SDK_DIR}"
tar --zstd -xf sdk.tar.zst --strip-components=1 -C "${SDK_DIR}"
rm -f sdk.tar.zst

cd "${SDK_DIR}"
echo "SDK root: $(pwd)"
ls -la feeds.conf.default scripts/ 2>/dev/null || { echo "ERROR: SDK extraction failed"; exit 1; }

# Fix feeds to use GitHub mirror (faster)
sed -i 's/git\.openwrt\.org\/project\/luci/github\.com\/openwrt\/luci/g' ./feeds.conf.default
sed -i 's/git\.openwrt\.org\/project\/feeds/github\.com\/openwrt\/feeds/g' ./feeds.conf.default

echo ">>> Updating feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# Copy package sources into SDK package tree
echo ">>> Installing package sources..."
for pkg_dir in ${PACKAGES_DIR}/*/; do
  [ -d "$pkg_dir" ] || continue
  pkg_name=$(basename "$pkg_dir")
  echo "    -> $pkg_name"
  cp -r "$pkg_dir" "./package/$pkg_name"
  chmod 755 -R "./package/$pkg_name"
  # Remove dev sources (src/) — CSS/JS is pre-built and placed via CI artifact
  rm -rf "./package/$pkg_name/src"
done


# Configure
echo ">>> Running defconfig..."
echo "CONFIG_PACKAGE_${PACKAGE}=m" >> .config
if [ "${VARIANT}" = "full" ]; then
  echo "CONFIG_PACKAGE_luci-mod-fluentdashboard=m" >> .config
  echo "CONFIG_PACKAGE_luci-i18n-fluentdashboard-zh-cn=m" >> .config
fi
make defconfig

# Build the selected theme package. Full builds also produce the dashboard replacement.
echo ">>> Building packages..."
if [ "${VARIANT}" = "full" ]; then
  make -j$(nproc) V=s BUILD_LOG=1 \
    "package/${PACKAGE}/compile" \
    "package/luci-mod-fluentdashboard/compile"
else
  make -j$(nproc) V=s BUILD_LOG=1 \
    "package/${PACKAGE}/compile"
fi

# Audit the staged package payload shared by both the IPK and APK builders.
# This catches source-tree fixes that fail to reach the actual router package.
echo ">>> Auditing staged package payload..."
PACKAGE_ROOT=$(find build_dir -type d -path "*/${PACKAGE}/.pkgdir/${PACKAGE}" -print -quit)
if [ -z "${PACKAGE_ROOT}" ] || [ ! -d "${PACKAGE_ROOT}" ]; then
  echo "ERROR: Could not locate staged payload for ${PACKAGE}" >&2
  exit 1
fi
TEMPLATE_ROOT="${PACKAGE_ROOT}/usr/share/ucode/luci/template/themes/fluent"
EXPECTED_VERSION=$(sed -n 's/^PKG_VERSION:=//p' "package/${PACKAGE}/Makefile")
test -d "${TEMPLATE_ROOT}"
test -f "${PACKAGE_ROOT}/www/luci-static/fluent/img/fortigate-community.svg"
test -f "${PACKAGE_ROOT}/www/luci-static/fluent/icon/fortigate-community-32.png"
test -f "${PACKAGE_ROOT}/www/luci-static/fluent/icon/fortigate-community-192.png"
grep -R -q -F "?v=${EXPECTED_VERSION}" "${TEMPLATE_ROOT}"
if grep -R -I -n -e '@VERSION@' -e '{# PKG_VERSION #}' "${PACKAGE_ROOT}"; then
  echo "ERROR: Unresolved package-version token found in staged payload" >&2
  exit 1
fi
if grep -R -I -i -n -e 'LazuliKao' -e 'fluent.svg' -e 'favicon-32.png' -e 'icon-192.png' "${PACKAGE_ROOT}"; then
  echo "ERROR: Legacy author or branding reference found in staged payload" >&2
  exit 1
fi
if [ "${VARIANT}" = "full" ]; then
  grep -q -F 'jxstarthxr/luci-theme-fortiwifi-30e' "${PACKAGE_ROOT}/www/luci-static/resources/view/fluent-config.js"
  grep -q -F 'github.com/jxstarthxr/luci-theme-fortiwifi-30e/releases/download/' "${PACKAGE_ROOT}/usr/libexec/rpcd/luci.fluent"
fi

# Collect the selected package. Full builds also own the shared translations.
echo ">>> Collecting ${PKG_EXT} files..."
mkdir -p "${OUTPUT_DIR}"
find bin -name "${PACKAGE}*.${PKG_EXT}" -exec cp {} "${OUTPUT_DIR}/" \;
if [ "${VARIANT}" = "full" ]; then
  find bin -name "luci-mod-fluentdashboard*.${PKG_EXT}" -exec cp {} "${OUTPUT_DIR}/" \;
  find bin -name "luci-i18n-fluent*.${PKG_EXT}" -exec cp {} "${OUTPUT_DIR}/" \;
fi
if ! find "${OUTPUT_DIR}" -maxdepth 1 -name "${PACKAGE}*.${PKG_EXT}" -print -quit | grep -q .; then
  echo "ERROR: ${PACKAGE} .${PKG_EXT} was not produced" >&2
  exit 1
fi
if [ "${PKG_EXT}" = "ipk" ] && ! find "${OUTPUT_DIR}" -maxdepth 1 -name "${PACKAGE}_*_all.ipk" -print -quit | grep -q .; then
  echo "ERROR: ${PACKAGE} IPK is not architecture-independent" >&2
  exit 1
fi
if [ "${VARIANT}" = "full" ]; then
  if ! find "${OUTPUT_DIR}" -maxdepth 1 -name "luci-mod-fluentdashboard*.${PKG_EXT}" -print -quit | grep -q .; then
    echo "ERROR: luci-mod-fluentdashboard .${PKG_EXT} was not produced" >&2
    exit 1
  fi
  if ! find "${OUTPUT_DIR}" -maxdepth 1 -name "luci-i18n-fluentdashboard-zh-cn*.${PKG_EXT}" -print -quit | grep -q .; then
    echo "ERROR: luci-i18n-fluentdashboard-zh-cn .${PKG_EXT} was not produced" >&2
    exit 1
  fi
  if [ "${PKG_EXT}" = "ipk" ] && ! find "${OUTPUT_DIR}" -maxdepth 1 -name "luci-mod-fluentdashboard_*_all.ipk" -print -quit | grep -q .; then
    echo "ERROR: luci-mod-fluentdashboard IPK is not architecture-independent" >&2
    exit 1
  fi
fi
tar -cJf "${OUTPUT_DIR}/logs.tar.xz" logs 2>/dev/null || true

echo "=== Build complete ==="
echo "Package format: ${PKG_FORMAT} (.${PKG_EXT})"
ls -lh "${OUTPUT_DIR}"/*.${PKG_EXT} 2>/dev/null || echo "Warning: no ${PKG_EXT} files found"
