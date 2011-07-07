define :bluepill_service, :enable => true, :rack_config_path => false do
  include_recipe "bluepill"
  config_path = "#{node[:bluepill][:config_dir]}/#{params[:name]}.conf.rb"

  service params[:name]

  link "/etc/init.d/#{params[:name]}" do
    to node[:bluepill][:bin]
  end
  
  service params[:name] do
    supports :restart => true, :status => true, :load => true
    action :nothing
  end
    
  template config_path do
    source params[:source] || "bluepill_#{params[:name]}.conf.erb"
    cookbook params[:cookbook]
    variables params
    notifies :load, resources(:service => params[:name])
  end
end