#! /usr/bin/env/ruby
#
#   wfs-tasks-status.rb
#
# DESCRIPTION:
#   This plugin collects wfs tasks status using WFS REST API.
#
# OUTPUT:
#   status_name number_of_tasks timestamp
#
# PLATEFORMS:
#   Windows
#
# DECENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   ruby wfs-tasks-status.rb -h HOST -p PORT
#
# NOTES:
#   default host: localhost
#   default port: 8731
#

require 'rubygems' if RUBY_VERSION <= '2.0.0'
require 'sensu-plugin/metric/cli'
require 'rest-client'

class WfsTaskStatusMetric < Sensu::Plugin::Metric::CLI::Graphite
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
        for i in 0..17
            response = RestClient.get "http://#{config[:host]}:#{config[:port]}/Rhozet.JobManager.JMServices/REST/Job/Task/GetTaskCountEx?status=" + i.to_s
            jobs_status = case i
                when 0
                    'Wainting'
                when 1
                    'Queued'
                when 2
                    'Error'
                when 3
                    'Completed'
                when 4
                    'Stopped'
                when 5
                    'Starting'
                when 6
                    'Started'
                when 7
                    'Preparing'
                when 8
                    'Fatal'
                when 9
                    'Stopping'
                when 10
                    'Pausing'
                when 11
                    'Paused'
                when 12
                    'Taken'
                when 13
                    'Resuming'
                when 14
                    'Hold'
                when 15
                    'Reject'
                when 16
                    'Ignored'
                when 17
                    'Inactive'
                end
            output jobs_status, response.gsub(/<\/?[^>]+>/, '')
        end
        ok
    end
end
