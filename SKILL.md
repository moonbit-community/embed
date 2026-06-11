---
name: embed-files
description: "Embed files into a generated MoonBit source file."
---

# embed-files

Use this skill when the user wants to embed a file or all files from one
directory into a generated MoonBit source file.

## Run

```sh
moon runwasm moonbit-community/embed-files <path> -o <output.mbt>
```

## Behavior

- `-o <output.mbt>` is required and selects the generated MoonBit source file.
- The output directory must already exist.
- For a single text file, writes one
  private `let _embed_files_<file_name_ext> : String = #|...` and one public
  `pub let <file_name_ext> : String = _embed_files_<file_name_ext>`.
- For a single binary file, writes one
  private `let _embed_files_<file_name_ext> : Bytes = ([0xFF, 0xAA, ...] : Bytes)`
  and one public `pub let <file_name_ext> : Bytes = _embed_files_<file_name_ext>`.
- For a directory, reads all files recursively, including hidden files, and
  writes the requested output file.
- Directory output defines `pub struct <DirName>Fixture { ... }` and
  `pub let <dir_name> : <DirName>Fixture = { ... }`. Subdirectories are
  preserved as nested fixture structs and nested record values instead of being
  flattened into one struct.
- Embedded file contents are emitted as private `_embed_files_*` top-level
  constants, and the final directory value references those constants.
- File and directory name characters that are not ASCII letters or digits are
  converted to underscores in generated names.
- Duplicate generated names are suffixed with `_2`, `_3`, and so on.
