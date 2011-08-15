require_recipe "syslog-ng"

template "/etc/syslog-ng/syslog-ng.conf" do
  source "syslog-ng-client.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "syslog-ng")
end