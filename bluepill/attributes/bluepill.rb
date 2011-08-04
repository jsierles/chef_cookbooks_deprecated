default.bluepill[:bin] = languages[:ruby][:bin_dir] + "/bluepill"

default.bluepill[:logfile] = "/var/log/bluepill.log"
default.bluepill[:init_dir] = "/etc/init.d"
default.bluepill[:conf_dir] = "/etc/bluepill"
default.bluepill[:log_dir] = "/var/log/bluepill"
default.bluepill[:pid_dir] = "/var/run/bluepill"
default[:bluepill][:state_dir] = "/var/lib/bluepill"

bluepill[:version] = "0.0.51"
