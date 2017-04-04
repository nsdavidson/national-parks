::Chef::Recipe.send(:include, HabitatBuildCookbook::Helpers)
::Chef::Resource::Execute.send(:include, HabitatBuildCookbook::Helpers)

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
