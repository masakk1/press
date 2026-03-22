# press

A description of this project.

## Devcontainers

This project has a `devcontainer/devcontainer.json` file.

For VSCode

1. Get VSCode, Docker and the devcontainer VSCode extension
2. Open the project and run Dev Containers : Rebuild Container
3. You can Run and Debug the app by pressing F5, or in Run and Debug.

Checkout [Building](#building) if you need to run commands manually.


## Building

### Dependencies

If you're not using devcontainers, these are the dependencies:

> `vala-language-server` and `gdb` are only need for development

- Arch: `pacman -S base-devel meson ninja vala vala-language-server gtk4 libadwaita glib2 gobject-introspection uncrustify libgee`
    - Development packages: `yay -S --noconfirm vala-language-server gdb`
- Alpine for devcontainers: `sudo apk add alpine-sdk meson ninja gtk4.0-dev libadwaita-dev desktop-file-utils gobject-introspection-dev adwaita-icon-theme font-dejavu json-glib-dev libgee-dev uncrustify gdb vala vala-language-server`

### Steps

#### Configurate
this project uses `_build`

```bash
meson setup _build
# If the build directory was created with a different Meson version, reconfigure instead:
meson setup --reconfigure _build
```

#### Build

```bash
meson compile -C _build
# or using ninja directly:
ninja -C _build
```

#### Run

During development, it's necessary to include the local `data` folder. It may be necessary to hardcode "/usr/local/share:/usr/share" if XDG_DATA_DIRS is empty - Specially with alpine.
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

- Make sure you run the app from a graphical session (X11 or Wayland) so `DISPLAY` or `WAYLAND_DISPLAY` is available.

#### Install

```bash
sudo meson install -C _build
```

# Contributing

### Formatting
This project uses a `.editorconfig` for spacing basics, and `uncrustify.cfg` for code formatting.

The `uncrustify.cfg` is mostly from https://github.com/PerfectCarl/elementary-uncrustify, with some adjustments

Then, there are some guidelines:
1. Don't use GObject's construction system. Like `construct {}` and `Object(...)`.


