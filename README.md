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

> `uncrustify`, `vala-language-server` and `gdb` are only need for development
>
> But for regular program use, you **will need** to install gstreamer plugins

<!-- Outdated - Arch: `pacman -S base-devel meson ninja vala vala-language-server gtk4 libadwaita glib2 gobject-introspection uncrustify libgee`
    - Development packages: `yay -S --noconfirm vala-language-server gdb` -->
- Alpine for devcontainers: `sudo apk add alpine-sdk meson ninja gtk4.0-dev libadwaita-dev desktop-file-utils gobject-introspection-dev adwaita-icon-theme font-dejavu json-glib-dev libgee-dev gstreamer-dev gst-plugins-base-dev uncrustify gdb vala vala-language-server just cargo`
- Fedora: `dnf install cmake meson ninja vala glib2-devel libgee-devel json-glib-devel msgfmt gtk4-devel libadwaita-devel update-desktop-database gstreamer1-devel gstreamer1-plugins-base-devel just`
    - Development packages: `dnf install vala-language-server uncrustify gdb git`
    - For just: `dnf install cargo` & `cargo install just-lsp`
    - Basic codecs, for the basic flac/mp3 support: `dnf install gstreamer1-plugins-good`
    - To install additional codecs, check [how to configure rpmfusion](https://rpmfusion.org/Configuration) and [install multimedia codecs](https://rpmfusion.org/Howto/Multimedia).
```bash
# Enable rpmfusion, and install codecs
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf group install -y multimedia
```

### Steps

This project uses `just` to handle commands, since it abstracts the complicated commands away. Type `just` to get a list of available commands.

**Setup**:

> The build directory name is `_build`.

```bash
just setup
```

**Compile**:

```bash
just compile
```

**Run**:

> Automatically compiles

```bash
just run

# With a specific language
just run es

# With debugging enabled, and a language
just run-debug es
```

**Install**:

```bash
just install
```

# Contributing

### Formatting
This project uses a `.editorconfig` for spacing basics, and `uncrustify.cfg` for code formatting.

The `uncrustify.cfg` is mostly from https://github.com/PerfectCarl/elementary-uncrustify, with some adjustments

Then, there are some guidelines:
1. Don't use GObject's construction system. Like `construct {}` and `Object(...)`.


