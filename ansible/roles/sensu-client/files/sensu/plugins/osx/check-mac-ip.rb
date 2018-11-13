#! /usr/bin/env ruby
# encoding: UTF-8
#
#   check-system_info
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 MSolution.IO, Inc <support@msolution.io>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'netaddr'

def get_ip(ip_array)
    interfaces = []
    ip_array.each do|a|
	tmp = a.split(' ')
	ip = tmp[1]
	nm = NetAddr.i_to_bits('0xffffff00'.to_i(16))
	my_str = nm.to_s
	interfaces.push(ip + '/' + nm.to_s)
    end
   return interfaces
end

def get_my_address
   interfaces = `ifconfig`
   re = interfaces.scan(/(inet \d*.\d*\.d*.\d*.\d* netmask \S*)/)
   interfaces = []
   re.each do|m|
        interfaces.push(m[0])
   end
   interfaces = get_ip(interfaces)
   return interfaces
end

class CheckSysInfo < Sensu::Plugin::Metric::CLI::JSON
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"

  def run
    ip = NetAddr.i_to_bits(0xffffff00)
    interfaces = get_my_address()
    ok "os" => "OSX", "ip" => interfaces
  end
end
