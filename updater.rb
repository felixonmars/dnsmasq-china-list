#!/usr/bin/ruby
require 'domain_name'
require 'optparse'
require 'ostruct'

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
    new_line = "server=/#{domain}/114.114.114.114\n"
    disabled_line = "#server=/#{domain}/114.114.114.114"
    if lines.include? new_line
        puts "Domain already exists: #{domain}"
    else
        if disabled_lines.any? { |line| line.start_with? disabled_line }
            puts "Domain already disabled: #{domain}"
        else
            # Check for duplicates
            test_domain = domain
            while test_domain.include? '.'
                test_domain = test_domain.partition('.').last
                _new_line = "server=/#{test_domain}/114.114.114.114\n"
                _disabled_line = "#server=/#{test_domain}/114.114.114.114"
                if lines.include? _new_line 
                    puts "Redundant domain already exists: #{test_domain}"
                    break
                elsif disabled_lines.any? { |line| line.start_with? _disabled_line }
                    puts "Redundant domain already disabled: #{test_domain}"
                    break
                end
            end
            next if test_domain.include? '.'

            puts "New domain added: #{domain}"
            lines << new_line
            changed = true
        end
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
