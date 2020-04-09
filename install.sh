#!/bin/bash
set -e

WORKDIR="$(mktemp -d)"
SERVERS=(114.114.114.114 114.114.115.115 180.76.76.76)
# Not using best possible CDN pop: 1.2.4.8 210.2.4.8 223.5.5.5 223.6.6.6
# Dirty cache: 119.29.29.29 182.254.116.116

CONF_WITH_SERVERS=(accelerated-domains.china google.china apple.china)
CONF_SIMPLE=(bogus-nxdomain.china)

echo "Downloading latest configurations..."
git clone --depth=1 https://gitee.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://pagure.io/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://github.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://bitbucket.org/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://gitlab.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://codehub.devcloud.huaweicloud.com/dnsmasq-china-list00001/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://code.aliyun.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 http://repo.or.cz/dnsmasq-china-list.git "$WORKDIR"

echo "Removing old configurations..."
for _conf in "${CONF_WITH_SERVERS[@]}" "${CONF_SIMPLE[@]}"; do
  rm -f /etc/dnsmasq.d/"$_conf"*.conf
done

# In MacOs,command cp will not create an empty folder if it doesn't exist,
# so command below will fail.
# cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.conf"
KERNAL_TYPE="$(uname -a|awk '{print $1}')"
if [ "$KERNAL_TYPE" = "Darwin" ];then
  if [ ! -d "/etc/dnsmasq.d" ]; then
    mkdir /etc/dnsmasq.d
  fi
fi

echo "Installing new configurations..."
for _conf in "${CONF_SIMPLE[@]}"; do
  cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.conf"
done

for _server in "${SERVERS[@]}"; do
  for _conf in "${CONF_WITH_SERVERS[@]}"; do
    cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.$_server.conf"
  done
  # It need a white character after sed -i on MacOs.
  if [ "$KERNAL_TYPE" = "Darwin" ];then
    sed -i "" "s|^\(server.*\)/[^/]*$|\1/$_server|" /etc/dnsmasq.d/*."$_server".conf
  else
    sed -i "s|^\(server.*\)/[^/]*$|\1/$_server|" /etc/dnsmasq.d/*."$_server".conf
  fi
done

echo "Restarting dnsmasq service..."
if hash systemctl 2>/dev/null; then
  systemctl restart dnsmasq
elif hash service 2>/dev/null; then
  service dnsmasq restart
elif hash rc-service 2>/dev/null; then
  rc-service dnsmasq restart
elif hash brew 2>/dev/null; then
  sudo brew services restart dnsmasq  # for macos 
else
  echo "Now please restart dnsmasq since I don't know how to do it."
fi

echo "Cleaning up..."
rm -r "$WORKDIR"
