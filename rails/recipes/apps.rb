require_recipe "nginx"
require_recipe "rails::app_dependencies"
require_recipe "unicorn"
require_recipe "bluepill"
require_recipe "users"
require_recipe "bundler"

if node[:active_applications]
  
  directory "/etc/nginx/sites-include" do
    mode 0755
  end
  
  node[:active_applications].each do |name, conf|
  
    app = search(:apps, "id:#{conf[:app_name] || name}").first

    app_name = name
    app_root = "/u/apps/#{name}"
  
    full_name = "#{app_name}_#{conf[:env]}"
    filename = "#{filename}_#{conf[:env]}.conf"

    domain = app["environments"][conf["env"]]["domain"]

    ssl_name = domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
    
    ssl_certificate ssl_name

    template "/etc/nginx/sites-include/#{full_name}" do
      source "app_nginx_include.conf.erb"
      variables :full_name => full_name, :conf => conf, :app_name => app_name
      notifies :reload, resources(:service => "nginx")
    end
              
    template "/etc/nginx/sites-available/#{full_name}.conf" do
      source "app_nginx.conf.erb"
      variables :full_name => full_name, :conf => conf, :app_name => app_name, 
                :domain => domain, :ssl_name => ssl_name, :app => app
      notifies :reload, resources(:service => "nginx")
    end

    common_variables = {
      :preload => app[:preload] || true,
      :app_root => app_root,
      :full_name => full_name,
      :app_name => app_name,
      :env => conf[:env],
      :user => "app",
      :group => "app",
      :listen_port => app[:listen_port] || 8600
    }

    template "#{node[:unicorn][:config_path]}/#{full_name}" do
      mode 0644
      cookbook "unicorn"
      source "unicorn.conf.erb"
      variables common_variables
    end

    template "#{node[:bluepill][:conf_dir]}/#{full_name}.pill" do
      mode 0644
      source "bluepill_unicorn.conf.erb"
      variables common_variables.merge(
        :interval => node[:rails][:monitor_interval],
        :memory_limit => app[:memory_limit] || node[:rails][:memory_limit],
        :cpu_limit => app[:cpu_limit] || node[:rails][:cpu_limit])
    end
    
    bluepill_service full_name do
      action [:enable, :load, :start]
    end
    
    nginx_site full_name do
      action :enable
    end
    
    logrotate full_name do
      files ["/u/apps/#{app_name}/current/log/*.log"]
      frequency "daily"
      rotate_count 14
      compress true
      restart_command "/etc/init.d/nginx reload > /dev/null"
    end
  end
end