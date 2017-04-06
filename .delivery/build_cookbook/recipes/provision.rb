#
# Cookbook Name:: build_cookbook
# Recipe:: provision
#
# Copyright (c) 2017 The Authors, All Rights Reserved.
require 'mixlib/shellout'
# get mongo ip
mongo_ip = MixLib::ShellOut.new("kubectl get pods -l app=mongodb,env=acceptance -o json | jq '.items[0].status.hostIP' -r").run_command.stdout
  # get docker tag for current build
  # lay down service/deployment templates
  # deploy updated containers to acceptance
docker_tag = 'latest'

template '/tmp/nationalparks-deployment.yaml' do
  source 'nationalparks-deployment.yaml.erb'
  mode '0755'
  variables(
    environment => node['delivery']['change']['stage'],
    container_tag => docker_tag,
    mongo_ip => mongo_ip
  )
  action :create
end

template '/tmp/nationalparks-service.yaml' do
  source 'nationalparks-service.yaml.erb'
  mode '0755'
  variables(
    environment => node['delivery']['change']['stage'],
  )
  action :create
end
  