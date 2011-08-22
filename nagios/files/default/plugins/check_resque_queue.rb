#!/usr/bin/env ruby

require 'rubygems'
require 'redis/namespace'
require 'optparse'

OPT = {}
OptionParser.new do |opts|
  opts.on("-h", "--host HOST", "Redis hostname") {|host| OPT[:host] = host }
  opts.on("-p", "--port PORT", "Write stats to log file") {|port| OPT[:port] = port || 6379 }
  opts.on("-q", "--queue QUEUE", "Resque queue names, comma-separated") { |queues| OPT[:queues] = queues.split(",") }
  opts.on("-w", "--critical WARNING", "Warning threshold") { |warning| OPT[:warning] = warning.to_i }
  opts.on("-c", "--critical CRITICAL", "Critical threshold") { |critical| OPT[:critical] = critical.to_i }
  opts.parse!(ARGV)
end

begin
  redis = Redis.new(:host => OPT[:host], :port => OPT[:port])
  resque = Redis::Namespace.new(:resque, :redis => redis)
  warning_queues = {}
  critical_queues = {}
  
  OPT[:queues].each do |q|
    length = resque.llen("queue:#{q}")
    if length >= OPT[:critical]
      critical_queues[q] = length
    elsif length >= OPT[:warning]
      warning_queues[q] = length
    end
  end

  if critical_queues.size > 0
    puts "Queues exceeding critical threshold of #{OPT[:critical]}: #{critical_queues.collect{|k, v| "#{k}(#{v})"}.join(", ") }"
    exit 2
  elsif warning_queues.size > 0
    puts "Queues exceeding warning threshold of #{OPT[:warning]}: #{warning_queues.collect{|k, v| "#{k}(#{v})"}.join(", ") }"
    exit 1
  else
    puts "Resque queues OK"
    exit 0
  end
rescue Errno::ECONNREFUSED
  puts "Redis server at #{OPT[:host]}:#{OPT[:port]} is unreachable."
  exit 2
end
