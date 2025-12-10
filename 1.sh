#!/bin/bash
export LANG=en_US.UTF-8
case "$(uname -m)" in
	x86_64 | x64 | amd64 )
	cpu=amd64
	;;
	i386 | i686 )
        cpu=386
	;;
	armv8 | armv8l | arm64 | aarch64 )
        cpu=arm64
	;;
	armv7l )
        cpu=arm
	;;
        mips64le )
        cpu=mips64le
	;;
        mips64 )
        cpu=mips64
	;;
        mips )
        cpu=mipsle
	;;
        mipsle )
        cpu=mipsle
	;;
	* )
	echo "当前架构为$(uname -m)，暂不支持"
	exit
	;;
esac
echo "$(uname -m)"
if timeout 3 ping -c 2 2400:3200::1 &> /dev/null; then
echo "当前网络支持IPV4+IPV6"
else
echo "当前网络仅支持IPV4"
fi
echo "甬哥Github项目  ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo
echo "请选择优选类型"
echo "1、IPV4"
echo "5、退出"
read -p "请选择【1-5】:" menu
if [ ! -e cfs5http ]; then
curl -L -o cfs5http -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare-vless-trojan/main/s5http_wkpgs/$cpu
chmod +x cfs5http
fi
./cfs5http cf_domain=paaz.pages.dev:443 cf_cdnip=www.visa.com.sg token=9527
