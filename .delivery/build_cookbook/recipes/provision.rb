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

# get prism ip
ruby_block 'get-prism-ip' do
  block do
    node.run_state["prism_ip"] = Mixlib::ShellOut.new("/usr/local/bin/kubectl get pods --kubeconfig #{kube_config} -l run=prism -o json | jq '.items[0].status.podIP' -r").run_command.stdout.chomp  
  end
  action :run
end

directory "#{node['delivery']['workspace']['repo']}/k8s_files" do
  owner 'dbuild'
  group 'dbuild'
  mode '0755'
end

template "#{node['delivery']['workspace']['repo']}/k8s_files/mongodb-deployment.yaml" do
  source 'mongodb-deployment.yaml.erb'
  mode '0755'
  variables(
    lazy {
      {
        :prism_ip => node.run_state["prism_ip"],
        :environment => node['delivery']['change']['stage']
      }
    }
  )
  action :create
end

# TODO: get docker tag for current build from publish phase
docker_tag = build_info['image_tag']

# lay down service/deployment templates
template "#{node['delivery']['workspace']['repo']}/k8s_files/nationalparks-deployment.yaml" do
  source 'nationalparks-deployment.yaml.erb'
  mode '0755'
  variables(
    lazy {
      {
        :environment => node['delivery']['change']['stage'],
        :container_tag => docker_tag,
        :prism_ip => node.run_state['prism_ip']
      }
    }
  )
  action :create
end

template "#{node['delivery']['workspace']['repo']}/k8s_files/nationalparks-service.yaml" do
  source 'nationalparks-service.yaml.erb'
  mode '0755'
  variables({
    :environment => node['delivery']['change']['stage'],
  })
  action :create
end

# Deploy the app
execute 'create-or-update-deployment' do
  command "/usr/local/bin/kubectl apply -R --kubeconfig #{kube_config} -f #{node['delivery']['workspace']['repo']}/k8s_files"
  action :run
  notifies :run, 'execute[sleep30]', :immediately
end

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
