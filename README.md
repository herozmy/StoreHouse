# Herozmy 私人存储仓库

面向自用/分享的构建产物与脚本文档集合，包含 sing-box / mihomo / mosdns 等相关组件。

## Release 每日编译
- sing-box 稳定版
- sing-box dev 开发版
- sing-box p 稳定版
- sing-box reF1nd（reF1nd 佬 R 核心）
- sing-box y 稳定版 / dev 开发版
- mihomo 稳定版 / 开发版
- mosdns（PH 魔改 UI 增强版本）

## 脚本
- install.sh：基础安装脚本（当前不包含 MyBox）
  ```bash
  wget https://raw.githubusercontent.com/herozmy/StoreHouse/refs/heads/latest/install.sh && bash install.sh
  ```
- proxy.sh：一键安装 sing-box / mosdns 分流环境
  文档见 `docs/router/mosdns分流sing-box安装指南.md`
  ```bash
  wget https://raw.githubusercontent.com/herozmy/StoreHouse/refs/heads/latest/script/proxy.sh && bash proxy.sh
  ```

## 文档导航
- 文档目录：`docs/README.md`
- RouterOS 基础设置：`docs/router/ros基础设置.md`
- RouterOS fakeip 分流：`docs/router/ros-fakeip分流模式.md`
- mosdns 分流 + sing-box 安装指南：`docs/router/mosdns分流sing-box安装指南.md`
- MyBox 详细文档：`mybox/README.md`

## MyBox 代理服务控制中心
当前版本：v1.1.0（2025-09-10）

MyBox 是一个现代化的代理服务控制中心，提供 Sing-Box 与 MosDNS 的服务管理、配置编辑、实时监控等能力。
完整特性、使用指南与构建说明请查看：`mybox/README.md`
