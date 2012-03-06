default.chef[:server_version] = "0.10.8"
default.chef[:server_path] = "#{languages[:ruby][:gems_dir]}/gems/chef-server-#{chef[:server_version]}"
default.chef[:server_api_path] = "#{languages[:ruby][:gems_dir]}/gems/chef-server-api-#{chef[:server_version]}"
default.chef[:server_webui_path] = "#{languages[:ruby][:gems_dir]}/gems/chef-server-webui-#{chef[:server_version]}"
