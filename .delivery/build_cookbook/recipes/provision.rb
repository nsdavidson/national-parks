#
# Cookbook Name:: build_cookbook
# Recipe:: provision
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

  # get mongo ip
  # get docker tag for current build
  # lay down service/deployment templates
  # deploy updated containers to acceptance

  template '/somewhere/nationalparks-deployment.yaml' do
    source 'nationalparks-deployment.yaml.erb'
    mode '0755'
    variables(
      environment => environment,
      container_tag => tag,
      mongo_ip => mongo_ip
    )
    action :create
  end

  template '/somewhere/nationalparks-service.yaml' do
    source 'nationalparks-service.yaml.erb'
    mode '0755'
    variables(
      environment => environment,
    )
    action :create
  end
  