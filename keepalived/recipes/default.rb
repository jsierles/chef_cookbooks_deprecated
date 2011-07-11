package "keepalived" do
  action :install
end

service "keepalived" do
  supports :restart => true
  action [:enable, :start]
end

template node[:keepalived][:config_path] do 
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0400
  notifies :restart, resources(:service => "keepalived")
end

