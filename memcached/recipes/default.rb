package "memcached"

directory "/etc/memcached"

cookbook_file "/usr/local/bin/memcache-top" do
  mode 0755
end
