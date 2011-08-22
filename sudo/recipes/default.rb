require_recipe 'users'

package "sudo" do
  action :upgrade
end

template "/etc/sudoers" do
  source "sudoers.erb"
  mode 0440
  owner "root"
  group "root"
  sudogroups = 
  variables(:sudoers_groups => node[:active_sudo_groups], :sudoers_users => node[:active_sudo_users])
end