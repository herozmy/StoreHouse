# RouterOS 从 0 开始基础设置

## 1. 初始化
- RouterOS 恢复原厂设置
```bash
/system reset-configuration
```

## 2. 配置网卡名称与拨号
请先确认 LAN/WAN 口，自行更改 ether1/ether2 名称，多个网卡以此类推。
```bash
/interface set ether1 name=lan
/interface set ether2 name=wan
/interface pppoe-client add name=pppoe-out1 interface=wan disabled=no
```

## 3. 建立 bridge 桥接
```bash
/interface bridge add name=bridge1
/interface bridge port add bridge=bridge1 interface=lan
```

## 4. 配置网络地址
```bash
/ip address add interface=bridge1 address=10.10.10.1/24 network=10.10.10.10
# WAN 口地址为光猫地址，方便访问光猫，可不配置
/ip address add interface=wan address=192.168.1.2/24 network=192.168.1 disabled=yes
```

## 5. 配置 DHCP
```bash
/ip pool add name=dhcpv4-pool1 ranges=10.10.10.100-10.10.10.200
/ip dhcp-server add name=dhcpv4-server1 interface=bridge1 address-pool=dhcpv4-pool1 lease-time=1d
/ip dhcp-server network add address=10.10.10.0/24 gateway=10.10.10.1 dns-server=10.10.10.1
```
- DHCP 范围示例为 `100-200`，其余地址可用于静态分配
- 若 LAN 网段不同，请同步修改网关与 DNS

## 6. 配置 DNS
```bash
/ip dns set servers=223.5.5.5 allow-remote-requests=yes max-concurrent-queries=4096 max-concurrent-tcp-sessions=512 cache-size=8192 cache-max-ttl=04:00:00
```

## 7. 配置源地址伪装（NAT）
```bash
/ip firewall nat add action=masquerade chain=srcnat
```

## 8. 配置 IPv4 防火墙
### filter
```bash
/ip firewall filter add action=accept chain=forward in-interface=bridge1
/ip firewall filter add action=accept chain=input in-interface=bridge1
/ip firewall filter add action=accept chain=input connection-state=established,related
/ip firewall filter add action=accept chain=input in-interface=!pppoe-out1 protocol=icmp
/ip firewall filter add action=drop chain=input connection-state=invalid in-interface=pppoe-out1
/ip firewall filter add action=drop chain=input in-interface=pppoe-out1 protocol=icmp
/ip firewall filter add action=drop chain=input dst-port=53,8291,80 in-interface=pppoe-out1 protocol=tcp
/ip firewall filter add action=drop chain=input dst-port=53,8291,80 in-interface=pppoe-out1 protocol=udp
/ip firewall filter add action=drop chain=input in-interface=pppoe-out1 src-address-list=BlockIP
/ip firewall filter add action=add-src-to-address-list address-list=BlockIP address-list-timeout=1w chain=input dst-port=!53,443,853 in-interface=pppoe-out1 protocol=tcp psd=21,5s,3,1
/ip firewall filter add action=add-src-to-address-list address-list=BlockIP address-list-timeout=1w chain=input dst-port=!53,443,853 in-interface=pppoe-out1 protocol=udp psd=21,5s,3,1
/ip firewall filter add action=drop chain=input src-address-list=BlockIP
```

### mangle
```bash
/ip firewall mangle add action=change-mss chain=forward protocol=tcp tcp-flags=syn new-mss=clamp-to-pmtu passthrough=yes
/ip firewall mangle add action=change-mss chain=output protocol=tcp tcp-flags=syn new-mss=clamp-to-pmtu passthrough=yes
```

### 关闭 service-port
```bash
/ip firewall service-port disable ftp
/ip firewall service-port disable irc
/ip firewall service-port disable pptp
/ip firewall service-port disable rtsp
/ip firewall service-port disable sip
/ip firewall service-port disable tftp
```

## 9. 关闭相关端口及服务
```bash
/ip smb set enabled=no
/ip smb shares disable numbers=0
/ip ssh set forwarding-enabled=no
/ip socks set enabled=no
/ip upnp set enabled=no
/ip proxy set enabled=no
/ip service disable api
/ip service disable api-ssl
/ip service disable ftp
/ip service disable ssh
/ip service disable telnet
/ip service disable www
/ip service disable www-ssl
/tool bandwidth-server set enabled=no
```

## 10. 配置时区和 NTP
```bash
/system clock set time-zone-name="Asia/Shanghai"
/system clock manual set time-zone=+08:00
/system ntp client set enabled=yes servers=cn.pool.ntp.org,ntp1.aliyun.com,time1.cloud.tencent.com
```

## 11. PPPoE 拨号
配置 `pppoe-out1` 接口拨号，User 填宽带账号，Password 填宽带密码，完成后即可上网。

## 12. 开启 IPv6（NAT6）
使用 NAT6 配置，IPv6 内网网段为 `dc00::/64`，bridge1 地址为 `dc00::1111/64`。
```bash
/ipv6 settings set disable-ipv6=no
```

### 获取 IPv6 前缀
```bash
/ipv6 dhcp-client add interface=pppoe-out1 pool-name=dhcpv6-gua-pool1 pool-prefix-length=60 request=prefix
```

### 添加局域网 ULA 地址池
```bash
/ipv6 pool add name=dhcpv6-ula-pool1 prefix=dc00::/64 prefix-length=64
```

### 配置 bridge1 的 ULA 地址
```bash
/ipv6 address add address=dc00::1111/64 from-pool=dhcpv6-ula-pool1 interface=bridge1
```

### 配置动态源地址伪装（NAT6）
```bash
/ipv6 firewall nat add chain=srcnat action=masquerade
```

### 禁用默认 ND 配置，新建配置
```bash
/ipv6 nd set [ find default=yes ] advertise-dns=no disabled=yes
/ipv6 nd add advertise-dns=no advertise-mac-address=no interface=bridge1 managed-address-configuration=yes other-configuration=yes ra-interval=5m-15m
```

### 配置 IPv6 防火墙
```bash
/ipv6 firewall filter add action=accept chain=forward in-interface=bridge1
/ipv6 firewall filter add action=accept chain=input in-interface=bridge1
/ipv6 firewall filter add action=accept chain=input connection-state=established,related
/ipv6 firewall filter add action=accept chain=input in-interface=!pppoe-out1 protocol=icmpv6
/ipv6 firewall filter add action=drop chain=input connection-state=invalid in-interface=pppoe-out1
/ipv6 firewall filter add action=drop chain=input in-interface=pppoe-out1 protocol=icmpv6
/ipv6 firewall filter add action=drop chain=input dst-port=53,8291,80 in-interface=pppoe-out1 protocol=tcp
/ipv6 firewall filter add action=drop chain=input dst-port=53,8291,80 in-interface=pppoe-out1 protocol=udp
```
