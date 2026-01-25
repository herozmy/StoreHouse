# RouterOS fakeip 分流模式（MikroTik）

## 适用范围
- RouterOS / MikroTik
- 配合 sing-box 或 mihomo 作为代理网关

## 说明
- 本文使用 `proxy-v4` / `proxy-v6` 作为 routing mark
- 请将示例中的网关地址替换为你自己的代理网关地址
  - IPv4 示例：10.10.10.254
  - IPv6 示例：dc00::2222

## IPv4 配置

### 1. 创建路由表
```bash
/routing table add name=proxy-v4 fib
```

### 2. 地址列表（fakeip + TG/奈菲/公共 DNS 示例）
```bash
/ip firewall address-list add list=proxy_ipv4 address=28.0.0.0/8
/ip firewall address-list add list=proxy_ipv4 address=207.45.72.0/22
/ip firewall address-list add list=proxy_ipv4 address=208.75.76.0/22
/ip firewall address-list add list=proxy_ipv4 address=210.0.153.0/24
/ip firewall address-list add list=proxy_ipv4 address=91.108.56.0/22
/ip firewall address-list add list=proxy_ipv4 address=91.108.4.0/22
/ip firewall address-list add list=proxy_ipv4 address=91.108.8.0/22
/ip firewall address-list add list=proxy_ipv4 address=91.108.16.0/22
/ip firewall address-list add list=proxy_ipv4 address=91.108.12.0/22
/ip firewall address-list add list=proxy_ipv4 address=149.154.160.0/20
/ip firewall address-list add list=proxy_ipv4 address=91.105.192.0/23
/ip firewall address-list add list=proxy_ipv4 address=91.108.20.0/22
/ip firewall address-list add list=proxy_ipv4 address=185.76.151.0/24
/ip firewall address-list add list=proxy_ipv4 address=95.161.64.0/20
/ip firewall address-list add list=proxy_ipv4 address=8.8.8.8/32
/ip firewall address-list add list=proxy_ipv4 address=8.8.4.4/32
/ip firewall address-list add list=proxy_ipv4 address=1.1.1.1/32
/ip firewall address-list add list=proxy_ipv4 address=1.0.0.1/32
```

### 3. 打标（mangle）
```bash
/ip firewall mangle add action=mark-routing chain=prerouting dst-address-list=proxy_ipv4 new-routing-mark=proxy-v4 passthrough=yes
```

### 4. 路由（指向代理网关）
```bash
/ip route add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=10.10.10.254 routing-table=proxy-v4 scope=30 suppress-hw-offload=no target-scope=10
```

### 5. NAT 伪装排除（可选）
用于在 sing-box/mihomo UI 中显示源地址 IP：

![image](https://github.com/user-attachments/assets/cfb992b0-a2ba-45d1-b2a8-8588996baf94)

## IPv6 配置

### 1. 创建路由表
```bash
/routing table add name=proxy-v6 fib
```

### 2. 地址列表（fakeip + TG v6）
```bash
/ipv6 firewall address-list add address=f2b0::/18 list=proxy_ipv6
/ipv6 firewall address-list add address=2001:b28:f23d::/48 list=proxy_ipv6
/ipv6 firewall address-list add address=2001:b28:f23f::/48 list=proxy_ipv6
/ipv6 firewall address-list add address=2001:67c:4e8::/48 list=proxy_ipv6
/ipv6 firewall address-list add address=2001:b28:f23c::/48 list=proxy_ipv6
/ipv6 firewall address-list add address=2a0a:f280::/32 list=proxy_ipv6
```

### 3. 打标（mangle）
```bash
/ipv6 firewall mangle add action=mark-routing chain=prerouting dst-address-list=proxy_ipv6 new-routing-mark=proxy-v6
```

### 4. 路由（指向代理网关）
```bash
/ipv6 route add dst-address=::/0 gateway=dc00::2222 routing-table=proxy-v6
```

### 5. 添加 v6 路由规则
```bash
/routing rule add action=lookup-only-in-table comment="for ipv6 mangle effective in route" disabled=no routing-mark=proxy-v6 table=proxy-v6
```

### 6. NAT 伪装排除（可选）
![image](https://github.com/user-attachments/assets/ba010fb0-e269-4009-b1df-ee245351f4de)
