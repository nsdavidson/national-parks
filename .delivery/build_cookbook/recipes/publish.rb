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
  notifies :run, 'execute[install-artifact]'
end

execute 'install-artifact' do
  command lazy { "sudo hab pkg install results/#{last_build_env['pkg_artifact']}" }
  cwd node['delivery']['workspace']['repo']
  action :nothing
  notifies :run, 'execute[export-container]'
end

execute 'export-container' do
  command lazy { "sudo hab pkg export docker #{last_build_env['pkg_ident']}" }
  action :nothing
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
end

docker_image "image-to-push" do
  repo lazy { "#{project_secrets['docker']['username']}/#{last_build_env['pkg_name']}" }
  tag lazy { "#{last_build_env['pkg_version']}-#{last_build_env['pkg_release']}" }
  action :push
end