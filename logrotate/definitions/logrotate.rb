define :logrotate, :frequency => "daily", :rotate_count => 5, :rotate_if_empty => false, :missing_ok => true, :compress => true, :enable => true  do
  template "/etc/logrotate.d/#{params[:name]}" do
    action :delete unless params[:enable]
    cookbook "logrotate"
    source "logrotate.conf.erb"
    variables(:p => params)
    backup 0
  end
end
