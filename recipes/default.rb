#
# Cookbook Name:: nginx_ssl_proxy
# Recipe:: default
#
# Copyright 2012, Coroutine LLC
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

defaults_ssl_listen = { "ssl_listen" => "443" }

# NOTE: shared secret must be in "/etc/chef/encrypted_data_bag_secret"
cert_key_pairs = node[:nginx][:cert_items].map do |cert_item|
  
  # By merging the cert data into the default_ssl_listen data,
  # we guarantee an ssl_listen value of '443' if not specified
  # in the cert data.
  cert      = defaults_ssl_listen.merge(Chef::EncryptedDataBagItem.load("nginx_ssl_certs", cert_item))
  paths     = {
    "crt_path"  => File.join(node[:nginx][:dir], node[:nginx][:ssldir], "#{cert["id"]}.crt"),
    "key_path"  => File.join(node[:nginx][:dir], node[:nginx][:ssldir], "#{cert["id"]}.key"),
  }
  
  # cert is merged into paths in the event that paths were specified
  # in the cert hash.
  paths.merge(cert)
end

# Create directory for Certs
directory "#{node[:nginx][:dir]}/#{node[:nginx][:ssldir]}" do
  mode 0755
  owner node[:nginx][:user]
  action :create
  recursive true
end

cert_key_pairs.each do |ckp|
  
  # Write the .crt file, eg: /etc/nginx/ssl/foo.crt
  template ckp["crt_path"] do
    source "ssl.erb"
    owner  "root"
    group  "root"
    mode   0600
    variables(:content => ckp["cert"].join("\n"))
  end 

  # Write the .key file, eg: /etc/nginx/ssl/foo.key
  template ckp["key_path"] do
    source "ssl.erb"
    owner  "root"
    group  "root"
    mode   0600
    variables(:content => ckp["key"].join("\n"))
  end 
end

# Write the new nginx config file
template "#{node[:nginx][:dir]}/nginx.conf" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :ssl_server_declarations => cert_key_pairs.map { |ckp| ckp.reject { |k, v| ["crt", "key"].include?(k) } }
  )
  notifies :reload, "service[nginx]"
end
