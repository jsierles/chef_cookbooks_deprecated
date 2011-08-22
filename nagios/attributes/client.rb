default.nagios[:plugins_dir] = "/u/nagios/plugins"

# load average check: 5, 10 and 15 minute averages
default.nagios[:checks][:load][:enable] = true
default.nagios[:checks][:load][:warning] = "15,10,7"
default.nagios[:checks][:load][:critical] = "30,20,10"

# free memory
default.nagios[:checks][:free_memory][:enable] = true
default.nagios[:checks][:free_memory][:warning] = 250
default.nagios[:checks][:free_memory][:critical] = 150

# free disk space percentage
default.nagios[:checks][:free_disk][:enable] = true
default.nagios[:checks][:free_disk][:warning] = "8"
default.nagios[:checks][:free_disk][:critical] = "5"

# HAProxy
default.nagios[:checks][:haproxy_queue][:enable] = true
default.nagios[:checks][:haproxy_queue][:critical] = "10"
default.nagios[:checks][:haproxy_queue][:warning] = "1"

# HTTP error rates
default.nagios[:checks][:http_error_rate][:enable] = true
default.nagios[:checks][:http_error_rate][:critical] = "20"
default.nagios[:checks][:http_error_rate][:warning] = "15"

# Exceptions error rates
default.nagios[:checks][:exceptions_log_error_rate][:enable] = true
default.nagios[:checks][:exceptions_log_error_rate][:critical] = "30"
default.nagios[:checks][:exceptions_log_error_rate][:warning] = "10"
