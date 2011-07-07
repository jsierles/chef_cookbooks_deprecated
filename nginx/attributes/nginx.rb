default.nginx[:architecture] = node[:kernel][:machine] == "x86_64" ? "amd64" : "i386"
default.nginx[:package_name] = "nginx"
default.nginx[:dir]     = "/etc/nginx"
default.nginx[:log_dir] = "/var/log/nginx"
default.nginx[:user]    = "www-data"
default.nginx[:group]   = "www-data"
default.nginx[:binary]  = "/usr/sbin/nginx"
default.nginx[:gzip_types] = [ "text/plain", "text/css", "application/javascript", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript" ]
default.nginx[:version] = "0.8.34-queuetime1"
default.nginx[:expires][:enabled] = true
default.nginx[:expires][:regex] = '^/(application|javascripts|stylesheets|images|sprockets|favicon)[/\.]'
default.nginx[:expires][:time] = "max"
default.nginx[:extras] = ['lb_addresses']
default.nginx[:helpers] = ['headers', 'expires', 'lb_filter', 'maintenance', 'invalid_requests', 'lb_addresses', 'ie', 'fcgi_params']
default.nginx[:log_keep_days] = 7
default.nginx[:enable_logging] = true

default.nginx[:gzip] = "on"
default.nginx[:gzip_http_version] = "1.0"
default.nginx[:gzip_comp_level] = "2"
default.nginx[:gzip_proxied] = "any"

default.nginx[:keepalive] = "on"
default.nginx[:keepalive_timeout] = 8

default.nginx[:worker_processes] = 12
default.nginx[:worker_connections] = 4096
default.nginx[:server_names_hash_bucket_size] = 128
default.nginx[:conf_dir] = nginx[:dir] + "/conf.d"

default.nginx[:open_files_limit] = 32768
default.nginx[:client_max_body_size] = "2048m"
default.nginx[:ssl_session_cache][:size] = "50m"
# backend read timeout in seconds
default.nginx[:proxy_read_timeout] = 180

# set a regex to bypass maintenance mode for a particular http host
default.nginx[:maintenance][:bypass_host_regex] = "^yourcompanysubdomain"
default.nginx[:maintenance][:bypass_ip_addresses] = ["1.2.3.4"]
