#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   iostat-extended-metrics
#
# DESCRIPTION:
#   This plugin collects iostat data for a specified disk or all disks.
#   Output is in Graphite format. See `man iostat` for detailed
#   explaination of each field.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Peter Fern <ruby@0xc0dedbad.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'aws-sdk'
require 'net/http'

class CheckEbsIops < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"

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
         description: 'EC2 Instance ID to check.'

  def self_metadata(data)
    metadata_endpoint = "http://instance-data/latest/meta-data/"
    return Net::HTTP.get(URI.parse(metadata_endpoint + data))
  end

  def get_volumes(instance_id)
    volumes = ec2.describe_volumes({
      filters: [
        {
          name: "attachment.instance-id",
          values: [instance_id],
        },
      ],
    }).volumes
    ok "No volumes found" if volumes.nil? or volumes.empty?
    return volumes
  end

  def output_data(instance_id, volumes)
    timestamp = Time.now.to_i
    volumes.each do |vol|
      device = vol.attachments[0].device.split("/")[-1].sub(/^s/, "xv").tr('0123456789', '')
      output [config[:scheme], "ebs-info", device, "instance_id"].join('.'), instance_id, timestamp
      output [config[:scheme], "ebs-info", device, "volume_id"].join('.'), vol.volume_id, timestamp
      output [config[:scheme], "ebs-info", device, "type"].join('.'), vol.volume_type, timestamp
      output [config[:scheme], "ebs-info", device, "size"].join('.'), vol.size, timestamp
      if vol.volume_type != "standard"
        output [config[:scheme], "ebs-info", device, "iops"].join('.'), vol.iops, timestamp
      end
    end
  end

  def ec2
    @ec2 ||= Aws::EC2::Client.new(region: config[:aws_region])
  end

  def run
    if config[:instance_id].nil?
      instance_id = self_metadata("instance-id")
    else
      instance_id = config[:instance_id]
    end
    volumes = get_volumes(instance_id)
    output_data(instance_id, volumes)
    ok
  end
end
