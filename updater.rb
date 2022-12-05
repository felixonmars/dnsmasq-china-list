#!/usr/bin/ruby
require 'domain_name'
require 'optparse'
require 'ostruct'
require_relative 'verify'

options = OpenStruct.new
options.sort = true
options.file = "accelerated-domains.china.conf"
options.add = []
options.delete = []
OptionParser.new do |opts|
    opts.banner = "dnsmasq-china-list updater"

    opts.on("-s", "--[no-]sort", "Sort the list (default action)") do |s|
        options.sort = s
    end

    opts.on("-f", "--file FILE", "Specify the file to update (accelerated-domains.china.conf by default)") do |f|
        options.file = f
    end

    opts.on("-a", "--add domain1,domain2", Array, "Add domain(s) to the list (implies -s)") do |a|
        options.add = a
        options.sort = true
    end

    opts.on("-d", "--delete domain1,domain2", Array, "Remove domain(s) from the list (implies -s)") do |d|
        options.delete = d
        options.sort = true
    end
end.parse!

lines = File.readlines(options.file).filter { |line| !line.empty? }
disabled_lines = lines.filter { |line| line.start_with?("#") }

changed = false

options.add.each do |domain|
    domain = DomainName.normalize(domain)
    new_line = CheckRedundant(lines, disabled_lines, domain)
    if new_line != false
        puts "New domain added: #{domain}"
        lines << new_line
        changed = true
    end
end

options.delete.each do |domain|
    domain = DomainName.normalize(domain)
    target_line = "server=/#{domain}/114.114.114.114\n"
    unless lines.include? target_line
        puts "Failed to remove domain #{domain}: not found."
    else
        puts "Domain removed: #{domain}"
        lines.delete(target_line)
        changed = true
    end
end

fail "No changes made." if (options.add.length || options.delete.length) && !changed

lines.sort_by! { |x| x.delete_prefix("#") } if options.sort

File.write(options.file, lines.join)
