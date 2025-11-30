# press

A description of this project.

## Building

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

## Contributing

### Formatting
This project uses a `.editorconfig` for spacing basics, and `uncrustify.cfg` for code formatting.

The `uncrustify.cfg` is mostly from https://github.com/PerfectCarl/elementary-uncrustify, with some adjustments
