template "/etc/apt/sources.list" do
  source "sources.list.erb"
  owner "root"
  group "root"
  mode 0644
  variables(:sources => node[:apt][:sources])
end

template "/etc/apt/preferences" do
  source "preferences.erb"
  owner "root"
  group "root"
  mode 0644
  variables(:sources => node[:apt][:sources])
end
