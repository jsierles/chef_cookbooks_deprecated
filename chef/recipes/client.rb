include_recipe "logrotate"

gem_package "chef" do
  action :install
  version node[:chef][:client_version]
end

template "/etc/chef/client.rb" do
  mode 0644
  source "client.rb.erb"
  action :create
end

directory "/var/log/chef"

logrotate "chef-client" do
  rotate_count 5
  files ["/var/log/chef/*.log"]
end

execute "Register client node with chef server" do
  command "#{node[:chef][:client_path]} -t \`cat /etc/chef/validation_token\`"
  
  only_if { File.exists?("/etc/chef/validation_token") }
  not_if  { File.exists?("/var/chef/cache/registration") }
end

execute "Remove the validation token" do
  command "rm /etc/chef/validation_token"
  only_if { File.exists? "/etc/chef/validation_token" }
end

if node[:chef][:client_enable]
  runit_service "chef-client"

  service "chef-client" do
    action :enable
  end
end
