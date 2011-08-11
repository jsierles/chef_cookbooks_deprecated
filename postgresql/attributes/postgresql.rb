default[:postgresql][:version] = "9.0"
default[:postgresql][:config_dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
default[:postgresql][:data_dir] = "/var/lib/postgresql/#{node[:postgresql][:version]}"
default[:postgresql][:archive_dir] = "#{node[:postgresql][:data_dir]}/wal_archive"

# comma-separated, * means all
default[:postgresql][:listen_addresses] = "*"