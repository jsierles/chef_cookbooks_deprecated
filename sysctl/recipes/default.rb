service "procps"

if node[:sysctl][:settings]
  template "/etc/sysctl.d/60-custom-settings.conf" do
    source "60-custom-settings.conf.erb"
    notifies :restart, resources(:service => "procps")
  end
end