<div align="center">
<img src="./package/luci-theme-fluent/htdocs/luci-static/fluent/img/fluent.svg" alt="FortiWiFi 30E 社区主题图标" width="112" />

# FortiWiFi 30E 社区主题

为运行 OpenWrt 的 FortiWiFi 30E 制作的非官方 FortiGate 风格 LuCI 主题。
</div>

本分支基于 [`LazuliKao/luci-theme-fluent`](https://github.com/LazuliKao/luci-theme-fluent)。为了方便合并上游更新，软件包名、`fluent` UCI 配置命名空间和静态资源路径保持不变；用户界面则显示为 FortiGate 社区主题。

## 主要定制

- 默认浅色强调色为 FortiGate 橙色 `#f4511e`，深色模式使用更明亮的橙色。
- 顶栏、登录页、应用图标和 favicon 使用原创的盾牌、网络与 Wi-Fi 图案。
- 登录动态背景采用橙红配色。
- LuCI 设置页、状态面板、软件包说明和内置更新器均指向本分支。
- GitHub Actions 每周创建上游同步 Pull Request，经过 CI 后再合并。

所有颜色仍可在 **系统 → FortiGate Theme** 中修改。

## 安装

安装最新稳定版：

```sh
wget -qO- https://raw.githubusercontent.com/jxstarthxr/luci-theme-fortiwifi-30e/main/install.sh | sh
```

安装 nightly 版：

```sh
wget -qO- https://raw.githubusercontent.com/jxstarthxr/luci-theme-fortiwifi-30e/main/install.sh | sh -s nightly
```

OpenWrt 24.10 使用 `.ipk`，OpenWrt 25.12 使用 `.apk`。完整版本包含设置页面和 GUI 更新器；lite 版本不包含更新器和可选增强功能。

## GUI 更新

进入 **系统 → FortiGate Theme → 关于**，选择稳定版或 nightly 通道，然后点击检查更新。建议使用 GitHub 官方下载方式。仅当所有软件包都有 GitHub SHA-256 摘要时，界面才允许通过 GHProxy 安装。

## 上游同步

`Sync upstream` 工作流每周一运行，也可以在 Actions 页面手动运行。它会把上游 `main` 合并到 `automation/sync-upstream` 分支，并创建或更新 Pull Request。若同一处定制发生冲突，需要手动保留本分支的仓库地址、橙色默认值、原创图标和商标声明。

## 商标说明

这是独立社区项目，与 Fortinet 没有关联，也未获得 Fortinet 赞助或认可。项目不包含 Fortinet 官方 logo，而使用原创图标。详情请阅读 [TRADEMARKS.md](./TRADEMARKS.md)。

Fortinet、FortiGate 和 FortiWiFi 是 Fortinet, Inc. 的商标。代码按照 [Apache-2.0](./LICENSE) 许可证发布。
