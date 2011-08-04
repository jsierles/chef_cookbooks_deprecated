gem_package "bluepill" do
  version node[:bluepill][:version]
end

[node[:bluepill][:conf_dir], node[:bluepill][:log_dir], node[:bluepill][:pid_dir]].each do |dir|
  directory dir do
    owner "root"
    group "root"
  end
end

template "/etc/init.d/bluepill" do
  source "init.sh.erb"
  mode 0755
end

service "bluepill" do
  action [:enable, :start]
end
