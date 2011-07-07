define :bluepill_monitor, :enable => true, :rack_config_path => false do
  include_recipe "bluepill"
  config_path = "#{node[:bluepill][:config_dir]}/#{params[:name]}.conf.rb"

  execute "load-bluepill-#{params[:name]}" do
    command "bluepill load #{node[:bluepill][:config_dir]}/#{params[:name]}.conf.rb"
    action :nothing
  end
  
  execute "restart-bluepill-#{params[:name]}" do
    command "bluepill restart #{params[:name]}"
    action :nothing
  end
  
  template config_path do
    source params[:source] || "bluepill_#{params[:name]}.conf.erb"
    cookbook params[:cookbook]
    variables params[:variables] || params
    notifies :run, resources("execute[load-bluepill-#{params[:name]}]")
  end
end