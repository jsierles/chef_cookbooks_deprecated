require_recipe "nginx"
require_recipe "rails::app_dependencies"
require_recipe "unicorn"
require_recipe "bluepill"
require_recipe "users"
require_recipe "bundler"

node[:active_applications].each do |name, conf|
  
  app = search(:apps, "id:#{conf[:app_name] || name}").first

  app_name = name
  app_root = "/u/apps/#{name}"
  
  full_name = "#{app_name}_#{conf[:env]}"
  filename = "#{filename}_#{conf[:env]}.conf"
  
  template "/etc/nginx/sites-available/#{full_name}" do
    source "app_nginx.conf.erb"
    variables :full_name => full_name, :app => app, :conf => conf, :app_name => app_name
    notifies :reload, resources(:service => "nginx")
  end
  
  bluepill_monitor full_name do
    source "bluepill_unicorn.conf.erb"
    app_root "#{app_root}/current"
    preload app[:preload] || true
    env conf[:env]
    interval node[:rails][:monitor_interval]
    user "app"
    group "app"
    memory_limit app[:memory_limit] || node[:rails][:memory_limit]
    cpu_limit app[:cpu_limit] || node[:rails][:cpu_limit]
  end

  nginx_site full_name

  logrotate full_name do
    files "/u/apps/#{app_name}/current/log/*.log"
    frequency "daily"
    rotate_count 14
    compress true
    restart_command "/etc/init.d/nginx reload > /dev/null"
  end

end