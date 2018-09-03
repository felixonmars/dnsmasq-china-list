SERVER=114.114.114.114
NEWLINE=UNIX

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
ifeq ($(NEWLINE),DOS)
	sed -i 's/\r*$$/\r/' accelerated-domains.china.unbound.conf google.china.unbound.conf apple.china.unbound.conf
endif

bind: raw
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' accelerated-domains.china.raw.txt > accelerated-domains.china.bind.conf
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' google.china.raw.txt > google.china.bind.conf
	sed -e 's|\(.*\)|zone "\1." {type forward; forwarders { $(SERVER); }; };|' apple.china.raw.txt > apple.china.bind.conf
ifeq ($(NEWLINE),DOS)
	sed -i 's/\r*$$/\r/' accelerated-domains.china.bind.conf google.china.bind.conf apple.china.bind.conf
endif

dnscrypt-proxy: raw
	sed -e 's|\(.*\)|\1 $(SERVER)|' accelerated-domains.china.raw.txt google.china.raw.txt apple.china.raw.txt > dnscrypt-proxy-forwarding-rules.txt
ifeq ($(NEWLINE),DOS)
	sed -i 's/\r*$$/\r/' dnscrypt-proxy-forwarding-rules.txt
endif

dnsforwarder6: raw
	{ printf "protocol udp\nserver $(SERVER)\nparallel on \n"; cat accelerated-domains.china.raw.txt; } > accelerated-domains.china.dnsforwarder.conf
	{ printf "protocol udp\nserver $(SERVER)\nparallel on \n"; cat google.china.raw.txt; } > google.china.dnsforwarder.conf
	{ printf "protocol udp\nserver $(SERVER)\nparallel on \n"; cat apple.china.raw.txt; } > apple.china.dnsforwarder.conf
ifeq ($(NEWLINE),DOS)
	sed -i 's/\r*$$/\r/' accelerated-domains.china.dnsforwarder.conf google.china.dnsforwarder.conf apple.china.dnsforwarder.conf
endif

clean:
	rm -f {accelerated-domains,google,apple}.china.{dnsmasq,unbound,bind}.conf {accelerated-domains,google,apple}.china.raw.txt dnscrypt-proxy-forwarding-rules.txt
