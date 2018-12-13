#!/usr/bin/env python

import dns.resolver
from termcolor import colored
import random
import ipaddress
import tldextract

with open("ns-whitelist.txt") as f:
    whitelist = list([l.rstrip('\n') for l in f if l])

with open("ns-blacklist.txt") as f:
    blacklist = list([l.rstrip('\n') for l in f if l])

with open("cdn-testlist.txt") as f:
    cdnlist = list([l.rstrip('\n') for l in f if l])

try:
    with open("/usr/share/chnroutes2/chnroutes.txt") as f:
        chnroutes = list([l.rstrip('\n') for l in f if l and not l.startswith("#")])
except:
    print(colored("Failed to load chnroutes, CDN check disabled"), "red")
    chnroutes = None


with open("accelerated-domains.china.raw.txt") as f:
    domains = random.sample([line.rstrip('\n') for line in f], 100)
    # domains = [line.rstrip('\n') for line in f][13820:13830]


def cn_ip_test(domain):
    answers = dns.resolver.query(domain, 'A')
    answer = answers[0].to_text()
    
    return any(ipaddress.IPv4Address(answer) in ipaddress.IPv4Network(n) for n in chnroutes)


for domain in domains:
    if domain:
        nameserver = None
        nameserver_text = ""
        ns_failed = False
        try:
            answers = dns.resolver.query(domain, 'NS')
        except dns.resolver.NXDOMAIN:
            print(colored("NXDOMAIN found in domain: " + domain, "white", "on_red"))
            continue
        except Exception:
            ns_failed = True
        else:
            for rdata in answers:
                if nameserver is None:
                    nameserver = rdata.to_text()
                nameserver_text += rdata.to_text()

        testdomain = None
        if any(i in nameserver_text for i in whitelist):
            print(colored("NS Whitelist matched for domain: " + domain, "green"))
        elif domain.count(".") > 1 and tldextract.extract(domain).registered_domain != domain or any(testdomain.endswith(domain) for testdomain in cdnlist):
            for testdomain in cdnlist:
                if testdomain.endswith(domain):
                    break
            else:
                testdomain = domain
            if chnroutes:
                try:
                    if cn_ip_test(testdomain):
                        print(colored("CDNList matched and verified for domain: " + domain, "green"))
                    else:
                        print(colored("CDNList matched but failed to verify for domain: " + domain, "red"))
                except:
                    print("Failed to find A for cdnlist domain:", testdomain)
                    continue
            else:
                print(colored("CDNList matched (but verification is not available) for domain: " + domain))
        elif any(i in nameserver_text for i in blacklist):
            print(colored("NS Blacklist matched for domain: " + domain, "red"))
        else:
            if ns_failed:
                print("Failed to find NS for domain: " + domain)
            elif chnroutes:
                try:
                    if cn_ip_test(nameserver):
                        print(colored("NS verified for domain: " + domain, "green"))
                    else:
                        print(colored("NS failed to verify for domain: " + domain, "red"))
                except:
                    print("Failed to find A for NS domain:", nameserver, "domain:", domain)
            else:
                print("Neutral domain:", domain)
