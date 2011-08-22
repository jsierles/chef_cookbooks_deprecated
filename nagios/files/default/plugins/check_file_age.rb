#!/usr/bin/env ruby
#
# Nagios check
# Check the age of a file. Replaces the nagios default plugin 
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

  option :file do
    short '-f'
    long '--file=VALUE'
    desc 'Path to file'
  end

  option :invert do
    short '-i'
    long '--invert'
    desc 'File timestamp must be *newer* than the provided thresholds to alert'
  end
  
end

c = Choice.choices

age = (Time.now - File.stat(c[:file]).mtime).round

operator = c[:invert] ? "<=" : ">="

if c[:warn] && c[:crit]

  if age.send(operator.to_sym, c[:crit]) 
    puts "File age is CRITICAL: #{age} seconds"
    exit(EXIT_CRITICAL)
  end
  
  if age.send(operator.to_sym, c[:warn]) 
    puts "File age is WARNING: #{age} seconds"
    exit(EXIT_WARNING)
  end
  
else
  puts "Please provide a warning and critical threshold"
end

puts "File age OK"