require_recipe "bluepill"

remote_file "/tmp/#{node.fcgiwrap[:version]}.deb" do
  source "#{node[:package_url]}/#{node.fcgiwrap[:version]}.deb"
  not_if { File.exists?("/tmp/#{node.fcgiwrap[:version]}.deb") }
end

dpkg_package "fcgiwrap" do
  source "/tmp/#{node.fcgiwrap[:version]}.deb"
  only_if { File.exists?("/tmp/#{node.fcgiwrap[:version]}.deb") }
end
  
service "fcgiwrap" do
  action [:enable, :start]
end