#!/usr/bin/env ruby
#
# Nagios check for MogileFS bored query workers
# Copyright 37signals, 2010
# Author: John Williams (john@37signals.com)

require 'rubygems'
require 'choice'
require 'net/telnet'

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

  option :host do
    short '-h'
    long '--host=VALUE'
    desc 'MogileFS host'
  end
  
  option :port do
    short '-p'
    long '--port=VALUE'
    desc 'MogileFS port'
  end
end

c = Choice.choices

if c[:crit]

  value = 0
  
  begin
  results = ""
  mogilefs = Net::Telnet::new("Host" => c[:host], "Port" => c[:port], "Telnetmode" => true, "Prompt" => /[$%#>] \z/n)
  results = mogilefs.cmd("String" => "!stats", "Match" => /./) { |r| results += r }
  mogilefs.close
  results.each_line do |line|
    if line.match "bored_queryworkers"
      value = line.split(" ").last.to_i
    end
  end
  
  rescue Exception => e
    puts "Error checking MogileFS: #{e.message}"
    exit(EXIT_UNKNOWN)
  end 

  if value <= c[:crit]
    message = "MogileFS is CRITICAL: reports %d bored query workers"
    puts sprintf(message, value)
    exit(EXIT_CRITICAL)
  end

  if c[:warn] && value <= c[:warn]
    message = "MogileFS is WARNING: reports %d bored query workers"
    puts sprintf(message, value)
    exit(EXIT_WARNING)
  end

else
  puts "Please provide a critical threshold"
  exit
end

puts sprintf("MogileFS is OK, reports %d bored query workers", value)