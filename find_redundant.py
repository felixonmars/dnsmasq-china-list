#!/usr/bin/env python3

''' Find accelerated-domains.china.conf for redundant item.
'''

LEAF = 1

def main():
    with open('accelerated-domains.china.conf', 'r') as f:
        lines = f.readlines()

    # Parse conf file & prepare data structure
    data = {}
    for line in lines:
        if line == '' or line.startswith('#'):
            continue
        domain = line.split('/')[1].lower()
        labels = domain.split('.')
        labels.reverse()
        if domain in data:
            print(f"Redundant found: {domain}")
        data[domain] = labels
    domains = list(data.keys())
    domains.sort(key=lambda k: len(data[k]))

    tree = {}
    for domain in domains:
        labels = data[domain]
        node = tree  # Init current node with root node
        for i, label in enumerate(labels):
            isLastLabel = i + 1 == len(labels)
            # Check whether redundant
            if (node == LEAF) or (isLastLabel and label in node):
                print(f"Redundant found: {domain}")
                break
            # Create leaf node
            if isLastLabel:
                node[label] = LEAF
                break
            # Create branch node
            if label not in node:
                node[label] = {}
            # Iterate to child node
            node = node[label]

if __name__ == '__main__':
    main()
