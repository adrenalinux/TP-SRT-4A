#! /usr/bin/env/ruby
#
#   wfs-tasks-status.rb
#
# DESCRIPTION:
#   This plugin collects wfs tasks type using WFS REST API.
#
# OUTPUT:
#   type_name number_of_tasks timestamp
#
# PLATEFORMS:
#   Windows
#
# DECENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   ruby wfs-tasks-type.rb -h HOST -p PORT
#
# NOTES:
#   default host: localhost
#   default port: 8731
#

require 'rubygems' if RUBY_VERSION <= '2.0.0'
require 'sensu-plugin/metric/cli'
require 'rest-client'

class WfsTaskTypeMetric < Sensu::Plugin::Metric::CLI::Graphite
    option :host,
        description: 'WFS API host',
        short: '-h',
        long: '--host HOST',
        default: 'localhost'

    option :port,
        description: 'WFS API port',
        short: '-p',
        long: '--port PORT',
        default: '8731'

    def run
        for i in 0..28
            response = RestClient.get "http://#{config[:host]}:#{config[:port]}/Rhozet.JobManager.JMServices/REST/Job/Task/GetTaskCountByTaskType?type=" + i.to_s
            task_type = case i
                when 0
                    'Undefined'
                when 1
                    'Transcode'
                when 2
                    'RMP'
                when 3
                    'NotifySMTP'
                when 4
                    'NotifyURL'
                when 5
                    'NotifyProcess'
                when 6
                    'Transfer'
                when 7
                    'Multiplex'
                when 8
                    'WatchTrigger'
                when 9
                    'Pause'
                when 10
                    'QC'
                when 11
                    'Review'
                when 12
                    'StartTask'
                when 13
                    'NoopTask'
                when 14
                    'EndTask'
                when 15
                    'MediaEvaluate'
                when 16
                    'ControlledCapture'
                when 17
                    'LiveCapture'
                when 18
                    'Rehearsal'
                when 19
                    'Maintenance'
                when 20
                    'Encryption'
                when 21
                    'WatchIndex'
                when 22
                    'Package_HDS'
                when 23
                    'Package_HLS'
                when 24
                    'Package_Smooth'
                when 25
                    'Report'
                when 26
                    'Encryption_HDS'
                when 27
                    'Xpress'
                when 28
                    'Package_DASH'
                end
            output task_type, response.gsub(/<\/?[^>]+>/, '')
        end
        ok
    end
end
