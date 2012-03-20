#
# Cookbook Name:: nginx_ssl_proxy
# Attributes:: default
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

# Let's be a little more conservative with these
# attributes, by default
default[:nginx][:dir]        = "/etc/nginx"
default[:nginx][:user]       = "www-data"
default[:nginx][:worker_connections] = 1024
default[:nginx][:worker_processes]   = 1
default[:nginx][:gzip] = "off"
default[:nginx][:disable_access_log] = true

# The following are new attributes defined in this cookbook.
default[:nginx][:listen]        = "80"
default[:nginx][:ssl_listen]    = "443"
default[:nginx][:ssldir]        = "ssl" # inside [:nginx][:dir]
default[:nginx][:ssl_protocols] = "SSLv3 TLSv1" # PCI compliant
default[:nginx][:ssl_ciphers]   = "ALL:!aNULL:!ADH:!eNULL:!LOW:!MEDIUM:!EXP:RC4+RSA:+HIGH"
default[:nginx][:ssl_prefer_server_ciphers] = 'on'

default[:nginx][:use_epoll]     = true
default[:nginx][:multi_accept]  = 'on' 
default[:nginx][:ssl_only]      = true # redirect all traffic from port 80 -> 443
default[:nginx][:databag_item]  = nil # id to use for an encrypted data bag
                                      # item containing the ssl cert info

# Config for upstream
default[:nginx][:upstream][:name] = "haproxy"
default[:nginx][:upstream][:servers] = []

# upstream servers should be configured via an array of hashes like the following:
# {
#   :address      => "127.0.0.1:8000",
#   :max_fails    => "3"
#   :fail_timeout => "0",
#   :weight       => "1",
#   :down         => false
# }
