package "python-simplejson"

apt_repository "logentries" do
  uri "http://rep.logentries.com"
  distribution "squeeze"
  components ["main"]
  keyserver "pgp.mit.edu"
  key "C43C79AD"
  action :add
  notifies :run, "execute[apt-get update]", :immediately
end

directory "/etc/le"

template "/etc/le/config" do
  not_if { File.exists?("/etc/le/config") }
end

package "logentries-daemon" do
  action :install
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
