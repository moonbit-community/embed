---
name: embed-files
description: "Embed UTF-8 files into a generated MoonBit source file."
---

# embed-files

Use this skill when the user wants to embed a UTF-8 file or all UTF-8 files
from one directory into a generated MoonBit source file.

## Run

```sh
moon runwasm moonbit-community/embed-files <path>
```

## Behavior

- For a single file, writes `<file_name_ext>_bundle.mbt` with one
  `pub let <file_name_ext> : String = #|...`.
- For a directory, reads all UTF-8 files recursively, including hidden files,
  and writes `<dir>_bundle.mbt`.
- Directory output defines `pub struct <DirName>Fixture { ... }` and
  `pub let <dir_name> : <DirName>Fixture = { ... }`.
- File and directory name characters that are not ASCII letters or digits are
  converted to underscores in generated names.
- Duplicate generated names are suffixed with `_2`, `_3`, and so on.
