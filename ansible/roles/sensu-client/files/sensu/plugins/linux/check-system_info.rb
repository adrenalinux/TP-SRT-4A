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

def get_my_address
   interfaces = `ip addr`
   re = interfaces.scan(/inet (\d{0,3}.\d{0,3}.\d{0,3}.\d{0,3}\/\d{0,2})/)
   interfaces = ""
   re.each do|m|
        interfaces +=  m[0] + ' '
   end
   return interfaces
end

class CheckSysInfo < Sensu::Plugin::Metric::CLI::JSON
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"

  def run
    os = `uname -s`.gsub(/\n/, "")
    disk = `parted -l | grep -i "Disk /dev/sda"`.gsub(/\n/, "")

    ip = get_my_address
    ok "os" => os, "disk" => disk, "ip" => ip
  end
end
