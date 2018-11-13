#! /usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class Ping < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"  
  def run
    timestamp = Time.now.to_i
    cmd = `ping -c 5 www.google.com`
    unless cmd.empty?
        cmd1 = /mdev = (.+)\ /.match(cmd).to_s
        cmd2 = cmd1.split(' ')
        avg = cmd2[2].split('/')
        average_value = avg[1].to_f
        output "#{config[:scheme]}.ping.avg", average_value, timestamp
        ok
     end
    end
  end
