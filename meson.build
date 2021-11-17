# Project name, programming language and version
project (
    'com.github.brain_child.moobo',
    'c', 'vala',
    version: '0.1.1'
)

# GNOME module
gnome = import ('gnome')

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# Compiling resources
asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('gtk+-3.0'),
    dependency ('granite'),
    dependency ('libhandy-1'),
    dependency ('json-glib-1.0')
]


subdir ('src')

# Define executable
executable(
    meson.project_name (),
    sources,
    asresources,
    dependencies: dependencies,
    install: true
)

subdir ('data')
subdir ('po')

meson.add_install_script ('meson/post_install.py')
