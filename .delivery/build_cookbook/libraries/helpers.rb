include HabitatBuildCookbook::Helpers

::Chef::Recipe.send(:include, HabitatBuildCookbook::Helpers)
::Chef::Resource::Execute.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerTag.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerImage.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerRegistry.send(:include, HabitatBuildCookbook::Helpers)

module KubeBuildCookbook
  module Helpers
    def load_build_info
      Chef::DataBagItem.load('nationalparks-build-info', 'latest')
    rescue
      nil
    end

    def write_build_info(data)
      item = load_build_info || Chef::DataBagItem.new

    end
    
  end
end