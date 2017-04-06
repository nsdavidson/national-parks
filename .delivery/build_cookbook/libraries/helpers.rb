include HabitatBuildCookbook::Helpers

::Chef::Recipe.send(:include, HabitatBuildCookbook::Helpers)
::Chef::Resource::Execute.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerTag.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerImage.send(:include, HabitatBuildCookbook::Helpers)
::DockerCookbook::DockerRegistry.send(:include, HabitatBuildCookbook::Helpers)
