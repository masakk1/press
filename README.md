# press

A description of this project.

# Guides
## Building
### Building with flatpak extension

> :warning: This extension has some performance issues (2 Dec 2025), so checkout [Building without sandboxing](#building-without-sandboxing-meson) if that's still the case

Install the GNOME Sdk and Platform package from flathub
```sh
# change it for whatever the new version is (the io.github.masakk1.press.json manifest will have the specific one)
flatpak install flathub org.gnome.Platform//49
flatpak install flathub org.gnome.Sdk//49
```

Using the Flatpak extension by Bilal Elmoussaoui on VSCode:
```sh
# Open command palette (Ctrl+Shift+P)
> Build and run
```

### Building without sandboxing (meson)

#### Dependencies

- Arch: `pacman -S base-devel meson ninja vala gtk4 libadwaita glib2 gobject-introspection gdb uncrustify libgee`
- Alpine: `sudo apk add alpine-sdk meson ninja gtk4.0-dev libadwaita-dev desktop-file-utils gobject-introspection-dev adwaita-icon-theme font-dejavu json-glib-dev libgee-dev uncrustify gdb vala vala-language-server`

#### Building

These instructions describe how to build and run the application locally using Meson/Ninja (native build), matching what was used during development.

1. Configure or reconfigure the build directory (this project uses `_build`):

```bash
meson setup _build
# If the build directory was created with a different Meson version, reconfigure instead:
meson setup --reconfigure _build
```

2. Build the project:

```bash
meson compile -C _build
# or using ninja directly:
ninja -C _build
```

3. Run the built binary. Make sure to add the XDG_DATA_DIRS environment variable change. It won't run properly otherwise. It may be necessary to hardcode "/usr/local/share:/usr/share" if XDG_DATA_DIRS is empty - useful in barebones distros, like the alpine image used in devcontainers.
```bash
XDG_DATA_DIRS="data:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" _build/src/press
```

- Useful environment variables and debugging tips:

```bash
# Force GDK backend if needed:
GDK_BACKEND=wayland _build/src/press
# or
GDK_BACKEND=x11 _build/src/press

# Enable GLib/Gtk debug messages:
G_MESSAGES_DEBUG=all _build/src/press
```

- Notes:
	- Make sure you run the app from a graphical session (X11 or Wayland) so `DISPLAY` or `WAYLAND_DISPLAY` is available.
	- If `meson` complains about Meson version mismatches for an existing build directory, use `--reconfigure` or `meson setup --wipe _build` followed by `meson setup _build` to recreate the build directory.
	- To install the app system-wide (requires appropriate permissions):

```bash
sudo meson install -C _build
```

# Contributing

### Formatting
This project uses a `.editorconfig` for spacing basics, and `uncrustify.cfg` for code formatting.

The `uncrustify.cfg` is mostly from https://github.com/PerfectCarl/elementary-uncrustify, with some adjustments

Then, there are some guidelines:
1. Don't use GObject's construction system. Like `construct {}` and `Object(...)`.


