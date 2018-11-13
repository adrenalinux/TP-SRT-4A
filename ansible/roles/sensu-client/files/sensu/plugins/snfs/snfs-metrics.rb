#! /usr/bin/env ruby


require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'yaml'
require 'socket'
require 'net/ssh'
require_relative 'snfs_parser.rb'

class SnfsCheck < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
    description: 'ssh host',
    short: '-h HOST',
    long: '--host HOST',
    default: 'localhost'

  option :user,
    description: 'ssh user',
    short: '-u USER',
    long: '--user USER'

  option :password,
    description: 'ssh password',
    short: '-p PASSWORD',
    long: '--password PASSWORD'

  option :config_file,
    description: 'YAML file where configurations might be stored',
    short: '-c CONFIG',
    long: '--config CONFIG'

  option :scheme,
    description: 'Metric naming scheme, text to prepend to .$parent.$child',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}"

  option :cvfsdir,
    description: 'Cvfs install directory, text to prepend to /bin/cv*, default is /usr/cvfs',
    short: '-d CVFSBIN',
    long: '--cvfsdir CVFSDIR',
    default: '/usr/cvfs'

  option :table_type,
    description: 'Type of metrics extracted from SNFS (client, global, disk, sg, system)',
    short: '-t TABLE_TYPE',
    long: '--table_type TABLE_TYPE',
    default: 'global'

  def execute cmd
    if config[:host] == "localhost"
      res = `#{cmd}`
    else
      ssh = Net::SSH.start(config[:host], config[:user], :password => config[:password], :auth_methods => ["password"], :timeout => 10)
      res = ssh.exec!(cmd)
      ssh.close
    end
    res
  end

  def config
    config = super
    if config[:config_file]
      begin
        config = config.merge(Hash[YAML.load_file(config[:config_file]).map { |k, v| [k.to_sym, v] }])
      rescue
      end
    end
    @cached_resolved_config = config
  end

  def version
    @version = execute("#{config[:cvfsdir] + '/bin/cvversions | grep -oE "Server\sRevision\s[0-9]" | grep -oE "[0-9]"'}").to_i
  end

  def host_addresses
    host = [ 'localhost', 'MDC', config[:host], '127.0.0.1', `#{'hostname --fqdn'}`.chomp, `#{'hostname --ip-address'}`.chomp ] + `#{'hostname --all-ip-addresses'}`.chomp.split(' ')
    Regexp.union(host)
  end

  def filesystems
    filesystems = execute("#{config[:cvfsdir] + "/bin/cvadmin -e 'select'"}")
    filesystems = filesystems.lines.select { |fs| fs.match(/>\*[0-9a-zA-Z_-]+.+\s#{host_addresses}:/) }
    filesystems.collect! { |fs| /[0-9a-zA-Z_-]+/.match(/>\*[0-9a-zA-Z_-]+/.match(fs).to_s).to_s }
    ok 'No cvfs filesystems found' if filesystems.empty?
    filesystems
  end

  def run
    #unknown 'SNFS version not supported' if version != 5
    #warning 'No "setuid" found on cvadmin binary, use "chmod u+s ' + config[:cvfsdir] + '/bin/cvadmin"' unless execute("#{'ls -l ' + config[:cvfsdir] + '/bin/ | grep -cE "^-..s.*cvadmin$"'}").to_i > 0
    filesystems.each do |fs|
      qustat_output = execute("#{config[:cvfsdir] + "/bin/qustat -f " + fs.to_s + " -m FSM -F all -F csv"}")
      output_values(qustat_output)
    end
    ok
  end

  def disk_tables(data_tables)
    @disk_tables = data_tables.select { |table| table[:table_type] == config[:table_type] }
  end

  def display_line(prefix, timestamp, line)
    case line[:data_type]
      when 'cnt'
        output [prefix, line[:data_name], 'count'].join('.'), line[:data_count], timestamp
      when 'lvl'
        output [prefix, line[:data_name], 'level'].join('.'), line[:data_tot_lvl], timestamp
      when 'sum'
        output [prefix, line[:data_name], 'count'].join('.'), line[:data_count], timestamp
        output [prefix, line[:data_name], 'total'].join('.'), line[:data_tot_lvl], timestamp
      when 'tim'
        output [prefix, line[:data_name], 'count'].join('.'), line[:data_count], timestamp
        output [prefix, line[:data_name], 'min'].join('.'), line[:data_min] / 1000, timestamp
        output [prefix, line[:data_name], 'max'].join('.'), line[:data_max] / 1000, timestamp
        output [prefix, line[:data_name], 'avg'].join('.'), line[:data_avg] / 1000, timestamp
        output [prefix, line[:data_name], 'total'].join('.'), line[:data_tot_lvl], timestamp
    end
  end

  def output_values(data_raw)
    parser = SnfsParser.new
    data = parser.parse_raw_csv(data_raw)
    disk_tables(data[:data]).each do |disk_table|
      prefix = "#{config[:scheme]}" + "." + "snfs" + "." + data[:common_data][:group] + "." + disk_table[:table_type]
      if config[:table_type] == "client" || config[:table_type] == "disk" || config[:table_type] == "sg"
        prefix += "." + disk_table[:table_attribute_1]
      end
      if config[:table_type] == "disk"
        prefix += "." + disk_table[:table_attribute_2]
      end
      prefix += "." + disk_table[:table_data_type]
      disk_table[:table_data].each do |data_line|
        display_line(prefix, data[:common_data][:recorded], data_line)
      end
      output [prefix, 'last_reset', 'timestamp'].join('.'), disk_table[:table_time_last_reset], data[:common_data][:recorded]
    end
  end
end
