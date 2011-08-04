require_recipe "nginx"

node[:nginx][:proxy_frontends] = {}

search(:apps) do |app|
  next unless app[:environments] &&
  app[:environments]['staging'] &&
  app[:environments]['staging'][:ssl_vhosts] &&
  node[:active_applications].keys.include?(app['id'])

  app[:environments]['staging'][:ssl_vhosts].each do |domain, vhost_vip_octet|
    ssl_certificate domain
    node[:nginx][:proxy_frontends][domain] = {
      :certificate => domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
    }
  end
end

template "/etc/nginx/sites-available/proxy_frontend" do
  source "proxy_frontend.conf.erb"
end

nginx_site "proxy_frontend"
