#
# Cookbook Name:: build_cookbook
# Recipe:: provision
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

kube_config = "/var/opt/delivery/workspace/.kube/config"
build_info = with_server_config { data_bag_item('nationalparks-build-info', 'latest') }

# First create a mongo deployment
ruby_block 'get-mongo-deployment-count' do
  block do
    count = MixLib::ShellOut.new("/usr/local/bin/kubectl get deployments --kubeconfig #{kube_config} -l app=mongodb,env=#{node['delivery']['change']['stage']} 2>&1 | grep -c 'No resources found'").stdout.chomp.to_i
    node.run_state["mongo_command"] = count > 0 ? 'create' : 'apply'
  end
  action :run
end

execute 'create-or-update-mongo-deployment' do
  command lazy { "/usr/local/bin/kubectl #{node.run_state["mongo_command"]} --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/mongodb-deployment.yaml" }
  action :run
end

# get mongo ip
ruby_block 'get-mongo-ip' do
  block do
    node.run_state["mongo_ip"] = Chef::ShellOut.new("/usr/local/bin/kubectl get pods --kubeconfig #{kube_config} -l app=mongodb,env=#{node['delivery']['change']['stage']} -o json | jq '.items[0].status.podIP' -r").stdout.chomp
  end
  action :run
end

# TODO: get docker tag for current build from publish phase
docker_tag = build_info['image_tag']

# lay down service/deployment templates
template "#{node['delivery']['workspace']['repo']}/nationalparks-deployment.yaml" do
  source 'nationalparks-deployment.yaml.erb'
  mode '0755'
  variables({
    :environment => node['delivery']['change']['stage'],
    :container_tag => docker_tag,
    :mongo_ip => node.run_state['mongo_ip']
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

# Deploy the app
app_deployment_count = shell_out("/usr/local/bin/kubectl get deployments --kubeconfig #{kube_config} -l app=nationalparks,env=#{node['delivery']['change']['stage']} 2>&1 | grep -c 'No resources found'").stdout.chomp.to_i
command = app_deployment_count > 0 ? 'create' : 'apply'

execute 'create-or-update-deployment' do
  command "/usr/local/bin/kubectl #{command} --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/nationalparks-deployment.yaml"
  action :run
end

app_service_count = shell_out("/usr/local/bin/kubectl get services --kubeconfig #{kube_config} -l app=nationalparks,env=#{node['delivery']['change']['stage']} 2>&1 | grep -c 'No resources found'").stdout.chomp.to_i
command = app_service_count > 0 ? 'create' : 'apply'
execute 'create-or-update-service' do
  command "/usr/local/bin/kubectl #{command} --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/nationalparks-service.yaml"
  action :run
end

#elb = shell_out("kubectl get service nationalparks-#{node['delivery']['change']['stage']} -o json | jq '.status.loadBalancer.ingress[0].hostname' -r").stdout.chomp
