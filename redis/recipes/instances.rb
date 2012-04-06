require_recipe "redis"

if node[:redis][:instances]  
  node[:redis][:instances].each do |name, config|  

    default_config = {
      "name" => "#{config[:prefix]}redis_#{name}",
      "log_path" => "#{node[:redis][:root_path]}/#{name}/redis.log",
      "pid_path" => "#{node[:redis][:root_path]}/#{name}/redis.pid",
      "data_directory" => "#{node[:redis][:root_path]}/#{name}/data",
      "config_path" => "#{node[:redis][:root_path]}/#{name}/redis.conf",
      "root" => "#{node[:redis][:root_path]}/#{name}",
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

    template "#{node[:bluepill][:conf_dir]}/#{merged_config["name"]}.pill" do
      mode 0644
      source "bluepill.conf.erb"
      variables merged_config
    end
    
    bluepill_service merged_config["name"] do
      action [:enable, :load, :start]
    end
  end
end