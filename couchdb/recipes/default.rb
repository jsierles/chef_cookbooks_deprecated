package "couchdb" do
  version node[:couchdb][:version]
end

service "couchdb" do
  action :enable
end

template "/etc/couchdb/local.ini" do
  notifies :restart, resources(:service => "couchdb")
end

service "couchdb" do
  action :start
end
