#!/usr/bin/env ruby
#
# Check the size of a database queue
#
require 'rubygems'
require 'highrise'
require 'choice'

# Hide SSL certificate validation warnings.
class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

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

  option :subdomain do
    short '-s'
    long '--subdomain=VALUE'
    desc 'Highrise subdomain'
  end

  option :api_key do
    short '-a'
    long '--api_key=VALUE'
    desc 'HR API key'
  end
  
  option :item do
    short '-i'
    long '--item=VALUE'
    desc 'HR object type to check age for: task, recording, etc'
  end 
  
end

c = Choice.choices

Highrise::Base.site = "https://#{c[:subdomain]}.highrisehq.com"
Highrise::Base.user = c[:api_key]
tasks = "Highrise::#{c[:item].classify}".constantize.find(:all).sort_by{|t| t.created_at}

http = Net::HTTP.new("#{c[:subdomain]}.highrisehq.com",443)

tasks.each do |task|
  if Time.now - task.created_at > 30.minutes
    req = Net::HTTP::Delete.new("/tasks/#{task.id}.xml")
    http.use_ssl = true
    req.basic_auth c[:api_key], "X"
    response = http.request(req)
  end
end

latest_item_created_at = Time.now - tasks.last.created_at

if latest_item_created_at > c[:crit].to_i.minutes
  puts "CRITICAL: Latest Highrise #{c[:item]} older than #{c[:crit]} minutes"
  exit EXIT_CRITICAL
elsif latest_item_created_at > c[:warn].to_i.minutes
  puts "WARNING: Latest Highrise #{c[:item]} older than #{c[:warn]} minutes"
  exit EXIT_WARNING
else  
  puts "OK: Latest Highrise #{c[:item]} less than #{c[:warn]} minutes old"
 exit EXIT_OK
end
