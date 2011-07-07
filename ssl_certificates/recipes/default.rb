directory node[:ssl_certificates][:path] do
  mode "0750"
  owner "root"
  group "www-data"
end