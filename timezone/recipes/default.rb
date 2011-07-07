link "/etc/localtime" do
  filename = "/usr/share/zoneinfo/#{node[:timezone]}"
  to filename
  only_if { File.exists? filename }
end