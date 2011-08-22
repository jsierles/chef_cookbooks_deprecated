#!/usr/bin/env ruby
#
# Check the size of a database queue
#

require 'rubygems'
require 'choice'
require 'mysql'

EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3

Choice.options do
  header ''
  header 'Specific options:'

  option :host do
    short '-H'
    long '--host=VALUE'
    desc 'MySQL DB host'
  end

  option :port do
    short '-P'
    long '--port=VALUE'
    desc 'MySQL DB port'
  end    

  option :username do
    short '-u'
    long '--username=VALUE'
    desc 'MySQL DB username'
  end    
  
  option :password do
    short '-p'
    long '--password=VALUE'
    desc 'MySQL DB password'
  end    
  
  option :database do
    short '-d'
    long '--database=VALUE'
    desc 'MySQL database'
  end

end

c = Choice.choices

# nagios performance data format: 'label'=value[UOM];[warn];[crit];[min];[max]
# see http://nagiosplug.sourceforge.net/developer-guidelines.html#AEN203
  
conn = Mysql::connect(c[:host], c[:username], c[:password], c[:database], c[:port].to_i)
res = conn.query("SHOW GLOBAL VARIABLES LIKE 'read_only';")
value = res.fetch_row.last

if value != 'ON'
  puts "Critical: Read only is set to #{value}"
  exit(EXIT_CRITICAL)
end

# if warning nor critical trigger, say OK and return performance data

puts "Mysql readonly is set to #{value}"
