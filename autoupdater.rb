#!/usr/bin/ruby
require 'filelock'
require 'set'
require_relative 'verify'

$stdout.sync = true

echo_set = Set[]
tested = Set[]
queue = Queue.new

File.readlines("accelerated-domains.china.conf").each do |line|
    line.chomp!
    if !line.empty? and !line.start_with?("#")
        tested << line.split("/")[1]
    end
end

threads = []
ENV.fetch("JOBS", "1").to_i.times.each do
    threads << Thread.new do
        v = ChinaListVerify.new
        while domain = queue.pop
            begin
                domain = PublicSuffix.domain(domain, ignore_private: true)
            rescue PublicSuffix::DomainNotAllowed, PublicSuffix::DomainInvalid
                next
            end

            next if tested.include? domain
            tested << domain

            if v.check_domain_verbose(domain, enable_cdnlist: false, show_green: true)
                Filelock '.git.lock' do
                    puts `./updater.py -a #{domain}`
                    puts `git commit -S -am "accelerated-domains: add #{domain}"` if $?.success?
                    puts `./update-local` if $?.success?
                end
            end
        end
    end
end

ARGF.each do |domain|
    domain.chomp!.downcase!
    next if domain.empty? or domain.end_with?('.arpa', '.cn', '.top')

    if !echo_set.include? domain
        puts "Trying to detect #{domain}"
        echo_set << domain
    end

    queue << domain
end

queue.close
threads.each(&:join)
