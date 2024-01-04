FAK-DNS for AdGuard Home
==================

中国特定配置，改善您最喜爱的 DNS 服务器。

- 提高国内域名的解析速度。

- 尽可能获得您附近最好的 CDN 节点，但不要影响国外 CDN 的结果，这样您也可以同时为您的 VPN 获得最佳的 CDN 节点。

文件截图如下

![](https://s2.loli.net/2024/01/04/N4QkHzlaSCIDbrt.jpg)

Details
=======
主要的文件在`converted`文件夹下

- `FAK-DNS.txt`: 融合了下述三个文件。

- `accelerated-domains.china.conf.txt`：要加速的一般域名。

   使用中国 DNS 服务器时，这些域名具有更好的解析速度和/或结果。

   要确定域名是否符合条件，必须满足以下条件之一：

  - 该域名的NS服务器位于中国大陆。

  - 当使用中国 DNS 服务器时，域名将解析为位于中国大陆的 IP，但在使用外国 DNS 服务器时_并非总是如此（例如，在中国有节点的 CDN 加速站点）。 然而，这并不包括那些在中国大陆附近有节点的节点，例如日本、香港、台湾等。

   如果顶级域已在列表中，请不要添加子域。 这包括已与“/cn/”规则匹配的所有 .cn 域。

- `google.china.conf.txt`：要加速的 Google 域名。

   使用中国 DNS 时，这些域名将解析为 Google 中国服务器。 在大多数情况下，这将为使用 Google 网络服务的网站带来更好的页面加载时间，例如 Google 网络字体和 AdSense。

   请记住，它们_不_被认为是稳定的。 **使用风险自负**。

- `apple.china.conf.txt`：要加速的 Apple 域名。

   一些 ISP（通常是较小的 ISP）在使用其中国大陆 CDN 服务器访问 Apple 的资产时遇到问题。 如果您遇到这种情况，请考虑删除此文件。 有关更多信息，请参阅#156。

Usage
=====

根据[dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)的规则写了一个github action，自动同步它的新文件并建立AdGuard Home DNS规则。可以通过设置github自定义上游DOH/DOT服务器，默认国内走阿里DOH，国外走Cloudflare DOH。默认合并了googlehost，applehost，和国内域名。

![](https://s2.loli.net/2024/01/02/86f3HDuQMzScewI.jpg)

直接能用👉<https://raw.githubusercontent.com/Leev1s/FAK-DNS/master/converted/FAK-DNS.txt>
如果你想自定义就fork一下，然后改一下，CN_DNS填国内的，THE_DNS是国外的，两者都可以添加多个，注意换行，每行填写一个。
文件下载下来之后，进入AdGuard Home的目录，一般在/opt/AdGuardHome，编辑AdGuardHome.yaml

![](https://s2.loli.net/2024/01/02/NmDTxR46sCGtked.jpg)

填写配置文件

![](https://s2.loli.net/2024/01/02/eh1NsW3p7IlMVdj.jpg)

重启AdGuardHome就可以了

> # 如果你方便可以给我一个Star🌟吗
> <https://github.com/Leev1s/FAK-DNS>

License
=======

```
Copyright © 2015 Felix Yan <felixonmars@archlinux.org>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the LICENSE file for more details.
```
