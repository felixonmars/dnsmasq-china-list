SERVER=114.114.114.114

raw:
	sed -e 's|^server=/\(.*\)/114.114.114.114$$|\1|' accelerated-domains.china.conf | egrep -v '^#' > accelerated-domains.china.raw.txt
	sed -e 's|^server=/\(.*\)/114.114.114.114$$|\1|' google.china.conf | egrep -v '^#' > google.china.raw.txt
	sed -e 's|^server=/\(.*\)/114.114.114.114$$|\1|' apple.china.conf | egrep -v '^#' > apple.china.raw.txt

dnsmasq: raw
	sed -e 's|\(.*\)|server=/\1/$(SERVER)|' accelerated-domains.china.raw.txt > accelerated-domains.china.dnsmasq.conf
	sed -e 's|\(.*\)|server=/\1/$(SERVER)|' google.china.raw.txt > google.china.dnsmasq.conf
	sed -e 's|\(.*\)|server=/\1/$(SERVER)|' apple.china.raw.txt > apple.china.dnsmasq.conf

unbound: raw
	sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: $(SERVER)\n|' accelerated-domains.china.raw.txt > accelerated-domains.china.unbound.conf
	sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: $(SERVER)\n|' google.china.raw.txt > google.china.unbound.conf
	sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: $(SERVER)\n|' apple.china.raw.txt > apple.china.unbound.conf

bind: raw
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' accelerated-domains.china.raw.txt > accelerated-domains.china.bind.conf
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' google.china.raw.txt > google.china.bind.conf
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' apple.china.raw.txt > apple.china.bind.conf

clean:
	rm -f {accelerated-domains,google,apple}.china.{dnsmasq,unbound,bind}.conf {accelerated-domains,google,apple}.china.raw.txt
