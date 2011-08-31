require_recipe 'bluepill'

# TODO: install nodejs, using chris-lea/node.js ppa
# TODO: install npm

directory "/u/juggernaut/keys" do
  mode 0755
  recursive true
end

if node.juggernaut.ssl
  ssl_name = node.juggernaut.ssl.domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
  ssl_certificate node.juggernaut.ssl.domain
  
  link "/u/juggernaut/keys/certificate.pem" do
    to "/etc/ssl_certs/#{ssl_name}.crt"
  end
  link "/u/juggernaut/keys/privatekey.pem" do
    to "/etc/ssl_certs/#{ssl_name}.key"
  end
end

template "#{node[:bluepill][:conf_dir]}/juggernaut.pill" do
  source "bluepill.conf.erb"    
end

bluepill_service 'juggernaut' do
  action [:enable, :load, :start]
end