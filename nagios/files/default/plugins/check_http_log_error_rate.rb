#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'date'

OPT = {}
OptionParser.new do |opts|
  opts.on("-l", "--logfile FILENAME", "Log filename") {|logfile| OPT[:logfile] = logfile }
  opts.on("-w", "--critical WARNING", "Warning threshold (%)") { |warning| OPT[:warning] = warning.to_i }
  opts.on("-c", "--critical CRITICAL", "Critical threshold (%)") { |critical| OPT[:critical] = critical.to_i }
  opts.on("-a", "--app APPNAME", "Application name") { |app| OPT[:app] = app }
  opts.parse!(ARGV)
end

now = Time.now; past = Time.now - 300

DEBUG = false
NOW = DateTime.civil(now.year, now.month, now.day, now.hour, now.min, now.sec)
FIVE_MINUTES_AGO = DateTime.civil(past.year, past.month, past.day, past.hour, past.min, past.sec)
FILE_SIZE = File.size(OPT[:logfile])
LOGFILE = File.open OPT[:logfile]
MIN_OFFSET = 500 # How many bytes difference until we stop bothering to do a binary search

def datetime_from_string(date_string)
  DateTime.strptime(date_string, "%d/%b/%Y:%H:%M:%S")
end

def debug(message)
  DEBUG and puts message
end

def log_start_position(seek_pos, old_pos = 0)
  # Don't try and seek past the beginning or end of the file
  return FILE_SIZE if seek_pos >= FILE_SIZE
  return 0 if seek_pos <= 0
  
  debug "Seeking to #{seek_pos} (#{(seek_pos/FILE_SIZE.to_f) * 100}%), offset is #{seek_pos - old_pos}"
  
  LOGFILE.seek(seek_pos)
  
  # discard the first line, it could be incomplete
  LOGFILE.readline
  ln = LOGFILE.readline
  # Dec 20 21:30:34 proxy-01 haproxy[25225]: 10.10.1.6:33020 [20/Dec/2010:21:30:33.215] basecamp_production app_hosts/bc_02 0/0/0/1467/1467 200 7194 - - ---- 77/77/70/7/0 0/0 {204.128.192.4|heavenspotdesign.basecamphq.com} "GET /projects/5820242/log HTTP/1.0"
  raw_date = ln.match(/\[(\d\d\/\w{3}\/\d{4}:\d\d:\d\d:\d\d)\.\d*\]/)[1]
  date = datetime_from_string(raw_date)
  
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

status_counts = {}
error_count = 0
non_error_count = 0
total_requests = 0

# Generate status code statistics
LOGFILE.readlines.each do |ln|
  begin
    # Dec 20 21:30:34 proxy-01 haproxy[25225]: 10.10.1.6:33020 [20/Dec/2010:21:30:33.215] basecamp_production app_hosts/bc_02 0/0/0/1467/1467 200 7194 - - ---- 77/77/70/7/0 0/0 {204.128.192.4|heavenspotdesign.basecamphq.com} "GET /projects/5820242/log HTTP/1.0"
    raw_date, status = ln.match(/\[(\d\d\/\w{3}\/\d{4}:\d\d:\d\d:\d\d)\.\d*\] \w+ [\w\/<>]* -?\d+\/-?\d+\/-?\d+\/-?\d+\/\d+ (\d+)/)[1,2]
    
    date = datetime_from_string(raw_date)
    if date > FIVE_MINUTES_AGO
      status = status.to_i
      status_counts[status] ||= 0
      status_counts[status] += 1
      if status < 400
        non_error_count += 1
      else
        error_count += 1
      end
      total_requests += 1
    end
  rescue NoMethodError
    
  end
end

def error_statuses(statuses, total_requests)
  statuses.select{|code, count| code.to_i >= 400 }.map {|code, count|
    "#{code}: #{sprintf("%.1f", (count / total_requests.to_f) * 100)}%"
  }.join(", ")
end

def human_error_percentage(long_float)
  sprintf("%.1f", long_float)
end

error_percentage = (error_count / total_requests.to_f) * 100

# Let nagios know what the status is
if error_percentage > OPT[:critical]
  puts "HTTP error rate for #{OPT[:app]} of #{human_error_percentage(error_percentage)}% over #{total_requests} requests is above #{OPT[:critical]}% [#{error_statuses(status_counts, total_requests)}]"
  exit 2
elsif error_percentage > OPT[:warning]
  puts "HTTP error rate for #{OPT[:app]} of #{human_error_percentage(error_percentage)}% over #{total_requests} requests is above #{OPT[:warning]}% [#{error_statuses(status_counts, total_requests)}]"
  exit 1
else
  puts "HTTP error rate for #{OPT[:app]} of #{human_error_percentage(error_percentage)}% over #{total_requests} requests is OK"
  exit 0
end
