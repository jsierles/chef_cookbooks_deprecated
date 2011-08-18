default.memcached[:conf_path] = "/etc/memcached.conf"
default.memcached[:max_memory] = 256 unless memcached.has_key?(:max_memory)
default.memcached[:max_connections] = 1024 unless memcached.has_key?(:max_connections)
default.memcached[:port] = 11211 unless memcached.has_key?(:port)
default.memcached[:user] = "nobody" unless memcached.has_key?(:user)
default.memcached[:log_path] = "/var/log/memcached.log"