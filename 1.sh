#!/bin/bash
export LANG=en_US.UTF-8
arch="$(uname -m)"
case "$arch" in
x86_64|x64|amd64)   cpu=amd64 ;;
i386|i686)          cpu=386 ;;
armv8|armv8l|arm64|aarch64) cpu=arm64 ;;
armv7l)             cpu=arm ;;
mips64le)           cpu=mips64le ;;
mips64)             cpu=mips64 ;;
mips|mipsle)        cpu=mipsle ;;
*)
echo "当前架构为 $arch，暂不支持"
exit
;;
esac
showmenu(){
files=$(find "$HOME/cfs5http" -maxdepth 1 -type f -name "cf_*" 2>/dev/null)
if [ -n "$files" ]; then
echo "已安装节点："
while IFS= read -r f; do
echo "$f"
done <<< "$files"
else
echo "未安装任何节点"
fi
}

echo "1、设置/重置配置"
echo "2、运行一次某个节点"
echo "3、删除某个节点"
echo "4、查看某个节点日志"
echo "5、卸载删除所有配置节点"
echo "6、退出"
echo
showmenu
echo
read -p "请选择【1-6】:" menu
if [ "$menu" = "1" ]; then
mkdir -p "$HOME/cfs5http"
cd "$HOME/cfs5http"
if [ ! -s cfwp ]; then
curl -L -o cfwp -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare-vless-trojan/main/s5http_wkpgs/linux-$cpu
chmod +x cfwp
fi
read -p "客户端本地端口设置（回车跳过为30000）:" menu
port="${menu:-30000}"
read -p "CF workers/pages/自定义的域名设置（格式为域名:443系端口或者80系端口）:" menu
cf_domain="$menu"
read -p "客户端地址优选IP/域名（回车跳过为yg1.ygkkk.dpdns.org）:" menu
cf_cdnip="${menu:-yg1.ygkkk.dpdns.org}"
read -p "密钥设置（回车跳过为不设密钥）:" menu
token="${menu:-}"
read -p "DoH服务器设置（回车跳过为dns.alidns.com/dns-query）:" menu
dns="${menu:-dns.alidns.com/dns-query}"
read -p "ECH开关（回车跳过或者输入y为开启ECH，输入n表示关闭ECH）:" menu
enable_ech=$([ -z "$menu" ] || [ "$menu" = y ] && echo y || echo n)
cat > "cf_$port.sh" << EOF
#!/bin/bash
nohup ./cfwp client_ip=:"$port" dns="$dns" cf_domain="$cf_domain" cf_cdnip="$cf_cdnip" token="$token" enable_ech="$enable_ech" > "$port.log" 2>&1 &
EOF
chmod +x "cf_$port.sh"
echo "设置完毕，请回主菜单选择2运行一次"
elif [ "$menu" = "2" ]; then
find "$HOME/cfs5http" -maxdepth 1 -type f -name "cf_*" -printf "%f\n"
read -p "选择要运行的端口节点（输入端口即可）:" port
bash "$HOME/cfs5http/cf_$port.sh"

elif [ "$menu" = "3" ]; then
find "$HOME/cfs5http" -maxdepth 1 -type f -name "cf_*" -printf "%f\n"
read -p "选择要删除的端口节点（输入端口即可）:" port
pid=$(lsof -t -i :$port)
if [ -n "$pid" ]; then
kill -9 $pid
echo "端口 $port 的进程已被终止"
else
echo "端口 $port 没有占用进程"
fi
rm -rf "$HOME/cfs5http/$port.log" "$HOME/cfs5http/cf_$port.sh"

elif [ "$menu" = "4" ]; then
find "$HOME/cfs5http" -maxdepth 1 -type f -name "cf_*" -printf "%f\n"
read -p "选择要查看的端口节点日志（输入端口即可）:" port
cat "$HOME/cfs5http/$port.log"

elif [ "$menu" = "5" ]; then
killall -9 cfwp
rm -rf "$HOME/cfs5http"
echo "卸载完成"
else
exit
fi
