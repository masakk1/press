# For Developers

## Building

### Flatpak, with GNOME Builder

Although development is done through [Devcontainers](https://containers.dev/),
you can use GNOME Builder for a more straight-forward experience.

### Native, with Meson

The inteded development environment, specially with [Development containers](https://containers.dev).

But you can check [Dependencies](#dependencies) for local development.

Press uses `just` recipes to simplify commands. Check [Commands](#commands) below.

#### Setting up Devcontainers

In Visual Studio Code:

1. Install de "Dev Containers" extension
2. Clone the repo in your local machine
3. Open Command Palette (Ctrl+Shift+P) > Rebuild and Reopen in Container

#### Dependencies

**Alpine**:

> Checkout [devcontainer.json](/.devcontainer/devcontainer.json) and the [Dockerfile](/.devcontainer/Dockerfile)

**Fedora**:

> If you haven't already installed codecs:
>   - [how to configure rpmfusion](https://rpmfusion.org/Configuration)
>   - [install multimedia codecs](https://rpmfusion.org/Howto/Multimedia).

```bash
sudo dnf install cmake meson ninja vala glib2-devel libgee-devel json-glib-devel msgfmt gtk4-devel libadwaita-devel update-desktop-database gstreamer1-devel gstreamer1-plugins-base-devel just

# Development packages
sudo dnf install vala-language-server uncrustify gdb git

# Just:
sudo dnf install cargo
cargo install just-lsp
```

#### Commands

This project uses `just` to handle commands, since it abstracts the complicated commands away. Type `just` to get a list of available commands.

> :memo: For VSCode
> - Run these commands with Tasks: `Ctrl+Shift+P > Tasks: Run Task`
> - Launch a debugging session: Press `F5`, or go to `Run and Debug (Ctrl-Shift-D) > Play button`


**Setup**:

> The build directory name is `_build`.

```bash
just setup

# If it complains about having to reconfigure
just setup-reconfigure

# If you're still having issues, wipe it
just setup-wipe
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

## Contributors Guide

### Formatting
This project uses a `.editorconfig` for spacing basics, and `uncrustify.cfg` for code formatting.

The `uncrustify.cfg` is mostly from https://github.com/PerfectCarl/elementary-uncrustify, with some adjustments
