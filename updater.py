#!/usr/bin/env python
from __future__ import unicode_literals
from argparse import ArgumentParser

if __name__ == "__main__":
    parser = ArgumentParser(description="dnsmasq-china-list updater")
    parser.add_argument(
        '-a', '--add',
        nargs='?',
        help='Add a new domain (implies -s)',
    )
    parser.add_argument(
        '-s', '--sort',
        action='store_true',
        default=True,
        help='Sort the list (default action)',
    )

    options = parser.parse_args()

    with open("accelerated-domains.china.conf") as f:
        lines = list(f)

    if options.add:
        options.sort = True
        lines.append("server=/%s/114.114.114.114\n" % options.add)

    if options.sort:
        lines.sort(key=lambda x: x.lstrip("#"))

    with open("accelerated-domains.china.conf", "w") as f:
        f.write(''.join(filter(lambda line: line.strip(), lines)))
