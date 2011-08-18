require_recipe "memcached"

service "memcached" do
  action [:stop, :disable]
end

if node[:memcached][:instances]
  node[:memcached][:instances].each do |name, instance|
    full_name = "memcached_#{name}"
    memcached_config = { "name" => full_name,
                         "max_memory" => node[:memcached][:max_memory],
                         "port" => node[:memcached][:port], "user" => node[:memcached][:user],
                         "max_connections" => node[:memcached][:max_connections],
                         "pid_path" => "/var/run/memcached_#{name}.pid",
                         "user" => "root",
                         "group" => "root" }.merge(instance)

    template "#{node[:bluepill][:conf_dir]}/#{full_name}.pill" do
     source "bluepill.conf.erb"
     variables memcached_config
    end

    bluepill_service full_name do
     action [:enable, :load, :start]
    end
  end
end
