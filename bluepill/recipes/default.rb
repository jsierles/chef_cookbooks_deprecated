gem_package "bluepill" do
  version node[:bluepill][:version]
end

directory node[:bluepill][:config_dir] do
  owner "root"
  group "root"
end

directory node[:bluepill][:log_dir] do
  owner "root"
  group "root"
end

directory node[:bluepill][:pid_dir] do
  owner "root"
  group "root"
end

template "/etc/init.d/bluepill" do
  source "init.sh.erb"
  mode 0755
end

service "bluepill" do
  action [:enable, :start]
end
