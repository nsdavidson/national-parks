::Chef::Recipe.send(:include, HabitatBuildCookbook::Helpers)

project_secrets = get_project_secrets

if habitat_origin_key?
  keyname = project_secrets['habitat']['keyname']
  origin = keyname.split('-')[0...-1].join('-')
end

hab_build node['delivery']['change']['project'] do
  origin origin
  plan_dir habitat_plan_dir
  cwd node['delivery']['workspace']['repo']
  home_dir delivery_workspace
  action :build
end