#!/usr/bin/env python3

''' Find redundant items in accelerated-domains.china.conf.
    e.g. 'bar.foo.com' is redundant for 'foo.com'.
'''


def load(conf_file):
    ''' Parse conf file & Prepare data structure
        Returns: [ ['abc', 'com'],
                   ['bar', 'foo', 'com'],
                   ... ]
    '''

    results = []
    with open(conf_file, 'r') as f:
        for line in f.readlines():
            line = line.strip()
            if line == '' or line.startswith('#'):
                continue
            # A domain name is case-insensitive and
            # consists of several labels, separated by a full stop
            domain_name = line.split('/')[1]
            domain_name = domain_name.lower()
            domain_labels = domain_name.split('.')
            results.append(domain_labels)

    # Sort results by domain labels' length
    results.sort(key=len)
    return results


def find(labelses):
    ''' Find redundant items by a tree of top-level domain label to sub-level.
        `tree` is like { 'com': { 'foo: { 'bar': LEAF },
                                  'abc': LEAF },
                         'org': ... }
    '''
    tree = {}
    LEAF = 1
    for labels in labelses:
        domain = '.'.join(labels)
        # Init root node as current node
        node = tree
        while len(labels) > 0:
            label = labels.pop()
            if label in node:
                # If child node is a LEAF node,
                # current domain must be an existed domain or a subdomain of an existed.
                if node[label] == LEAF:
                    print(f"Redundant found: {domain} at {'.'.join(labels)}")
                    break
            else:
                # Create a leaf node if current label is last one
                if len(labels) == 0:
                    node[label] = LEAF
                # Create a branch node
                else:
                    node[label] = {}
            # Iterate to child node
            node = node[label]

if __name__ == '__main__':
    find(load('accelerated-domains.china.conf'))
