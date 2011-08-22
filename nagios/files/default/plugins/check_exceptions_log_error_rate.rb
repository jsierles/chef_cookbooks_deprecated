#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'date'

# Useful for testing
# require 'timecop'
# Timecop.travel(Time.local(2011, 1, 19, 13, 40, 0)) #Jan 19 13:40:26

OPT = {}
OptionParser.new do |opts|
  opts.on("-l", "--logfile FILENAME", "Log filename") {|logfile| OPT[:logfile] = logfile }
  opts.on("-w", "--critical WARNING", "Warning threshold") { |warning| OPT[:warning] = warning.to_i }
  opts.on("-c", "--critical CRITICAL", "Critical threshold") { |critical| OPT[:critical] = critical.to_i }
  opts.parse!(ARGV)
end

def debug(message)
  DEBUG and puts message
end

def datetime_from_string(log)
  date = log.match /Date: (\w{3}, \d+ \w{3} \d{4} \d{2}:\d{2}:\d{2} \+\d{4})\s+From:/
  if date
    return DateTime.strptime(date[1], "%a, %d %b %Y %H:%M:%S %z")
  else
    # Some log entries don't have a full date, use the shorter initial date that doesn't specify the year
    return DateTime.strptime(log[0..14], "%b %e %H:%M:%S")
  end
end

now = Time.now; past = Time.now - 300
NOW = DateTime.civil(now.year, now.month, now.day, now.hour, now.min, now.sec)
FIVE_MINUTES_AGO = DateTime.civil(past.year, past.month, past.day, past.hour, past.min, past.sec)

DEBUG = false
HOSTNAME = `hostname`.strip
FILE_SIZE = File.size(OPT[:logfile])
LOGFILE = File.open OPT[:logfile]
MIN_OFFSET = 500 # How many bytes difference until we stop bothering to do a binary search

def log_start_position(seek_pos, old_pos = 0)
  # Don't try and seek past the beginning or end of the file
  return FILE_SIZE if seek_pos >= FILE_SIZE
  return 0 if seek_pos <= 0
  
  debug "Seeking to #{seek_pos} (#{(seek_pos/FILE_SIZE.to_f) * 100}%), offset is #{seek_pos - old_pos}"
  
  LOGFILE.seek(seek_pos)
  
  # discard the first line, it could be incomplete
  LOGFILE.readline
  return LOGFILE.pos if LOGFILE.pos == FILE_SIZE
  ln = LOGFILE.readline
  date = datetime_from_string(ln)
  
  if date < FIVE_MINUTES_AGO
    # The position we are in in the file is too far back in time, jump forward
    new_pos = LOGFILE.pos + ((FILE_SIZE - LOGFILE.pos) / 2)
    debug "Date #{date} is too old compared to #{FIVE_MINUTES_AGO.to_s}, new position is #{new_pos}"
    return LOGFILE.pos if new_pos - LOGFILE.pos <= MIN_OFFSET
    return log_start_position(new_pos, seek_pos)
  else
    # The position we are in the file is too close to the present, jump back
    new_pos = LOGFILE.pos - ((seek_pos - old_pos) / 2)
    debug "Date #{date} is too new compared to #{FIVE_MINUTES_AGO.to_s}, new position is #{new_pos}"
    return LOGFILE.pos if LOGFILE.pos - new_pos <= MIN_OFFSET
    return log_start_position(new_pos, seek_pos)
  end
end

# Seek to the beginning of the log entries we are interested in
LOGFILE.seek log_start_position(FILE_SIZE/2)

error_count = 0

# Work out error rates
LOGFILE.readlines.each do |ln|
  date = datetime_from_string(ln)
  if date >= FIVE_MINUTES_AGO
    error_count += 1
  end
end

# Let nagios know what the status is
if error_count > OPT[:critical].to_i
  puts "Exceptionsfor on #{HOSTNAME} for the last 5 minutes above #{OPT[:critical]} (#{error_count} exceptions)"
  exit 2
elsif error_count > OPT[:warning].to_i
  puts "Exceptions for on #{HOSTNAME} for the last 5 minutes above #{OPT[:warning]} (#{error_count} exceptions)"
  exit 1
else
  puts "Exceptions for on #{HOSTNAME} for the last 5 minutes (#{error_count} exceptions) is OK"
  exit 0
end
