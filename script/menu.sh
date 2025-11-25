#!/bin/bash
#
# 服务管理菜单
# 优化版本: 1.0

# --- 颜色定义 ---
green_text="\033[32m"
yellow_text="\033[33m"
red_text="\033[31m"
grey_text="\033[90m"
reset="\033[0m"

# --- 变量定义 ---
DIRPATH="/usr/local/bin/tools"
local_ip=$(hostname -I | awk '{print $1}')
# --- 工具函数 ---
# 确保 proxytool 命令可用
ensure_proxytool() {
    if ! command -v proxytool &> /dev/null; then
        echo "检测到 proxytool 未安装，正在设置..."
        cp "$DIRPATH/proxytool.sh" /usr/bin/proxytool
        chmod +x /usr/bin/proxytool
        echo "proxytool 已设置。"
    fi
    proxytool
}

# 获取服务状态: 1=运行中, 0=未运行, 9=未安装
get_service_status() {
    local program_name=$1
    local program_path="/usr/local/bin/$program_name"
    local service_name=$program_name
    
    # Redis服务名与程序名不同
    [[ "$program_name" == "redis-server" ]] && service_name="redis"
    
    # 检查安装和运行状态
    if [[ ! -f "$program_path" ]]; then 
        return 9  # 未安装
    elif systemctl is-active --quiet "$service_name"; then 
        return 1  # 运行中
    else 
        return 0  # 未运行
    fi
}

# 格式化状态显示
format_status_for_menu() {
    case $1 in
        1) echo -e "${green_text}[运行中]${reset}" ;;
        0) echo -e "${red_text}[未运行]${reset}" ;;
        9) echo -e "${grey_text}[未安装]${reset}" ;;
    esac
}

# 获取网络配置状态
get_network_status() {
    local first_interface=$(ip link show | grep -E "^[0-9]+:" | grep -v "lo:" | head -1 | awk -F': ' '{print $2}' | awk '{print $1}')
    
    if [[ -z "$first_interface" ]]; then
        return 9  # 无接口
    fi
    
    # 检查是否为DHCP配置
    local is_dhcp=false
    
    # 检查netplan配置
    if ls /etc/netplan/*.yaml &>/dev/null; then
        if grep -q "dhcp4.*true" /etc/netplan/*.yaml 2>/dev/null; then
            is_dhcp=true
        fi
    fi
    
    # 检查NetworkManager配置
    if command -v nmcli &>/dev/null; then
        local nm_method=$(nmcli connection show "$first_interface" 2>/dev/null | grep "ipv4.method" | awk '{print $2}')
        if [[ "$nm_method" == "auto" ]]; then
            is_dhcp=true
        fi
    fi
    
    # 检查interfaces文件
    if [[ -f "/etc/network/interfaces" ]] && grep -q "iface.*inet dhcp" /etc/network/interfaces 2>/dev/null; then
        is_dhcp=true
    fi
    
    # 检查是否有有效IP地址
    local has_ip=false
    if ip -4 addr show "$first_interface" 2>/dev/null | grep -q "inet "; then
        has_ip=true
    fi
    
    # 返回状态: 1=DHCP, 0=静态, 9=未配置
    if [[ "$has_ip" == false ]]; then
        return 9  # 未配置
    elif [[ "$is_dhcp" == true ]]; then
        return 1  # DHCP
    else
        return 0  # 静态
    fi
}

# 格式化网络状态显示
format_network_status() {
    case $1 in
        1) echo -e "${green_text}[DHCP]${reset}" ;;
        0) echo -e "${yellow_text}[静态]${reset}" ;;
        9) echo -e "${grey_text}[未配置]${reset}" ;;
    esac
}

# 检查系统优化状态
get_system_optimization_status() {
    local bbr_enabled=false
    local config_exists=false
    local modules_loaded=false
    
    # 检查 BBR 是否已启用
    if command -v sysctl &> /dev/null; then
        local current_bbr=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "")
        if [[ "$current_bbr" == "bbr" ]]; then
            bbr_enabled=true
        fi
    fi
    
    # 检查配置文件是否存在
    if [[ -f "/etc/sysctl.d/99-sysctl.conf" ]] && grep -q "MosDNS 系统优化配置" "/etc/sysctl.d/99-sysctl.conf" 2>/dev/null; then
        config_exists=true
    fi
    
    # 检查内核模块是否已加载
    if lsmod | grep -q "tcp_bbr\|sch_fq" 2>/dev/null; then
        modules_loaded=true
    fi
    
    # 返回优化状态
    if [[ "$bbr_enabled" == true ]] && [[ "$config_exists" == true ]] && [[ "$modules_loaded" == true ]]; then
        return 1  # 已完全优化
    elif [[ "$bbr_enabled" == true ]] || [[ "$config_exists" == true ]] || [[ "$modules_loaded" == true ]]; then
        return 0  # 部分优化
    else
        return 9  # 未优化
    fi
}

# 格式化系统优化状态显示
format_optimization_status() {
    case $1 in
        1) echo -e "${green_text}[已优化]${reset}" ;;
        0) echo -e "${yellow_text}[部分优化]${reset}" ;;
        9) echo -e "${grey_text}[未优化]${reset}" ;;
    esac
}

# 处理“服务已运行”的交互逻辑
handle_running_service() {
    local display_name=$1
    local cleanup_cmd=$2
    local install_script=$3

    echo -e "${display_name} 服务已运行，继续安装将进行${yellow_text}覆盖安装${reset}。"
    echo -e "输入 ${green_text}g${reset} 进行覆盖安装"
    echo -e "输入 ${green_text}n${reset} 返回主菜单"
    echo -e "输入 ${green_text}任意其他键${reset} 进入 ${display_name} 快捷管理脚本"
    read -rp "请输入: " input
    case "$input" in
        g|G) 
            echo "正在执行覆盖安装前的清理操作..."
            eval "$cleanup_cmd"
            echo "清理完成，开始执行安装脚本..."
            eval "$install_script"
            ;;
        n|N) . "$DIRPATH/menu.sh" ;;
        *) ensure_proxytool ;;
    esac
}

# 处理“服务未运行”的交互逻辑
handle_stopped_service() {
    local service_name=$1
    local display_name=$2
    echo "${display_name} 服务未运行，是否启动服务？ (y/n)"
    read -rp "请输入: " start_input
    if [[ "$start_input" == "y" || "$start_input" == "Y" ]]; then
        systemctl start "$service_name"
        echo "${display_name} 服务已启动。"
    else
        echo "未启动 ${display_name} 服务。"
    fi
}

# --- 核心逻辑 ---

# --- 主程序 ---
# 1. 获取各服务状态
get_service_status "mosdns"; mosdns_status=$?
mosdns_display=$(format_status_for_menu $mosdns_status)

# 处理 Unbound+Redis 复合状态
get_service_status "unbound"; unbound_status=$?
get_service_status "redis-server"; redis_status=$?
if [[ $unbound_status -eq 1 && $redis_status -eq 1 ]]; then 
    unbound_redis_status=1  # 全部运行中
elif [[ $unbound_status -eq 9 && $redis_status -eq 9 ]]; then 
    unbound_redis_status=9  # 全部未安装
else 
    unbound_redis_status=0  # 部分运行
fi
unbound_redis_display=$(format_status_for_menu $unbound_redis_status)

# 获取代理服务状态
get_service_status "sing-box"; singbox_status=$?
singbox_display=$(format_status_for_menu $singbox_status)

get_service_status "mihomo"; mihomo_status=$?
mihomo_display=$(format_status_for_menu $mihomo_status)

# 获取系统优化状态
get_system_optimization_status; optimization_status=$?
optimization_display=$(format_optimization_status $optimization_status)

# 获取网络配置状态
get_network_status; network_status=$?
network_display=$(format_network_status $network_status)


# 2. 显示菜单
clear
echo "-------------------------------------------------"
echo -e "${green_text}DNS服务${reset}"
echo "-------------------------------------------------"
echo -e "1. ${yellow_text}Mosdns${reset}          ${mosdns_display}"
echo -e "2. ${yellow_text}Unbound+Redis${reset}   ${unbound_redis_display}"
echo "------------------------------------------------- "
echo -e "${green_text}Proxy代理${reset}"
echo "-------------------------------------------------"
echo -e "3. ${yellow_text}sing-box${reset}        ${singbox_display}"
echo -e "4. ${yellow_text}mihomo${reset}          ${mihomo_display}"
echo "-------------------------------------------------"
echo -e "${green_text}多功能脚本${reset}"
echo -e "i. ${yellow_text}Debian/Ubuntu设置静态IP/DHCP${reset}  ${network_display}"
echo -e "m. ${yellow_text}Mosdns——系统优化${reset}    ${optimization_display}"
#echo -e "p. ${yellow_text}Proxytool——代理管理${reset}" 
echo "-------------------------------------------------"
echo -e "0. ${red_text}卸载核心组件${reset}"
echo -e "999. ${yellow_text}更新脚本${reset}"
echo "================================================="
echo -e "当前机器地址: ${green_text}${local_ip}${reset}"
echo "-------------------------------------------------"
read -rp "请选择: " choice

# 3. 根据选择执行操作
case $choice in
    1)  # MosDNS
        case $mosdns_status in
            1)  # 运行中
                if [[ -d "/cus/mosdns" ]]; then
                    # 魔改UI版
                    echo "正在安装MosDNS魔改UI版..."
                    echo "请注意：魔改UI版可能存在不稳定因素，请谨慎使用。"
                    cleanup_cmd=". ${DIRPATH}/init.sh mosdns /usr/local/bin/mosdns /cus/mosdns && rm -rf /cus/mosdns && rm -rf /etc/mosdns"
                    handle_running_service "Mosdns (魔改UI版)" "$cleanup_cmd" ". $DIRPATH/mosdns.sh" 
                else
                    # 标准版
                    cleanup_cmd=". ${DIRPATH}/init.sh mosdns /usr/local/bin/mosdns /etc/mosdns && rm -rf /etc/mosdns"
                    handle_running_service "Mosdns (标准版)" "$cleanup_cmd" ". $DIRPATH/mosdns.sh" 
                fi
                ;;
            0) handle_stopped_service "mosdns" "Mosdns" ;;
            9) . "$DIRPATH/mosdns.sh" ;;
        esac
        ;;
    2)  # Unbound+Redis
        case $unbound_redis_status in
            1)  # 全部运行中
                unbound_cleanup=". $DIRPATH/init.sh unbound /usr/local/bin/unbound* /etc/unbound && rm -rf /etc/unbound"
                redis_cleanup=". $DIRPATH/init.sh redis-server /usr/local/bin/redis* /etc/redis && rm -rf /etc/redis"
                handle_running_service "Unbound+Redis" "$unbound_cleanup && $redis_cleanup" ". $DIRPATH/unbound.sh"
                ;;
            0)  # 部分运行或未运行
                echo "Unbound 或 Redis 未完全运行，是否尝试启动？ (y/n)"
                read -rp "请输入: " start_input
                if [[ "${start_input,,}" == "y" ]]; then
                    [[ $unbound_status -ne 1 ]] && systemctl start unbound
                    [[ $redis_status -ne 1 ]] && systemctl start redis
                    echo "Unbound+Redis DNS 服务已尝试启动。"
                else
                    echo "未启动服务。"
                fi
                ;;
            9)  # 未安装
                . "$DIRPATH/unbound.sh" 
                ;;
        esac
        ;;
        
    3)  # sing-box
        case $singbox_status in
            1)  # 运行中
                handle_running_service "sing-box" \
                    ". $DIRPATH/init.sh sing-box /usr/local/bin/sing-box /etc/sing-box && rm -rf /etc/sing-box" \
                    ". $DIRPATH/sing-box.sh" 
                ;;
            0)  # 未运行
                handle_stopped_service "sing-box" "sing-box" 
                ;;
            9)  # 未安装
                . "$DIRPATH/sing-box.sh" 
                ;;
        esac
        ;;
        
    4)  # mihomo
        case $mihomo_status in
            1)  # 运行中
                handle_running_service "mihomo" \
                    ". $DIRPATH/init.sh mihomo /usr/local/bin/mihomo /etc/mihomo && rm -rf /etc/mihomo" \
                    ". $DIRPATH/sing-box.sh mihomo" 
                ;;
            0)  # 未运行
                handle_stopped_service "mihomo" "mihomo" 
                ;;
            9)  # 未安装
                . "$DIRPATH/sing-box.sh" mihomo 
                ;;
        esac
        ;;
    i)  # 设置静态IP
        . "$DIRPATH/ipset.sh"
        ;;
    m )  # mosdns sysctl系统优化
        . "$DIRPATH/mosdns_sysctl.sh"
        ;;
    0)  # 卸载核心
        . "$DIRPATH/uninstall.sh"
        ;;
        
    999)  # 更新脚本
        . "$DIRPATH/install.sh"
        ;;
        
    *)
        echo "无效的选项，请重新运行脚本并选择有效的选项。"
        ;;
esac