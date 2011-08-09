default[:postgresql][:version] = "9.0"
default[:postgresql][:config_dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
default[:postgresql][:datadir] = "/var/lib/postgresql/#{node[:postgresql][:version]}/main"

# comma-separated, * means all
default[:postgresql][:listen_addresses] = "*"