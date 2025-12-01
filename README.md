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

These instructions describe how to build and run the application locally using Meson/Ninja (native build), matching what was used during development.

- Configure or reconfigure the build directory (this project uses `_build`):

```bash
meson setup _build
# If the build directory was created with a different Meson version, reconfigure instead:
meson setup --reconfigure _build
```

- Build the project:

```bash
meson compile -C _build
# or using ninja directly:
ninja -C _build
```

- Run the built binary (the executable is placed under `_build/src`):

```bash
_build/src/press
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


