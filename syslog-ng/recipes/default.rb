package "syslog-ng" do
  action :install
end

service "syslog-ng" do
  supports :restart => true, :reload => true
  action [:enable, :start]
end