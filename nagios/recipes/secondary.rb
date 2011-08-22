require_recipe "nginx"
require_recipe "fcgiwrap"
require_recipe  "runit"
require_recipe "ssl_certificates"
include_recipe "users"

package "nagios3"
package "nagios-nrpe-plugin"
package 'spawn-fcgi'
package 'libclass-dbi-perl'
package 'libnet-dns-perl'

# required for Solr plugin
gem_package "xml-simple"
gem_package "choice"

gem_package "tinder"
gem_package "twilio"
gem_package "xmpp4r-simple"
gem_package "twiliolib"
gem_package "clickatell"
gem_package "activeresource"

user "nagios" do
  action :manage
  home "/u/nagios"
  shell "/bin/bash"
end

execute "copy distribution init.d script" do
  command "mv /etc/init.d/nagios3 /etc/init.d/nagios3.dist"
  creates "/etc/init.d/nagios3.dist"
end

directory "/u/nagios/.ssh" do
  mode 0700
  owner "nagios"
  group "nagios"
end

htpasswd_file "/etc/nagios3/htpasswd.users" do
  owner "nagios"
  group "www-data"
  mode 0640
end

directory "/var/lib/nagios3" do
  mode 0755
end

directory "/etc/nagios3" do
  mode 0755
  owner "nagios"
  group "nagios"
end

directory "/var/lib/nagios3/rw" do
  group "www-data"
  mode 02775
end

link "/bin/mail" do
  to "/usr/bin/mailx"
end

runit_service "nagios3"

notifiers = search(:credentials, "id:notifiers").first
sysadmin = search(:credentials, "id:sysadmin").first
sysadmin_users = search(:users, "groups:admin")
pager_duty_credentials = search(:credentials, "id:pager_duty").first

nagios_conf "nagios" do
  config_subdir false
  variables({:sysadmin => sysadmin})
end

directory "#{node[:nagios][:root]}/dist" do
  owner "nagios"
  group "nagios"
  mode 0755
end

%w(templates contacts commands).each do |dir|
  directory "#{node[:nagios][:root]}/conf.d/#{dir}" do
    owner "nagios"
    group "nagios"
    mode 0755
    
  end
end

execute "archive default nagios object definitions" do
  command "mv #{node[:nagios][:root]}/conf.d/*_nagios*.cfg #{node[:nagios][:root]}/dist"
  not_if { Dir.glob(node[:nagios][:root] + "/conf.d/*_nagios*.cfg").empty? }
end

remote_directory node[:nagios][:notifiers_dir] do
  source "notifiers"
  files_backup 5
  files_owner "nagios"
  files_group "nagios"
  files_mode 0755
  owner "nagios"
  group "nagios"
  mode 0755
end


nagios_conf "hostgroups" do
  prefix "sec"
end

nodes = search(:node, "hostname:noc-01" )

nagios_conf "hosts" do
  variables({:hosts => nodes})
  prefix "sec"
end

nagios_conf "contacts" do
  variables({:sysadmins => sysadmin_users, :notifiers => notifiers})
end

nagios_conf "service_templates" do
  prefix "sec"
end

nagios_conf "templates"

nagios_conf "commands" do
  variables({:notifiers => notifiers})
end

nagios_conf "timeperiods"

nagios_conf "cgi" do
  config_subdir false
end

nagios_conf "pagerduty_nagios" do
  variables(:credentials => pager_duty_credentials)
end

nagios_conf "services" do
  prefix "sec"
end

template "/etc/nagios3/nginx.conf" do
  source "sec_nginx.conf.erb"
end

# install the wildcard cert for this domain
ssl_certificate "*.#{node[:domain]}"

link "/usr/share/nagios3/htdocs/stylesheets" do
  to "/etc/nagios3/stylesheets"
end

nginx_site "nagios" do
  config_path "/etc/nagios3/nginx.conf"
end

bot_data = search(:credentials, "id:jabber").first

runit_service "nagios-bot" do
  options :bot_data => bot_data
end
