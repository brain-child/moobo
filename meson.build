# project name and programming language
project('com.github.brain_child.moobo', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Include the GNOME module
gnome = import('gnome')

# Tell meson where to find our resources file and to compile it as a GResource
gresource = gnome.compile_resources(
    'gresource',
    'data' / 'gresource.xml',
    source_dir: 'data'
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    gresource,
    'src' / 'Application.vala',
    'src' / 'Window.vala',
    'src' / 'Movable.vala',

    'src' / 'Widgets' / 'Board.vala',
    'src' / 'Widgets' / 'Row.vala',
    'src' / 'Widgets' / 'MenuItemColor.vala',
    'src' / 'Widgets' / 'ColorButton.vala',
    'src' / 'Widgets' / 'FloatingButton.vala',
    'src' / 'Widgets' / 'TextWidget.vala',
    'src' / 'Widgets' / 'LabelWidget.vala',
    'src' / 'Widgets' / 'ImageWidget.vala',

    'src' / 'Controllers' / 'BoardController.vala',
    'src' / 'Controllers' / 'RowController.vala',
    'src' / 'Controllers' / 'TextController.vala',
    'src' / 'Controllers' / 'LabelController.vala',
    'src' / 'Controllers' / 'ImageController.vala',
    'src' / 'Controllers' / 'FloatingButtonController.vala',

    'src' / 'Models' / 'BoardModel.vala',
    'src' / 'Models' / 'BaseModel.vala',
    'src' / 'Models' / 'TextModel.vala',
    'src' / 'Models' / 'LabelModel.vala',
    'src' / 'Models' / 'ImageModel.vala',

    'src' / 'Helper' / 'Colors.vala',
    'src' / 'Helper' / 'Constants.vala',
    'src' / 'Helper' / 'Serializer.vala',
    'src' / 'Helper' / 'Deserializer.vala',
    'src' / 'Helper' / 'DemoBoard.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('libhandy-1'),
        dependency('json-glib-1.0'),
    ],
    install: true
)

#Translate and install our .desktop file
i18n.merge_file(
    input: 'data' / 'moobo.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

#Translate and install our .appdata file
i18n.merge_file(
    input: 'data' / 'moobo.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: meson.source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo'
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
