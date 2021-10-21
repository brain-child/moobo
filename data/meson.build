config_data = configuration_data()
config_data.set('install_prefix', get_option('prefix'))
config_data.set('bin_dir', get_option('bindir'))
config_data.set('exec_name', meson.project_name())

icon_sizes = ['16', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach

install_data (
    'gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0', 'schemas'),
    rename: meson.project_name () + '.gschema.xml'
)
