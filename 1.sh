#!/bin/sh

XRAY_PATH="$HOME/xray"
CONFIG_PATH="$XRAY_PATH/config.json"
XRAY_BINARY="$XRAY_PATH/xray"
SCREEN_NAME="xray_screen"
UUID_FILE="$XRAY_PATH/uuid.txt"

# 获取用户名和主机名后缀
username=$(whoami)
hostname_full=$(hostname)
hostname_suffix=$(echo "$hostname_full" | cut -d'.' -f2-)

if [ "$hostname_suffix" = "serv00" ]; then
  domain_suffix="serv00.net"
else
  domain_suffix="$hostname_suffix"
fi

domain="$username.$domain_suffix"

# 检查 Xray 是否已安装
check_xray_installed() {
    if [ -f "$XRAY_BINARY" ]; then
        return 0
    else
        return 1
    fi
}

# 下载并安装 Xray
install_xray() {
    if check_xray_installed; then
        echo "Xray 已经安装，跳过下载。"
    else
        echo "正在下载 Xray..."
        wget https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-freebsd-64.zip -O xray.zip
        unzip xray.zip -d $XRAY_PATH
        rm xray.zip
        chmod +x $XRAY_BINARY
        echo "Xray 已安装在 $XRAY_PATH"
    fi
}

# 卸载 Xray
uninstall_xray() {
    echo "正在卸载 Xray..."
    pkill -f "$XRAY_BINARY"
    rm -rf $XRAY_PATH
    echo "Xray 已卸载"
}

# 启动 Xray
start_xray() {
    echo "正在启动 Xray..."
    if screen -dmS $SCREEN_NAME $XRAY_BINARY run -c $CONFIG_PATH; then
        echo "Xray 启动成功"
    else
        echo "Xray 启动失败，请检查配置"
        screen -ls | grep $SCREEN_NAME && screen -S $SCREEN_NAME -X quit
    fi
}

# 停止 Xray
stop_xray() {
    echo "正在停止 Xray..."
    screen -S $SCREEN_NAME -X quit
    pkill -f "$XRAY_BINARY"
    echo "Xray 已停止"
}

# 生成或读取私钥、公钥和 UUID
generate_keys() {
    echo "正在生成私钥、公钥和 UUID..."
    KEYS=$($XRAY_BINARY x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep 'Private' | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep 'Public' | awk '{print $3}')
    UUID=$(uuidgen)
    echo "UUID: $UUID" > $UUID_FILE
    echo "PublicKey: $PUBLIC_KEY" >> $UUID_FILE
    echo "PrivateKey: $PRIVATE_KEY" >> $UUID_FILE
    echo "私钥: $PRIVATE_KEY"
    echo "公钥: $PUBLIC_KEY"
}

# 创建 shortid
generate_short_id() {
    SHORT_ID=$(uuidgen | tr -d '-' | head -c 8)
    echo "生成的 ShortId: $SHORT_ID"
}

# 创建配置文件
create_config() {
    read -p "请输入端口: " PORT

    generate_keys
    generate_short_id

    echo "正在创建配置文件..."
    cat <<EOF > "$CONFIG_PATH"
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.wto.org:443",
                    "xver": 0,
                    "serverNames": [
                        "www.wto.org"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": [
                        "$SHORT_ID"
                    ],
                    "fingerprint": "chrome"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF
    echo "配置文件创建完成: $CONFIG_PATH"
}

# 显示节点链接
show_node_link() {
    if [ ! -f "$UUID_FILE" ]; then
        echo "UUID 文件不存在，请先生成 UUID。"
        exit 1
    fi

    UUID=$(cat $UUID_FILE | grep 'UUID' | awk '{print $2}')
    PUBLIC_KEY=$(cat $UUID_FILE | grep 'PublicKey' | awk '{print $2}')

    NODE_LINK="vless://$UUID@$domain:$PORT?type=tcp&security=reality&encryption=none&flow=xtls-rprx-vision&pbk=$PUBLIC_KEY&sni=www.wto.org&sid=$SHORT_ID#vless+Reality$username"
    echo "节点链接: $NODE_LINK"
}

# 主程序
main() {
    echo "请选择操作："
    echo "1) 安装 Xray"
    echo "2) 卸载 Xray"
    echo "3) 启动 Xray"
    echo "4) 停止 Xray"
    echo "5) 配置节点"
    echo "6) 显示节点链接"
    echo "7) 退出"
    read -p "请输入选项 (1-7): " OPTION

    case $OPTION in
        1)
            install_xray
            ;;
        2)
            uninstall_xray
            ;;
        3)
            start_xray
            ;;
        4)
            stop_xray
            ;;
        5)
            create_config
            ;;
        6)
            show_node_link
            ;;
        7)
            exit 0
            ;;
        *)
            echo "无效选项，请重试"
            ;;
    esac
}

while true; do
    main
done
