press_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

press_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
]

press_sources += gnome.compile_resources('press-resources',
  'press.gresource.xml',
  c_name: 'press'
)

executable('press', press_sources,
  dependencies: press_deps,
  include_directories: config_inc,
       install: true,
)
