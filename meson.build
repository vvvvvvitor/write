project(
'io.github.vvvvvvitor.write',
'vala', 'c',
version: '1.0.0',
license: '',
default_options : []
)

dependencies = [
    dependency('gtk4'),
    dependency('granite-7'),
    dependency('gio-2.0'),
    dependency('libadwaita-1')
]

source_files = files (
[
    'src' / 'main' / 'vala' / 'Application.vala',
    'src' / 'main' / 'vala' / 'MainWindow.vala',
    'src' / 'main' / 'vala' / 'DocumentView.vala',
    'src' / 'main' / 'vala' / 'DocumentStack.vala',
]
)

application = executable(
'text-editor',
dependencies: dependencies,
sources: source_files,
)
