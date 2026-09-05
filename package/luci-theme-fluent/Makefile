include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-fluent
PKG_VERSION:=1.0.13
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0

LUCI_TITLE:=FortiGate Community Theme for LuCI
LUCI_DEPENDS:=+luci-base
LUCI_MINIFY_CSS:=0
LUCI_MAINTAINER:=jxstarthxr
LUCI_URL:=https://github.com/jxstarthxr/luci-theme-fortiwifi-30e

define Package/$(PKG_NAME)/conffiles
/etc/config/fluent
endef


define Package/$(PKG_NAME)/preinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	if command -v apk >/dev/null 2>&1 && apk info -e luci-theme-fluent-lite >/dev/null 2>&1; then
		echo "luci-theme-fluent-lite is installed; remove it before installing luci-theme-fluent" >&2
		exit 1
	fi
	if command -v opkg >/dev/null 2>&1 && opkg list-installed luci-theme-fluent-lite 2>/dev/null | grep -q '^luci-theme-fluent-lite '; then
		echo "luci-theme-fluent-lite is installed; remove it before installing luci-theme-fluent" >&2
		exit 1
	fi
}
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete luci.themes.Fluent
	uci batch <<-EOF
		set luci.themes.FortiGate=/luci-static/fluent
		commit luci
	EOF
	/etc/init.d/rpcd restart
}
endef

# call BuildPackage - OpenWrt buildroot signature
include $(TOPDIR)/feeds/luci/luci.mk
