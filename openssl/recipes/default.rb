#
# Cookbook Name:: openssl
# Recipe:: default
#
# Copyright 2009, 37signals
#
# All rights reserved - Do Not Redistribute
#

dpkg_package "libssl0.9.8_0.9.8k-7ubuntu8.1" do
  source "/home/system/pkg/debs/openssl/libssl0.9.8_0.9.8k-7ubuntu8.1_amd64.deb"
  not_if "dpkg-query -l libssl-* | grep 0.9.8k-7ubuntu8.1"
end

dpkg_package "libssl0.9.8-dbg_0.9.8k-7ubuntu8.1" do
  source "/home/system/pkg/debs/openssl/libssl0.9.8-dbg_0.9.8k-7ubuntu8.1_amd64.deb"
  not_if "dpkg-query -l libssl-* | grep 0.9.8k-7ubuntu8.1"
end

dpkg_package "libssl-dev_0.9.8k-7ubuntu8.1" do
  source "/home/system/pkg/debs/openssl/libssl-dev_0.9.8k-7ubuntu8.1_amd64.deb"
  not_if "dpkg-query -l libssl-* | grep 0.9.8k-7ubuntu8.1"
end

dpkg_package "openssl_0.9.8k-7ubuntu8.1" do
  source "/home/system/pkg/debs/openssl/openssl_0.9.8k-7ubuntu8.1_amd64.deb"
  not_if "dpkg-query -l openssl* | grep 0.9.8k-7ubuntu8.1"
end
