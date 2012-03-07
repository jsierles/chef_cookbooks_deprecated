package "zlib1g-dev"
package "libxml2-dev"
package "sqlite3"
package "libsqlite3-dev"
package "libgecode-dev"

include_recipe "chef::rabbitmq"
include_recipe "openssl"
include_recipe "bluepill"
require_recipe "runit"
require_recipe "nginx"
require_recipe "couchdb"
require_recipe "unicorn"

package "openjdk-6-jre"

%w(chef-server chef-server-api chef-solr).each do |name|
  gem_package name do
    version node[:chef][:server_version]
  end
end

user "chef" do
  comment "Chef user"
  gid "chef"
  uid 8000
  home "/var/chef"
  shell "/bin/bash"
end

%w(/var/chef /etc/chef /var/log/chef /var/chef/openid /var/chef/ca /var/chef/cache /var/chef/pids /var/chef/sockets /var/chef/cookbooks
   /var/chef/site-cookbooks /var/chef/cookbook-tarballs /var/chef/sandboxes /var/chef/checksums).each do |dir|
  directory dir do
    owner "chef"
    mode 0775
  end
end

directory "/etc/chef/certificates" do
  owner "root"
  group "root"
  mode "700"
end

runit_service "chef-solr"
runit_service "chef-solr-indexer"

template "/etc/chef/server.rb" do
  owner "chef"
  mode 0664
  source "server.rb.erb"
  action :create
end

template "/etc/chef/client.rb" do
  owner "chef"
  mode 0664
  source "client.rb.erb"
  action :create
end
  
%w(chef-server-api chef-server-webui).each do |app|
  unicorn_conf = "/etc/chef/#{app}.unicorn.conf.rb"
  directory "/var/chef/#{app}"
  
  template unicorn_conf do
    source 'unicorn.conf.erb'
    variables :worker_count => 2,
              :socket_path =>  "/var/chef/sockets/#{app}.sock",
              :pid_path => "/var/chef/pids/#{app}.pid"
    owner "chef"
  end
  # unicorn setup
  
  bluepill_monitor app do
    cookbook 'unicorn'
    source "bluepill.conf.erb"
    env 'production'
    app_root "/var/chef"
    preload false
    interval 30
    user "chef"
    memory_limit 250 # megabytes
    cpu_limit 50 # percent
    rack_config_path "#{node[:languages][:ruby][:gems_dir]}/gems/#{app}-#{node[:chef][:server_version]}/config.ru"
    pid_path "/var/chef/pids/#{app}.pid"
    unicorn_log_path "/var/log/chef/unicorn.log"
    unicorn_config_path unicorn_conf
  end
end

template "/etc/chef/server-vhost.conf" do
  source 'chef-server-vhost.conf.erb'
  action :create
  owner "root"
  group "www-data"
  0664
  notifies :restart, resources(:service => "nginx")
end

ssl_cert "/etc/chef/certificates" do
  fqdn "chef.#{node[:domain]}"
end

# install the wildcard cert for this domain
# ssl_certificate "*.#{node[:domain]}"

nginx_site "chef-server" do
  config_path "/etc/chef/server-vhost.conf"
  action [:create, :enable]
end

cron "compact chef couchDB" do
  command "curl -X POST http://localhost:5984/chef/_compact >> /var/log/cron.log 2>&1"
  hour "5"
  minute "0"
end
