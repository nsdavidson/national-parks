#
# Cookbook Name:: build_cookbook
# Recipe:: provision
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

kube_config = "/var/opt/delivery/workspace/.kube/config"
build_info = with_server_config { data_bag_item('nationalparks-build-info', 'latest') }

execute 'sleep30' do
  command 'sleep 30'
  action :nothing
end

template "#{node['delivery']['workspace']['repo']}/mongodb-deployment.yaml" do
  source 'mongodb-deployment.yaml.erb'
  mode '0755'
  variables({
    :environment => node['delivery']['change']['stage']
  })
  action :create
end

# First create a mongo deployment
ruby_block 'get-mongo-deployment-count' do
  block do
    count = Mixlib::ShellOut.new("/usr/local/bin/kubectl get deployments --kubeconfig #{kube_config} -l app=mongodb,env=#{node['delivery']['change']['stage']} 2>&1 | grep -c 'No resources found'").run_command.stdout.chomp.to_i
    node.run_state["mongo_command"] = count > 0 ? 'create' : 'apply'
  end
  action :run
end

execute 'create-or-update-mongo-deployment' do
  command lazy { "/usr/local/bin/kubectl #{node.run_state["mongo_command"]} --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/mongodb-deployment.yaml" }
  action :run
  notifies :run, 'execute[sleep30]', :immediately
end

# get mongo ip
ruby_block 'get-mongo-ip' do
  block do
    node.run_state["mongo_ip"] = Mixlib::ShellOut.new("/usr/local/bin/kubectl get pods --kubeconfig #{kube_config} -l app=mongodb,env=#{node['delivery']['change']['stage']} -o json | jq '.items[0].status.podIP' -r").run_command.stdout.chomp  
  end
  action :run
end

# TODO: get docker tag for current build from publish phase
docker_tag = build_info['image_tag']

# lay down service/deployment templates
template "#{node['delivery']['workspace']['repo']}/nationalparks-deployment.yaml" do
  source 'nationalparks-deployment.yaml.erb'
  mode '0755'
  variables(
    lazy {
      {
        :environment => node['delivery']['change']['stage'],
        :container_tag => docker_tag,
        :mongo_ip => node.run_state['mongo_ip']
      }
    }
  )
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
  notifies :run, 'execute[sleep30]', :immediately
end

#elb = shell_out("kubectl get service nationalparks-#{node['delivery']['change']['stage']} -o json | jq '.status.loadBalancer.ingress[0].hostname' -r").stdout.chomp
ruby_block 'get-elb' do
  block do
    node.run_state['elb'] = Mixlib::ShellOut.new("/usr/local/bin/kubectl --kubeconfig #{kube_config} get service nationalparks-#{node['delivery']['change']['stage']} -o json | jq '.status.loadBalancer.ingress[0].hostname' -r").run_command.stdout.chomp
  end
  action :run
end

include_recipe 'route53'
route53_record 'create-env-cname' do
  name "np-#{node['delivery']['change']['stage']}.success.chef.co"
  value lazy { node.run_state['elb'] }
  type "CNAME"
  overwrite true
  ttl 60
  zone_id 'Z1NW3SLGMJY6GJ'
end
