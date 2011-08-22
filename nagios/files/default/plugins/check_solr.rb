#!/usr/bin/env ruby
#
# Nagios check for Solr server health
# Copyright 37signals, 2010
# Author: Joshua Sierles (joshua@37signals.com)

require 'rubygems'
require 'hpricot'
require 'net/http'
require 'uri'
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
    desc 'Expected value'
    cast Integer
  end

  option :host do
    short '-h'
    long '--host=VALUE'
    desc 'Solr host'
  end
  
  option :port do
    short '-a'
    long  '--port=VALUE'
    desc 'Alternate Solr Port'
    default 8983
  end  

  option :prefix do
    short '-p'
    long '--prefix=VALUE'
    desc 'App prefix'
  end
  
  option :start do
    short '-s'
    long '--start=VALUE'
    desc 'Start index'
  end
  
  option :rows do
    short '-r'
    long  '--rows=VALUE'
    desc 'Number of rows to check for'
    default 10
  end
  
  option :query do
    short '-q'
    long  '--query=VALUE'
    desc 'Query term to search for'
    default "%2Blaksjdflkajsdflkas%0D%0A"
  end
  
  option :ping do
    short '-g'
    long '--ping'
    desc 'Only ping the server for uptime'
  end

  option :version do
    short '-v'
    long  '--version=VALUE'
    desc 'Specify version'
    default "2.2"
  end
end

c = Choice.choices

value = 0

url_prefix = "http://#{c[:host]}:#{c[:port]}/#{c[:prefix]}"

if c[:ping]
  url = "#{url_prefix}/admin/ping"
  xml = Hpricot::XML(`curl -s '#{url}'`.strip)
  value = xml.at('str[@name="status"]').inner_text
  if value != "OK"
    puts sprintf("Solr is %s", value)
    exit(EXIT_CRITICAL)
  else
    puts sprintf("OK: Solr is up")
    exit  
  end
  
else

  url = "#{url_prefix}/select/?q=#{c[:query]}&version=#{c[:version]}&start=#{c[:start]}&rows=#{c[:rows]}&indent=on"
  expected = c[:crit]
  message = "Solr reports %d rows"
  xml = Hpricot::XML(`curl -s '#{url}'`.strip)
  value = xml.at('str[@name="rows"]').inner_text.to_i

  if c[:crit] && value < c[:crit]
    puts sprintf(message, value)
    exit(EXIT_CRITICAL)
  elsif c[:warn] && value < c[:warn]
    puts sprintf(message, value)
    exit(EXIT_WARNING)
  else
    puts sprintf(message, value)
    exit
  end
end