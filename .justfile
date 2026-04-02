
# Default recipe
default:
    @just --list

# == Setup and compile ==

# Regular setup
setup:
    meson setup _build

# Setup with --reconfigure
setup-reconfigure:
    meson setup --reconfigure _build

# Setup with --wipe
setup-wipe:
    meson setup --wipe _build

compile:
    meson compile -C _build

# == Running ==

# Compile and run the binary - Optionally with a language
run lang="": compile
    LANGUAGE={{lang}} XDG_DATA_DIRS=data:$XDG_DATA_DIRS _build/src/press

# "run" with debugging on
run-debug lang="": compile
    G_MESSAGES_DEBUG=all just run {{lang}}

# == Translation macros ==

# Recreate pot file
create-pot: compile
    ninja -C _build press-pot

# run create-pot and create po files for each language
update-po: create-pot
    ninja -C _build press-update-po
