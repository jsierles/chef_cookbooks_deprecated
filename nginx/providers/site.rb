action :create do
  if !@site.exists
    link "#{node[:nginx][:dir]}/sites-available/#{new_resource.name}.conf" do
      to new_resource.config_path
    end
  end
end
 
action :enable do
  if !@site.exists
    action :create
  end
  
  link "#{node[:nginx][:dir]}/sites-enabled/#{new_resource.name}.conf" do
    to "#{node[:nginx][:dir]}/sites-available/#{new_resource.name}.conf"
    notifies :reload, "service[nginx]"
  end
end
 
action :delete do

  action :disable

  if @site.exists
    file "#{node[:nginx][:dir]}/sites-available/#{new_resource.name}.conf" do
      action :delete
      notifies :reload, "service[nginx]"
    end  
  end
end

action :disable do
  if @site.enabled
    file "#{node[:nginx][:dir]}/sites-enabled/#{new_resource.name}.conf" do
      action :delete
      notifies :reload, "service[nginx]"
    end
  end
end

def load_current_resource
  @site = Chef::Resource::NginxSite.new(new_resource.name)
  
  Chef::Log.debug("Checking status of Nginx site #{new_resource.name}")
  @site.exists(::File.exists?("#{node.nginx.dir}/sites-available/#{new_resource.name}.conf")) 
  @site.enabled(::File.exists?("#{node.nginx.dir}/sites-enabled/#{new_resource.name}"))
end