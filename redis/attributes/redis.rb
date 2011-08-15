default.redis[:root_path] = "/u/redis"
default.redis[:port] = 6379
default.redis[:bind_address] = "0.0.0.0"
default.redis[:timeout] = 300
default.redis[:filename] = "redis-server_2.2.12-ubuntu2%7Elucid_amd64.deb"
# max memory in MB
default.redis[:max_memory] = "250"

default.redis[:data_directory] = "/var/lib/redis"
default.redis[:pid_path] = "/var/run/redis.pid"
default.redis[:log_path] = "/var/log/redis/redis-server.log"

# default to full durability persistence
default.redis[:appendonly] = true