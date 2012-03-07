define :runit_service, :directory => nil, :only_if => false, :options => {} do
  params[:directory] ||= node[:runit_sv_dir]
  
  sv_dir_name = "#{params[:directory]}/#{params[:name]}"
  template_source = params[:template_name] || params[:name]
  
  directory sv_dir_name do
    mode 0755
    recursive true
    action :create
  end
  
  directory "#{sv_dir_name}/log" do
    mode 0755
    action :create
  end
  
  directory "#{sv_dir_name}/log/main" do
    mode 0755
    action :create
  end

  service params[:name]
  
  template "#{sv_dir_name}/run" do
    mode 0755
    cookbook(params[:cookbook]) if params[:cookbook]
    source "sv-#{template_source}-run.erb"
    variables(params[:options])
    notifies :restart, resources(:service => params[:name])
  end
  
  template "#{sv_dir_name}/log/run" do
    mode 0755
    cookbook(params[:cookbook]) if params[:cookbook]
    source "sv-#{template_source}-log-run.erb"
    variables(params[:options])
    notifies :restart, resources(:service => params[:name])
  end
  
  link "/etc/init.d/#{params[:name]}" do
    to node[:runit_sv_bin]
  end
  
  link "#{node[:runit_service_dir]}/#{params[:name]}" do 
    to "#{sv_dir_name}"
  end
  
  service params[:name] do
    supports :restart => true, :status => true
    action :nothing
  end
    
  #execute "#{params[:name]}-down" do
  #  command "/etc/init.d/#{params[:name]} down"
  #  only_if do params[:only_if] end
  #end
  
end
