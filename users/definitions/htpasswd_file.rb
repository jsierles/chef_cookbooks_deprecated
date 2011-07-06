define :htpasswd_file, :groups => [:git], :owner => "root", :group => "www-data" do
  template params[:name] do
    cookbook "users"
    source "htpasswd.erb"
    users = search(:users, params[:groups].collect {|gr| "groups:#{gr.to_s}" }.join)
    variables(:users => users)
    mode 0640
    owner params[:owner]
    group params[:group]
  end
end