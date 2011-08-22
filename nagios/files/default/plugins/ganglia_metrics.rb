#!/usr/bin/env ruby
#
# Nagios check for Ganglia metrics
# Copyright 37signals, 2010
# Author: John Williams (john@37signals.com)

require 'rubygems'
require 'socket'
require 'choice'
require 'nokogiri'

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
  end

  option :crit, :required => true do
    short '-c'
    long '--critical=VALUE'
    desc 'Critical threshold (REQUIRED)'
  end

  option :metric, :required => true do
    short '-m'
    long '--metric=VALUE'
    desc 'Ganglia metric (REQUIRED)'
  end

  option :host, :required => true do
    short '-h'
    long '--host=VALUE'
    desc 'Ganglia host (REQUIRED)'
    default '127.0.0.1'
  end
  
  option :port do
    short '-p'
    long '--port=VALUE'
    desc 'Ganglia port'
    default 8649
    cast Integer
  end
  
  option :operator, :required => true do
    short '-o'
    long '--operator=VALUE'
    desc 'Operator <less|more|equal|notequal> less, more, equal and notequal specify whether we mark metric critical if it is less, more, equal or notequal to critical value (REQUIRED)'
    valid %w[less more equal notequal]
  end
end

c = Choice.choices

socket = TCPSocket.new(c[:host], c[:port])
xml_doc = socket.read

noko = Nokogiri::XML(xml_doc)
metric = noko.root.xpath("/GANGLIA_XML/CLUSTER/HOST[starts-with(@NAME, \"#{c[:host]}\")]/METRIC[@NAME=\"#{c[:metric]}\"]").first

if metric
  
  critical_message = "#{metric["NAME"]} is CRITICAL: reports %s"
  warning_message = "#{metric["NAME"]} is WARNING: reports %s"
  value = metric["VAL"]
  
  if value.to_i.to_s == value || value.to_f.to_s == value
    value = value.to_f
  end
  
  if c[:operator] == "less"
    if value < c[:crit]
      puts sprintf(critical_message, value)
      exit(EXIT_CRITICAL)
    end
    if c[:warn] && value < c[:warn]
      puts sprintf(warning_message, value)
      exit(EXIT_WARNING)
    end
  elsif c[:operator] == "more"
    if value > c[:crit]
      puts sprintf(critical_message, value)
      exit(EXIT_CRITICAL)
    end
    if c[:warn] && value > c[:warn]
      puts sprintf(warning_message, value)
      exit(EXIT_WARNING)
    end
  elsif c[:operator] == "equal"
    if value == c[:crit]
      puts sprintf(critical_message, value)
      exit(EXIT_CRITICAL)
    end
    if c[:warn] && value == c[:warn]
      puts sprintf(warning_message, value)
      exit(EXIT_WARNING)
    end
  elsif c[:operator] == "notequal"
    if value != c[:crit]
      puts sprintf(critical_message, value)
      exit(EXIT_CRITICAL)
    end
    if c[:warn] && value != c[:warn]
      puts sprintf(warning_message, value)
      exit(EXIT_WARNING)
    end
  end
  puts sprintf("#{metric["NAME"]} is OK, reports %s", value)
end