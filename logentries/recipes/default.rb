package "python-simplejson"

deb = "logentries_1.1.1_all.deb"
debpath = "/var/tmp/#{deb}"

remote_file "#{debpath}" do
  source "#{node[:package_url]}/#{deb}"
  not_if { File.exists?("#{debpath}")}
end

dpkg_package deb do
  source "#{debpath}"
  action :install
  only_if { File.exists?("#{debpath}")}
end

deb = "logentries-daemon_0.7.2_all.deb"
debpath = "/var/tmp/#{deb}"

remote_file "#{debpath}" do
  source "#{node[:package_url]}/#{deb}"
  not_if { File.exists?("#{debpath}")}
end

directory "/etc/le"

template "/etc/le/config" do
  not_if { File.exists?("/etc/le/config") }
end

execute "install logentries daemon" do
  command "echo 'Y' | dpkg -i #{debpath}"
  not_if "dpkg -l | grep logentries-daemon | grep ii"
end

execute "register agent" do
  command "le register"
  not_if "grep agent-key /etc/le/config"
end


if node[:logentries][:logs]
  node[:logentries][:logs].each do |name, path|
    execute "follow file #{name} at #{path}" do
      command "le follow #{path} --name #{name}"
      not_if "le whoami | grep #{name}"
    end
  end
end
