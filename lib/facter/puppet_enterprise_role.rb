# frozen_string_literal: true

require 'open3'
require 'json'
require 'socket'

Facter.add(:puppet_enterprise_role) do
  # confine kernel: 'Linux' # disable as this causing issues with unit tests on osx.
  setcode do
    def get_puppet_role
      output, status = Open3.capture2('puppet infrastructure status')
      hostname = Socket.gethostname
      results = {}

      # Populate the hash with value for Primary and Replica
      output.each_line do |line|
        if line.match?(%r{^Primary: })
          results['Primary'] = line.gsub(%r{^Primary: }, '').lstrip.rstrip
        elsif line.match?(%r{^Master: })
          results['Primary'] = line.gsub(%r{^Master: }, '').lstrip.rstrip
        elsif line.match?(%r{^Replica: })
          results['Replica'] = line.gsub(%r{^Replica: }, '').lstrip.rstrip
        end
      end

      # Compare our hostname to results
      results.each do |k, v|
        if v.include? hostname
          return k
        end
      end

      # If we have not matched, we are probably running on a compiler.
      return 'Compiler' unless status == 0
      'Error getting Puppet Infra Role'
    end

    # confirm this is a pe
    if Facter.value(:pe_version).to_s.empty?
      nil
    else
      # we are running on PE node, check role.
      get_puppet_role
    end
  end
end
