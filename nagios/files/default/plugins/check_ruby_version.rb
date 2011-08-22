#!/usr/bin/env ruby
#
# Nagios check for Ruby Version.
# Copyright 37signals, 2010
# Author: John Williams (john@37signals.com)

require 'rubygems'
require 'choice'

EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3

Choice.options do
  header ''
  header 'Specific options:'

  option :required_version do
    short '-r'
    long '--required_version=VALUE'
    desc 'Required Ruby Version'
  end
end

c = Choice.choices

if c[:required_version]
  
  ruby_version = `ruby -v`
  
  unless ruby_version.include?(c[:required_version])
    puts "Ruby Version is CRITICAL: #{ruby_version}"
    exit(EXIT_CRITICAL)
  end

else
  puts "Please provide a required Ruby version."
  exit
end

puts "Ruby is OK, #{ruby_version}"