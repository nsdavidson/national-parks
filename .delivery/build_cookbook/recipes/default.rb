include_recipe 'habitat-build::default'

docker_installation 'default'

apt_repository 'kubernees' do
  uri 'http://apt.kubernetes.io/'
  components 'main'
  key 'https://packages.cloud.google.com/apt/doc/apt-key.gpg'
end

package 'kubectl'
