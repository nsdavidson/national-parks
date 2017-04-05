pkg_name=national-parks
pkg_description="A sample JavaEE Web app deployed in the Tomcat8 package"
pkg_origin=nsdavidson
pkg_version=0.1.4
pkg_maintainer="Bill Meyer <bill@chef.io>"
pkg_license=('Apache-2.0')
pkg_source=none
pkg_deps=(core/tomcat8 core/jdk8 core/mongo-tools)
pkg_build_deps=(core/git core/maven)
pkg_expose=(8080)
pkg_svc_user="root"

do_download() {
    return 0
}

do_unpack()
{
    cp -a ../ ${HAB_CACHE_SRC_PATH}
}

do_build()
{
    build_line "do_build() ===================================================="

    # Maven requires JAVA_HOME to be set, and can be set via:
    export JAVA_HOME=$(hab pkg path core/jdk8)

    cd ${HAB_CACHE_SRC_PATH}
    mvn -q package
}

do_install()
{
    build_line "do_install() =================================================="

    # Our source files were copied over to the HAB_CACHE_SRC_PATH in do_build(),
    # so now they need to be copied into the root directory of our package through
    # the pkg_prefix variable. This is so that we have the source files available
    # in the package.

    local source_dir="${HAB_CACHE_SRC_PATH}"
    local webapps_dir="$(hab pkg path core/tomcat8)/tc/webapps"
    cp -v ${source_dir}/target/${pkg_name}.war ${webapps_dir}/

    # Copy our seed data so that it can be loaded into Mongo using our init hook
    cp -v ${source_dir}/national-parks.json ${PREFIX}/
}

do_verify()
{
    return 0
}
