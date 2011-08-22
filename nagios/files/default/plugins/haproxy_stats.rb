#!/usr/bin/env ruby
#
# Nagios plugin for haproxy sockets
#

require 'rubygems'
require 'choice'

EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3

Choice.options do
  header ''
  header 'Specific options:'

  option :warn do
    short '-w'
    long '--warning=VALUE'
    desc 'Warning threshold'
    cast Integer
  end

  option :crit do
    short '-c'
    long '--critical=VALUE'
    desc 'Critical threshold'
    cast Integer
  end

  option :path do
    short '-p'
    long '--path=VALUE'
    desc 'Path to socket file'
  end

  option :backend do
    short '-b'
    long '--backend=VALUE'
    desc 'Backend name'
  end

  option :type do
    short '-t'
    long '--type=VALUE'
    desc 'Valid options are: backlog'
    valid %w(backlog)
  end
  
end

c = Choice.choices

# nagios performance data format: 'label'=value[UOM];[warn];[crit];[min];[max]
# see http://nagiosplug.sourceforge.net/developer-guidelines.html#AEN203


if c[:warn] && c[:crit]

  if c[:type] == 'backlog'
    perfdata = "backlog=%d;#{c[:warn]};#{c[:crit]}"
    message = "%d backlogged connections exceeds %d|#{perfdata}"
    ok_message = "%d backlogged connections OK|#{perfdata}"
    backends = `echo "show stat" | socat #{c[:path]} stdio | grep BACKEND`.split("\n")
    be = backends.detect {|b| b.split(",").first == c[:backend] }
    parts = be.split(",")
    # qcur value from stats output
    value = parts[2].to_i
  end
  
  if value >= c[:crit]
    puts sprintf(message, value, c[:crit], value)
    exit(EXIT_CRITICAL)
  end
  
  if value >= c[:warn]
    puts sprintf(message, value, c[:warn], value)
    exit(EXIT_WARNING)
  end
  
else
  puts "Please provide a warning and critical threshold"
end

# if warning nor critical trigger, say OK and return performance data

puts sprintf(ok_message, value, value)