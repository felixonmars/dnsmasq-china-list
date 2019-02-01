#!/usr/bin/env python

import dns.resolver
from termcolor import colored
import random
import ipaddress
import tldextract


class ChnroutesNotAvailable(Exception):
    pass

class NSNotAvailable(Exception):
    pass

# OK
class OK(Exception):
    pass

class WhitelistMatched(OK):
    pass

class CDNListVerified(OK):
    pass

class NSVerified(OK):
    pass

# Not OK
class NotOK(Exception):
    pass

class NXDOMAIN(NotOK):
    pass

class BlacklistMatched(NotOK):
    pass

class CDNListNotVerified(NotOK):
    pass

class NSNotVerified(NotOK):
    pass


class ChinaListVerify(object):
    whitelist_file = "ns-whitelist.txt"
    blacklist_file = "ns-blacklist.txt"
    cdnlist_file = "cdn-testlist.txt"
    chnroutes_file = "/usr/share/chnroutes2/chnroutes.txt"

    def __init__(self):
        self.whitelist = self.load_list(self.whitelist_file)
        self.blacklist = self.load_list(self.blacklist_file)
        self.cdnlist = self.load_list(self.cdnlist_file)

        try:
            self.chnroutes = self.load_list(self.chnroutes_file)
        except FileNotFoundError:
            print(colored("Failed to load chnroutes, CDN check disabled", "red"))
            self.chnroutes = None

    def load_list(self, filename):
        with open(filename) as f:
            return list([l.rstrip('\n') for l in f if l and not l.startswith("#")])

    def test_cn_ip(self, domain):
        if self.chnroutes is None:
            raise ChnroutesNotAvailable

        answers = dns.resolver.query(domain, 'A')

        for answer in answers:
            answer = answer.to_text()
            if any(ipaddress.IPv4Address(answer) in ipaddress.IPv4Network(n) for n in self.chnroutes):
                return True

        return False

    def check_whitelist(self, nameservers):
        if any(i in " ".join(nameservers) for i in self.whitelist):
            raise WhitelistMatched

    def check_blacklist(self, nameservers):
        if any(i in " ".join(nameservers) for i in self.blacklist):
            raise BlacklistMatched

    def check_cdnlist(self, domain):
        if self.test_cn_ip(domain):
            raise CDNListVerified
        else:
            raise CDNListNotVerified

    def check_domain(self, domain, enable_cdnlist=True):
        nameservers = []
        nxdomain = False
        try:
            answers = dns.resolver.query(domain, 'NS')
        except dns.resolver.NXDOMAIN:
            nxdomain = True
        except:
            pass
        else:   
            for rdata in answers:
                nameserver = rdata.to_text()
                if tldextract.extract(nameserver).registered_domain:
                    nameservers.append(nameserver)

            self.check_whitelist(nameservers)

        if enable_cdnlist:
            for testdomain in self.cdnlist:
                if testdomain == domain or testdomain.endswith("." + domain):
                    try:
                        self.check_cdnlist(testdomain)
                    except dns.resolver.NXDOMAIN:
                        raise NXDOMAIN

            # Assuming CDNList for non-TLDs
            if domain.count(".") > 1 and tldextract.extract(domain).registered_domain != domain:
                try:
                    self.check_cdnlist(domain)
                except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.resolver.NoNameservers, dns.exception.Timeout):
                    pass

        if nxdomain:
            # Double check due to false positives
            try:
                dns.resolver.query("www." + domain, 'A')
            except dns.resolver.NXDOMAIN:
                raise NXDOMAIN

        self.check_blacklist(nameservers)

        for nameserver in nameservers:
            try:
                if self.test_cn_ip(nameserver):
                    raise NSVerified
            except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.resolver.NoNameservers, dns.exception.Timeout):
                pass

        if nameservers:
            raise NSNotVerified
        else:
            raise NSNotAvailable

    def check_domain_quiet(self, domain, **kwargs):
        try:
            self.check_domain(domain, **kwargs)
        except OK:
            return True
        except NotOK:
            return False
        except:
            return None
        else:
            return None

    def check_domain_verbose(self, domain, show_green=False, **kwargs):
        try:
            try:
                self.check_domain(domain, **kwargs)
            except NXDOMAIN:
                print(colored("NXDOMAIN found in (cdnlist or) domain: " + domain, "white", "on_red"))
                raise
            except WhitelistMatched:
                if show_green:
                    print(colored("NS Whitelist matched for domain: " + domain, "green"))
                raise
            except CDNListVerified:
                if show_green:
                    print(colored("CDNList matched and verified for domain: " + domain, "green"))
                raise
            except CDNListNotVerified:
                print(colored("CDNList matched but failed to verify for domain: " + domain, "red"))
                raise
            except BlacklistMatched:
                print(colored("NS Blacklist matched for domain: " + domain, "red"))
                raise
            except NSVerified:
                if show_green:
                    print(colored("NS verified for domain: " + domain, "green"))
                raise
            except NSNotVerified:
                print(colored("NS failed to verify for domain: " + domain, "red"))
                raise
            except ChnroutesNotAvailable:
                print("Additional Check disabled due to missing chnroutes. domain:", domain)
                raise
            except NSNotAvailable:
                print("Failed to get correct name server for domain:", domain)
                raise
            else:
                raise NotImplementedError
        except OK:
            return True
        except NotOK:
            return False
        except:
            return None
        else:
            return None

    def check_domain_list(self, domain_list, sample=30, show_green=False):
        domains = self.load_list(domain_list)
        if sample:
            domains = random.sample(domains, sample)
        else:
            random.shuffle(domains)
        for domain in domains:
            self.check_domain_verbose(domain, show_green=show_green)


if __name__ == "__main__":
    import argparse
    description = 'A simple verify library for dnsmasq-china-list'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('-f', '--file', nargs='?', default="accelerated-domains.china.raw.txt",
                        help='File to examine')
    parser.add_argument('-s', '--sample', nargs='?', default=0,
                        help='Verify only a limited sample. Pass 0 to example all entries.')
    parser.add_argument('-v', '--verbose', action="store_true",
                        help='Show green results.')
    parser.add_argument('-d', '--domain', nargs='?',
                        help='Verify a domain instead of checking a list. Will ignore the other options.')

    config = parser.parse_args()
    v = ChinaListVerify()

    if config.domain:
        v.check_domain_verbose(config.domain, show_green=config.verbose)
    else:
        v.check_domain_list(config.file, show_green=config.verbose, sample=int(config.sample))
