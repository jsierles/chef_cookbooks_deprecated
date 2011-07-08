require_recipe 'apt'

execute "launchpad-update" do
  command "/usr/local/bin/launchpad-update"
  action :nothing
end

template "/etc/apt/sources.list.d/ppas.list" do
  notifies :run, "execute[launchpad-update]", :immediately
  notifies :run, "execute[apt-get-update]"
end