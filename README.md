dnsmasq-china-list
==================

Configuration for hot China domains (or CDN domains that have node in China) to accelerate via Dnsmasq (Now also includes bogus-nxdomain lines to stop common DNS servers from hijacking NXDOMAIN results)

Content
=======

- `accelerated-domains.china.conf`: Acceleratable Domains.

  The domain should have a better resolving speed or result when using a Chinese DNS server.

  To determine if a domain is eligible, one of the criteria below must be met:

 - The domain's NS server is located in China.

 - The domain will resolve to an IP located in China mainland when using a Chinese DNS server, but _not_ always do when using a foreign DNS server (For example, CDN accelerated sites that have node in China). This however does _not_ include those having node _near_ China mainland, like in Japan, Hong Kong, Taiwan, etc.
 
  Please don't add subdomains if the top domain is already in the list. This includes all .cn domains which are already matched by the `/cn/` rule.

- `bogus-nxdomain.china.conf`: Known addresses that are hijacking NXDOMAIN results returned by DNS servers.

- `google.china.conf`: Acceleratable Google domains.

  These domains are resolved to Google China servers when using a Chinese DNS. In most conditions this will yield better page load time for sites using Google's web services, e.g. Google Web Fonts and AdSense.

  Bear in mind that they are _not_ considered stable. **Use at your own risk**.

Usage
=====

1. Place accelerated-domains.china.conf, bogus-nxdomain.china.conf (and optionally google.china.conf) under /etc/dnsmasq.d/ (Create the folder if it does not exist).
2. Uncomment "conf-dir=/etc/dnsmasq.d" in /etc/dnsmasq.conf
3. (Optional) Place dnsmasq-update-china-list into /usr/bin/

有一些域名无法被指定的域名服务器正常解析，这就会导致莫名其妙的访问失败。check.js是检测域名是否可以正常解析的nodejs脚本
使用方法
`node check.js > checked-domains.china.conf`
如果在accelerated-domains.china.conf里的域名无法被选择的域名服务器解析，那么将会被注释掉
使用检测结果checked-domains.china.conf代替accelerated-domains.china.conf文件

License
=======

```
Copyright © 2015 Felix Yan <felixonmars@archlinux.org>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the LICENSE file for more details.
```
