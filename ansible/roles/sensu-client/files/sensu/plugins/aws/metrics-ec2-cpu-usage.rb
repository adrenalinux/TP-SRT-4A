#! /usr/bin/env ruby
#
# metrics-ec2-cpu-usage
#
# DESCRIPTION:
#   EC2 CPU Metrics by CloudWatch API.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: aws-sdk
#   gem: sensu-plugin
#
# USAGE:
#   ./metrics-ec2-cpu-usage.rb -r ${you_region} -i ${your_instance_id}
#
#

require 'sensu-plugin/metric/cli'
require 'aws-sdk'

class MetricsEc2CpuUsage < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long:        '--scheme SCHEME',
         default:     `#{'hostname --fqdn'}`.chomp

  option :aws_access_key,
         short:       '-a AWS_ACCESS_KEY',
         long:        '--aws-access-key AWS_ACCESS_KEY',
         description: "AWS Access Key. Either set ENV['AWS_ACCESS_KEY'] or provide it as an option",
         default:     ENV['AWS_ACCESS_KEY']

  option :aws_secret_access_key,
         short:       '-k AWS_SECRET_KEY',
         long:        '--aws-secret-access-key AWS_SECRET_KEY',
         description: "AWS Secret Access Key. Either set ENV['AWS_SECRET_KEY'] or provide it as an option",
         default:     ENV['AWS_SECRET_KEY']

  option :aws_region,
         short:       '-r AWS_REGION',
         long:        '--aws-region REGION',
         description: 'AWS Region (defaults to us-east-1).',
         default:     'us-east-1'

  option :instance_id,
         short:       '-i instance-id',
         long:        '--instance-id instance-ids',
         description: 'EC2 Instance ID to check.',
         default:     `#{'ec2metadata --instance-id'}`.chomp

  option :start_time,
         short:       '-s T',
         long:        '--start-time TIME',
         default:     Time.now - 600,
         description: 'CloudWatch metric statistics start time'

  option :end_time,
         short:       '-t T',
         long:        '--end-time TIME',
         default:     Time.now,
         description: 'CloudWatch metric statistics end time'

  option :period,
         short:       '-p N',
         long:        '--period SECONDS',
         default:     60,
         description: 'CloudWatch metric statistics period'

  %w(warning critical).each do |severity|
    %w(over under).each do |interval|
      option :"#{severity}_#{interval}",
             long:        "--#{severity}-#{interval} COUNT",
             description: "Trigger a #{severity} if cpu usage is #{interval} specified percent"
    end
  end

  def timestamp
    @timestamp = Time.now.to_i
  end

  def aws_config
    { access_key_id: config[:aws_access_key],
      secret_access_key: config[:aws_secret_access_key],
      region: config[:aws_region]
    }
  end

  def ec2
    @ec2 ||= Aws::EC2::Client.new aws_config
  end

  def cloud_watch
    @cloud_watch ||= Aws::CloudWatch::Client.new aws_config
  end

  def usage_metric(instance, metric_name)
    cloud_watch.get_metric_statistics(
      namespace: 'AWS/EC2',
      metric_name: metric_name,
      dimensions: [
        {
          name: 'InstanceId',
          value: instance
        }
      ],
      start_time: config[:start_time],
      end_time: config[:end_time],
      statistics: ['Average'],
      period: config[:period]
    )
  end

  def latest_value(value)
    value.datapoints[0][:average].to_f unless value.datapoints[0].nil?
  end

  def check_metric(instance, metric_name)
    metric = usage_metric instance, metric_name
    latest_value metric unless metric.nil?
  end

  def run
    metric_value = []
    metric_value[0] = check_metric config[:instance_id], 'CPUUtilization'
    if !metric_value[0].nil?
      output [config[:scheme], 'metrics-ec2-cpu-usage', config[:instance_id], 'cpu-utilization'].join('.'), metric_value[0], timestamp
      if `#{'ec2metadata --instance-type'}`.chars.to_a[0] == 't'
        metric_value[1] = check_metric config[:instance_id], 'CPUCreditBalance'
        metric_value[2] = check_metric config[:instance_id], 'CPUCreditUsage'
        output [config[:scheme], 'metrics-ec2-cpu-usage', config[:instance_id], 'cpu-credit-balance'].join('.'), metric_value[1], timestamp
        output [config[:scheme], 'metrics-ec2-cpu-usage', config[:instance_id], 'cpu-credit-usage'].join('.'), metric_value[2], timestamp
      end
      ok
    else
      ok 'No data found'
    end
  end
end
