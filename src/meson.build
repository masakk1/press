press_sources = [
  'main.vala',
  'compress_config.vala',
  'compressor.vala',
  'presets_loader.vala',

  'application.vala',
  'config_page.vala',
  'window.vala',
]

press_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('json-glib-1.0', required: true),
  dependency('gee-0.8', required: true),
  dependency('gstreamer-1.0', required: true),
  dependency('gstreamer-pbutils-1.0', required: true),
]

press_sources += gnome.compile_resources(
  'press-resources',
  'ui/press.gresource.xml',
  c_name: 'press',
  source_dir: ['ui'],
)

executable(
  'press',
  press_sources,
  dependencies: press_deps,
  include_directories: config_inc,
  install: true,
)
