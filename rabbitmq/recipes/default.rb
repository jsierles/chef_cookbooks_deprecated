package "rabbitmq-server"

service "rabbitmq-server" do
  supports [ :restart, :status ]
  action [ :enable, :start ]
end
