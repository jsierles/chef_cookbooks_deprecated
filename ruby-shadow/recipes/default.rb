remote_directory "/usr/local/src/shadow-2.3.14" do
  source 'shadow-2.3.14'
  not_if { File.exists?("#{node[:languages][:ruby][:bin_dir].gsub(/bin$/, "lib/ruby/site_ruby/1.9.1/")}#{node[:languages][:ruby][:platform]}/shadow.so") }
end

bash "install ruby shadow library" do
  user "root"
  cwd "/usr/local/src"
  code <<-EOH
  cd shadow-2.3.14
  ruby extconf.rb
  make install
  EOH
  not_if { File.exists?("#{node[:languages][:ruby][:bin_dir].gsub(/bin$/, "lib/ruby/site_ruby/1.9.1/")}#{node[:languages][:ruby][:platform]}/shadow.so") }
end