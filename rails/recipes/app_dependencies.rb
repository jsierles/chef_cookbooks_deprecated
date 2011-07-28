require_recipe "users"

["/u", "/u/apps"].each do |dir|
  directory dir do
    owner "app"
    group "app"
    mode 0755
  end
end

if node[:active_applications]
  
  node[:active_applications].each do |name, conf|

    app = search(:apps, "id:#{conf[:app_name] || name}").first
    app_name = name
    app_root = "/u/apps/#{app_name}"

    %w(config tmp sockets log tmp/pids system bin).each do |dir|
      directory "/u/apps/#{app_name}/shared/#{dir}" do
        recursive true
        owner "app"
        group "app"
      end
    end
            
    if app

      if app[:packages]
        app[:packages].each do |package_name|
          package package_name
        end      
      end

      if app[:gems]
        app[:gems].each do |g|
          if g.is_a? Array
            gem_package g.first do
              version g.last
            end
          else
            gem_package g
          end
        end
      end
    
      if app[:symlinks]
        app[:symlinks].each do |target, source|
          link target do
            to source
          end
        end
      end
    end              
  end
else
  Chef::Log.info "Add an :active_applications attribute to configure this node's Rails apps"
end