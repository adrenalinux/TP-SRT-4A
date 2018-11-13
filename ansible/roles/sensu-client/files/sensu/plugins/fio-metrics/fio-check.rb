#! /usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'

video_value = 27500.0

timestamp = Time.now.to_i
cmd = `fio /etc/sensu/plugins/conf.fio`
unless cmd.empty?
  value = cmd.scan(/aggrb=(\d*)KB\/s/)
  unless value.empty?
    write_value = value[0][0].to_f
    read_value = value[1][0].to_f
    cmd = `rm /tmp/conf-readwrite*`
    if write_value < video_value
      exit 1
    else
      exit 0
    end
  end
end


