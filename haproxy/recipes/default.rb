# remote_file "/tmp/haproxy_1.4.15-2~lucid.1_amd64.deb" do
#   source "#{node[:package_url]}/haproxy_1.4.15-2~lucid.1_amd64.deb"
#   not_if { File.exists?("/tmp/haproxy_1.4.15-2~lucid.1_amd64.deb") }
# end
# 
# dpkg_package "haproxy" do
#   source "/tmp/haproxy_1.4.15-2~lucid.1_amd64.deb"
#   only_if { File.exists?("/tmp/haproxy_1.4.15-2~lucid.1_amd64.deb") }
# end

include_recipe "nginx"

directory "/etc/haproxy" do
  action :create
  owner "root"
  group "root"
  mode 0755
end

directory "/var/log/haproxy" do
  action :create
  owner node[:haproxy][:user]
  group node[:haproxy][:user]
  mode 0750
end

directory "/var/run/haproxy" do
  action :create
  owner node[:haproxy][:user]
  group node[:haproxy][:user]
  mode 0750
end

template "/etc/haproxy/500.http"