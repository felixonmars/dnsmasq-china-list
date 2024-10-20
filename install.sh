#!/bin/bash
set -e

SEDI=(-i)
DEFAULTCONFDIR="/etc/dnsmasq.d"
case "$(uname)" in
  Darwin*)
  DEFAULTCONFDIR="/opt/homebrew/etc/dnsmasq.d"
  SEDI=(-i "")
esac 

WORKDIR="$(mktemp -d)"
CONFDIR=${1:-$DEFAULTCONFDIR}
SERVERS=(114.114.114.114 114.114.115.115 223.5.5.5 119.29.29.29)
# Others: 223.6.6.6 119.28.28.28
# Not using best possible CDN pop: 1.2.4.8 210.2.4.8
# Broken?: 180.76.76.76

CONF_WITH_SERVERS=(accelerated-domains.china google.china apple.china)
CONF_SIMPLE=(bogus-nxdomain.china)


echo "Downloading latest configurations..."
git clone --depth=1 https://gitee.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://pagure.io/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://github.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://bitbucket.org/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://gitlab.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://e.coding.net/felixonmars/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 https://codehub.devcloud.huaweicloud.com/dnsmasq-china-list00001/dnsmasq-china-list.git "$WORKDIR"
#git clone --depth=1 http://repo.or.cz/dnsmasq-china-list.git "$WORKDIR"

echo "Removing old configurations..."
for _conf in "${CONF_WITH_SERVERS[@]}" "${CONF_SIMPLE[@]}"; do
  rm -f "$CONFDIR"/"$_conf"*.conf
done

echo "Installing new configurations..."
for _conf in "${CONF_SIMPLE[@]}"; do
  cp "$WORKDIR/$_conf.conf" "$CONFDIR/$_conf.conf"
done

for _server in "${SERVERS[@]}"; do
  for _conf in "${CONF_WITH_SERVERS[@]}"; do
    cp "$WORKDIR/$_conf.conf" "$CONFDIR/$_conf.$_server.conf"
  done

  sed "${SEDI[@]}" "s|^\(server.*\)/[^/]*$|\1/$_server|" $CONFDIR/*."$_server".conf
done

echo "Restarting dnsmasq service..."
if hash systemctl 2>/dev/null; then
  systemctl restart dnsmasq
elif hash service 2>/dev/null; then
  service dnsmasq restart
elif hash rc-service 2>/dev/null; then
  rc-service dnsmasq restart
elif hash busybox 2>/dev/null && [[ -d "/etc/init.d" ]]; then
  /etc/init.d/dnsmasq restart
elif hash brew 2>/dev/null; then
  brew services restart dnsmasq
else
  echo "Now please restart dnsmasq since I don't know how to do it."
fi

echo "Cleaning up..."
rm -r "$WORKDIR"
