prefix := "/usr"
docdir := "./docs/press"

# Default recipe
default:
    @just --list

# == Setup and compile ==

# Regular setup
setup:
    meson setup _build --prefix={{prefix}}

# Setup with --reconfigure
setup-reconfigure:
    meson setup --reconfigure _build --prefix={{prefix}}

# Setup with --wipe
setup-wipe:
    meson setup --wipe _build --prefix={{prefix}}

compile:
    meson compile -C _build

lint:
    io.elementary.vala-lint src -c vala-lint.conf

lint-fix:
    io.elementary.vala-lint src -c vala-lint.conf --fix

# == Documentation ==

# Clean and create the generated documentation directory
docs-setup:
    rm -r {{docdir}}
    mkdir {{docdir}}

docs-generate:
    valadoc --force --package-name=press --package-version=0.2.0 \
    --pkg=gtk4 --pkg=libadwaita-1 --pkg=json-glib-1.0 --pkg=gee-0.8 \
    --pkg=gstreamer-1.0 --pkg=gstreamer-pbutils-1.0 \
    -o {{docdir}} \
    src/*.vala src/*.vapi \
    --private

# Serves the page in port 3000
docs-serve port="3000":
    npx serve {{docdir}} -p {{port}}

# Quick macro to clean, generate, and serve
docs: docs-setup docs-generate docs-serve

# == Running ==

# Compile and run the binary - Optionally with a language
run lang="": compile
    LANGUAGE={{lang}} \
    XDG_DATA_DIRS=data:${XDG_DATA_DIRS:-/usr/local/share:/usr/share} \
    _build/src/press

# "run" with debugging on
run-debug lang="": compile
    G_MESSAGES_DEBUG=all just run {{lang}}

# == Installing ==

install: setup-wipe compile
    meson install -C _build

# == Translation macros ==

# Recreate pot file
create-pot: compile
    ninja -C _build press-pot

# run create-pot and create po files for each language
update-po: create-pot
    ninja -C _build press-update-po
