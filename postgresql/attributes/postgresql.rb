default[:postgresql][:version] = "9.0"
default[:postgresql][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"

# comma-separated, * means all
default[:postgresql][:listen_addresses] = "*"