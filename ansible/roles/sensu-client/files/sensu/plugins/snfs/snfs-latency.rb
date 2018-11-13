#! /usr/bin/env ruby


###
#cvadmin binary must have a 's' byte for the augmentation privileges at execution
###
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'net/ssh'
require 'socket'

class Fio < Sensu::Plugin::Metric::CLI::Graphite
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
    config[:host] = settings['snfs']['host'] if settings['snfs'].key?('host')
    config[:user] = settings['snfs']['user'] if settings['snfs'].key?('user')
    config[:password] = settings['snfs']['password'] if settings['snfs'].key?('password')
    if config[:config_file]
      config = config.merge(Hash[YAML.load_file(config[:config_file]).map { |k, v| [k.to_sym, v] }])
    end
    @cached_resolved_config = config
  end

  def host_addresses
    host = [ 'localhost', '127.0.0.1', `#{'hostname --fqdn'}`.chomp, `#{'hostname --ip-address'}`.chomp ] + `#{'hostname --all-ip-addresses'}`.chomp.split(' ')
    Regexp.union(host)
  end

  def filesystems
    filesystems = execute("#{config[:cvfsdir] + '/bin/cvadmin -e \'select\''}")
    filesystems = filesystems.lines.select { |fs| fs.match (/>\*[0-9a-zA-Z_-]+.+\s#{host_addresses}:/) }
    filesystems.collect! { |fs| /[0-9a-zA-Z_-]+/.match(/>\*[0-9a-zA-Z_-]+/.match(fs).to_s).to_s }
    ok 'No cvfs filesystems found' if filesystems.empty?
    filesystems
  end

  def run
    @timestamp = Time.now.to_i
    @version = execute("#{config[:cvfsdir] + '/bin/cvversions | grep -oE "Server\sRevision\s[0-9]" | grep -oE "[0-9]"'}").to_i
    #unknown 'SNFS version not supported' if @version != 4 and @version != 5

    #warning 'No "setuid" found on cvadmin binary, use "chmod u+s ' + config[:cvfsdir] + '/bin/cvadmin"' unless `#{'ls -l ' + config[:cvfsdir] + '/bin/ | grep -cE "^-..s.*cvadmin$"'}`.to_i > 0
    filesystems.each do |fs|
      qustat_output = execute("#{config[:cvfsdir] + "/bin/qustat -f " + fs.to_s + " " + module_opt + " -F all -F csv"}")
      read_latency = compute_latency_values(qustat_output, "read")
      write_latency = compute_latency_values(qustat_output, "write")
      output_values(fs, read_latency, write_latency)
    end
    ok
  end

  def module_opt
    if @version == 4
      module_arg = '-m FSM'
    elsif @version == 5
      module_arg = '-m all'
    end
    module_arg
  end

  def compute_latency_values(output, type)
    matched_lines = output.lines.select { |l| l.match (/^#{make_regex(type).to_s}/) }
    warning "No latency value found" if matched_lines.empty?

    minC = 0
    maxC = 0
    avgC = 0
    min = 0
    max = 0
    avg = 0

    for line in matched_lines do
      line = line.split(",")
      if !line[3].empty?
        minC += 1
        min += line[3].to_i
      end
      if !line[4].empty?
        maxC += 1
        max += line[4].to_i
      end
      if !line[6].empty?
        avgC += 1
        avg += line[6].to_i
      end
    end

    value = []
    value[0] = min / minC
    value[1] = max / maxC
    value[2] = avg / avgC
    value[3] = avgC

    return value
  end

  def make_regex(type)
    if type == "read"
      regex = "Read HiPri"
    elsif type == "write"
      regex = "Write HiPri"
    end
    if @version == 4
      regex = "PIO " + regex
    end
    return regex
  end

  def output_values(file_system, read, write)
      write_min = write[0].to_i
      write_max = write[1].to_i
      write_avg= write[2].to_i
      read_min = read[0].to_i
      read_max = read[1].to_i
      read_avg = read[2].to_i
      records = write[3].to_i + read[3].to_i
      output "#{config[:scheme]}.snfs-latency." + file_system + ".write_min", write_min, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".write_max", write_max, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".write_avg", write_avg, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".read_min", read_min, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".read_max", read_max, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".read_avg", read_avg, @timestamp
      output "#{config[:scheme]}.snfs-latency." + file_system + ".records", records, @timestamp
  end
end
