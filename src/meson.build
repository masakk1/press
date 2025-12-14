press_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'compressor.vala'
]

press_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('json-glib-1.0', required: true)
]

press_sources += gnome.compile_resources('press-resources',
  'ui/press.gresource.xml',
  c_name: 'press',
  source_dir: ['ui']
)

executable('press', press_sources,
  dependencies: press_deps,
  include_directories: config_inc,
       install: true,
)
