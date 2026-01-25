# mosdns 分流 + sing-box 安装指南

## 特别鸣谢
- @Panicpanic
- @ovpavac

## 简介
本指南基于手动流程整理成脚本安装步骤，包含 mosdns 分流规则与 sing-box 多内核选择。

- mosdns 规则：O 佬 / PH 佬 两套配置
- sing-box 内核：
  - 官方内核
  - puer sing-box 内核（支持机场）
  - 曦灵 X 内核（支持机场）

## 适用范围
- 仅测试 Ubuntu 22.04；理论支持 Debian 系统
- 架构：amd64 / arm64

## 部署建议
- 建议 sing-box 与 mosdns 分开部署为两个系统
- sing-box 推荐 VM；mosdns 可用 VM 或 LXC

## 一键脚本
```bash
wget https://raw.githubusercontent.com/herozmy/StoreHouse/refs/heads/latest/script/proxy.sh && bash proxy.sh
```

## 安装流程

### 1) 安装 sing-box / mihomo
脚本进入 sing-box 安装流程后，会出现内核选择与安装方式提示。

![image](https://github.com/user-attachments/assets/abaa16a8-a0b9-432d-90f2-105cedec5bde)

选择内核：

![image](https://github.com/user-attachments/assets/500e9f93-b332-405c-ab35-c6234d6f17a5)

- 官方内核支持两种安装方式：
  1. 源码编译安装
  2. 二进制安装

这里以「曦灵 X 核」为例，其他内核同理。选择 3，脚本自动安装内核。

![image](https://github.com/user-attachments/assets/da09fca4-77f8-40d9-85d6-2c73cb60e8a9)

输入你的机场订阅地址（脚本不会储存订阅地址，请放心使用），输入 `y` 安装并写入订阅。

![image](https://github.com/user-attachments/assets/2eddf4be-8cc6-4dc9-a0fa-1c60d39ec3d9)

如需「回家配置」，脚本会提示设置（mihomo 暂未支持）：
- DDNS 域名
- 协议端口号
- 密码
- 内网网段（示例：10.10.10.0/24）

![image](https://github.com/user-attachments/assets/a0c90cd5-2458-4bb0-afdf-93cfcfe163c1)

分流规则选择：
- O 佬规则：用于手机 sing-box 访问内网服务（如需代理需自行补充协议）
- PH 佬规则：配合家里 mosdns 分流，可直接使用 sing-box 节点

![image](https://github.com/user-attachments/assets/e2caa5f3-2f6d-4f15-92b7-583133b9c41b)

PH 规则需要填写 mosdns 服务器地址。
家里 WiFi BSSID 可先保持默认，后续可在手机端 sing-box 日志中查看并回填。

安装完成后配置文件位置：`/root/go_home.json`

常用服务命令：
```bash
systemctl start sing-box
systemctl enable sing-box
systemctl status sing-box
systemctl restart sing-box
systemctl stop sing-box
systemctl disable sing-box
systemctl restart nftables
systemctl status nftables
systemctl restart sing-box-router
systemctl status sing-box-router
```

生成配置后自行下载到手机端 sing-box 使用。

### 2) 安装 mosdns
选择 mosdns 安装脚本：

![image](https://github.com/user-attachments/assets/ee0da52b-6cab-419d-882c-330deecaf6ee)

输入 sing-box/mihomo 入站地址端口（例如：`10.10.10.254:6666`）

![image](https://github.com/user-attachments/assets/66fb2692-82ca-4b8f-92ae-0a8abbcc7df7)

选择分流规则：
- O 佬规则
- PH 佬规则（优势：安装完成后可访问 `http://ip:9099/graphic`）

![image](https://github.com/user-attachments/assets/e32568ae-c46c-42b7-bc48-a4d0fa4da2dd)

安装完成。

### 3) 主路由设置
主路由 fakeip 分流设置参考：
- [ros-fakeip分流模式.md](ros-fakeip分流模式.md)
