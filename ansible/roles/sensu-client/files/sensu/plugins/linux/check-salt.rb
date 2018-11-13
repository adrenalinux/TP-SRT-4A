#!/usr/bin/env ruby                                                             

# get the current list of processes                                             
processes = `ps aux`

# determine if the salt-minion process is running                               
running = processes.lines.detect do |process|
  process.include?('salt-minion')
end

# return appropriate check output and exit status code                          
puts running
if running
  puts 'OK - salt-minion is running'
  exit 0
else
  puts 'WARNING - salt-minion is NOT running'
  exit 1
end
