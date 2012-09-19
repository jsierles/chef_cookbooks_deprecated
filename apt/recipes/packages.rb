require_recipe 'apt'

if node[:apt][:packages]
  node[:apt][:packages].each do |group, packages|
    packages.each do |name|
      package name
    end
  end
end
