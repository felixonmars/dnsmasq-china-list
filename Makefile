SERVER=114.114.114.114

raw:
	sed -e 's|^server=/\(.*\)/114.114.114.114$$|\1|' accelerated-domains.china.conf | egrep -v '^#' > accelerated-domains.china.raw.txt

dnsmasq: raw
	sed -e 's|\(.*\)|server=/\1/$(SERVER)|' accelerated-domains.china.raw.txt > accelerated-domains.china.dnsmasq.conf

unbound: raw
	sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: $(SERVER)\n|' accelerated-domains.china.raw.txt > accelerated-domains.china.unbound.conf

bind: raw
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' accelerated-domains.china.raw.txt > accelerated-domains.china.bind.conf

clean:
	rm -f accelerated-domains.china.{dnsmasq,unbound,bind}.conf accelerated-domains.china.raw.txt
