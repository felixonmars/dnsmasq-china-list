#!/usr/bin/ruby

""" Find redundant items in accelerated-domains.china.conf.
    e.g. 'bar.foo.com' is redundant for 'foo.com'.
"""

def load(conf_file)
    """ Parse conf file & Prepare data structure
        Returns: [ ['abc', 'com'],
                   ['bar', 'foo', 'com'],
                   ... ]
    """

    results = []
    if conf_file.is_a? String
        lines = File.readlines(conf_file)
    elsif conf_file.is_a? Array
        lines = conf_file
    end
    lines.map do |line|
        line = line.chomp
        next if line.empty? or line.start_with?('#')
        # A domain name is case-insensitive and
        # consists of several labels, separated by a full stop
        domain_name = line.split('/')[1]
        domain_name = domain_name.downcase
        domain_labels = domain_name.split('.')
        results << domain_labels
    end

    # Sort results by domain labels' length
    results.sort_by(&:length)
end


LEAF = 1
def find(labelses)
    """ Find redundant items by a tree of top-level domain label to sub-level.
        `tree` is like { 'com': { 'foo: { 'bar': LEAF },
                                  'abc': LEAF },
                         'org': ... }
    """
    redundant = []
    tree = {}
    labelses.each do |labels|
        domain = labels.join('.')
        # Init root node as current node
        node = tree
        until labels.empty?
            label = labels.pop
            if node.include? label
                # If child node is a LEAF node,
                # current domain must be an existed domain or a subdomain of an existed.
                if node[label] == LEAF
                    puts "Redundant found: #{domain} at #{labels.join('.')}"
                    redundant << domain
                    break
                end
            else
                # Create a leaf node if current label is last one
                if labels.empty?
                    node[label] = LEAF
                # Create a branch node
                else
                    node[label] = {}
                end
            end
            # Iterate to child node
            node = node[label]
        end
    end
    redundant
end

def find_redundant(conf_file)
    return find(load(conf_file))
end

if __FILE__ == $0
    find_redundant('accelerated-domains.china.conf')
end
