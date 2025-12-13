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
files=$(ps | grep "$HOME/cfs5http/cfwp" | grep -v grep | sed -n 's/.*client_ip=:\([0-9]\+\).*/\1/p')
if [ -n "$files" ]; then
echo "已安装节点端口："
while IFS= read -r f; do
echo "$f"
done <<< "$files"
else
echo "未安装任何节点"
fi
}

echo "1、设置配置"
echo "2、删除某个节点"
echo "3、查看某个节点配置信息及日志"
echo "4、卸载删除所有配置节点"
echo "5、退出"
echo
showmenu
echo
read -p "请选择【1-5】:" menu
if [ "$menu" = "1" ]; then
mkdir -p "$HOME/cfs5http"
if [ ! -s "$HOME/cfs5http/cfwp" ]; then
curl -L -o "$HOME/cfs5http/cfwp" -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare-vless-trojan/main/s5http_wkpgs/linux-$cpu
chmod +x "$HOME/cfs5http/cfwp"
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
cat > "$HOME/cfs5http/cf_$port.sh" << EOF
#!/bin/bash
nohup $HOME/cfs5http/cfwp client_ip=:"$port" dns="$dns" cf_domain="$cf_domain" cf_cdnip="$cf_cdnip" token="$token" enable_ech="$enable_ech" > "$HOME/cfs5http/$port.log" 2>&1 &
EOF
chmod +x "$HOME/cfs5http/cf_$port.sh"
bash "$HOME/cfs5http/cf_$port.sh"
echo "安装完毕已在运行中，查看运行日志请选择3"
elif [ "$menu" = "2" ]; then
showmenu
read -p "选择要删除的端口节点（输入端口即可）:" port
pid=$(lsof -t -i :$port)
if [ -n "$pid" ]; then
kill -9 $pid
echo "端口 $port 的进程已被终止"
else
echo "端口 $port 没有占用进程"
fi
rm -rf "$HOME/cfs5http/$port.log" "$HOME/cfs5http/cf_$port.sh"
elif [ "$menu" = "3" ]; then
showmenu
read -p "选择要查看的端口节点配置信息及日志（输入端口即可）:" port
{ echo "$port端口节点配置信息及日志如下：" ; echo "------------------------------------"; sed -n '1,16p' "$HOME/cfs5http/$port.log" | grep '服务端域名与端口\|客户端地址与端口\|运行中的优选IP' ; echo "------------------------------------" ; sed '1,16d' "$HOME/cfs5http/$port.log" | tail -n 10; }
elif [ "$menu" = "4" ]; then
ps | grep '[c]fwp' | awk '{print $1}' | xargs kill -9
rm -rf "$HOME/cfs5http"
echo "卸载完成"
else
exit
fi
