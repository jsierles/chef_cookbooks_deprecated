remote_file "/tmp/#{node[:ree][:filename]}" do
  source "#{node[:package_url]}/#{node[:ree][:filename]}"
  not_if { File.exists?("/tmp/#{node[:ree][:filename]}") }
end

dpkg_package "ruby-enterprise" do
  source "/tmp/#{node[:ree][:filename]}"
end

gem_package "rake" do
  options :force => true
  not_if "gem list | grep rake"
end

gem_package "rack" do
  options :force => true
  not_if "gem list | grep rack"
end

include_recipe "ruby::gc_wrapper"

