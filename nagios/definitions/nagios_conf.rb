define :nagios_conf, :variables => {}, :config_subdir => true, :prefix => nil do
    
  subdir = if params[:config_subdir]
    "/#{node[:nagios][:config_subdir]}/"
  else
    "/"
  end
  
  template "#{node[:nagios][:root]}#{subdir}#{params[:name]}.cfg" do
    owner "nagios"
    group "nagios"
    if params[:prefix]
      source "#{params[:prefix]}_#{params[:name]}.cfg.erb"
    else
      source "#{params[:name]}.cfg.erb"
    end
    mode 0644
    variables params[:variables]
    notifies :restart, resources(:service => "nagios3")
    backup 0
  end
end
