require_recipe 'haproxy'
require_recipe "bluepill"

if node[:haproxy][:instances]
  node[:haproxy][:instances].each do |name, config|
    
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
end