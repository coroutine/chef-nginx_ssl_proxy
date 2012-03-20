#
# Cookbook Name:: nginx_ssl_proxy
# Recipe:: default
#
# Copyright 2021, Coroutine LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "nginx::default"

# Pull SSL info from an encrypted data bag item
#
# cert = {
#   :id   => 'foo'
#   :cert => ['...', '...', ] # content for .crt
#   :key  => ['...', '...', ] # content for .key
# }

# NOTE: shared secret must be in "/etc/chef/encrypted_data_bag_secret"
cert = Chef::EncryptedDataBagItem.load("nginx_ssl_certs", node[:nginx][:databag_item])
cert_crt_path = "#{node[:nginx][:dir]}/#{node[:nginx][:ssldir]}/#{cert["id"]}.crt"
cert_key_path = "#{node[:nginx][:dir]}/#{node[:nginx][:ssldir]}/#{cert["id"]}.key"

Chef::Log.info("cert_crt_path = #{cert_crt_path}")
Chef::Log.info("cert_key_path = #{cert_key_path}")
Chef::Log.info("cert.id = #{cert["id"]}\n\n")
Chef::Log.info("cert.cert\n\n #{cert["cert"]}\n\n")
Chef::Log.info("cert.key\n\n #{cert["key"]}\n\n")

# Create directory for Certs
directory "#{node[:nginx][:dir]}/#{node[:nginx][:ssldir]}" do
  mode 0755
  owner node[:nginx][:user]
  action :create
  recursive true
end

# Write the .crt file, eg: /etc/nginx/ssl/foo.crt
template cert_crt_path do
  source "ssl.erb"
  owner  "root"
  group  "root"
  mode   0600
  variables(:content => cert["cert"].join("\n"))
end 

# Write the .key file, eg: /etc/nginx/ssl/foo.key
template cert_key_path do
  source "ssl.erb"
  owner  "root"
  group  "root"
  mode   0600
  variables(:content => cert["key"].join("\n"))
end 

# Write the new nginx config file
template "#{node[:nginx][:dir]}/nginx.conf" do
  #path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :cert_name => cert[:id],
    :crt_path  => cert_crt_path,
    :key_path  => cert_key_path
  )
  notifies :reload, "service[nginx]"
end
