SERVER=114.114.114.114

raw:
	sed -e 's|^server=/\(.*\)/114.114.114.114$$|\1|' accelerated-domains.china.conf | egrep -v '^#' > accelerated-domains.china.raw.txt

dnsmasq: raw
	sed -e 's|\(.*\)|server=/\1/$(SERVER)|' accelerated-domains.china.raw.txt > accelerated-domains.china.dnsmasq.conf

unbound: raw
	sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: $(SERVER)\n|' accelerated-domains.china.raw.txt > accelerated-domains.china.unbound.conf

clean:
	rm -f accelerated-domains.china.{dnsmasq,unbound}.conf accelerated-domains.china.raw.txt
