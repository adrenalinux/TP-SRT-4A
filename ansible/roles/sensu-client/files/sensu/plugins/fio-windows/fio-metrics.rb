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
    cmd = `fio conf.fio`
    unless cmd.empty?
        value = cmd.scan(/aggrb=(\d*)KB\/s/)
        unless value.empty?
            write_value = value[0][0].to_f
            read_value = value[1][0].to_f
            output "#{config[:scheme]}.fio.write", write_value, timestamp
            output "#{config[:scheme]}.fio.read", read_value, timestamp
            ok
        end
    end
  end
end
