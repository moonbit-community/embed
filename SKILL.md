---
name: embed-files
description: "Embed files into a generated MoonBit source file."
---

# embed-files

Use this skill when the user wants to embed a file or all files from one
directory into a generated MoonBit source file.

## Run

```sh
moon runwasm moonbit-community/embed-files <path>
```

## Behavior

- For a single text file, writes `<file_name_ext>_bundle.mbt` with one
  `pub let <file_name_ext> : String = #|...`.
- For a single binary file, writes `<file_name_ext>_bundle.mbt` with one
  `pub let <file_name_ext> : Bytes = ([0xFF, 0xAA, ...] : Bytes)`.
- For a directory, reads all files recursively, including hidden files, and
  writes `<dir>_bundle.mbt`.
- Directory output defines `pub struct <DirName>Fixture { ... }` and
  `pub let <dir_name> : <DirName>Fixture = { ... }`, with each field typed as
  `String` or `Bytes`.
- File and directory name characters that are not ASCII letters or digits are
  converted to underscores in generated names.
- Duplicate generated names are suffixed with `_2`, `_3`, and so on.
