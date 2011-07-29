remote_file "/tmp/#{node[:ree][:filename]}" do
  source "#{node[:ree][:base_url]}/#{node[:ree][:filename]}"
  not_if { File.exists?("/tmp/#{node[:ree][:filename]}") }
end

dpkg_package "ruby-enterprise" do
  source "/tmp/#{node[:ree][:filename]}"
end

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

instances = {}

search(:apps) do |app|
  next unless app[:environments] && node[:active_applications][app['id']]
  app[:environments].keys.each do |env|
    next unless node[:active_applications][app['id'].to_s]['env'] == env
    app_nodes = []

    search(:node, "roles:#{app['id']}-app OR (roles:staging AND active_applications:#{app['id']})") do |app_node|
      next if app_node[:hostname].match(/cron|^bc-intl|^hr-beta/) # super hacky
      app_nodes << [app_node[:hostname], app_node[:ipaddress]] if app_node[:active_applications][app['id']][:env] == env
    end

    instances["#{app['id']}_#{env}"] = {
      :admin_subdomains => app[:admin_subdomains],
      :use_stunnel_ssl => app[:use_stunnel_ssl],
      :ssl_vhosts => app[:environments][env.to_s][:ssl_vhosts],
      :maxconn => app[:environments][env.to_s]["worker_count"],
      :http_log => app[:proxy_disable_log].nil? ? true : nil,
      :proxy_vip_octet => app[:proxy_vip_octet],
      :proxy_acls => app[:proxy_acls].nil? ? [] : app[:proxy_acls][env.to_s],
      :monitoring => app[:monitoring],
      :proxy_backends => app[:proxy_backends].nil? ? [] : app[:proxy_backends][env.to_s],
      :frontends => {
        "#{app['id']}_#{env}" => {
          :backends => {
            "app_hosts" => {
              :servers => app_nodes
            }
          }
        }
      }
    }
    
  end
end

instances.each do |name, config|
  template "/etc/init.d/haproxy_#{name}" do
    source "haproxy.init.erb"
    variables(:name => name)
    owner "root"
    group "root"
    mode 0755
  end
  
  service "haproxy_#{name}" do
    action [ :disable ]    
  end

  template "/etc/init/haproxy_#{name}.conf" do
    source "haproxy.upstart.erb"
    variables(:name => name)
    owner "root"
    group "root"
    mode 0644
  end
  
  service "haproxy_#{name}" do
    pattern "haproxy.*#{name}"
    provider Chef::Provider::Service::Upstart
    supports [ :start, :stop, :restart, :reload ]
    action [ :enable ]
  end

  template "/etc/haproxy/#{name}.cfg" do
    source "haproxy.cfg.erb"
    variables(:name => name, :config => config)
    owner node[:haproxy][:user]
    group node[:haproxy][:group]
    mode 0640
    # disable restarts in case the chef index messes up the configs
    #notifies :restart, resources(:service => "haproxy_#{name}")
  end
  
  unless config[:use_stunnel_ssl]
    (config[:ssl_vhosts] || {}).each do |domain, vhost_vip_octet|
      vhost_name = domain.gsub(/^\*\./, '').gsub(/\./, '_')
      ssl_certificate domain
    
      template "/etc/nginx/sites-enabled/#{name}-#{vhost_name}_ssl" do
        source "nginx-ssl.cfg.erb"
        variables(
          :proxy_vip => "#{node[:proxy][:vip_prefix]}.#{config[:proxy_vip_octet]}",
          :vhost_vip => "#{node[:proxy][:vip_prefix]}.#{vhost_vip_octet}",
          :certificate => domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
        )
      end

      nginx_site "#{name}_ssl"
    end
  end
end
