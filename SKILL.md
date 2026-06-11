---
name: embed-files
description: "Bundle a directory of UTF-8 files into a MoonBit source file."
---

# embed-files

Use this skill when the user wants to embed all UTF-8 files from one directory
into a generated MoonBit source file.

## Run

```sh
moon runwasm moonbit-community/embed-files <dir>
```

## Behavior

- Reads all UTF-8 files under `<dir>` recursively, including hidden files.
- Writes `<dir>_bundle.mbt`.
- Each file becomes `let <dir>_<file_path_parts> : String = #|...`.
- File and directory name characters that are not ASCII letters or digits are
  converted to underscores in the generated constant names.
- Duplicate generated names are suffixed with `_2`, `_3`, and so on.
- The input directory must be visible to the WASIp1 runner. For example:

```sh
wasmtime run --dir ./fixtures::fixtures _build/wasm/debug/build/embed-files/embed-files.wasm fixtures
```
