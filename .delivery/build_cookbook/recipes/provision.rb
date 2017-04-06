#
# Cookbook Name:: build_cookbook
# Recipe:: provision
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

kube_config = "/var/opt/delivery/workspace/.kube/config"
build_info = data_bag_item('nationalparks-build-info')
# get mongo ip
mongo_ip = shell_out!("/usr/local/bin/kubectl get pods --kubeconfig #{kube_config} -l app=mongodb,env=#{node['delivery']['change']['stage']} -o json | jq '.items[0].status.podIP' -r").stdout.chomp

# TODO: get docker tag for current build from publish phase
docker_tag = build_info[:image_tag]

# lay down service/deployment templates
template "#{node['delivery']['workspace']['repo']}/nationalparks-deployment.yaml" do
  source 'nationalparks-deployment.yaml.erb'
  mode '0755'
  variables({
    :environment => node['delivery']['change']['stage'],
    :container_tag => docker_tag,
    :mongo_ip => mongo_ip
  })
  action :create
end

template "#{node['delivery']['workspace']['repo']}/nationalparks-service.yaml" do
  source 'nationalparks-service.yaml.erb'
  mode '0755'
  variables({
    :environment => node['delivery']['change']['stage'],
  })
  action :create
end

# deploy updated containers to acceptance
execute 'update-deployment' do
  command "/usr/local/bin/kubectl apply --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/nationalparks-deployment.yaml"
  action :run
end

execute 'update-service' do
  command "/usr/local/bin/kubectl apply --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/nationalparks-service.yaml"
  action :run
end
