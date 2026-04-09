# For translators

<!-- Thanks bazaar. Pretty much copy-paste from their TRANSLATORS.md file. :) -->

# Instructions for Translators

Thank you for your interest in translating Press!

Some basic rules:
- You must be fluent in the language you contribute
- You may not use LLMs to generate the strings (I could do that). If
  you do, I will ban you from the project

## Basic Process

Fork the project (so you can open a PR later) and clone the repo. Then
make sure your current directory is the bazaar project root:

```sh
# Replace '...' with the URL of your Press fork
# for which you have write permissions
git clone ...
cd press
```

## Manual Setup

### Generating the necessary files

1. Once you're inside the `press` directory, edit `po/LINGUAS` and make sure your language exists.

> If it's already there, you're good to go

Let's say you speak Spanish. That would be `es`.
So if the `po/LINGUAS` file currently looks like this:

```bash
# Please keep this file sorted alphabetically.
ab
en_GB
ms
```

you will edit the file to look like this:

```bash
# Please keep this file sorted alphabetically.
ab
en_GB
es
ms
```

2. Generate the necessary PO files

If you have installed the necessary dependencies, and `just` is installed:

```bash
just update-po
```

There should be a `.po` file with your language. Such as: `es.po`.

3. You can now translate

### Testing

If you need to test your translation, you can run the application with `just run`, and specifying your language.

Example for Spanish:

```bash
just run es
```

### Uploading

Once you're done, stage and commit your changes.

```bash
# If you were editing the es.po, for a Spanish translation

# 1. Stage
git add po/es.po

# 2. Commit
git commit -m "translation: (es) Update Spanish translation"

# 3. Push
git push
```

Then, you can open a PR

# Notes For Translators

Both automatic and manual processes may generate entries marked as `fuzzy`.
This means that for such entries, `gettext` attempted to derive previously
existing translation. Some translation suites, like Lokalize, will utilize this
marking to set strings as unreviewed and remove when the entry is marked
finished. When working with pot-files using text editor, be sure to remove
`fuzzy` marks yourself from entries you deem finished, else your translation
will not appear in Press.
