#! /usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class Fio < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"  
  def run
    timestamp = Time.now.to_i
    cmd = `iostat -x`
    unless cmd.empty?
        cmd = cmd.split(' ')
	value = []
	value[0] = cmd[-8]
	value[1] = cmd[-9]
        unless value.empty?
            write_value = value[0].to_f
            read_value = value[1].to_f
            output "#{config[:scheme]}.iostat-x.write", write_value, timestamp
            output "#{config[:scheme]}.iostat-x.read", read_value, timestamp
            ok
        end
    end
  end
end
