# Creating custom formats and presets

## Introduction

There's a file called `presets.json`, located in the data directory of your installation process.

You can access it by opening the _Main Menu_ > Open Presets Location

<details>
<summary>Flatpak locations</summary>
If that didn't work, here are common flatpak locations:

- `/var/lib/flatpak/app/io.github.masakk1.press/current/active/files/share/presets.json`
- `~/.local/share/flatpak/app/io.github.masakk1.press/current/active/files/extra/share/presets.json`
</details>

## Presets

### Quality

Quality presets are predefined configurations to compress to.
This is useful if you use a certain configuration *very often*, and would like to save it between sessions.

Otherwise, use the GUI. By selecting the "Custom" option on the Quality Preset selection.

For example, this is the _High Quality_ preset:

```json
"high": {
    "name": "High Quality",
    "format": "m4a",
    "bitrate": 192,
    "samplerate": 48000
},
```

From here on, duplicate that snippet, and change whatever parameter you'd like.
> :warning: Formats
>
> For formats, you must use the ones laid out under the `"formats"` code block.
>
> Notice how it uses the format _keyword_, not the full name.
> Such as:
> - Yes: `"format": "m4a",`
> - ~~Not: `"format": "AAC / m4a",`~~

### Formats

If you need a specific format and aren't familiar with [GStreamer](https://gstreamer.freedesktop.org/), feel free to request it by [opening an issue](https://github.com/masakk1/press/issues/new). Otherwise, welcome aboard!

This is an example for AAC, that outputs to m4a. It's quite simple at the moment.
```json
"m4a": {
    "name": "AAC / m4a",
    "extension": "m4a",
    "encoder": "avenc_aac",
    "encoderProperties": {},
    "bitrateMult": 1000,
    "filters": [
        "mp4mux"
    ]
},
```

Another example would be mp3s. lamemp3 requires some specific parameters, and some extra parsers/remuxers.
```json
"mp3": {
    "name": "MPEG / mp3",
    "extension": "mp3",
    "encoder": "lamemp3enc",
    "encoderProperties": {
        "target": 1
    },
    "bitrateMult": 1,
    "filters": [
        "mpegaudioparse",
        "xingmux",
        "id3v2mux"
    ]
},
```

- **name**: The display name on the interface.
    - The format should be: `Encoder / extension` — such as `AAC / m4a`
- **extension**: File extension name. Don't include a dot
    - Example: `mp3` or `m4a`
- **encoder**: The encoder element for GStreamer to recognize
- **encoderProperties**: If your encoder requires a certain property, add them here as key-value pairs. Leave it empty if you don't need any
    - Example: lamemp3 needs to be told to use bitrate with `target=1`
        ```json
        "encoder": "lamemp3enc",
        "encoderProperties": {
            "target": 1
        },
        ```
    - Example 2: `avenc_aac` doesn't require anything else, so leave it empty `{}`
        ```json
        "encoderProperties": {}
        ```
- **bitrateMult**: By default, bitrate is in kbps — i.e. 192 kbps. Different encoders take b/s.
    - in kbps? Leave it as 1: `"bitrateMult": 1,`
    - in bps? Multiply by 1000: `"bitrateMult": 1000,`
- **filters**: the rest of the GStreamer elements such as remuxers or parsers. These go right after the encoder.
    - for `avenc_aac`, we only need a single remuxer:
        ```json
        "filters": [
            "mp4mux"
        ]
        ```
    - for `lamemp3enc`, we need to have an image parser, xingmux, and id3v2mux for optimal outputs:
        ```json
        "filters": [
            "mpegaudioparse",
            "xingmux",
            "id3v2mux"
        ]
        ```

When you're done testing, [share it!](#contribute-back)

## Contribute back!

You made a custom format? Share it!

You made a custom quality preset, and you think it should *just be there already*? Share it!

Share it by:

1. Making a PR: [Contributing](/CONTRIBUTING.md).
2. Opening an issue with your suggestion: [New issue](https://github.com/masakk1/press/issues/new).
