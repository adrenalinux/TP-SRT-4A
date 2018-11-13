#! /usr/bin/env/ruby
#
#   wfs-jobs-status.rb
#
# DESCRIPTION:
#   This plugin collects wfs jobs status using WFS REST API.
#
# OUTPUT:
#   status_name number_of_jobs timestamp
#
# PLATEFORMS:
#   Windows
#
# DECENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   ruby wfs-jobs-status.rb -h HOST -p PORT
#
# NOTES:
#   default host: localhost
#   default port: 8731
#

require 'rubygems' if RUBY_VERSION <= '2.0.0'
require 'sensu-plugin/metric/cli'
require 'rest-client'

class WfsJobsStatusMetric < Sensu::Plugin::Metric::CLI::Graphite
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
        for i in 0..6
            response = RestClient.get "http://#{config[:host]}:#{config[:port]}/Rhozet.JobManager.JMServices/REST/Job/GetJobCount?status=" + i.to_s
            jobs_status = case i
                when 0
                    'Queued'
                when 1
                    'Paused'
                when 2
                    'Active'
                when 3
                    'Fatal'
                when 4
                    'Completed'
                when 5
                    'Abort'
                when 6
                    'Inactive'
                end
            output jobs_status, response.gsub(/<\/?[^>]+>/, '')
        end
        ok
    end
end
