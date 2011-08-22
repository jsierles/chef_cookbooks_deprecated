def nagios_boolean(true_or_false)
  true_or_false ? "1" : "0"
end

def nagios_interval(seconds)
  if seconds.to_i < @node[:nagios][:interval_length].to_i
    raise ArgumentError, "Specified nagios interval of #{seconds} seconds must be equal to or greater than the default interval length of #{@node[:nagios][:interval_length]}"
  end
  interval = seconds / @node[:nagios][:interval_length]
  interval
end

def nagios_attr(name)
  @node[:nagios][name]
end

def hostgroups_for(host)
  "servers, #{host['role']}"
end
