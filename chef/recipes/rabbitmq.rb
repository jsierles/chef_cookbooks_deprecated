require_recipe "rabbitmq"

execute "rabbitmqctl add_vhost /chef" do
  not_if "rabbitmqctl list_vhosts| grep /chef"
end

# create chef user
execute "rabbitmqctl add_user chef testing" do
  not_if "rabbitmqctl list_users |grep chef"
end

# grant the mapper user the ability to do anything with the /nanite vhost
# the three regex's map to config, write, read permissions respectively
execute 'rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"' do
  not_if 'rabbitmqctl list_user_permissions mapper|grep /nanite'
end