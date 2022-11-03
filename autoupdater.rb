#!/usr/bin/ruby
require 'concurrent'
require 'filelock'
require 'set'
require_relative 'verify'

$stdout.sync = true

echo_set = Concurrent::Set[]
tested = Concurrent::Set[]

File.readlines("accelerated-domains.china.conf").each do |line|
    line.chomp!
    if !line.empty? and !line.start_with?("#")
        tested << line.split("/")[1]
    end
end

v = ChinaListVerify.new
pool = Concurrent::FixedThreadPool.new(ENV.fetch("JOBS", Concurrent.processor_count).to_i)

ARGF.each do |domain|
    pool.post do
        domain.chomp!.downcase!
        next if domain.empty? or domain.end_with?('.arpa', '.cn', '.top')

        if !echo_set.include? domain
            puts "Trying to detect #{domain}"
            echo_set << domain
        end

        begin
            domain = PublicSuffix.domain(domain, ignore_private: true)
        rescue PublicSuffix::DomainNotAllowed, PublicSuffix::DomainInvalid
            next
        end

        next if tested.include? domain
        tested << domain

        if v.check_domain_verbose(domain, enable_cdnlist: false, show_green: true)
            Filelock '.git.lock' do
                puts `./updater.rb -a #{domain}`
                puts `git commit -S -am "accelerated-domains: add #{domain}"` if $?.success?
                puts `./update-local` if $?.success?
            end
        end
    end
end

pool.shutdown
pool.wait_for_termination
