#!/usr/bin/env ruby

require 'socket'

host,port = ARGV[0], ARGV[1]

begin
  info = {}
  sock = TCPSocket.open(host, port)
  sock.puts("INFO")
  
  while ((data = sock.gets) !~ /^\s*$/)
    (key, value) = data.chomp.split(':')
    value = value.to_i if value =~ /^\d+$/
    info[key] = value
  end

  puts "Redis server at #{host}:#{port} OK: #{info.inspect}"
  exit 0
rescue Errno::ECONNREFUSED
  puts "Redis server at #{host}:#{port} is unreachable."
  exit 2
end
