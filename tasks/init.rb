#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'hocon'

# facts defs

REGEX_FACTS = [%r{^blockdevice_(?<devicename>.*)_(?<attribute>model|size|vendor)$},
               %r{^(?<attribute>ipaddress|ipaddress6|macaddress|mtu|netmask|netmask6|network|network6)_(?<interface>.*)$},
               %r{^processor(?<id>[0-9]+)$},
               %r{^sp_(?<name>.*)$},
               %r{^ssh(?<algorithm>dsa|ecdsa|ed25519|rsa)key$},
               %r{^ldom_(?<name>.*)$},
               %r{^zone_(?<name>.*)_(?<attribute>brand|iptype|name|uuid|id|path|status)$}].freeze

LEGACY_FACTS = ['memoryfree_mb', 'memorysize_mb', 'swapfree_mb',
                'swapsize_mb', 'blockdevices', 'interfaces', 'zones',
                'sshfp_dsa', 'sshfp_ecdsa', 'sshfp_ed25519', 'sshfp_rsa',
                'architecture', 'augeasversion', 'bios_release_date', 'bios_vendor',
                'bios_version', 'boardassettag', 'boardmanufacturer', 'boardproductname',
                'boardserialnumber', 'chassisassettag', 'chassistype', 'domain',
                'fqdn', 'gid', 'hardwareisa', 'hardwaremodel',
                'hostname', 'id', 'ipaddress', 'ipaddress6',
                'lsbdistcodename', 'lsbdistdescription', 'lsbdistid', 'lsbdistrelease',
                'lsbmajdistrelease', 'lsbminordistrelease', 'lsbrelease', 'macaddress',
                'macosx_buildversion', 'macosx_productname', 'macosx_productversion', 'macosx_productversion_major',
                'macosx_productversion_minor', 'manufacturer', 'memoryfree', 'memorysize',
                'netmask', 'netmask6', 'network', 'network6',
                'operatingsystem', 'operatingsystemmajrelease', 'operatingsystemrelease', 'osfamily',
                'physicalprocessorcount', 'processorcount', 'productname', 'rubyplatform',
                'rubysitedir', 'rubyversion', 'selinux', 'selinux_config_mode',
                'selinux_config_policy', 'selinux_current_mode', 'selinux_enforced', 'selinux_policyversion',
                'serialnumber', 'swapencrypted', 'swapfree', 'swapsize',
                'system32', 'uptime', 'uptime_days', 'uptime_hours',
                'uptime_seconds', 'uuid', 'xendomains', 'zonename'].freeze

# Read paramerters from STDIN
params = JSON.parse(STDIN.read)
check_ruby = params['check_ruby']
environment = params['environment']
environment_path = params['environment_path']
pattern = [%r{\.pp$}, %r{\.epp$}, %r{\.erb$}, %r{\.yaml$}]

# Get environment dir
puts "environment_path is #{environment_path}"
if environment_path.nil?
  # load configuration
  config = Hocon.load('/etc/puppetlabs/puppetserver/conf.d/file-sync.conf')
  puts "config is #{config}"
  # value = config.dig('file-sync', 'repos', 'puppet-code', 'live-dir')
  if config.dig('file-sync', 'repos', 'puppet-code', 'live-dir').nil?
    puts 'Unable to get puppet environment path, please specify path and ensure you are running task on the correct server.'
    exit(1)
  else
    environment_path = "#{config.dig('file-sync', 'repos', 'puppet-code', 'live-dir')}/environments"
    puts "Path is #{environment_path}"
  end
end

if check_ruby
  pattern.push(%r{\.rb})
end

def get_pp_files(files, folder, pattern)
  Dir.glob(folder) do |file|
    if File.directory?(file)
      get_pp_files(files, "#{file}/*", pattern)
    else
      pattern.each do |i|
        file.match?(i) ? files.push(file) : next
      end
    end
  end
end

def print_message(file, fact, line)
  puts "File: #{file} contains legacy fact #{fact} on line #{line}"
end

def check_file(file)
  handle    = File.open(file, 'r')
  count     = 0
  handle.each_line do |line|
    count += 1
    # Check if line is commented
    next if line.match?(%r{^#})
    # check for easy facts.
    LEGACY_FACTS.each do |easy|
      if file.match?(%r{\.pp$|\.epp$|\.erb$})
        # check epp pp and erb
        if line.match?(%r{[\$\@]facts\[\'#{easy}\'\]})
          print_message(file, easy, count)
        elsif line.match?(%r{[\$\@]#{easy}[ %=\{]})
          print_message(file, easy, count)
        elsif line.match?(%r{[\$\@]\:\:#{easy}[ %=\{]})
          print_message(file, easy, count)
        end
      elsif file.match?(%r{\.rb$})
        # check rb only
        if line.match?(%r{Factor.value\(\'#{easy}\'\)})
          print_message(file, easy, count)
        elsif line.match?(%r{confine #{easy}\:})
          print_message(file, easy, count)
        elsif line.match?(%r{defaultfor #{easy}\:})
          print_message(file, easy, count)
        end
      elsif file.match?(%r{\.yaml$})
        if line.match?(%r{\%\{\:\:#{easy}\}})
          print_message(file, easy, count)
        elsif line.match?(%r{\%\{#{easy}\}})
          print_message(file, easy, count)
        elsif line.match?(%r{\%\{facts.#{easy}\}})
          print_message(file, easy, count)
        end
      end
    end
    REGEX_FACTS.each do |regex|
      if line.match?(regex)
        print_message(file, regex, count)
      end
    end
  end
end

files = []
puts "Environment path is #{environment_path}/#{environment}/*"
get_pp_files(files, "#{environment_path}/#{environment}/*", pattern)

files.each do |file|
  check_file(file)
end
