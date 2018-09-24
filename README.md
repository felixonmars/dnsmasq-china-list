dnsmasq-china-list
==================

Chinese-specific configuration to improve your favorite DNS server. Best partner for chnroutes.

- Improve resolve speed for Chinese domains.

- Get the best CDN node near you whenever possible, but don't compromise foreign CDN results so you also get best CDN node for your VPN at the same time.

- Block ISP ads on NXDOMAIN result (like 114so).

Details
=======

- `accelerated-domains.china.conf`: General domains to be accelerated.

  These domains have a better resolving speed and/or result when using a Chinese DNS server.

  To determine if a domain is eligible, one of the criteria below must be met:

 - The domain's NS server is located in China mainland.

 - The domain will resolve to an IP located in China mainland when using a Chinese DNS server, but _not_ always do when using a foreign DNS server (For example, CDN accelerated sites that have node in China). This however does _not_ include those having node _near_ China mainland, like in Japan, Hong Kong, Taiwan, etc.

  Please don't add subdomains if the top domain is already in the list. This includes all .cn domains which are already matched by the `/cn/` rule.

- `google.china.conf`: Google domains to be accelerated.

  These domains are resolved to Google China servers when using a Chinese DNS. In most conditions this will yield better page load time for sites using Google's web services, e.g. Google Web Fonts and AdSense.

  Bear in mind that they are _not_ considered stable. **Use at your own risk**.

- `apple.china.conf`: Apple domains to be accelerated.

  Some ISPs (often smaller ones) have problem accessing Apple's assets using their China mainland CDN servers. Please consider remove this file if that happens to you. See #156 for some more info.

- `bogus-nxdomain.china.conf`: Known addresses that are hijacking NXDOMAIN results returned by DNS servers.

Usage
=====

Automatic Installation (recommended)
------------------------------------

1. Fetch the installer from github (or a mirror): `wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/install.sh`
2. (Optional) Edit it to use your favorite DNS server and/or another mirror to download the list.
3. Run it as root: `sudo ./install.sh`

You can save the installer and run it again to update the list regularly.

Manual Installation
-------------------

1. Place accelerated-domains.china.conf, bogus-nxdomain.china.conf (and optionally google.china.conf, apple.china.conf) under /etc/dnsmasq.d/ (Create the folder if it does not exist).
2. Uncomment "conf-dir=/etc/dnsmasq.d" in /etc/dnsmasq.conf
3. (Optional) Place dnsmasq-update-china-list into /usr/bin/
4. (Optional) Make custom DNS server configuration and/or other services' configuration.

  ```shell
  # change the default DNS server to 202.96.128.86
  make SERVER=202.96.128.86 dnsmasq
  # generate unbound's configuration
  make unbound
  # generate bind's configuration
  make bind
  # full example of generating dnscrypt-proxy forwarding rules for Windows
  make SERVER=101.6.6.6 NEWLINE=DOS dnscrypt-proxy
  ```

License
=======

```
Copyright © 2015 Felix Yan <felixonmars@archlinux.org>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the LICENSE file for more details.
```
