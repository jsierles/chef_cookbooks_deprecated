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
    desc 'MySQL Slave host'
  end
  
  option :masterhost do
    short '-m'
    long '--masterhost=VALUE'
    desc 'MySQL Master Host'
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
  
conn = Mysql::connect(c[:host], c[:username], c[:password], "", c[:port].to_i)
res = conn.query("SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE host LIKE '#{c[:masterhost]}%' AND db = '#{c[:database]}';")
value = res.fetch_row

if value.nil?
  puts "CRITICAL: #{c[:masterhost]} is not warming this slave."
  exit(EXIT_CRITICAL)
end

# if warning nor critical trigger, say OK and return performance data

puts "OK: #{c[:masterhost]} is warming this slave."
