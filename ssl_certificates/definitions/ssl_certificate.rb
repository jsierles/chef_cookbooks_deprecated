define :ssl_certificate do

  directory node[:ssl_certificates][:path] do
    mode 0755
  end
  
  name = params[:name] =~ /\*\.(.+)/ ? "#{$1}_wildcard" : params[:name]

  # gsub is required since databags can't contain dashes
  cert = Chef::EncryptedDataBagItem.load(:certificates, name.gsub(".", "_"))
  
  template "#{node[:ssl_certificates][:path]}/#{name}.crt" do
    source "cert.erb"
    mode "0640"
    cookbook "ssl_certificates"
    owner "root"
    group "www-data"
    variables :cert => cert["cert"]
  end

  template "#{node[:ssl_certificates][:path]}/#{name}.key" do
    source "cert.erb"
    mode "0640"
    cookbook "ssl_certificates"
    owner "root"
    group "www-data"
    variables :cert => cert["key"]
  end

  template "#{node[:ssl_certificates][:path]}/#{name}_combined.crt" do
    source "cert.erb"
    mode "0640"
    cookbook "ssl_certificates"
    owner "root"
    group "www-data"
    extra = cert["intermediate"] || ""
    variables :cert => cert["cert"], :extra => extra
  end

  if cert["intermediate"]
    template "#{node[:ssl_certificates][:path]}/#{name}_intermediate.crt" do
      source "cert.erb"
      mode "0640"
      cookbook "ssl_certificates"
      owner "root"
      group "www-data"
      variables :cert => cert["intermediate"]
    end
  end
end
