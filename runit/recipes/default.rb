execute "start-runsvdir" do
  command "start runsvdir"
  action :nothing
end

directory node[:runit_service_dir] do
  mode 0755
  recursive true
  action :create
end
  
package "runit" do
  action :install
  notifies :run, resources(:execute => "start-runsvdir")
end