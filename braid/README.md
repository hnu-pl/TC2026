# braid

Compose and execute literate code snippets across languages.

## Install locally

Place this package at:

- Linux: `$XDG_DATA_HOME/typst/packages/local/braid/0.1.0` (or `~/.local/share/typst/packages/local/braid/0.1.0`)
- macOS: `~/Library/Application Support/typst/packages/local/braid/0.1.0`
- Windows: `%APPDATA%/typst/packages/local/braid/0.1.0`

Then import it with:

```typst
#import "@local/braid:0.1.0": setup
```

## Quick start

```typst
#import "@local/braid:0.1.0": setup

#let braid = setup(config: (
  files-db: json("files.json"),
  build-dir: "_build",
  typfile-path: "../main.typ",
  tag-stdioe-cmd: "python ../tag-stdioe.py",
))

#let code(file: none, visible: true, body) =
  (braid.code)(file: file, visible: visible, body)

#(braid.init)()

#code(file: "Main.hs")[```haskell
main = print "hello"
```]
```

## Public API

- `setup(config: (:))`
- Returned members:
  - `init`
  - `code`
  - `read-raw`
  - `code-languages`
  - `cfg-state`
  - `get-extension`
  - `join-lines`
  - `join-str`
  - `count-lines`
  - `snippet-break-str`

## Config keys

- `files-db`: Required for metadata diffing and `read-raw`.
- `build-dir`: Output directory for generated source/input/output files.
- `typfile-path`: Path to main Typst source as seen from generated Makefile.
- `tag-stdioe-cmd`: Command used to run tagged stdio executor.
- `lang-configs`, `lang-aliases`, `codly-local`, `codly-lang-default`: Advanced rendering/runtime controls.
