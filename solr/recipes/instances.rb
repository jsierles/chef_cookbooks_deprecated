require_recipe "java"
package "tomcat6"
package "tomcat6-user"

# custom startup to use logger for syslogging stdout
cookbook_file "/usr/share/tomcat6/bin/catalina.sh" do
  source "catalina.sh"
  owner "root"
  group "root"
  mode 0755
end

service "tomcat6" do
  name "tomcat6"
  supports :restart => true, :reload => false
  action [ :disable, :stop ]
end

node[:solr][:instances].each do |app, config|

  directory node[:solr][:multi_tomcat_root] do
    recursive true
    owner "app"
    group "app"
    mode "0755"
  end

  execute "tomcat6-instance-create-#{app}" do
    command "tomcat6-instance-create -p #{config[:http_port]} -c #{config[:control_port]} #{node[:solr][:multi_tomcat_root]}/#{app}-solr"
    action :run
    not_if {File.exists?("#{node[:solr][:multi_tomcat_root]}/#{app}-solr")}
    user "app"
  end
  
  directory "#{node[:solr][:root]}/#{app}" do
    recursive true
    owner "app"
    group "app"
    mode 0755
  end

  remote_directory "#{node[:solr][:root]}/#{app}/bin" do
    source "#{node[:solr][:version]}-bin"
    owner "app"
    group "app"
    mode 0755
    files_owner "app"
    files_group "app"
    files_mode 0700
    files_backup false
  end
  
  directory "#{node[:solr][:root]}/#{app}/data" do
    owner "app"
    group "app"
    mode 0755
  end

  file = config[:war_file] || node[:solr][:war_file]
  remote_file "#{node[:solr][:root]}/#{app}/#{file}" do
    source "#{node[:package_url]}/#{file}"
    owner "app"
    group "app"
    mode 0644
  end
  
  directory "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/conf/Catalina/localhost" do
    owner "app"
    group "app"
    mode 0755
    recursive true
  end
  
  directory "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/pids" do
    owner "app"
    group "app"
    mode 0755
    recursive true
  end
  
  template "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/conf/Catalina/localhost/#{app}.xml" do
    source "context.xml.erb"
    variables(:app => app, :config => config)
    owner "app"
    group "app"
    mode 0644
    backup false
  end
  
  template "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/bin/setenv.sh" do
    source "setenv.sh.erb"
    variables(:app => app, :config => config)
    owner "app"
    group "app"
    mode 0755
    backup false
  end
  
  template "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/conf/server.xml" do
    source "server.xml.erb"
    variables(:app => app, :config => config)
    owner "app"
    group "app"
    mode 0644
    backup false
  end
  
  file "#{node[:solr][:multi_tomcat_root]}/#{app}-solr/conf/logging.properties" do
    action :delete
    only_if { File.exists?("#{node[:solr][:multi_tomcat_root]}/#{app}-solr/conf/logging.properties") }
  end
    
  template "/etc/init.d/#{app}_solr" do
    source "multi_init.erb"
    variables(:app => app, :config => config)
    owner "root"
    mode 0755
    backup false
  end
  
  service "#{app}_solr" do
    supports [ :status, :restart ]
    action [ :enable, :start ]
  end
  
end
