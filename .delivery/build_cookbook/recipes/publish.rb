project_secrets = get_project_secrets
plan_dir = habitat_plan_dir

if habitat_origin_key?
  keyname = project_secrets['habitat']['keyname']
  origin = keyname.split('-')[0...-1].join('-')
end

hab_build node['delivery']['change']['project'] do
  origin origin
  plan_dir plan_dir
  cwd node['delivery']['workspace']['repo']
  home_dir delivery_workspace
  action :build
end

execute 'install-artifact' do
  command lazy { "sudo hab pkg install results/#{last_build_env['pkg_artifact']}" }
  cwd node['delivery']['workspace']['repo']
  action :run
end

execute 'export-container' do
  command lazy { "sudo hab pkg export docker #{last_build_env['pkg_ident']}" }
  action :run
end

docker_tag 'retag' do
  target_repo lazy { "#{last_build_env['pkg_origin']}/#{last_build_env['pkg_name']}" }
  target_tag lazy { "#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}" }
  to_repo lazy { "#{project_secrets['docker']['username']}/#{last_build_env['pkg_name']}" }
  to_tag lazy { "#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}" }
  only_if { last_build_env['pkg_origin'] != project_secrets['docker']['username'] }
  retries 5
end

docker_registry 'https://index.docker.io/v1/' do
  username project_secrets['docker']['username']
  password project_secrets['docker']['password']
  email project_secrets['docker']['email']
  action :login
end

docker_image "image-to-push" do
  repo lazy { "#{project_secrets['docker']['username']}/#{last_build_env['pkg_name']}" }
  tag lazy { "#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}" }
  action :push
end

execute 'push-image' do
  command lazy { "docker login -u #{project_secrets['docker']['username']} -p #{project_secrets['docker']['password']} && docker push #{project_secrets['docker']['username']}/#{last_build_env['pkg_name']}:#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}" }
  action :run
end

if search(:'nationalparks-build-info', 'id:latest').empty?
  databag = Chef::DataBag.new
  databag.name('nationalparks-build-info')
  databag.create
end

ruby_block 'update-build-info' do
  block do
    build_info = {
      'id' => 'latest',
      'image_tag' => "#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}"
    }
    databag_item = Chef::DataBagItem.new
    databag_item.data_bag("nationalparks-build-info")
    databag_item.raw_data = build_info
    databag_item.save
  end
  action :run
end

