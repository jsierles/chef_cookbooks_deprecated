package "postgresql-#{node[:postgresql][:version]}"
package "libpq-dev"
package "postgresql-server-dev-#{node[:postgresql][:version]}"

include_recipe "postgresql::client"

directory "/etc/postgresql" do
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
  template "#{node[:postgresql][:datadir]}/recovery.conf" do
    source "recovery.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    
    # disabled to prevent accidental restarts in production    
    # notifies :restart, resources(:service => "postgresql")
  end  
else
  file "#{node[:postgresql][:datadir]}/recovery.conf" do
    action :delete
  end
end
