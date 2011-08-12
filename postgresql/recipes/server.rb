include_recipe "postgresql::client"

package "postgresql-#{node[:postgresql][:version]}"
package "postgresql-server-dev-#{node[:postgresql][:version]}"

%w(postgresql-contrib libpq-dev libxslt1-dev libxml2-dev libpam0g-dev libedit-dev).each {|p| package p }

remote_file "/tmp/postgresql-repmgr-9.0_1.0.0.deb" do
  source "#{node[:package_url]}/postgresql-repmgr-9.0_1.0.0.deb"
  not_if { File.exists?("/tmp/postgresql-repmgr-9.0_1.0.0.deb") }
end

dpkg_package "postgresql-repmgr" do
  source "/tmp/postgresql-repmgr-9.0_1.0.0.deb"
  only_if { File.exists?("/tmp/postgresql-repmgr-9.0_1.0.0.deb") }
end

directory "/etc/postgresql" do
  mode 0755
  owner "postgres"
  group "postgres"
end

directory "#{node[:postgresql][:data_dir]}/wal_archive" do
  mode 0755
  owner "postgres"
  group "postgres"
end

service "postgresql" do
  service_name "postgresql"
  supports :restart => true, :status => true, :reload => true
  action :nothing
end

template "#{node[:postgresql][:config_dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0644
  notifies :reload, resources(:service => "postgresql")
end

template "#{node[:postgresql][:config_dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0644
  
  # disabled to prevent accidental restarts in production
  # notifies :restart, resources(:service => "postgresql")
end

if node[:postgresql][:role] == "slave"
  template "#{node[:postgresql][:data_dir]}/main/recovery.conf" do
    source "recovery.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    
    # disabled to prevent accidental restarts in production    
    # notifies :restart, resources(:service => "postgresql")
  end  
else
  file "#{node[:postgresql][:data_dir]}/main/recovery.conf" do
    action :delete
  end
end
