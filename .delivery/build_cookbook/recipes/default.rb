include_recipe 'habitat-build::default'

docker_installation 'default'

package 'jq'

remote_file '/usr/local/bin/kubectl' do
  source 'https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Need to template out a kubectl config file here from secrets.  Putting config file on the build node for now.

