require_recipe 'apt'

if node[:packages]
  node[:packages].each do |group, packages|
    Chef::Log.debug "Installing packages for package group, #{group}"
    packages.each do |name, options|
      package name do
        options.each { |opt, arg| send(opt.to_sym, arg) }
      end
    end
  end
end
