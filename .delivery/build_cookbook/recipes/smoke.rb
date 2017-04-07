#
# Cookbook Name:: build_cookbook
# Recipe:: smoke
#
# Copyright (c) 2017 The Authors, All Rights Reserved.
#

host_endpoint = "http://np-#{node['delivery']['change']['stage']}.success.chef.co/national-parks/"
attributes_file = "smoke-attributes-#{node['delivery']['change']['stage']}.yaml"
smoke_spec = ".delivery/build_cookbook/test/smoke/default/smoke.rb"

template "#{node['delivery']['workspace']['repo']}/#{attributes_file}" do
  source 'smoke-attributes.yaml.erb'
  mode '0755'
  variables({
    :endpoint => host_endpoint
  })
  action :create
end

chef_gem "inspec" do
  action :upgrade
end

execute "run smoke tests on #{host_endpoint}" do
  command "inspec exec #{smoke_spec} --attrs #{node['delivery']['workspace']['repo']}/#{attributes_file}"
  cwd node['delivery']['workspace']['repo']
  action :run
end
