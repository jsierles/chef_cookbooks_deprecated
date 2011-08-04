require_recipe 'haproxy'
require_recipe "bluepill"

instances = {}

search(:apps) do |app|
  next unless app[:environments] && node[:active_applications].keys.include?(app['id'])
  
  instance = instances[app['id']] = {}
  instance[:ssl_vhosts] = app[:environments]['production'][:ssl_vhosts]
  instance[:domains] = app[:environments]['production'][:domains]
  instance[:monitoring] = app[:monitoring]
  instance[:proxy_acls] = app[:proxy_acls][:staging] if app[:proxy_acls]
  instance[:proxy_backends] = app[:proxy_backends][:staging] if app[:proxy_backends]
  instance[:proxy_vip_octet] = app[:proxy_vip_octet]
  instance[:http_log] = app[:proxy_disable_log].nil? ? true : nil
  instance[:app] = app
  instance[:backend_hosts] = {}
  search(:node, "active_applications:#{app['id']}") do |app_node|
    instance[:backend_hosts][app_node[:hostname]] = app_node[:ipaddress]
  end
end

instances.each do |name, config|
  
  full_name = "haproxy_#{name}"
  
  template "/etc/haproxy/#{name}.cfg" do
    source "haproxy.cfg.erb"
    variables(:name => name, :config => config)
    owner node[:haproxy][:user]
    group node[:haproxy][:group]
    mode 0640
  end
  
  # (config[:ssl_vhosts] || {}).each do |domain, vhost_vip_octet|
  # 
  #   vhost_name = domain.gsub(/^\*\./, '').gsub(/\./, '_')
  #   ssl_certificate domain
  #   
  #   vars = {:proxy_vip => "#{node[:proxy][:vip_prefix]}.#{config[:proxy_vip_octet]}",
  #           :vhost_vip => "#{node[:proxy][:vip_prefix]}.#{vhost_vip_octet}",
  #           :certificate => domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain}
  # 
  #   template "/etc/nginx/sites-enabled/#{name}-#{vhost_name}_ssl" do
  #     source "nginx-ssl.cfg.erb"
  #     variables vars
  #   end
  #   nginx_site "#{name}_ssl"
  #   
  # end
  
  template "#{node[:bluepill][:conf_dir]}/#{full_name}.pill" do
    source "bluepill.conf.erb"    
    variables :full_name => full_name, :short_name => name
  end
  
  bluepill_service full_name do
    action [:enable, :load, :start]
  end

end
