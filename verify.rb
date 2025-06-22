#!/usr/bin/ruby

require 'colorize'
require 'concurrent'
require 'ipaddr'
require 'public_suffix'
require 'resolv'
require 'set'

class ChinaListVerify
    def initialize(
        dns=nil,
        whitelist_file: "ns-whitelist.txt",
        blacklist_file: "ns-blacklist.txt",
        cdnlist_file: "cdn-testlist.txt",
        chnroutes_file: "/usr/share/china_ip_list.txt"
    )
        @dns = dns
        @whitelist = load_list whitelist_file
        @blacklist = load_list blacklist_file
        @cdnlist = load_list cdnlist_file
        @tld_ns = Concurrent::Hash.new

        begin
            @chnroutes = load_list(chnroutes_file).map { |line| IPAddr.new line }
        rescue Errno::ENOENT
            puts "Failed to load chnroutes, CDN check disabled".red
            @chnroutes = nil
        end
    end

    def load_list(filename)
        File.readlines(filename).each do |line|
            line if !line.chomp!.empty? and !line.start_with?("#")
        end
    end

    def test_cn_ip(domain, response: nil)
        if @chnroutes == nil
            raise "chnroutes not loaded"
        end

        answers = resolve(domain, 'A')

        if response != nil && !response.empty?
            answers += response.filter_map { |n, r| r if n.to_s == domain && r.class == Resolv::DNS::Resource::IN::A }
        end

        answers.each do |answer|
            answer = IPAddr.new answer.address.to_s
            if @chnroutes.any? { |range| range.include? answer }
                return true
            end
        end

        return false
    end

    def resolve(domain, rdtype="A", server: nil, with_glue: false)
        rdtype = Kernel.const_get("Resolv::DNS::Resource::IN::#{rdtype}")
        if !server
            if !@dns
                resolver = Resolv::DNS.new
            else
                resolver = Resolv::DNS.new(nameserver: @dns)
            end
        else
            server = [server] unless server.is_a? Array
            resolver = Resolv::DNS.new(nameserver: server)
        end
        begin
            if !with_glue
                return resolver.getresources(domain, rdtype)
            else
                # Workaround for https://github.com/ruby/resolv/issues/27
                result = []
                glue = []
                n0 = Resolv::DNS::Name.create domain
                resolver.fetch_resource(domain, rdtype) {|reply, reply_name|
                    reply.each_resource {|n, ttl, data|
                        if n0 == n && data.is_a?(rdtype)
                            result << data
                        else
                            glue << [n, data]
                        end
                    }
                }
                return result, glue
            end
        rescue Exception => e
            if !with_glue
                return []
            else
                return [], []
            end
        end
    end

    def get_ns_for_tld(tld)
        if !@tld_ns.has_key? tld
            answers = resolve(tld + ".", "NS")
            results = []
            answers.each do |answer|
                ips = resolve answer.name.to_s
                ips.each do |ip|
                    results << ip.address.to_s
                end
            end
            @tld_ns[tld] = results
        end

        @tld_ns[tld]
    end

    def check_whitelist(nameservers)
        @whitelist.each { |pattern| nameservers.each {|ns| return pattern if ns.end_with? pattern }}
        nil
    end

    def check_blacklist(nameservers)
        @blacklist.each { |pattern| nameservers.each {|ns| return pattern if ns.end_with? pattern }}
        nil
    end

    def check_cdnlist(domain)
        test_cn_ip domain
    end

    def check_domain(domain, enable_cdnlist: true)
        nameservers = Set[]
        nxdomain = false
        begin
            tld_ns = get_ns_for_tld(PublicSuffix.parse(domain, ignore_private: true).tld)
        rescue PublicSuffix::DomainNotAllowed, PublicSuffix::DomainInvalid
            yield nil, "Invalid domain #{domain}"
            return nil
        end
        response, glue = self.resolve(
            domain + ".",
            'NS',
            server: tld_ns,
            with_glue: true
        )
        response.each do |rdata|
            begin
                nameserver = rdata.name.to_s
                if PublicSuffix.valid?(nameserver, ignore_private: true)
                    nameservers << nameserver
                end

                if result = check_whitelist(nameservers)
                    yield true, "NS Whitelist #{result} matched for domain #{domain}" if block_given?
                    return true
                end
            rescue NoMethodError => e
                puts "Ignoring error: #{e}"
            end
        end

        nameservers.clone.each do |nameserver|
            response = self.resolve(
                domain + ".",
                'NS',
                server: nameserver,
            )
            response.each do |rdata|
                begin
                    nameserver = rdata.name.to_s
                    if PublicSuffix.valid?(nameserver, ignore_private: true)
                        nameservers << nameserver
                    end

                    if result = check_whitelist(nameservers)
                        yield true, "NS Whitelist #{result} matched for domain #{domain}" if block_given?
                        return true
                    end
                rescue NoMethodError => e
                    puts "Ignoring error: #{e}"
                end
            end
        end

        if enable_cdnlist
            @cdnlist.each do |testdomain|
                if testdomain == domain or testdomain.end_with? "." + domain
                    if result = check_cdnlist(testdomain)
                        yield true, "CDN List matched (#{testdomain}) and verified #{result} for domain #{domain}" if block_given?
                        return true
                    end
                end
            end

            # Assuming CDNList for non-TLDs
            if domain.count(".") > 1 and PublicSuffix.domain(domain, ignore_private: true) != domain
                if result = check_cdnlist(domain)
                    yield true, "CDN List matched and verified #{result} for domain #{domain}" if block_given?
                    return true if result
                end
            end
        end

        if result = check_blacklist(nameservers)
            yield false, "NS Blacklist #{result} matched for domain #{domain}" if block_given?
            return false
        end

        nameservers.each do |nameserver|
            if result = test_cn_ip(nameserver, response: glue)
                yield true, "NS #{nameserver} verified #{result} for domain #{domain}" if block_given?
                return true
            end
        end

        if !nameservers.empty?
            yield false, "NS (#{nameservers.join(", ")}) not verified for domain #{domain}" if block_given?
            return false
        else
            yield nil, "Failed to get correct name server for domain #{domain}" if block_given?
            return nil
        end
    end

    def check_domain_verbose(domain, show_green: false, **kwargs)
        check_domain(domain, **kwargs) do |result, message|
            if result == true
                puts message.green if show_green
            elsif result == false
                puts message.red
            else
                puts message.yellow
            end
        end
    end

    def check_domain_list(domain_list, sample: 30, show_green: false, jobs: Concurrent.processor_count)
        domains = load_list domain_list
        if sample > 0
            domains = domains.sample(sample)
        else
            domains.shuffle!
        end
        pool = Concurrent::FixedThreadPool.new(jobs)
        domains.each do |domain|
            pool.post do
                if check_domain_verbose(domain, show_green: show_green)
                    yield domain if block_given?
                end
            end
        end
        pool.shutdown
        pool.wait_for_termination
    end
end

# Operates on the raw file to preserve commented out lines
def CheckRedundant(lines, disabled_lines, domain)
    new_line = "server=/#{domain}/114.114.114.114\n"
    disabled_line = "#server=/#{domain}/114.114.114.114"
    if lines.include? new_line
        puts "Domain already exists: #{domain}"
        return false
    elsif disabled_lines.any? { |line| line.start_with? disabled_line }
        puts "Domain already disabled: #{domain}"
        return false
    else
        # Check for duplicates
        test_domain = domain
        while test_domain.include? '.'
            test_domain = test_domain.partition('.').last
            _new_line = "server=/#{test_domain}/114.114.114.114\n"
            _disabled_line = "#server=/#{test_domain}/114.114.114.114"
            if lines.include? _new_line 
                puts "Redundant domain already exists: #{test_domain}"
                return false
            elsif disabled_lines.any? { |line| line.start_with? _disabled_line }
                puts "Redundant domain already disabled: #{test_domain}"
                return false
            end
        end
    end
    return new_line
end

if __FILE__ == $0
    require 'optparse'
    require 'ostruct'

    options = OpenStruct.new
    options.file = "accelerated-domains.china.raw.txt"
    options.sample = 0
    options.verbose = false
    options.domain = nil
    options.dns = nil
    OptionParser.new do |opts|
        opts.banner = 'A simple verify library for dnsmasq-china-list'

        opts.on("-f", "--file FILE", "File to check") do |f|
            options.file = f
        end

        opts.on("-s", "--sample SAMPLE", Integer, "Verify only a limited sample. Pass 0 to example all entries") do |s|
            options.sample = s
        end

        opts.on("-v", "--[no-]verbose", "Show green results") do |v|
            options.verbose = v
        end

        opts.on("-d", "--domain DOMAIN", "Verify a domain instead of checking a list. Will ignore the other list options.") do |d|
            options.domain = d
        end

        opts.on("-D", "--dns DNS", "Specify a DNS server to use instead of the system default one.") do |d|
            options.dns = d
        end

        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end
    end.parse!

    v = ChinaListVerify.new options.dns

    if options.domain
        exit v.check_domain_verbose(options.domain, show_green: options.verbose) == true
    else
        v.check_domain_list(options.file, sample: options.sample, show_green: options.verbose)
    end
end
