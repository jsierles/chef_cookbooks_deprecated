define :nginx_site, :enable => true do
  include_recipe "nginx"

  if params[:config_path]
    link "#{node[:nginx][:dir]}/sites-available/#{params[:name]}" do
      to params[:config_path]
      only_if { File.exists?(params[:config_path]) }
    end
  end

  if params[:enable]
    execute "nxensite #{params[:name]}" do
      command "/usr/sbin/nxensite #{params[:name]}"
      notifies :reload, resources(:service => "nginx")
      only_if { File.exists?("#{node[:nginx][:dir]}/sites-available/#{params[:name]}") }
      not_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{params[:name]}") end
    end
  else
    execute "nxdissite #{params[:name]}" do
      command "/usr/sbin/nxdissite #{params[:name]}"
      notifies :reload, resources(:service => "nginx")
      only_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{params[:name]}") end
    end
  end
end
