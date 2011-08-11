remote_file "/tmp/#{node[:redis][:filename]}" do
  source "#{node[:package_url]}/#{node[:redis][:filename]}"
  not_if { File.exists?("/tmp/#{node[:redis][:filename]}") }
end

dpkg_package "ruby-server" do
  source "/tmp/#{node[:redis][:filename]}"
end