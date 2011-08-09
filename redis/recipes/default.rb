remote_file "/tmp/#{node[:redis][:filename]}" do
  source "#{node[:package_url]}/#{node[:redis][:filename]}"
  not_if { File.exists?("/tmp/#{node[:redis][:filename]}") }
end

dpkg_package "ruby-server" do
  source "/tmp/#{node[:redis][:filename]}"
end

if node[:redis][:instances]
  
  node[:redis][:instances].each do |name, config|  

    default_config = {
      "name" => "redis_#{name}",
      "log_path" => "/u/redis/#{name}/redis.log",
      "pid_path" => "/u/redis/#{name}/redis.pid",
      "data_directory" => "/u/redis/#{name}/data",
      "config_path" => "/u/redis/#{name}/redis.conf",
      "root" => "/u/redis/#{name}",
      "owner" => "redis",
      "group" => "redis"
    }
    
    merged_config = node[:redis].to_hash.merge(default_config).merge(config)

    directory merged_config["root"] do
      owner merged_config["owner"]
      group merged_config["group"]
      mode 0750
      recursive true
    end
    
    directory merged_config["data_directory"] do
      owner merged_config["owner"]
      group merged_config["group"]
      mode 0750
      recursive true
    end
    
    template merged_config["config_path"] do
      owner merged_config["owner"]
      group merged_config["group"]
      variables merged_config
      mode 0644      
    end

    bluepill_monitor merged_config["name"] do
      source "bluepill.conf.erb"
      variables merged_config
    end
    
  end
  
else
  service "redis-server" do
    action :enable
  end

  template "/etc/redis/redis.conf" do
    mode 0644
    variables node[:redis]
  end

  service "redis-server" do
    action :start
  end
end