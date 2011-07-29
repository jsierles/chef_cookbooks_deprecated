dpkg_package "haproxy" do
  source "/home/system/pkg/debs/haproxy_#{node[:haproxy][:version]}_amd64.deb"
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

cookbook_file "/etc/sysctl.d/20-ip-nonlocal-bind.conf" do
  source "20-ip-nonlocal-bind.conf"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/haproxy/500.http"

instances = {}

search(:apps) do |app|
  next unless app[:environments] &&
  app[:environments]['staging'] &&
  node[:active_applications].keys.include?(app['id'])
  
  instance = instances["#{app['id']}_staging"] = {}
  instance[:ssl_vhosts] = app[:environments]['staging'][:ssl_vhosts]
  instance[:domains] = app[:environments]['staging'][:domains]
  instance[:monitoring] = app[:monitoring]
  instance[:proxy_acls] = app[:proxy_acls][:staging] if app[:proxy_acls]
  instance[:proxy_backends] = app[:proxy_backends][:staging] if app[:proxy_backends]
  instance[:proxy_vip_octet] = app[:proxy_vip_octet]
  instance[:http_log] = app[:proxy_disable_log].nil? ? true : nil
  instance[:app] = app
  # TODO: support production app host. see haproxy/recipes/default.rb
  instance[:backend_hosts] = {}
  instance[:backend_hosts]["staging_01"] = "10.10.10.#{app[:proxy_vip_octet]}"
  instance[:backend_hosts]["staging_02"] = "10.10.11.#{app[:proxy_vip_octet]}"
end

instances.each do |name, config|
  
  full_name = "haproxy_#{name}"
  
  template "/etc/haproxy/#{name}.cfg" do
    source "haproxy_staging_new.cfg.erb"
    variables(:name => name, :config => config)
    owner node[:haproxy][:user]
    group node[:haproxy][:group]
    mode 0640
  end
  
  (config[:ssl_vhosts] || {}).each do |domain, vhost_vip_octet|

    vhost_name = domain.gsub(/^\*\./, '').gsub(/\./, '_')
    ssl_certificate domain
    
    vars = {:proxy_vip => "#{node[:proxy][:vip_prefix]}.#{config[:proxy_vip_octet]}",
            :vhost_vip => "#{node[:proxy][:vip_prefix]}.#{vhost_vip_octet}",
            :certificate => domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain}

    template "/etc/nginx/sites-enabled/#{name}-#{vhost_name}_ssl" do
      source "nginx-ssl.cfg.erb"
      variables vars
    end
    nginx_site "#{name}_ssl"
    
  end
  
  bluepill_monitor full_name do
    cookbook "haproxy"
    source "bluepill.conf.erb"
    user node[:haproxy][:user]
    group node[:haproxy][:group]
    variables :full_name => full_name, :short_name => name
  end

end
