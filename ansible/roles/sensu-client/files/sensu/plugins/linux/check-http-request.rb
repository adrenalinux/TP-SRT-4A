#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'httparty'

class HttpRequest < Sensu::Plugin::Metric::CLI::Graphite
    option :url,
        description: 'GET request URL',
        long: '--url URL',
        short: '-u URL',
        default: "localhost"
    option :scheme,
        description: 'Metric naming scheme, text to prepend to .$parent.$child',
        long: '--scheme SCHEME',
        default: "#{Socket.gethostname}"
    def run
        timestamp = Time.now.to_i
        response = HTTParty.get("#{config[:url]}")
        output "#{config[:scheme]}.http_request.code", response.code, timestamp
        critical if response.code != 200
        ok
    end
end
