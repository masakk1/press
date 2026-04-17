# For Developers

## Building

### Flatpak, with GNOME Builder

Although development is done through [Devcontainers](https://containers.dev/),
you can use GNOME Builder for a more straight-forward experience.

### Native, with Meson

The intended development environment, specially with [Development containers](https://containers.dev).

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

# Documentation
sudo dnf install valadoc graphviz npm
sudo npm install -g serve

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

### Code Style Guidelines


For this project, use [Elementary OS' Guidelines](https://docs.elementary.io/develop/writing-apps/code-style) with some extra steps:

1. String interpolation `@"word $variable $(obj.call ())"` is generally more readable than `.printf()`. With some exceptions:
    - Very long strings — such as error messages
    - Number formatting
2. Probably OK to use `as` in scenarios where you absolutely know that's what it is, like a `[GtkCallback]`
3. Try to use `this.` sparingly.
4. For `[GtkChild]` tags when declaring children, write the tag in the same line as the declaration.
	```vala
	[GtkChild] private unowned Adw.ActionRow source_directory_row;
	```
    - This does NOT include other tags, like `[GtkCallback]` 
5. Try to avoid using `constructor {}` syntax, unless it is necessary (i.e. a template)
6. Document all public methods and sometimes properties. 
    - Private methods should be documented, but it's optional if they aren't called, or are descriptive enough. (i.e. on_button_pressed isn't called)
    - Private attributes/properties aren't required to have comments
    - Public properties don't absolutely need it, but it is recommended
    - When modifying a method, remember to also update it's existing in-code documentation
8. Format your code, preferably before a commit. Checkout [formatting](#formatting)
9. You should avoid stray values, defining constants are preferred.
    - It's hard to change it afterwards
    - It's hard to understand what it is
    - Except for error messages!
    - OK `const string CUSTOM_NAME = "CustomName"`
    - NOT `names["CustomName"].call()`
    - NOT `num * 3.1415`
        - Instead: `const double PI = 3.1415` and `num * PI`
    - You don't have to enforce it strictly, but it certainly helps

### Formatting
This project uses _EditorConfig_ and `vala-lint`.

1. Use an automatic formatter
    - The official vala VS Code extension has a decent formatter.
2. Run `vala-lint` to check your code
    - `just lint` will say the errors you have
    - `just lint-fix` will try to fix some issues
