#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   check-ram
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   OSX
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

MEGABYTE = 1024 * 1024

def bytesToMeg bytes
    bytes / MEGABYTE
end

class CheckRAM < Sensu::Plugin::Check::CLI
  option :megabytes,
         short: '-m',
         long: '--megabytes',
         description: 'Unless --megabytes is specified the thresholds are in percents',
         boolean: true,
         default: false

  option :warn,
         short: '-w WARN',
         proc: proc(&:to_i),
         default: 10

  option :crit,
         short: '-c CRIT',
         proc: proc(&:to_i),
         default: 5

  def run
    total_ram, free_ram = 0, 0

    cmd = `sysctl hw.memsize`.split(' ')
    total_ram = bytesToMeg(cmd[1].to_i)
    
    cmd = `top -l 1 | head -n 10 | grep PhysMem`
    free_ram = /, (\d*)./.match(cmd)
    free_ram = free_ram[1].to_i

    if config[:megabytes]
      message "#{free_ram} megabytes free RAM left"

      critical if free_ram < config[:crit]
      warning if free_ram < config[:warn]
      ok
    else
      unknown 'invalid percentage' if config[:crit] > 100 || config[:warn] > 100

      percents_left = free_ram * 100 / total_ram
      message "#{percents_left}% free RAM left"

      critical if percents_left < config[:crit]
      warning if percents_left < config[:warn]
      ok
    end
  end
end
