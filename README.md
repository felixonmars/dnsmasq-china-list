dnsmasq-china-list
==================

Configuration for hot China domains (or CDN domains that have node in China) to accelerate via Dnsmasq (Now also includes bogus-nxdomain lines to stop common DNS servers from hijacking NXDOMAIN results)

Usage
=====

1. Place accelerated-domains.china.conf and bogus-nxdomain.china.conf under /etc/dnsmasq.d/ (Create the folder if it does not exist).
2. Uncomment "conf-dir=/etc/dnsmasq.d" in /etc/dnsmasq.conf
3. (Optional) Place dnsmasq-update-china-list into /usr/bin/

License
=======

This piece of configurations and scripts are licensed under WTFPL v2, below is the full text version:

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004
    
    Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
    
    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.
    
               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
    
     0. You just DO WHAT THE FUCK YOU WANT TO.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/felixonmars/dnsmasq-china-list/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

